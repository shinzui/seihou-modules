# {{project.name}}

> {{project.description}}
{{#if IsSet project.description-long}}

{{project.description-long}}
{{/if}}

## Layout

This project is a single cabal package:

- **`{{project.name}}`** — the library. Exposes the top-level
  `{{project.namespace}}` module (your public API surface) and a
  project-wide `{{project.namespace}}.Prelude` that re-exports
  [`lens`](https://hackage.haskell.org/package/lens) and
  [`generic-lens`](https://hackage.haskell.org/package/generic-lens) so
  individual modules can `import {{project.namespace}}.Prelude` and skip
  the usual per-module vocabulary imports.
{{#if Eq project.tests true}}
- **`{{project.name}}-test`** — a [`tasty`](https://hackage.haskell.org/package/tasty)
  test-suite under `test/Spec.hs` (using [`tasty-hunit`](https://hackage.haskell.org/package/tasty-hunit)),
  wired up via `exitcode-stdio-1.0`.
{{/if}}

The package targets **GHC `{{ghc.version}}`** with `default-language: GHC2024`,
the standard warning set, and the default extensions `DeriveAnyClass`,
`DuplicateRecordFields`, `OverloadedLabels`, and `OverloadedStrings`.

## Develop

The project ships a Nix flake (`nix-haskell-flake`) that pins GHC and provides
the dev shell. Enter the shell with:

```bash
nix develop      # or: direnv allow, if you use direnv
```

Then build{{#if Eq project.tests true}} and test{{/if}}:

```bash
cabal build all
{{#if Eq project.tests true}}cabal test all
{{/if}}```

## License

[BSD-3-Clause](./LICENSE) — (c) {{project.copyright-year}} {{project.author}}.
