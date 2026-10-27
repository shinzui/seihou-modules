---
type: Friction Entry
title: "Released probe schema omits nullable timestamp semantics"
description: "The released OpenAPI generic record derivation drops Maybe nullability, requiring correction of the derived probe schema before publication."
generated:
  by: "codex-cli/gpt-6.1-sol"
  at: "2026-10-27T02:51:09Z"
frictionId: FRIC-4
status: "accepted"
impact: detour
kind: interface
origin: "mori://shinzui/seihou-modules"
affects: "mori://shinzui/openapi-hs/packages/openapi-hs"
plan: "docs/plans/8-complete-the-keiro-project-bootstrap-with-api-testing-and-test-data.md"
workaround: "Normalize only the library-derived ProbeStatus timestamp property and required key in the seed schema exporter; retain released dependencies and library wire/server types."
resolution: "Keep the released dependency cohort and narrowly correct the derived probe timestamp schema at export; conformance and schema tests cover it until upstream releases corrected generic record derivation."
amended:
  - by: "codex-cli/gpt-6.1-sol"
    at: "2026-10-27T03:05:42Z"
    change: "Accept the documented schema-export correction while the released generic Maybe derivation omits nullability."
---
# Released probe schema omits nullable timestamp semantics

## Attempted

Build generated seed and run cabal test all with servant-health 0.1.0.0 and openapi-hs 5.0.0

## Encountered

The healthy wire response includes failingSince:null but the derived property references a non-null UTCTime schema and omits failingSince from required.

```text
OpenAPI schema test failed: timestamp permits null; ProbeStatus.required = [status, check]; failingSince.$ref = #/components/schemas/UTCTime
```

## Workaround

Normalize only the library-derived ProbeStatus timestamp property and required key in the seed schema exporter; retain released dependencies and library wire/server types.
