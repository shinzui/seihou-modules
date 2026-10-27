#!/usr/bin/env bash
#
# update-nix-haskell-flake-lock.sh — regenerate the nix-haskell-flake module's
# canonical pin (files/flake.nix.tpl) and lock (files/flake.lock) together, so
# every project generated from a given module version locks to byte-identical
# inputs and shares one nix store closure.
#
# The generated flake pins haskell-nix-dev, haskell-nix, redpanda-container and nix2container;
# other module-owned inputs follow those pins. The locked graph is a pure function
# of those immutable selections, and the
# shipped flake.lock is a cache-warming convenience rather than the source of
# truth. That also means a project may add inputs of its own without any merge:
# `nix flake lock` there only appends nodes, and `nix flake update` cannot move a
# rev-pinned input.
#
# This script is the only supported way to move that rev. It:
#   1. resolves the target haskell-nix-dev rev (--rev, else latest master) and
#      haskell-nix rev (--haskell-nix-rev, else latest master),
#   2. rewrites both revs in files/flake.nix.tpl,
#   3. renders the canonical inputs block (all module-owned inputs are always
#      locked; feature toggles only control imports and generated files),
#   4. asserts `nix flake update` on that flake is a no-op (the pin really sticks),
#   5. asserts a minimal feature configuration reproduces the identical lock,
#   6. writes files/flake.lock.
#
# Usage:
#   update-nix-haskell-flake-lock.sh [--rev REV] [--haskell-nix-rev REV] [--nix2container-rev REV] [--check]
#
#   --rev REV   Pin to a specific haskell-nix-dev revision (default: latest master).
#   --haskell-nix-rev REV
#               Pin to a specific haskell-nix revision (default: latest master).
#   --nix2container-rev REV
#               Pin nix2container (default: preserve the template's released pin).
#   --check     Verify the shipped tpl/lock against its current pins (unless
#               explicitly overridden). Writes nothing. For CI.
#
# It never commits, and it does not bump the module version — do both by hand.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MODULE_FILES="$REPO_ROOT/modules/haskell/nix-haskell-flake/files"
TPL="$MODULE_FILES/flake.nix.tpl"
LOCK="$MODULE_FILES/flake.lock"
FLAKE_REF="github:shinzui/haskell-nix-dev"
HN_FLAKE_REF="github:shinzui/haskell-nix"

REV=""
HN_REV=""
N2C_REV=""
CHECK=0
while [ $# -gt 0 ]; do
  case "$1" in
    --rev) REV="$2"; shift 2 ;;
    --haskell-nix-rev) HN_REV="$2"; shift 2 ;;
    --nix2container-rev) N2C_REV="$2"; shift 2 ;;
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

out, stack = [], []
for line in lines:
    stripped = line.strip()
    if stripped.startswith("{{#if"):
        # Output-module conditionals are irrelevant to the extracted inputs block.
        # Keep both modes for the exact-lock assertion below and for compatibility
        # with older templates where inputs were conditional.
        stack.append(mode == "minimal")
        continue
    if stripped.startswith("{{/if}}"):
        if stack:
            stack.pop()
        continue
    if any(stack):
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
# Validation must remain reproducible when upstream master moves. Regeneration
# may deliberately choose latest; --check defaults to the shipped selections.
template_revision() {
  python3 - "$TPL" "$1" <<'PY'
import re, sys
text = open(sys.argv[1]).read()
matches = re.findall(r'github:' + re.escape(sys.argv[2]) + r'/([0-9a-f]{40})(?=")', text)
if len(matches) != 1:
    sys.exit('expected one immutable template pin for ' + sys.argv[2])
print(matches[0])
PY
}
if [ "$CHECK" -eq 1 ]; then
  [ -n "$REV" ] || REV="$(template_revision shinzui/haskell-nix-dev)"
  [ -n "$HN_REV" ] || HN_REV="$(template_revision shinzui/haskell-nix)"
fi
[ -n "$N2C_REV" ] || N2C_REV="$(template_revision nlewo/nix2container)"
for pin in "$REV" "$HN_REV" "$N2C_REV"; do
  [ -z "$pin" ] || [[ "$pin" =~ ^[0-9a-f]{40}$ ]] || { echo "expected a full immutable revision: $pin" >&2; exit 2; }
done
echo "target nix2container rev: $N2C_REV"
if [ -z "$REV" ]; then
  echo "resolving latest $FLAKE_REF …"
  REV="$(nix flake metadata "$FLAKE_REF" --refresh --json \
        | python3 -c 'import json,sys; print(json.load(sys.stdin)["revision"])')"
fi
echo "target haskell-nix-dev rev: $REV"
if [ -z "$HN_REV" ]; then
  echo "resolving latest $HN_FLAKE_REF …"
  HN_REV="$(nix flake metadata "$HN_FLAKE_REF" --refresh --json \
        | python3 -c 'import json,sys; print(json.load(sys.stdin)["revision"])')"
fi
echo "target haskell-nix rev: $HN_REV"

# --- 2. rewrite the pin in the template --------------------------------------
python3 - "$TPL" "$REV" "$HN_REV" "$WORK/flake.nix.tpl" "$N2C_REV" <<'PY'
import re, sys
src = open(sys.argv[1]).read()
out = re.sub(r'(github:shinzui/haskell-nix-dev)(/[^"?]*)?', r'\1/' + sys.argv[2], src)
assert out.count("github:shinzui/haskell-nix-dev/" + sys.argv[2]) == 1, \
    "expected exactly one haskell-nix-dev pin in the template"
out = re.sub(r'(github:shinzui/haskell-nix)(?![-\w])(/[^"?]*)?', r'\1/' + sys.argv[3], out)
assert out.count("github:shinzui/haskell-nix/" + sys.argv[3]) == 1, \
    "expected exactly one haskell-nix pin in the template"
out, count = re.subn(r'github:nlewo/nix2container/[^"?]*', 'github:nlewo/nix2container/' + sys.argv[5], out)
assert count == 1, "expected exactly one nix2container pin in the template"
open(sys.argv[4], "w").write(out)
PY

# --- 3. lock the canonical inputs render -------------------------------------
mkdir -p "$WORK/superset"
render_inputs "$WORK/flake.nix.tpl" all > "$WORK/superset/flake.nix"
git -C "$WORK/superset" init -q .
git -C "$WORK/superset" add flake.nix
echo "locking the canonical flake …"
nix flake lock "$WORK/superset" >/dev/null

for node in haskell-nix-dev nixpkgs flake-parts treefmt-nix pre-commit-hooks haskell-nix nix2container; do
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
if ! cmp -s "$WORK/superset.lock.before" "$WORK/superset/flake.lock"; then
  echo "FAIL: 'nix flake update' moved a module-owned pin — the graph is not fully rev-pinned." >&2
  diff <(lock_pins "$WORK/superset.lock.before") <(lock_pins "$WORK/superset/flake.lock") >&2 || true
  exit 1
fi
echo "ok: 'nix flake update' is a no-op against the canonical lock"

# --- 5. a minimal feature set must reproduce the exact lock -------------------
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
if ! cmp -s "$WORK/superset/flake.lock" "$WORK/minimal/flake.lock"; then
  echo "FAIL: feature toggles changed the canonical lock" >&2
  diff -u "$WORK/superset/flake.lock" "$WORK/minimal/flake.lock" >&2 || true
  exit 1
fi
echo "ok: feature toggles reproduce the exact canonical lock"

# --- 6. publish or check ------------------------------------------------------
if [ "$CHECK" = 1 ]; then
  status=0
  diff -u "$TPL" "$WORK/flake.nix.tpl" || status=1
  diff -u "$LOCK" "$WORK/superset/flake.lock" || status=1
  if [ "$status" = 0 ]; then
    echo "✓ shipped template and lock match the canonical pins $REV / haskell-nix $HN_REV"
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
