---
type: SeihouModule
title: gcp-kube-env
description: Checkout-local GCP project and Kubernetes context through direnv, with
  a private kubeconfig and a configurable env filename defaulting to .envrc.local
resource: seihou://seihou-modules/modules/cloud/gcp-kube-env
tags:
- gcp
- kubernetes
- direnv
- environment
status: stable
generated:
  by: seihou-okf-extension/0.16.0.0
version: 0.2.0
---

# gcp-kube-env

Checkout-local GCP project and Kubernetes context through direnv, with a private kubeconfig and a configurable env filename defaulting to .envrc.local

**Version:** 0.2.0

## Declaration metadata

- description: `Configure a checkout-local GCP project and Kubernetes context through direnv, with a private kubeconfig and a configurable env filename (default .envrc.local), preserving existing settings and global CLI configuration.`

## Dependencies

This module has no dependencies.

## Variables

- `gcp.project` — text, required. Google Cloud project ID for CLOUDSDK_CORE_PROJECT and GOOGLE_CLOUD_PROJECT; independent of the project hosting the cluster.
- `k8s.context` — text, required. Existing local kubectl context to copy into this checkout's private kubeconfig. Credentials must already be available on each machine.
- `env.file` — text, required, default `.envrc.local`. Checkout-root env filename, using letters, digits, dots, underscores, or hyphens; defaults to .envrc.local. Cannot be .envrc, .gitignore, or .direnv.

## Exports

No exports declared.

## Prompts

- `gcp.project` — `Google Cloud project ID?`
- `k8s.context` — `Existing Kubernetes context?`
- `env.file` — `Local env filename?`

## Generation steps

- `Copy` `setup-gcp-kube-env.py` → `scripts/setup-gcp-kube-env.py` — Managed: owned and reconciled by Seihou updates
- `Template` `gcp-kube-env.conf.tpl` → `.seihou/gcp-kube-env/settings.conf` — Managed: owned and reconciled by Seihou updates

## Commands

- `python3 scripts/setup-gcp-kube-env.py` (application command)

## Migrations

### 0.1.1 → 0.2.0

- move `.seihou/gcp-kube-env.conf` → `.seihou/gcp-kube-env/settings.conf`
