# {{project.name}}

> {{project.description}}
{{#if IsSet project.description-long}}

{{project.description-long}}
{{/if}}

## Layout

This project is split into two cabal packages:

- **`{{project.name}}-core`** — the reusable library. The starter
  `{{project.namespace}}.greet` function is called by the CLI, and the project-wide
  `{{project.namespace}}.Prelude` re-exports
  [`lens`](https://hackage.haskell.org/package/lens) and
  [`generic-lens`](https://hackage.haskell.org/package/generic-lens).
- **`{{project.name}}-cli`** — the command-line interface. Exposes parser types,
  `parserInfo`, and `{{project.namespace}}.Cli.runCli`, and ships an executable named
  **`{{project.name}}`**.{{#if Eq project.tests true}} Its Tasty suite checks the core behavior
  and parses the starter command without mutating process arguments.{{/if}}

Both packages use **GHC `{{ghc.version}}`** by default and expose **GHC 9.14.1** as a
secondary shell. They use `default-language: GHC2024` and the same warning set + default extensions
(`DeriveAnyClass`, `DuplicateRecordFields`, `OverloadedLabels`, `OverloadedStrings`).
Each package contains its own `LICENSE` and `CHANGELOG.md`, so `cabal check` and source
distributions do not depend on parent-directory paths.

## Develop

The project ships a Nix flake (`nix-haskell-flake`) that pins GHC and provides
the dev shell. Enter the shell with:

```bash
nix develop                # GHC {{ghc.version}} with HLS
nix develop .#ghc9141      # current stable GHC compatibility shell
```

To add dev-shell tools or extra flake outputs, copy `flake.module.nix.example` to
`flake.module.nix` and edit it. It is imported automatically and is never overwritten
by template upgrades, so your customizations there survive `nix-haskell-flake` updates.

Then build and run:

```bash
cabal build all
{{#if Eq project.tests true}}cabal test all
{{/if}}cabal run {{project.name}} -- hello --name world
```

The flake exposes both packages and chooses the CLI executable as the default package.
{{#if Eq project.tests true}}It also runs the test suite as a flake check.
{{#else}}It can still be checked without a generated test suite.
{{/if}}

```bash
nix build                         # same as .#{{project.name}}-cli
nix build .#{{project.name}}-core
nix flake check
nix fmt -- --ci .
```

## License

[BSD-3-Clause](./LICENSE) — (c) {{project.copyright-year}} {{project.author}}.
