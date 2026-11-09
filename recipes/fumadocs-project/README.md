# fumadocs-project

Create a container-enabled Fumadocs documentation site, install six technical
writing skills, and register the documentation project locally with Mori.
Run this recipe in the directory that will own the documentation site.

Requires Seihou 0.15.0.0+, Mori 7.2.0.0, Python 3, `dhall-to-json`, Git and access
to a migrated local Mori PostgreSQL registry through `MORI_PG_CONNECTION_STRING`.
The project being documented must already be registered there. Site builds also
require Nix with flakes, Bun dependencies and network access for initial downloads.

```bash
seihou install https://github.com/shinzui/seihou-modules.git --module fumadocs-project
seihou run fumadocs-project \
  --var project.name=widget-docs --var project.description='Widget documentation' \
  --var docs.site-name='Widget docs' --var docs.github-user=example \
  --var mori.namespace=example \
  --var mori.source-namespace=example --var mori.source-project=widget
mori registry show example/widget-docs --full
mori registry relations --from mori://example/widget-docs --json
mori registry relations --to mori://example/widget --json
```

`project.name` and `mori.namespace` identify this documentation project.
`mori.source-namespace` and `mori.source-project` identify the project it documents;
these identities may use different names and namespaces. All five identity and
description inputs are required. `docs.site-name` is the visible title and
`docs.github-user` controls the site's GitHub links (default `shinzui`). The other
[Fumadocs variables](../../modules/typescript/fumadocs/README.md) remain available.

The recipe composes `fumadocs`, external `technical-docs`, then `docs-mori-bootstrap`.
It binds `docs.container=true`, `nix.bun2nix=true` and
`nix.package-module=nix/fumadocs-container.nix` without changing ordinary Fumadocs
defaults or dependency identities. Seihou acquires the external module and its
`agent-gitignore` dependency from `https://github.com/shinzui/agent-seihou.git`.
The writing skills belong to `mori://shinzui/agent-seihou/templates/technical-docs`;
their shared source is `agents/skills/tech-docs*`, linked from `.claude/skills`,
`.codex/skills` and `.agents/skills`. `skill.prefix` can change their prefix.

Registration runs after scaffold and skills generation. The helper creates a
minimal, project-owned `mori.dhall` only when absent, with a `site` reference to
`content/docs` and a project-level typed `dependencyRefs` entry naming the documented
project. Mori exposes this documented-project association as `depends-on`; it is
not fork ancestry. The helper validates the manifest, calls
`mori register --local --path <absolute-site-root>` and verifies the identity,
path and resolved relation before reporting completion. `--no-commands` renders
the scaffold and skills but creates no manifest or registration.

Rerunning preserves existing manifests byte for byte, including authored additions,
and requires their identity and association to agree with the inputs. Missing targets,
self-association and identities registered at another path fail before manifest creation.
Reconcile conflicting manifests explicitly. On registry failure, fix connectivity and
rerun the recipe or `python3 .seihou/docs-mori-bootstrap/bootstrap-docs.py` in the
site directory. Generated files remain; registration is an external effect and is
not rolled back by Seihou. Removal preserves `mori.dhall`, authored content and
registration; manage registry lifecycle explicitly with Mori.

Build the generated site from a Git checkout (initialize one if needed):

```bash
git init
nix develop --command bun install
nix run .#bun2nix -- --lock-file bun.lock --output-file bun-deps.nix
git add flake.nix flake.lock nix/ package.json bun.lock bun-deps.nix content/
nix build .#docs-site
```

On a matching native Linux runner, build and export the image explicitly:

```bash
nix build .#dockerImage
nix run .#dockerImage.copyTo -- oci-archive:/absolute/artifacts/docs.tar:widget-docs:latest
```

The image serves prerendered docs with Caddy on port 8080 as user `65532:65532`.
macOS exposes the site build and omits image outputs. Lock files, `bun-deps.nix`
and `flake.module.nix` belong to the consumer; lock generation is explicit.
See the Fumadocs README for fonts, sandbox/network constraints and container
startup commands. This recipe does not create a GitHub repository or publish/deploy images.

Qualify acquisition and registration with `python3 scripts/test-fumadocs-project.py`
from this registry checkout; see that script's prerequisites and executable selectors.
Run `python3 scripts/test-fumadocs-container.py --apple-linux` for native Linux
image build, archive inspection/export and HTTP startup using local Apple containers.
The host site build runs sandboxed; the disposable Linux build container disables
the nested Nix sandbox. Other native Linux builders can use `--native-linux SYSTEM`
for the existing archive check.
