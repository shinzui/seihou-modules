---
type: Improvement Request
title: "Add a starter for a Mori app"
description: "Provide a module and recipe that generate a building, testable webhook daemon on `mori-app` with its pins, configuration, selectors and registration instructions, so the third Mori app starts from a working receiver instead of a day of copying from the first two."
generated:
  by: "claude-code/claude-fable-5-2"
  at: "2026-11-19T05:58:53Z"
timestamp: "2026-11-19T05:58:53Z"
requestId: IR-1
status: proposed
origin: mori://shinzui/mori-kaizen
dependencies:
  - ref: mori://shinzui/mori-app/okf/improvement-requests/concepts/IR-2
    kind: soft
    reason: "Once the library ships the enqueue helper, test support and composable configuration, the starter generates references to them instead of copies."
acceptanceCriteria:
  - id: AC-1
    statement: "Applying the starter to an empty repository yields a Haskell package that builds and whose test suite passes in the generated development shell, with `mori-app` and `mori-types` pinned at released commits and the runtime dependency cohort taken from `mori://shinzui/haskell-nix`."
    verification: "The module's test applies it to a temporary directory and runs the build and the tests."
  - id: AC-2
    statement: "The generated daemon verifies a signed `ChangesetObserved` delivery, claims it, enqueues one envelope and drains it through a stub handler, with configuration declared through Settei."
    verification: "The generated test suite posts a signed delivery against an ephemeral PostgreSQL and asserts the acknowledgement, the single `webhook_delivery` row and the handler call."
  - id: AC-3
    statement: "The starter generates a selector file and a short operator page giving the `mori app register` command for the generated name and port, and how to run the daemon."
    verification: "Following the generated page against a local Mori registers the app, and a commit matching the selector reaches the stub handler."
  - id: AC-4
    statement: "A recipe composes the starter with repository creation, the flake, and the agent planning modules, as `haskell-cli-app-repo` does for a command-line program."
    verification: "A dry run of the recipe lists the composed modules, and the recipe's test applies it end to end."
---

# Improvement Request: Add a starter for a Mori app

## Status

- **Status:** proposed (2026-11-19)
- **Origin:** `mori://shinzui/mori-kaizen`, raised while planning `mori://shinzui/mori-kaizen/plans/1-bootstrap-mori-kaizen-as-a-mori-app-that-receives-friction-log-commits`.
- **Owner of the build:** `shinzui/seihou-modules`

## Context

A Mori app is a webhook daemon that Mori (`mori://shinzui/mori`) delivers signed events to. `mori://shinzui/mori-rei-app` was the first; the shared plumbing was then extracted into `mori://shinzui/mori-app`. mori-kaizen (`mori://shinzui/mori-kaizen`) is the second app, and more are expected, since an app is the way to react to what happens across every repository the owner maintains.

## What exists today

Verified on 2026-11-19 against seihou-modules at `8c8db40`.

- `modules/haskell` holds `haskell-library`, `haskell-cli-app`, `haskell-keiro-project` and `nix-haskell-flake`; `modules/mori` holds only `docs-mori-bootstrap`. The recipes cover a library repository and a command-line application repository. Nothing generates a receiver built on `mori-app`.
- mori-kaizen's repository was created with `git-init` and the agent planning modules. The whole first milestone of its bootstrap plan is work a starter would do: a Cabal package, source pins for `mori-app` and `mori-types` (neither is on Hackage), a flake with PostgreSQL for the ephemeral test database, a Settei configuration, the `AppSpec` wiring with an envelope type and a stub handler, a signed-delivery test, a selector file, and the registration command.
- Getting the pins right is the expensive part. `mori-app` 0.1.0.0 bounds `mori-types ^>=5.0` while Mori is at 7.3, so a new app must pin a matching pair, and the working combination is known only by reading `mori-rei-app`.

## Requested change

Add the module and the recipe as the acceptance criteria describe. The generated code should be the smallest receiver that proves the round trip, with the domain left as one stub function.

## Non-goals

- Generating domain logic, an event store, or a language-model integration.
- Deployment units; the generated page covers running the daemon locally.

## Workaround

Copy the structure from `mori-rei-app` by hand, as mori-kaizen's bootstrap plan describes.
