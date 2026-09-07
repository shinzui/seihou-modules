# {{project.name}}

{{project.description}}

This is the initial six-package Keiro service structure. Libraries build before domain
implementation; HTTP, workers, migrations, client generation, and runtime tests still need
implementation. Follow [the bootstrap brief](docs/bootstrap-keiro.md) or run the
`haskell-keiro-service` Seihou blueprint with the same project variables.

```bash
nix develop
just build
just --list
```

Core owns domain and read models; API owns routes; server owns HTTP execution; workers own
background processing; migrations owns the independent migration toolchain; client consumes API.
The domain contract lives in `domain/{{keiro.context}}.keiro-workspace`. Add real aggregate
members before scaffolding and paste the complete generated Cabal fragment into core.

The Nix module supplies PostgreSQL and process-compose. `just create-database` creates only the
local database until migration wiring is implemented. Set `DATABASE_URL` explicitly for the real
migration CLI. Customize Nix in `flake.module.nix` and process-compose in its override file;
keep managed base files unchanged. There is no default Nix package build for this multi-package
workspace; use Cabal in the dev shell and add a project-specific build when needed.

This module seeds files that become hand-owned during implementation. Review `seihou diff`
before reapplying it; never force it over domain changes. Update `nix-haskell-flake` independently.

Standards: `mori://shinzui/keiro-runtime-patterns/docs/runtime-patterns-getting-started`.
