# upgrade-haskell-nix2container

Migrate existing `nix-haskell-flake` service images from dockerTools to nix2container.
The target module is 0.37.0; the blueprint is 0.1.0. Canonical identity:
`mori://shinzui/seihou-modules/templates/upgrade-haskell-nix2container`.
This is a locally prepared release until the reviewed registry commit is published.

The blueprint inventories the actual image and its consumers, updates managed files
through Seihou, translates custom image wiring in the unmanaged extension and replaces
tarball assumptions in load/export/CI commands. It preserves executable, runtime files,
configuration, toolchain pins, custom inputs and ownership. Libraries with only a commented
example stay without an image. It reviews and verifies but never commits or pushes images.

Install the blueprint from the reviewed registry revision using `seihou install
https://github.com/shinzui/seihou-modules.git --module upgrade-haskell-nix2container`.
Existing module applications must update from their genuine recorded origin.
For local rehearsal, copy this blueprint and the candidate module into matching
`.seihou/modules/` directories in a disposable consumer with a genuine local origin.
Copying a candidate does not override a recorded remote origin.

For existing consumers, including versions earlier than 0.36.0, use the run workflow:

```bash
seihou agent --debug run upgrade-haskell-nix2container --no-baseline
seihou agent run upgrade-haskell-nix2container --no-baseline
```

For a recorded 0.36.0 consumer, capture the before inventory and source version, then
use the declared migration edge:

```bash
seihou agent --debug migrate upgrade-haskell-nix2container --from 0.36.0 --to 0.37.0
seihou agent migrate upgrade-haskell-nix2container --from 0.36.0 --to 0.37.0
```

The prompt performs the reviewed `seihou update`; do not update before saving the
inventory. Do not invent edges for other versions or fabricate a legacy application's
origin. Back up affected paths and consistent Seihou metadata outside the checkout.
Review conflicts without force. Repeat runs independently validate even when an edge
was already attended.

On Linux, the resulting commands are:

```bash
nix build .#dockerImage
nix run .#dockerImage.copyToDockerDaemon
nix run .#dockerImage.copyTo -- docker-archive:/absolute/artifacts/service.tar:service:latest
```

`result` is an image description, so `docker load < result` is no longer valid. Registry
push helpers are documented in the prompt and require separate authorization to execute.
Native build/export, file/configuration parity and the consumer's harmless runtime smoke
are acceptance evidence. An unavailable Linux builder or daemon must be reported explicitly;
successful evaluation or a Seihou attendance receipt is insufficient.

Repository validation:

```bash
seihou validate-blueprint blueprints/upgrade-haskell-nix2container --lint
bash scripts/update-nix-haskell-flake-lock.sh --check
python3 scripts/test-haskell-nix2container.py
python3 scripts/test-haskell-nix2container.py --native-linux aarch64-linux
```

The default fixture exercises real Seihou generation/update and Linux/Darwin evaluation.
The optional native mode requires a matching Linux builder and exports/inspects a real
archive. It never loads or pushes an image and does not claim arbitrary consumer migration
or daemon runtime acceptance.
