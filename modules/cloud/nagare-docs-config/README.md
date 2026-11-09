# nagare-docs-config

Version 0.1.0. Requires Seihou 0.15+ and Nagare v0.16.2 from
`mori://shinzui/nagare` for offline configuration checks.

Seeds `nagare/Config.hs` and an image-to-deployment runbook. The typed single-service
Application uses the independently selected service name and full DNS hostname,
namespace `personal` by default, port 8080, `/healthz`, scale 0..2, small stateless
resources and login protection. Its image repository is `project.name`.

| Variable | Requirement |
| --- | --- |
| `project.name` | Image repository name |
| `nagare.service-name` | Required lowercase DNS label, at most 63 characters |
| `nagare.domain` | Required full hostname; no automatic service prefix |
| `nagare.namespace` | DNS label, default `personal` |

Seihou rejects schemes, ports, paths, command syntax, empty or overlong labels.
Nagare smart constructors also enforce the 253-character total hostname limit.
DNS-only template inputs cannot inject Haskell string syntax. At evaluation,
`DOCS_IMAGE_TAG` must be `git-<12 lowercase hex characters>`; missing/invalid tags
fail before provider access. No mutable default is generated.

The generated Application and service agree on image, namespace, access and
environment and are validated through `mkApplication` before `emitApplication`.
Both files are project-owned seeds: reruns with new values preserve existing edits
and intentional deletion. Edit an existing config directly to rename a service.

Use the [Labs recipe](../../../recipes/docs-microapp-labs/README.md) to compose it
with the reader in one resolver pass. Generation and offline checking never
publish, deploy, select a context or create hostname grants. Login protection
requires an existing authorized grant in the chosen compatible target context.
