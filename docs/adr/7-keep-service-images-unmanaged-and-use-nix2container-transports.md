# Keep service images unmanaged and use nix2container transports

## Status

Accepted on 2026-10-27.

## Context

`nix-haskell-flake` supports libraries, single executables and composed workspaces.
Its former service example used dockerTools.buildLayeredImage and produced a Docker
archive. Existing consumers may customize executable selection, root assets, image
configuration and archive handling in CI. The shared module cannot infer those choices.

## Decision

Version 0.37.0 always declares an immutable nix2container input, pinned to the released
v1.1.0 commit and following the application's nixpkgs. All feature combinations share
the same lock; unused image support is not built. Existing Haskell toolchain inputs
remain unchanged. Dependency ownership is `mori://nlewo/nix2container`; artifact-level
URI coverage is pending for upstream `README.md` and `default.nix`.

Keep image definitions in the unmanaged `flake.module.nix` extension, consistent with
[ADR 3](3-separate-managed-scaffold-nix-wiring-from-user-extensions.md). The module
provides a commented Linux-only example, allowing consumers to retain their actual
package, executable, configuration and files. Libraries do not acquire images.

Use nix2container.buildImage with an explicit copyToRoot tree. Its output describes
an image; copyToDockerDaemon loads it, copyToRegistry pushes the configured name/tag,
and copyTo exports to an explicit transport such as docker-archive. Do not treat the
build result as a Docker tarball. Archive destinations include the intended repository/tag
suffix to preserve tagging on later docker load. Sandbox exports pass `--tmpdir`
explicitly because Skopeo defaults to `/var/tmp`, which a build sandbox may omit. The output includes executable/runtime closures
referenced from image configuration and root trees.

Consumer migration is agent-guided through `upgrade-haskell-nix2container`. Use real
Seihou three-way updates for managed inputs/example files, and merge changes into
unmanaged image definitions. Translate dockerTools-specific root/permission commands
and update load/export/CI consumers explicitly. Keep custom input nodes and existing
image semantics. Native Linux image build/export, configuration/root-file inspection
and daemon smoke evidence remain distinct from evaluation and migration attendance.

`nix-bun-flake` 0.6.0 applies the same decision to Bun and Node servers: the same pinned
input, always declared across toggles, and a commented Linux-only example in the unmanaged
extension. That example layers the runtime and application separately over a project-owned
package instead of assembling a root tree. It has no consumer migration blueprint because
the module shipped no earlier image example to migrate from.

`fumadocs` 0.4.0 is a deliberate exception to keeping images unmanaged. A static site has no
project-specific executable, entrypoint or runtime to choose, so the module owns an opt-in
Caddy image, Caddyfile and sandboxed site build behind `docs.container`. Projects still own
`bun.lock` and `bun-deps.nix`. Opting in also sets `nix.bun2nix` and `nix.package-module`
explicitly. Seihou dependency bindings are static literals, and they are part of a dependency's
identity: binding `nix.package-module` for every site made `seihou update fumadocs` lose the
saved inputs of existing projects.

## Consequences

Updating the module refreshes its managed inputs and example but does not rewrite an
existing consumer's image extension. The blueprint must inventory and preserve each
consumer's custom behavior; unresolved unsupported settings prevent parity acceptance.
Image definitions and helper resolution stay inside the Linux guard so macOS builds
can enumerate ordinary package outputs. Linux builds need a matching Linux builder.
Image publication is a separate authorized action from preparing or testing a migration.

## Documentation reader extension (2026-11-09)

`docs-microapp` 0.1.0 extends the scaffold-specific exception: its known Bun server,
client assets, fonts and explicit publication snapshot permit managed image helpers.
The unmanaged `flake.module.nix` configures `docsMicroapp.contentSource`,
`docsMicroapp.contentConfig` and `docsMicroapp.imageName`; it remains the consumer's
extension point. Application and registry-cache sources exclude documentation and
release metadata. A separately built content snapshot owns the approved-file inventory
and full release commit. Clean Git revisions produce `git-<12 hex characters>` tags;
dirty source still supports ordinary application/development builds.

The Linux image uses separate runtime/application/content layers, an unprivileged
numeric user and an explicit `/content` root. macOS exposes no image package.
Native build, explicit archive export, archive inspection and actual container/browser
startup are separate acceptance checks. A remote builder does not make Linux export
executables runnable on a macOS client: export on a Linux runner, then copy the archive.
