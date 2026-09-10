#!/usr/bin/env bash
#
# update-nix-haskell-flake-lock.sh — regenerate the nix-haskell-flake module's
# canonical pin (files/flake.nix.tpl) and lock (files/flake.lock) together, so
# every project generated from a given module version locks to byte-identical
# inputs and shares one nix store closure.
#
# How the determinism works: the generated flake.nix has exactly ONE pin of its
# own — the haskell-nix-dev revision — and every other module-owned input
# `follows` it. So the whole locked graph is a pure function of that rev, and the
# shipped flake.lock is a cache-warming convenience rather than the source of
# truth. That also means a project may add inputs of its own without any merge:
# `nix flake lock` there only appends nodes, and `nix flake update` cannot move a
# rev-pinned input.
#
# This script is the only supported way to move that rev. It:
#   1. resolves the target haskell-nix-dev rev (--rev, else latest master),
#   2. rewrites the rev in files/flake.nix.tpl,
#   3. renders the SUPERSET flake (every optional input switched on) and locks it,
#      so projects with any combination of toggles find their nodes present,
#   4. asserts `nix flake update` on that flake is a no-op (the pin really sticks),
#   5. asserts a minimal project (treefmt and pre-commit off) reusing the lock
#      keeps the identical haskell-nix-dev/nixpkgs pins,
#   6. writes files/flake.lock.
#
# Usage:
#   update-nix-haskell-flake-lock.sh [--rev REV] [--check]
#
#   --rev REV   Pin to a specific haskell-nix-dev revision (default: latest master).
#   --check     Verify only: fail if the shipped tpl/lock are not what this script
#               would produce for the current pin. Writes nothing. For CI.
#
# It never commits, and it does not bump the module version — do both by hand.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MODULE_FILES="$REPO_ROOT/modules/haskell/nix-haskell-flake/files"
TPL="$MODULE_FILES/flake.nix.tpl"
LOCK="$MODULE_FILES/flake.lock"
FLAKE_REF="github:shinzui/haskell-nix-dev"

REV=""
CHECK=0
while [ $# -gt 0 ]; do
  case "$1" in
    --rev) REV="$2"; shift 2 ;;
    --check) CHECK=1; shift ;;
    -h|--help) sed -n '2,36p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "unknown argument: $1" >&2; exit 2 ;;
  esac
done

[ -f "$TPL" ] || { echo "missing template: $TPL" >&2; exit 1; }

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

# --- template rendering -------------------------------------------------------
# Render the module template the way the seihou engine would with every toggle
# on, then keep only the `inputs = { … };` block: locking depends on nothing else,
# so this stays correct as the rest of the template evolves.
render_inputs() { # $1 = tpl, $2 = "all" | "minimal"
  python3 - "$1" "$2" <<'PY'
import re, sys
tpl, mode = sys.argv[1], sys.argv[2]
lines = open(tpl).read().splitlines()

out, skipping = [], 0
for line in lines:
    stripped = line.strip()
    if stripped.startswith("{{#if"):
        # "all" keeps every conditional body (the superset); "minimal" drops them.
        skipping += 1 if mode == "minimal" else 0
        continue
    if stripped.startswith("{{/if}}"):
        skipping = max(0, skipping - 1)
        continue
    if skipping:
        continue
    out.append(line)

text = re.sub(r"\{\{[^}]*\}\}", "rendered-by-update-nix-haskell-flake-lock", "\n".join(out))

# Extract `inputs = { … };` by brace matching.
start = text.index("inputs = {")
depth, i = 0, text.index("{", start)
while True:
    if text[i] == "{":
        depth += 1
    elif text[i] == "}":
        depth -= 1
        if depth == 0:
            break
    i += 1
block = text[start:i + 1]
assert "haskell-nix-dev.url" in block, "rendered inputs block has no haskell-nix-dev pin"
print("{\n  " + block + ";\n\n  outputs = _: { };\n}")
PY
}

lock_pins() { # $1 = flake.lock -> "name<TAB>rev" lines, sorted
  python3 - "$1" <<'PY'
import json, sys
nodes = json.load(open(sys.argv[1]))["nodes"]
for name in sorted(nodes):
    rev = nodes[name].get("locked", {}).get("rev")
    if rev:
        print(f"{name}\t{rev}")
PY
}

# --- 1. target rev ------------------------------------------------------------
if [ -z "$REV" ]; then
  echo "resolving latest $FLAKE_REF …"
  REV="$(nix flake metadata "$FLAKE_REF" --refresh --json \
        | python3 -c 'import json,sys; print(json.load(sys.stdin)["revision"])')"
fi
echo "target haskell-nix-dev rev: $REV"

# --- 2. rewrite the pin in the template --------------------------------------
python3 - "$TPL" "$REV" "$WORK/flake.nix.tpl" <<'PY'
import re, sys
src = open(sys.argv[1]).read()
out = re.sub(r'(github:shinzui/haskell-nix-dev)(/[^"?]*)?', r'\1/' + sys.argv[2], src)
assert out.count("github:shinzui/haskell-nix-dev/" + sys.argv[2]) == 1, \
    "expected exactly one haskell-nix-dev pin in the template"
open(sys.argv[3], "w").write(out)
PY

# --- 3. lock the superset render ---------------------------------------------
mkdir -p "$WORK/superset"
render_inputs "$WORK/flake.nix.tpl" all > "$WORK/superset/flake.nix"
git -C "$WORK/superset" init -q .
git -C "$WORK/superset" add flake.nix
echo "locking the superset flake …"
nix flake lock "$WORK/superset" >/dev/null

for node in haskell-nix-dev nixpkgs flake-parts treefmt-nix pre-commit-hooks; do
  python3 -c "
import json,sys
nodes = json.load(open('$WORK/superset/flake.lock'))['nodes']
sys.exit(0 if '$node' in nodes else 1)
" || { echo "FAIL: superset lock is missing node '$node'" >&2; exit 1; }
done

# --- 4. the pin must be immovable by a full update ----------------------------
cp "$WORK/superset/flake.lock" "$WORK/superset.lock.before"
git -C "$WORK/superset" add flake.lock
nix flake update --flake "$WORK/superset" >/dev/null 2>&1
if ! diff -q <(lock_pins "$WORK/superset.lock.before") <(lock_pins "$WORK/superset/flake.lock") >/dev/null; then
  echo "FAIL: 'nix flake update' moved a module-owned pin — the graph is not fully rev-pinned." >&2
  diff <(lock_pins "$WORK/superset.lock.before") <(lock_pins "$WORK/superset/flake.lock") >&2 || true
  exit 1
fi
echo "ok: 'nix flake update' is a no-op against the canonical lock"

# --- 5. a minimal project must reuse the same shared pins ---------------------
mkdir -p "$WORK/minimal"
render_inputs "$WORK/flake.nix.tpl" minimal > "$WORK/minimal/flake.nix"
cp "$WORK/superset/flake.lock" "$WORK/minimal/flake.lock"
git -C "$WORK/minimal" init -q .
git -C "$WORK/minimal" add flake.nix flake.lock
nix flake lock "$WORK/minimal" >/dev/null 2>&1
for node in haskell-nix-dev nixpkgs; do
  a="$(lock_pins "$WORK/superset/flake.lock" | awk -v n="$node" '$1==n{print $2}')"
  b="$(lock_pins "$WORK/minimal/flake.lock"  | awk -v n="$node" '$1==n{print $2}')"
  [ "$a" = "$b" ] || { echo "FAIL: minimal project got a different '$node' ($b != $a)" >&2; exit 1; }
done
echo "ok: a toggles-off project reuses the identical haskell-nix-dev/nixpkgs pins"

# --- 6. publish or check ------------------------------------------------------
if [ "$CHECK" = 1 ]; then
  status=0
  diff -u "$TPL" "$WORK/flake.nix.tpl" || status=1
  diff -u <(lock_pins "$LOCK") <(lock_pins "$WORK/superset/flake.lock") || status=1
  if [ "$status" = 0 ]; then
    echo "✓ shipped template and lock match the canonical pin $REV"
  else
    echo "✗ shipped template/lock are stale — rerun without --check" >&2
  fi
  exit $status
fi

cp "$WORK/flake.nix.tpl" "$TPL"
cp "$WORK/superset/flake.lock" "$LOCK"
echo
echo "wrote:"
echo "  ${TPL#"$REPO_ROOT"/}"
echo "  ${LOCK#"$REPO_ROOT"/}"
echo
echo "Next: bump the module version in module.dhall + seihou-registry.dhall, note the"
echo "toolchain move in the module README, and commit."
