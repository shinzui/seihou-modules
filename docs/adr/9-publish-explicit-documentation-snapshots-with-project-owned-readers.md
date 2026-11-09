# Publish explicit documentation snapshots with project-owned readers

## Status

Accepted on 2026-11-09.

## Context

A documentation reader needs reusable content selection and deployable assets while
preserving the consumer's application source, typography and authored documents.
Automatically copying an entire repository risks publishing unapproved files; inferring
bundle identity from project-specific `mori.dhall` parsing couples a general reader to
one producer. Rewriting source during scaffold upgrades breaks local customizations.

## Decision

`docs-microapp` seeds a Bun workspace with TanStack Start, React Aria/shadcn `aria-nova`,
Highlights, and self-hosted Geist Serif/Paper Mono. Source/manifests/content/configuration,
font sources and licenses are project-owned, following [ADR 3](3-separate-managed-scaffold-nix-wiring-from-user-extensions.md).
Nix package/snapshot/image helpers remain managed and parameterized, following
[ADR 7](7-keep-service-images-unmanaged-and-use-nix2container-transports.md).

A versioned JSON publication manifest names every approved Markdown file and asset
relative to an explicit root. Bundle declarations describe identity, never implicitly
include files. Canonical concept identities combine an explicit Mori project, bundle
name and document handle; without an explicit canonical project, use source paths.
Duplicate identities, invalid paths and escaping symlinks fail. Packaged snapshots
require regular files and carry a normalized manifest, file checksums and release
commit/date. Development and packaged readers use the same manifest shape. Request
handling invokes no repository CLI or Git. Raw HTML stays disabled, highlighted text
uses React text nodes, and links/assets resolve only to published paths.

Release metadata lives in the content snapshot, keeping documentation-only revisions
out of the application and registry-cache derivations. Workspace names come from
manifests and are excluded lazily from the registry cache, following
[ADR 6](6-share-an-opt-in-bun2nix-helper-and-isolate-registry-caches.md).
A nested `web/` Git flake selects its parent repository with
`docsMicroapp.contentSource = ../.;` in its unmanaged `flake.module.nix`.

Tailwind source discovery is explicit (`source(none)` plus approved application/UI
source paths), keeping client and server stylesheet URLs equal across build phases.
A production test requests SSR-linked CSS/JS before browser hydration as well as
checking loaded fonts and interactive behavior.

The released `mori://shinzui/seihou` 0.15.0.0 copy path decodes sources as text.
Until it supports binary seeds, the consumer owns base64 font representations and
a checksummed manifest. Vite verifies and decodes them locally, emitting the original
WOFF2 bytes for development/production; the module retains original release assets
and copyright licenses. The workaround has no network or private-checkout dependency.

`docs-microapp-labs` composes that reader with `nagare-docs-config` in one resolution
pass. Service name and full hostname are independent of the image repository, which
defaults to `project.name`. The seed constructs and emits a validated single-service
Nagare Application from `mori://shinzui/nagare` v0.16.2, with immutable image tag,
health check, port 8080, scale-to-zero and login protection. The outer application
and service agree on image, namespace, environment and access policy.

## Consequences

Consumers can adapt reader behavior and content without upgrade overwrite. Changing
seed variables during rerun does not rename an existing deployed service; edit the
seeded config directly and prepare a reviewed change. Font replacement requires an
explicit source/checksum/CSS update. No silent fallback hides a missing font.

Configuration generation and offline checks require no cluster context. Login policy
does not create a hostname grant: an authorized grant and compatible platform must
already exist for live operation. Native image publication and application deployment
are separate saved reviews. Publication acceptance supplies the real resource ID
needed by deployment; rollback selects an existing accepted immutable publication
with its original configuration/source revision. Neither the scaffold nor its tests
publish images, apply deployments or change grants/contexts.

Apple Container is the preferred local Linux runtime/build environment when its
architecture meets the check. The quick archive/browser path imports an OCI
conversion and uses Rosetta for amd64 images on Apple Silicon; this supplements
the separately verified native x86_64 build/export/startup evidence. Runtime and
build architecture qualifications remain explicit.
