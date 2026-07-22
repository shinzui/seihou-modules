# Keiro Service Standards Map

Run both discovery commands, then read the named docs before changing a scaffold rule:

```bash
mori registry docs shinzui/keiro-runtime-patterns
mori registry docs shinzui/haskell-jitsurei
```

| Topic | Project / local path | DocRef key | Why |
|---|---|---|---|
| Keiki validation | `shinzui/keiro-runtime-patterns` / `keiki/build-time-validation.md` | `keiki-build-time-validation` | Keep invalid transducers out of runtime startup. |
| Kiroku operations | `shinzui/keiro-runtime-patterns` / `kiroku/operational-invariants.md` | `kiroku-operational-invariants` | Preserve append, replay, idempotency, and watermark invariants. |
| Migration model | `shinzui/keiro-runtime-patterns` / `migrations/pg-migrate-model.md` | `migrations-pg-migrate-model` | Use components, strict manifests, and one complete plan. |
| Migration authoring | `shinzui/keiro-runtime-patterns` / `migrations/authoring.md` | `migrations-authoring` | Author forward-only ordered application SQL. |
| Migration package | `shinzui/keiro-runtime-patterns` / `migrations/service-package.md` | `migrations-service-package` | Shape the package, embedded component, CLI, and test support. |
| Migration operations | `shinzui/keiro-runtime-patterns` / `migrations/operations.md` | `migrations-operations` | Apply, verify, and recover safely. |
| Migration testing | `shinzui/keiro-runtime-patterns` / `migrations/testing.md` | `migrations-testing` | Prove fresh apply, schema state, ledger rows, and no-op reapply. |
| Runtime assembly | `shinzui/keiro-runtime-patterns` / `keiro/runtime-assembly.md` | `keiro-runtime-assembly` | Acquire resources and thread validated runtime options in order. |
| Two schemas | `shinzui/keiro-runtime-patterns` / `keiro/two-schema-arrangement.md` | `keiro-two-schema-arrangement` | Keep Keiro framework SQL separate from the Kiroku store schema. |
| Command cycle | `shinzui/keiro-runtime-patterns` / `keiro/command-cycle-and-errors.md` | `keiro-command-cycle-and-errors` | Map command, append, conflict, and error behavior consistently. |
| Keiro telemetry | `shinzui/keiro-runtime-patterns` / `keiro/telemetry.md` | `keiro-telemetry` | Connect runtime metrics and spans to the real SDK. |
| DSL workflow | `shinzui/keiro-runtime-patterns` / `keiro/dsl-adoption.md` | `keiro-dsl-adoption` | Keep specs, generated modules, and hand-owned holes distinct. |
| Message processing | `shinzui/keiro-runtime-patterns` / `messaging/shibuya-processing.md` | `messaging-shibuya-processing` | Preserve delivery, shutdown, idempotency, and trace propagation. |
| Service packages | `shinzui/keiro-runtime-patterns` / `architecture/service-packages.md` | `architecture-service-packages` | Keep the six-package ownership boundary. |
| Vertical modules | `shinzui/keiro-runtime-patterns` / `architecture/vertical-slice-modules.md` | `architecture-vertical-slice-modules` | Organize generated and hand-owned code by concept. |
| Specs and scaffolding | `shinzui/keiro-runtime-patterns` / `architecture/spec-and-scaffolding.md` | `architecture-spec-and-scaffolding` | Make regeneration deterministic and safe. |
| Tests | `shinzui/keiro-runtime-patterns` / `architecture/test-layout.md` | `architecture-test-layout` | Reproduce the fleet's package-aligned test suites. |
| Service configuration | `shinzui/keiro-runtime-patterns` / `config/settei-service-standard.md` | `config-settei-service-standard` | Resolve typed, inspectable settings with safe provenance. |
| Kubernetes configuration | `shinzui/keiro-runtime-patterns` / `config/kubernetes-deployment.md` | `config-kubernetes-deployment` | Gate rollout and drain server/workers safely. |
| Health endpoints | `shinzui/haskell-jitsurei` / `api/health-endpoints.md` | `api-health-endpoints` | Keep liveness and readiness consequences distinct. |
| OpenTelemetry | `shinzui/haskell-jitsurei` / `api/opentelemetry-integration.md` | `api-opentelemetry-integration` | Acquire, propagate, flush, and shut telemetry down correctly. |
| Request logging | `shinzui/haskell-jitsurei` / `api/request-logging.md` | `api-request-logging` | Emit structured production logs without probe noise. |
| Servant routes | `shinzui/haskell-jitsurei` / `api/servant-routes.md` | `api-servant-routes` | Use the fleet NamedRoutes and response conventions. |
| Problem details | `shinzui/haskell-jitsurei` / `api/rfc7807-problem-details.md` | `api-rfc7807-problem-details` | Return stable RFC 7807 application errors. |
