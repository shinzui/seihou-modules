# {{project.name}}

> {{project.description}}
{{#if IsSet project.description-long}}

{{project.description-long}}
{{/if}}

## Layout

This project is split into two cabal packages:

- **`{{project.name}}-core`** — the library. Domain types, business logic, and
  the project-wide `{{project.namespace}}.Prelude` that re-exports
  [`lens`](https://hackage.haskell.org/package/lens) and
  [`generic-lens`](https://hackage.haskell.org/package/generic-lens).
- **`{{project.name}}-cli`** — the command-line interface. Exposes
  `{{project.namespace}}.Cli.runCli` and ships an executable named
  **`{{project.name}}`** that just calls it.

Both packages target **GHC `{{ghc.version}}`** with `default-language: GHC2024`
and the same warning set + default extensions
(`DeriveAnyClass`, `DuplicateRecordFields`, `OverloadedLabels`, `OverloadedStrings`).

## Develop

The project ships a Nix flake (`nix-haskell-flake`) that pins GHC and provides
the dev shell. Enter the shell with:

```bash
nix develop      # or: direnv allow, if you use direnv
```

Then build and run:

```bash
cabal build all
cabal run {{project.name}} -- hello --name world
```

## License

[BSD-3-Clause](./LICENSE) — (c) {{project.copyright-year}} {{project.author}}.
