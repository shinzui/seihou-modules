# haskell-keiro-project

Bootstrap the shared structure of a Keiro service. This module composes `nix-haskell-flake`
and seeds six Cabal libraries, a custom Prelude, one `.keiro-workspace` manifest, a shared
Language 5 member, a justfile, BSD-3 license, README, and `docs/bootstrap-keiro.md`.
It does not invent a business domain or generate a working server from a project synopsis.

```bash
seihou run haskell-keiro-project
```

Prompts collect `project.name`, `project.namespace`, `project.description`, `keiro.context`,
`project.author`, `project.maintainer`, `project.copyright-year`, and `haskell.index-state`.
Author, maintainer, year, and index-state have defaults; use `--confirm-defaults` to review them.
Use `--var key=value` for noninteractive overrides. The inherited Nix variables remain available.
PostgreSQL and process-compose default on; the single-root Nix package build defaults off because
the Cabal files live in six child directories. GHC 9.12.4 is the bootstrap compiler contract.

For agent-assisted domain implementation, install and run the companion blueprint:

```bash
seihou agent run haskell-keiro-service
```

The blueprint applies this module first and then follows its generated brief. Use the same
variables when continuing a separately generated scaffold. Read the brief directly to use a
coding agent without the blueprint. It covers current standard discovery, released dependency
verification, domain questions, workspace generation, package boundaries, migrations, settings,
telemetry, HTTP, workers, and behavioral acceptance. Existing reference sketches are historical;
they do not override current standards or verified release APIs.

The six initial libraries are intentionally minimal and build before implementation. Executables,
real routes, SQL, worker registrations, lifecycle diagrams, and runtime tests are created during
the domain implementation phase. `just create-database` creates only the database until the real
migration CLI is wired in. DSL recipes require a verified tool installed in `.bin/keiro-dsl`.
The shared-only seed carries no business contract; author real members before scaffolding.

Keep later Nix customization in `flake.module.nix`. Update `nix-haskell-flake` independently;
review Seihou diffs before reapplying this seed module and never force it over hand-owned changes.

The package and workspace structure follows
`mori://shinzui/keiro-runtime-patterns/docs/architecture-service-packages` and
`mori://shinzui/keiro-runtime-patterns/docs/keiro-service-workspaces`, with
`mori://shinzui/jinmyaku` as a structural example. No files are copied from that project's domain.

Validate from this repository with `python3 scripts/check-keiro-bootstrap.py`.
