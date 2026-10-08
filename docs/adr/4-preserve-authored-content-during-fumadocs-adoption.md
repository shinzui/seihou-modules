# Preserve authored content during Fumadocs adoption

## Status

Accepted on 2026-10-08.

## Context

Existing documentation sites combine generated application files with authored pages,
custom components, package-manager workflows, and quality gates. Applying a starter
scaffold before inventorying that project can overwrite documentation and take ownership
of content that should survive removal of the application module.

## Decision

The `upgrade-fumadocs` agent blueprint has no automatic base modules. It inventories and
backs up the consumer, generates a canonical composed scaffold in isolation, then uses
Seihou operations to establish baselines before merging consumer customizations.

The Fumadocs module exposes `docs.starter-content`, defaulting to true for new projects.
Adoption sets it to false, so no starter documentation is written or claimed. Removing
the module never deletes documentation, including starter pages that users may have edited.

Application templates remain managed. Consumer edits remain visible against their canonical
baselines. The shared Nix environment remains managed, while project tools belong in the
unmanaged `flake.module.nix`, following [ADR 3](3-separate-managed-scaffold-nix-wiring-from-user-extensions.md).
Adopting Bun tooling does not require changing a site's existing package manager.

## Consequences

Migration requires a reviewed merge rather than an unconditional scaffold overwrite.
Authored content hashes and the consumer's complete quality gates verify preservation.
Debug run rendering records blueprint provenance but does not change module ownership;
debug migration rendering is read-only. Migration receipts are recorded only for version
edges actually applied and validated; legacy adoption does not invent a prior module version.

Multiple applications can share managed paths. Subsequent updates must include all shared
owners and preserve consumer modifications. Removing an obsolete application blindly is
unsafe because it can remove shared application files.
