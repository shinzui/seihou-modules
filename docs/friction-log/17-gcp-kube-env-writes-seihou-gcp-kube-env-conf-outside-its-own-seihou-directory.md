---
type: Friction Entry
title: "gcp-kube-env writes .seihou/gcp-kube-env.conf outside its own .seihou directory"
description: "The gcp-kube-env module generates .seihou/gcp-kube-env.conf directly under .seihou/, which the next Seihou release refuses at seihou run and seihou validate-module, so the module cannot be applied until it moves the file into .seihou/gcp-kube-env/."
generated:
  by: "claude-code/claude-opus-5-5"
  at: "2026-11-11T14:22:44Z"
frictionId: FRIC-17
status: "resolved"
impact: blocked
kind: interface
origin: "mori://shinzui/seihou-modules"
affects: "mori://shinzui/seihou-modules"
affectedVersion: "0.1.1"
tags:
  - "seihou-module-state"
resolution: "gcp-kube-env 0.2.0 writes .seihou/gcp-kube-env/settings.conf and declares a 0.1.1-to-0.2.0 MoveFile migration from .seihou/gcp-kube-env.conf, verified by an update with the development Seihou binary."
amended:
  - by: "claude-code/claude-opus-5-5"
    at: "2026-11-11T14:29:13Z"
    change: "Resolved by moving the module's parameter file into its own .seihou directory with a migration."
---
# gcp-kube-env writes .seihou/gcp-kube-env.conf outside its own .seihou directory

## Attempted

Validate the published modules that write under .seihou/ against Seihou's new module-state rule (mori://shinzui/seihou/plans/120-let-seihou-update-reconcile-module-owned-files-under-seihou, ADR 0025 in mori://shinzui/seihou) with the development binary: seihou validate-module modules/cloud/gcp-kube-env

## Encountered

The Module state destinations check fails for gcp-kube-env; docs-mori-bootstrap, openapi-typescript-client-dir and repo-dir, which write only under .seihou/<their own name>/, pass. seihou run gcp-kube-env fails the same way at plan time. Existing applications still load for seihou status and seihou remove.

```text
✗ Module state destinations
    step destination .seihou/gcp-kube-env.conf is outside this module's state directory; a module may write under .seihou/ only inside .seihou/gcp-kube-env/
```
