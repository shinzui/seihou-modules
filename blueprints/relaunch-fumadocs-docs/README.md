# relaunch-fumadocs-docs

Relaunch a legacy Fumadocs documentation site in place. The agent inventories and
backs up the site, rehearses the `fumadocs-site` recipe on a scratch clone with
`docs.starter-content=false`, applies it, restores the site's own gates, and proves
the build, the Nix site build and the container image on the unchanged content. It
then installs the `technical-docs` writing skills, registers the site with Mori,
enables the semantic SVG diagram system (`docs.svg-diagrams=true`, `fumadocs` 0.6.0),
pins the documented project's source, and adds the release gates. Finally it
measures the content against the documented project and stops with a
restart-or-refresh recommendation, a proposed page list and a diagram catalog for
the operator to confirm. It writes no pages and never commits or pushes unless
explicitly authorized. The empty baseline is intentional, as for `upgrade-fumadocs`.

```bash
seihou install git@github.com:shinzui/seihou-modules.git --module relaunch-fumadocs-docs --module fumadocs-site --module fumadocs --module nix-bun-flake --module docs-mori-bootstrap
seihou agent run relaunch-fumadocs-docs --var docs.source-project=mori://<namespace>/<name>
```

Variables:

- `docs.source-project`: the documented project's Mori URI. Empty reads the first
  typed `dependencyRefs` entry of the site's `mori.dhall`.
- `docs.source-name`: its display name, written into `docs-source.json` and shown by
  `<TestedWith />`.
- `relaunch.rehearsal-only`: `true` runs every phase in a scratch clone and leaves the
  real checkout untouched.

Inspect the rendered prompt without contacting a provider:

```bash
seihou agent --debug run relaunch-fumadocs-docs
```

Debug `run` records blueprint provenance in the manifest, so render it in a scratch
clone when the checkout must stay clean.

Outputs in the site: `docs/migration-ledger.md` (every non-content change, from
`files/migration-ledger.md`), `docs-source.json` (the project-neutral source pin:
Mori URI, display name, GitHub URL, full revision, version, environments),
`docs/verification.json` with its schema, `docs-gates.json`, the gate scripts and the
`<SourceRef>` component, and `docs/content-assessment.md` with its JSON form.

The gates are blueprint files rather than module output because they carry
product-specific configuration: source citations against the pin
(`lint:source-refs`), the verification register (`lint:verification`), prose rules
(`lint:prose`), static output with a private-text scan (`lint:static-output`),
source-level links that accept generated OpenAPI operation pages (`lint:doc-links`),
the drift report (`report:source-drift`) and the HTTP API index (`gen:api-index`).
Content gates that legacy pages fail are wired into `check:release` until the
content is rewritten.

The assessment (`files/assess-content.mjs`) measures commits to the documented
project since the content last changed, cited source paths missing at its current
revision, pages exposing private paths, capabilities no page mentions, and legacy
structure outside Diátaxis. It recommends a restart when most pages cite missing
source, expose private paths, or omit most capabilities. The decision stays with
the operator. Run it directly from a site root:

```bash
node files/assess-content.mjs --out docs/content-assessment.md --json docs/content-assessment.json
```

`seihou update` cannot reconcile a `fumadocs-site` application today, so the
blueprint reconfigures by reapplying the recipe with every variable and restoring
the recorded merge list. A second run appends to the ledger, keeps the pin and the
register, and must produce no toolchain drift.
