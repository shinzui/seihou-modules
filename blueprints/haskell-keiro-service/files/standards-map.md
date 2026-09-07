# Keiro Service Standards Map

Run both discovery commands, then read the named docs before changing a scaffold rule:

```bash
mori registry docs shinzui/keiro-runtime-patterns
mori registry docs shinzui/haskell-jitsurei
```

| Topic | Canonical reference | DocRef key | Why |
|---|---|---|---|
| Keiki validation | `mori://shinzui/keiro-runtime-patterns/docs/keiki-build-time-validation` | `keiki-build-time-validation` | Keep invalid transducers out of runtime startup. |
| Kiroku operations | `mori://shinzui/keiro-runtime-patterns/docs/kiroku-operational-invariants` | `kiroku-operational-invariants` | Preserve append, replay, idempotency, and watermark invariants. |
| Migration model | `mori://shinzui/keiro-runtime-patterns/docs/migrations-pg-migrate-model` | `migrations-pg-migrate-model` | Use components, strict manifests, and one complete plan. |
| Migration authoring | `mori://shinzui/keiro-runtime-patterns/docs/migrations-authoring` | `migrations-authoring` | Author forward-only ordered application SQL. |
| Migration package | `mori://shinzui/keiro-runtime-patterns/docs/migrations-service-package` | `migrations-service-package` | Shape the package, embedded component, CLI, and test support. |
| Migration operations | `mori://shinzui/keiro-runtime-patterns/docs/migrations-operations` | `migrations-operations` | Apply, verify, and recover safely. |
| Migration testing | `mori://shinzui/keiro-runtime-patterns/docs/migrations-testing` | `migrations-testing` | Prove fresh apply, schema state, ledger rows, and no-op reapply. |
| Runtime assembly | `mori://shinzui/keiro-runtime-patterns/docs/keiro-runtime-assembly` | `keiro-runtime-assembly` | Acquire resources and thread validated runtime options in order. |
| Two schemas | `mori://shinzui/keiro-runtime-patterns/docs/keiro-two-schema-arrangement` | `keiro-two-schema-arrangement` | Keep Keiro framework SQL separate from the Kiroku store schema. |
| Command cycle | `mori://shinzui/keiro-runtime-patterns/docs/keiro-command-cycle-and-errors` | `keiro-command-cycle-and-errors` | Map command, append, conflict, and error behavior consistently. |
| Keiro telemetry | `mori://shinzui/keiro-runtime-patterns/docs/keiro-telemetry` | `keiro-telemetry` | Connect runtime metrics and spans to the real SDK. |
| DSL workflow | `mori://shinzui/keiro-runtime-patterns/docs/keiro-dsl-adoption` | `keiro-dsl-adoption` | Keep specs, generated modules, and hand-owned holes distinct. |
| Message processing | `mori://shinzui/keiro-runtime-patterns/docs/messaging-shibuya-processing` | `messaging-shibuya-processing` | Preserve delivery, shutdown, idempotency, and trace propagation. |
| Service packages | `mori://shinzui/keiro-runtime-patterns/docs/architecture-service-packages` | `architecture-service-packages` | Keep the six-package ownership boundary. |
| Vertical modules | `mori://shinzui/keiro-runtime-patterns/docs/architecture-vertical-slice-modules` | `architecture-vertical-slice-modules` | Organize generated and hand-owned code by concept. |
| Specs and scaffolding | `mori://shinzui/keiro-runtime-patterns/docs/architecture-spec-and-scaffolding` | `architecture-spec-and-scaffolding` | Make regeneration deterministic and safe. |
| Tests | `mori://shinzui/keiro-runtime-patterns/docs/architecture-test-layout` | `architecture-test-layout` | Reproduce the fleet's package-aligned test suites. |
| Service configuration | `mori://shinzui/keiro-runtime-patterns/docs/config-settei-service-standard` | `config-settei-service-standard` | Resolve typed, inspectable settings with safe provenance. |
| Kubernetes configuration | `mori://shinzui/keiro-runtime-patterns/docs/config-kubernetes-deployment` | `config-kubernetes-deployment` | Gate rollout and drain server/workers safely. |
| Health endpoints | `mori://shinzui/haskell-jitsurei/docs/api-health-endpoints` | `api-health-endpoints` | Keep liveness and readiness consequences distinct. |
| OpenTelemetry | `mori://shinzui/haskell-jitsurei/docs/api-opentelemetry-integration` | `api-opentelemetry-integration` | Acquire, propagate, flush, and shut telemetry down correctly. |
| Request logging | `mori://shinzui/haskell-jitsurei/docs/api-request-logging` | `api-request-logging` | Emit structured production logs without probe noise. |
| Servant routes | `mori://shinzui/haskell-jitsurei/docs/api-servant-routes` | `api-servant-routes` | Use the fleet NamedRoutes and response conventions. |
| Problem details | `mori://shinzui/haskell-jitsurei/docs/api-rfc7807-problem-details` | `api-rfc7807-problem-details` | Return stable RFC 7807 application errors. |
| Bootstrap contract | `mori://shinzui/keiro-runtime-patterns/docs/keiro-service-workspaces` | `keiro-service-workspaces` | Use one workspace with independently owned members. |
| Bootstrap contract | `mori://shinzui/keiro-runtime-patterns/docs/keiro-language-versions` | `keiro-language-versions` | Select an explicit supported language contract. |
| Bootstrap contract | `mori://shinzui/keiro-runtime-patterns/docs/architecture-generated-compilation-contract` | `architecture-generated-compilation-contract` | Reconcile the whole generated Cabal fragment and conformance package. |
