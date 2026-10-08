# upgrade-fumadocs

Upgrade an existing site to `fumadocs` 0.2.1 and `nix-bun-flake` 0.3.0 while
preserving its content and customizations. It supports legacy manually assembled
sites, Bun sites, and pnpm/Node sites. The empty baseline is intentional: the
agent inventories the project before composing or adopting module output.

```bash
seihou install git@github.com:shinzui/seihou-modules.git --module upgrade-fumadocs --module fumadocs --module nix-bun-flake
seihou agent run upgrade-fumadocs
```

For projects on module 0.1.2, the recorded version edge is:

```bash
seihou agent migrate upgrade-fumadocs --from 0.1.2 --to 0.2.1
```

`--from`/`--to` refer to Fumadocs **module** versions. For legacy sites use
`agent run` for adoption; do not infer a module version from a library version.
Inspect the rendered prompt without contacting a provider:

```bash
seihou agent --debug run upgrade-fumadocs
seihou agent --debug migrate upgrade-fumadocs --from 0.1.2 --to 0.2.1
```

Debug `run` records blueprint provenance in the manifest, even with an empty
baseline. Debug `migrate` leaves the manifest unchanged. Neither contacts a provider.

The blueprint retains the site's package manager and quality gates, moves extra
Nix packages into the unmanaged extension, updates CI to the shared Nix tools,
and verifies static search and Markdown output. It never commits or pushes unless
explicitly requested. Reference versions describe a tested cohort and must be
refreshed with future module releases.
