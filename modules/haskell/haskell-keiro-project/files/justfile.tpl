# Run from the repository root. Install the verified DSL release into .bin first.
build:
    cabal build all

test:
    cabal test all

format:
    nix fmt

# Required by the nix-haskell-flake process-compose create_schema process.
# Bootstrap creates the database only. Wire the real migration CLI here once implemented.
create-database:
    #!/usr/bin/env bash
    set -euo pipefail
    : "${PGDATABASE:?Enter nix develop first}"
    exists=$(psql -X -d postgres --set=db="$PGDATABASE" -tA <<'SQL'
    SELECT 1 FROM pg_database WHERE datname = :'db';
    SQL
    )
    if [ "$exists" != "1" ]; then createdb -- "$PGDATABASE"; fi

keiro-check:
    mkdir -p .artifacts
    .bin/keiro-dsl check domain/{{project.name}}.keiro-workspace --min-language 5 --deny-warnings --coverage-report .artifacts/keiro-coverage.json --report-out .artifacts/keiro-check.json

keiro-scaffold: keiro-check
    .bin/keiro-dsl scaffold domain/{{project.name}}.keiro-workspace --out {{project.name}}-core/src --runtime-package {{project.name}}-core --goldens domain/golden-payloads

# Historical golden output is resolved relative to the workspace manifest directory.
keiro-diff:
    mkdir -p .artifacts domain/golden-payloads
    .bin/keiro-dsl diff domain/{{project.name}}.keiro-workspace --since HEAD --explain --emit-goldens golden-payloads --report-out .artifacts/keiro-diff.json --replay-impact-out .artifacts/replay-impact.json

keiro-conformance:
    cabal test keiro-{{project.name}}-conformance:conformance

# Build first: stdout from the executable is schema JSON only.
openapi:
    cabal build {{project.name}}-openapi
    mkdir -p docs
    "$(cabal list-bin {{project.name}}-openapi)" > docs/openapi.json.tmp
    mv docs/openapi.json.tmp docs/openapi.json

openapi-check:
    #!/usr/bin/env bash
    set -euo pipefail
    cabal build {{project.name}}-openapi
    tmp=$(mktemp)
    trap 'rm -f "$tmp"' EXIT
    "$(cabal list-bin {{project.name}}-openapi)" > "$tmp"
    diff -u docs/openapi.json "$tmp"

test-tools:
    hurl-workbench --version
    hinagata --version
    hurl-workbench --workspace hurl-workbench.dhall doctor

api-validate:
    hurl-workbench --workspace hurl-workbench.dhall validate

api-render:
    hurl-workbench --workspace hurl-workbench.dhall render workflow health

api-test $base_url="http://127.0.0.1:8080":
    hurl-workbench --workspace hurl-workbench.dhall test suite smoke --variable base_url="$base_url"

fixture-plan $name="bootstrap":
    bash scripts/keiro-test-env --check-config
    bash scripts/keiro-test-env fixture plan "$name" --json

fixture-load $target $name="bootstrap":
    bash scripts/keiro-test-env fixture load "$name" --target-database "$target" --json

fixture-with $name="bootstrap":
    bash scripts/keiro-test-env db with --fixture "$name" -- bash -euo pipefail -c 'value=$(psql -X -tAc "SELECT value FROM hinagata_bootstrap.marker WHERE id = 1"); test "$value" = ready; printf "%s\n" "$value"'
