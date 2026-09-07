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
    .bin/keiro-dsl check domain/{{keiro.context}}.keiro-workspace --min-language 5 --deny-warnings --coverage-report .artifacts/keiro-coverage.json --report-out .artifacts/keiro-check.json

keiro-scaffold: keiro-check
    .bin/keiro-dsl scaffold domain/{{keiro.context}}.keiro-workspace --out {{project.name}}-core/src --runtime-package {{project.name}}-core --goldens domain/golden-payloads

# Historical golden output is resolved relative to the workspace manifest directory.
keiro-diff:
    mkdir -p .artifacts domain/golden-payloads
    .bin/keiro-dsl diff domain/{{keiro.context}}.keiro-workspace --since HEAD --explain --emit-goldens golden-payloads --report-out .artifacts/keiro-diff.json --replay-impact-out .artifacts/replay-impact.json

keiro-conformance:
    cabal test keiro-{{keiro.context}}-conformance:conformance
