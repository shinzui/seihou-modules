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
  by: seihou-okf-extension/0.10.1.0
version: 0.1.0
---

# gcp-kube-env

Checkout-local GCP project and Kubernetes context through direnv, with a private kubeconfig and a configurable env filename defaulting to .envrc.local

**Version:** 0.1.0

## Dependencies

This module has no dependencies.

## Variables

- `gcp.project` — text, required. Google Cloud project ID for CLOUDSDK_CORE_PROJECT and GOOGLE_CLOUD_PROJECT; independent of the project hosting the cluster.
- `k8s.context` — text, required. Existing local kubectl context to copy into this checkout's private kubeconfig. Credentials must already be available on each machine.
- `env.file` — text, required, default `.envrc.local`. Checkout-root env filename, using letters, digits, dots, underscores, or hyphens; defaults to .envrc.local. Cannot be .envrc or .gitignore.

## Exports

No exports declared.

## Prompts

- `gcp.project` — Google Cloud project ID?
- `k8s.context` — Existing Kubernetes context?
- `env.file` — Local env filename?

## Generation steps

- `Copy` `setup-gcp-kube-env.py` → `scripts/setup-gcp-kube-env.py`
- `Template` `gcp-kube-env.conf.tpl` → `.seihou/gcp-kube-env.conf`

## Commands

- `python3 scripts/setup-gcp-kube-env.py`
