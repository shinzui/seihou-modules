---
type: SeihouBlueprint
title: upgrade-haskell-nix2container
description: Migrate Haskell service images to pinned nix2container with preserved
  image configuration, root files, custom inputs and explicit copy/export workflows
resource: seihou://seihou-modules/blueprints/upgrade-haskell-nix2container
tags:
- haskell
- nix
- docker
- nix2container
- migration
status: stable
generated:
  by: seihou-okf-extension/0.11.0.1
version: 0.1.0
---

# upgrade-haskell-nix2container

Migrate Haskell service images to pinned nix2container with preserved image configuration, root files, custom inputs and explicit copy/export workflows

**Version:** 0.1.0

## Base modules

This blueprint declares no base modules.

## Agent prompt

# Upgrade Haskell service images to nix2container

```text
# Upgrade Haskell service images to nix2container

Upgrade an existing consumer of nix-haskell-flake to 0.37.0 and replace its
dockerTools image implementation with the module's pinned nix2container builder.
Preserve the service's behavior and all unrelated project work. Review and verify;
do not commit, publish images, deploy, or migrate other repositories.

## Inventory before editing

Read repository instructions. Save git status, staged/unstaged diffs and affected
untracked files. Back up affected files and consistent .seihou manifest/baselines
outside the checkout. Rehearse in a disposable copy when local work makes recovery
uncertain. Inspect the actual recorded module version, origin, variables, shared
owners and current module installation. Do not invent a source version or rewrite
manifest hashes, origins, application IDs or baselines.

Inspect flake.nix, flake.lock, nix/*.nix, flake.module.nix, the existing image outputs,
CI, task scripts and deployment documentation. Find every docker load, docker-archive,
streamLayeredImage and image path consumer. Record output names, image name/tag,
package and executable, Cmd/Entrypoint, environment, exposed ports, user/group,
working directory, labels, volumes, TLS roots, timezone files, external tools,
dynamic libraries, copied assets and permissions. Capture evaluated configuration
and a root-file inventory of the old image when a Linux builder is available.
Keep application package recipes, retained-runtime selections, SDK/production split,
compiler, development shell, hooks, services and custom inputs unchanged.

If the project only has the commented example, refresh that example; do not enable
an image for a library or guess an executable. If an image already uses nix2container,
verify its pin and transport wiring and make only necessary changes.

## Update the managed module through Seihou

Use the reviewed registry release containing nix-haskell-flake 0.37.0. This blueprint
does not assert that a local candidate is remotely published. For local qualification,
use genuine project-local module discovery in a disposable consumer; for a recorded
remote origin, use its released update path rather than silently changing origin.
Inspect `seihou update --help` for the installed CLI. Preview first:

```bash
seihou update nix-haskell-flake --dry-run --json --include-shared-owners
seihou update nix-haskell-flake --json --include-shared-owners
```

Review the actual three-way changes and resolve conflicts without force. Preserve
custom inputs and their lock nodes; the shipped lock is the managed-only seed, not
permission to replace a custom graph. Ensure the resulting managed inputs match the
0.37.0 module, including nix2container's immutable v1.1.0 commit and nixpkgs follows.
Do not bump haskell-nix-dev, haskell-nix or other inputs to implement this migration.
Do not use `seihou run --force` or remove/recreate applications to bypass conflicts.
An unrecorded project must establish genuine ownership through an appropriate
adoption workflow separately before this blueprint claims a managed upgrade.

## Translate the image in its unmanaged home

Keep image definitions in flake.module.nix or another existing unmanaged imported
module. Relocate direct edits from managed modules into that home, preserving other
outputs and imports. Merge the provided reference; never copy it over an existing
extension. Retain the existing output name (usually packages.dockerImage) and guard
it with `pkgs.lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux`. Add `system` to
perSystem arguments and `inputs` to outer arguments as needed. Resolve the builder
only inside the Linux branch:

```nix
inputs.nix2container.packages.${system}.nix2container.buildImage
```

If the same perSystem record defines packages.default, combine the assignments as
`packages = { default = ...; } // pkgs.lib.optionalAttrs ... { dockerImage = ...; };`
or use separate imported modules. A packages.default assignment and a packages
expression in one Nix record collide before flake-parts can merge them.

Keep the actual package/executable and image name/tag. Preserve supported OCI config
fields exactly, including list order and entrypoint semantics. Nix string references
in config retain the executable's closure. Preserve the consumer's layering policy
where required; do not copy dockerTools-only arguments into buildImage.

Translate dockerTools `contents` or `copyToRoot` into an explicit root tree, commonly
`pkgs.buildEnv` with the original paths and appropriate pathsToLink, then pass it to
nix2container.copyToRoot. Preserve `/bin`, `/etc` and any other original root paths;
do not omit files merely because the generic reference only links /bin and /etc.
For `extraCommands`, build the same tree using `pkgs.runCommand` and add that tree to
copyToRoot (which accepts a list). Rewrite commands relative to `$out`; preserve
resource locations, symlinks, writable directories and executable bits. Map ownership
and modes from `fakeRootCommands` to nix2container `perms`, using paths in the source
root derivation and suitable regex/mode/uid/gid as supported by the pinned builder.
Do not run privileged chown during an ordinary Nix build. Verify the exact API from
source located with Mori; if the corpus is absent, use the immutable upstream source.

Neither extraCommands, fakeRootCommands, runAsRoot, diskSize nor buildVMMemorySize is
a nix2container buildImage argument. Translate their intended behavior explicitly;
do not silently discard it. Convert a dockerTools base image to a supported
nix2container pullImage/pullImageFromManifest with its original immutable digest,
or document and resolve the unsupported case before declaring success. Review
dockerTools-specific metadata such as Healthcheck against the pinned OCI config
implementation; preserve its operational behavior through the deployment/runtime
configuration if the builder cannot represent it. Report unresolved parity as a
blocker, not a completed migration.

## Update all image transports

`nix build .#dockerImage` now produces an image description, not a tar archive.
Replace `docker load < result` with:

```bash
nix run .#dockerImage.copyToDockerDaemon
```

For CI that needs an archive artifact, explicitly export it:

```bash
nix run .#dockerImage.copyTo -- docker-archive:/absolute/artifacts/service.tar:service:latest
```

The archive destination suffix `:service:latest` records the repository/tag in the
archive. Replace it with the inventoried image reference; omitting it produces an
untagged archive and changes what a later docker load imports.

Document `nix run .#dockerImage.copyToRegistry` for the configured image name/tag,
or `nix run .#dockerImage.copyTo -- docker://registry.example/service:tag` for an
explicit destination. Preserve CI authentication, tag policy and platform selection.
Updating CI instructions does not authorize pushing an image during migration.
Do not execute registry copy helpers unless the user separately authorized a push.
Update archive uploads/caches, task scripts and docs together. All commands use
Linux outputs on Linux; macOS requires a matching Linux builder or Linux CI.

## Verify before reporting success

Stage only new files Nix must see, without committing or disturbing the user's
index; use `git add -N` when appropriate and report any index changes. Run the
consumer's normal checks/builds and formatting. Evaluate both Linux architectures
where supported and confirm Darwin package enumeration excludes the image. Build
the actual production package and image on a matching Linux builder, export via
copyTo to an external temporary archive, inspect its image configuration and root
files, and compare with the inventory. Check executable, TLS roots, assets, modes,
ownership and required dynamic libraries. Where a daemon is available, load and run
the image using the consumer's documented harmless smoke/health command; do not start
persistent services or require production credentials. Distinguish evaluation, native
image build/export, runtime smoke and registry push evidence in the report.

Run a normal repeat Seihou update, then recheck the image configuration and unmanaged
files. Confirm unchanged toolchain pins, custom input nodes, source files and dev shell
behavior. If an agent migration edge is already attended, rerun verification anyway;
attendance is not acceptance. An unavailable Linux builder/daemon means native/runtime
validation remains unverified; never claim those checks passed from evaluation alone.
Finish with changed files, preservation evidence, exact commands/results and remaining
limitations. If interrupted, restore only affected paths and their consistent metadata
from backup, preserve unrelated work and rerun checks before resuming.
```

## Reference files

- `flake.module.nix` - Unmanaged Linux-only nix2container service image reference; merge with the consumer's existing outputs, never overwrite its extension

## Migrations

### 0.36.0 → 0.37.0

This edge upgrades the recorded nix-haskell-flake 0.36.0 application to 0.37.0.
Follow the main blueprint prompt, including inventory captured before updating,
genuine Seihou three-way updates, preservation of custom inputs and unmanaged
extensions, and explicit native acceptance. The new managed input pins nix2container
v1.1.0 at e503eb81630a0c5d7ec244e08e0733650235d8f1 with nixpkgs following the
existing application input. Existing Haskell toolchain pins must remain unchanged.
Translate each active dockerTools image and its load/export/push consumers; updating
only the commented example is insufficient when an active image exists. Keep projects
without active images without active images. Rerun independent image validation on
retries even if Seihou skips this attended edge. Never mark an edge applied to bypass
validation, publish images or commit changes.
