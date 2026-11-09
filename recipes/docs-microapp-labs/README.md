# docs-microapp-labs

Version 0.1.0. Composes `docs-microapp` (including `nix-bun-flake`) and
`nagare-docs-config` in one resolution pass. Seihou 0.15.0.0+ installs the entire
dependency closure. No GitHub repository or live deployment is created.

```bash
seihou install https://github.com/shinzui/seihou-modules.git --module docs-microapp-labs
seihou run docs-microapp-labs --no-save-prompted --no-commands \
  --var project.name=handbook-web \
  --var project.description='Team documentation' \
  --var docs.site-name='Team Handbook' \
  --var nagare.service-name=handbook \
  --var nagare.domain=handbook.labs.example.test \
  --var nagare.namespace=personal
```

`handbook` is the service, `handbook.labs.example.test` is the complete hostname,
and `handbook-web` is the image repository. These values are independent. Supply
an actual authorized hostname when preparing a live operator review.

Follow the generated reader README for local checks and native Linux packaging,
then `nagare/README.md` for the tested v0.16.2 offline check, explicit archive export,
saved image-publication review and separate application-deployment review.
Publication acceptance must provide a real accepted resource ID before the second
review. Check target platform compatibility and the existing hostname grant first.
For rollback select a previous accepted image publication and its original config
revision; retain its immutable tag. All authored source/content/fonts/configs are
seeds; rerun/update/removal preserve them, including intentional deletion.

See the [reader module](../../modules/typescript/docs-microapp/README.md) and
[configuration module](../../modules/cloud/nagare-docs-config/README.md) for the
ownership and publication interfaces. Automated acceptance exercises real recipe
installation in an isolated cache and two different emitted Applications through
the released Nagare runtime with empty configuration/context directories.
