---
type: Friction Entry
title: "Seihou treats a new dependency binding as a new instance and breaks update"
description: "Adding a var binding to a released dependency makes mori://shinzui/seihou lose the saved inputs of the existing instance, so seihou update fails for existing projects with an error that names neither the dependency nor the binding."
generated:
  by: "claude-code/claude-opus-5-5"
  at: "2026-11-04T17:41:42Z"
frictionId: FRIC-10
status: "promoted"
impact: detour
kind: interface
origin: "mori://shinzui/seihou-modules"
affects: "mori://shinzui/seihou"
affectedVersion: "0.15.0.0"
workaround: "Keep the released binding list unchanged and have consumers pass nix.package-module with --var when they opt in, which is why the fumadocs container takes three variables. Recorded in docs/adr/7-keep-service-images-unmanaged-and-use-nix2container-transports.md."
tags:
  - "seihou"
  - "update"
  - "dependencies"
promotedTo: "mori://shinzui/seihou/okf/improvement-requests/concepts/IR-15"
amended:
  - by: "claude-code/claude-opus-5-5"
    at: "2026-11-04T18:07:21Z"
    change: "Promoted to an improvement request after a minimal reproduction showed that supplying the missing value silently resets saved optional inputs."
---
# Seihou treats a new dependency binding as a new instance and breaks update

## Attempted

Release fumadocs 0.4.0 with the dependency binding nix.package-module on nix-bun-flake, then run seihou update fumadocs --no-commands --json --include-shared-owners in a project applied from fumadocs 0.3.0. Reproduced with two minimal local modules: a parent 1.1.0 adding the binding child.extra=x to its child dependency, against a control 1.1.0 with no new binding.

## Encountered

The update failed before planning and reported required variables as missing, although the project had saved values for them. The minimal control release updated cleanly, and the only difference in the failing release was the added binding. --var on the command line does not change the identity, while a binding does, and a binding value cannot be interpolated from a parent variable.

```text
{"error":{"code":"variable_errors","message":"Variables could not be resolved: missing required variable: project.name"},"outcome":"error","schemaVersion":1}
```

## Workaround

Keep the released binding list unchanged and have consumers pass nix.package-module with --var when they opt in, which is why the fumadocs container takes three variables. Recorded in docs/adr/7-keep-service-images-unmanaged-and-use-nix2container-transports.md.
