---
id: 2
slug: add-socket-only-redis-support-to-nix-haskell-flake
title: "Add socket-only Redis support to nix-haskell-flake"
kind: exec-plan
created_at: 2026-08-29T13:55:11Z
---

# Add socket-only Redis support to nix-haskell-flake

This ExecPlan is a living document. The sections Progress, Surprises & Discoveries,
Decision Log, and Outcomes & Retrospective must be kept up to date as work proceeds.
If durable project context changes, update or create ADRs in docs/adr/ in the same change.


## Purpose / Big Picture

The `nix-haskell-flake` Seihou module can currently provision PostgreSQL and ClickHouse for
local development, but a project that needs Redis must hand-edit a generated Nix module and
its `process-compose.yaml`. Those edits conflict with later Seihou updates and commonly bind
Redis's default TCP port, so two projects cannot reliably run their development services at
the same time.

After this change, a user can set `nix.redis=true` when applying or reconfiguring
`nix-haskell-flake`. The generated development shell will contain `redis-server` and
`redis-cli`, export a Redis UNIX-domain socket path beneath that project's checkout, and add
a Redis process when `nix.process-compose=true`. A UNIX-domain socket is a filesystem path
used for local inter-process communication; because every checkout gets its own path and the
server is started with TCP port `0`, Redis instances from different projects do not compete
for port 6379. The default remains disabled, so existing consumers that do not request Redis
retain their current shell and generated files.

The result is visible by generating a Redis-enabled fixture, starting process-compose, and
observing `PONG` from `redis-cli -s "$REDIS_SOCKET" ping`. Querying the live server with
`CONFIG GET port` must report `0`, and a Redis-disabled fixture must contain no Redis package,
environment, process, or ignored state directory.


## Progress

- [x] (2026-08-29 14:10Z) Milestone 1: added the generated Redis interface; `seihou
  validate-module modules/haskell/nix-haskell-flake` reported 13 variables, 9 prompts, 14
  steps, and a valid module.
- [x] (2026-08-29 14:11Z) Milestone 2: synchronized public documentation, Seihou and Mori
  metadata, and generated OKF docs at version 0.14.0; registry validation reported all 11
  entries in sync and OKF validation reported 11 valid concepts.
- [x] (2026-08-29 14:13Z) Milestone 3 rendering proof: the disabled fixture contained no Redis
  artifacts, and applying the enabled fixture twice produced the planned Redis content with
  exactly one `redis/` ignore entry.
- [x] (2026-08-29 14:30Z) Milestone 3 live proof: Redis 8.8.0 ran from the project-local socket,
  returned `PONG`, reported port `0`, appeared as `Running` and `Ready` with zero restarts in
  process-compose, and stopped cleanly through the same fixture-local control socket.
- [x] (2026-08-29 14:50Z) Completion: reran module, registry, OKF, and Mori checks; confirmed
  no repository flake or lock change; distilled the durable service contract into ADR 1; and
  removed both exact temporary fixtures.


## Surprises & Discoveries

Document unexpected behaviors, bugs, optimizations, or insights discovered during
implementation. Provide concise evidence.

- Observation: Regenerating the existing `okf-docs/` directory requires the OKF extension's
  `--force` flag even though the original plan command omitted it.
  Evidence: `seihou extension run okf -- docs --dir . --out okf-docs` exited with
  `output directory is not empty: okf-docs; pass --force to overwrite`.

- Observation: A full OKF regeneration now writes 11 concepts rather than the 10 anticipated by
  the plan because it materializes the previously missing current blueprint document.
  Evidence: the successful generator reported `Wrote 11 concepts to okf-docs` and created
  `okf-docs/blueprints/fix-nix-haskell-flake-customizations.md`; `okf validate okf-docs`
  subsequently reported `OK: 11 concepts`.

- Observation: The newly generated blueprint concept contained an extra blank line at end of
  file, which is accepted by OKF but rejected by Git's whitespace check.
  Evidence: `git diff --cached --check` reported
  `okf-docs/blueprints/fix-nix-haskell-flake-customizations.md:40: new blank line at EOF`;
  removing that final blank line made the check clean without changing document content.

- Observation: Redis 8.8.0 on macOS rejects a UNIX socket path once the full encoded path is
  104 bytes or longer; the operating system's default per-user temporary directory made the
  first enabled fixture's socket path 106 bytes.
  Evidence: `redis/redis.log` reported
  `Failed opening Unix socket: unix socket path too long (106), must be under 104` after
  confirming `Running mode=standalone, port=0`.

- Observation: This execution environment already owns TCP port 8080, which is also
  process-compose's default control-server port and is unrelated to Redis's disabled TCP port.
  Evidence: `lsof -nP -iTCP:8080 -sTCP:LISTEN` showed an existing `container` listener, and a
  plain `process-compose down` reached that listener and returned `405 Method Not Allowed`.


## Decision Log

- Decision: Add `nix.redis` as a required Boolean variable with a default of `false`, following
  the existing `nix.clickhouse` compatibility pattern.
  Rationale: The declared variable and prompt make the feature discoverable and configurable,
  while the false default keeps existing generated projects unchanged and lets composed
  modules inherit it without adding a new binding.
  Date: 2026-08-29

- Decision: Export `REDIS_SOCKET="$PWD/redis/redis.sock"` and
  `REDIS_LOG="$PWD/redis/redis.log"`, start Redis with `--port 0`, and set socket permissions
  to `700`.
  Rationale: A checkout-relative socket is naturally unique per project, disabling TCP removes
  the global port collision entirely, and owner-only socket permissions match Redis's secure
  example configuration. These names also match the already-proven consumer contract at
  `mori://shinzui/shikumi/packages/shikumi-cache-redis`.
  Date: 2026-08-29

- Decision: Use `pkgs.redis` from the nixpkgs revision already followed through
  `haskell-nix-dev`; do not add a flake input or a Redis-specific version variable.
  Rationale: The module's lock currently resolves `pkgs.redis` to Redis 8.8.0, which was
  verified against the current upstream release. Following nixpkgs preserves the repository's
  single-lock upgrade model and avoids an unnecessary independent pin.
  Date: 2026-08-29

- Decision: Make the generated development server ephemeral by passing `--save ""`, and let
  process-compose supervise the foreground server with a socket-based `PING` readiness probe.
  Rationale: This is a development dependency, not a production deployment. Disabling snapshot
  persistence avoids stale cache data while preserving logs for diagnosis, and the readiness
  probe verifies the same connection path applications use.
  Date: 2026-08-29

- Decision: Release the additive feature as module version `0.14.0` without a migration
  operation.
  Rationale: Enabling Redis adds new rendered content but does not move or delete consumer
  files. Existing managed templates are safely refreshed by normal `seihou update` or explicit
  reconfiguration, and the false default is backward-compatible.
  Date: 2026-08-29

- Decision: Preserve the public `$PWD/redis/redis.sock` interface, use `/tmp` explicitly for
  the live fixture, and give process-compose a fixture-local UNIX control socket during the
  smoke test.
  Rationale: The Redis socket must remain project-local and match the planned consumer
  contract. A short fixture proves that contract within macOS's UNIX socket limit, while a
  separate process-compose control socket avoids this runner's unrelated port-8080 listener
  without changing generated consumer files.
  Date: 2026-08-29

- Decision: Record the socket-only development-service contract and platform path-length
  constraint in
  [ADR 1](../adr/1-use-project-local-sockets-for-redis-development-services.md).
  Rationale: The connection interface, deliberate TCP exclusion, persistence policy, and
  platform constraint affect future module evolution and consumer checkout layout beyond this
  implementation task.
  Date: 2026-08-29


## Outcomes & Retrospective

Summarize outcomes, gaps, and lessons learned at major milestones or at completion.
Compare the result against the original purpose. Before marking the plan complete,
distill durable project context from the Decision Log, Surprises & Discoveries, and
this section into docs/adr/. Keep task-local execution details here.

- Milestone 1 established the default-disabled `nix.redis` variable, conditional Redis package
  and shell environment, socket-only supervised process, and idempotent `redis/` ignore patch.
  The module-level structural validation passed with the planned counts.

- Milestone 2 made Redis discoverable in the module README, composed-recipe inventories,
  remediation blueprint, Seihou registry, Mori template metadata, and regenerated OKF module
  documentation. Regeneration also restored the missing generated document for the current
  customization-remediation blueprint.

- Milestone 3 proved both conditional rendering branches and the live service. The enabled
  development shell exposed Redis 8.8.0, process-compose reported the process `Running` and
  `Ready`, the project-local socket returned `PONG`, live configuration reported TCP port `0`,
  and shutdown removed reachability. The first macOS fixture exposed the durable socket-path
  limit now documented in the README and
  [ADR 1](../adr/1-use-project-local-sockets-for-redis-development-services.md).

- The completed release meets the original purpose: consumers can opt into Redis without
  editing generated files or claiming port 6379, while default-disabled consumers render no
  Redis artifacts. All planned structural, metadata, rendering, idempotence, live-service, and
  shutdown checks passed. No implementation gap remains. The one operational caveat is the
  platform UNIX-socket path limit, which is now explicit in user documentation and durable
  architectural context.


## Context and Orientation

This repository stores reusable Seihou scaffolding. A Seihou module declares variables,
prompts, generated-file steps, and a semantic version in a Dhall record. Applying a module
renders its templates into another project and records baselines so later updates can detect
user conflicts. The module in scope is rooted at
`modules/haskell/nix-haskell-flake/`; its implemented version is 0.14.0.

`modules/haskell/nix-haskell-flake/module.dhall` is the authoritative module declaration. It
currently declares `nix.postgresql`, optional PostgreSQL database-name configuration, and
default-disabled `nix.clickhouse`, alongside process-compose, formatting, pre-commit, and
Haskell toolchain settings. It also lists every template or patch step. Redis must be added
here as `nix.redis`, including its prompt and a conditional `.gitignore` patch step.

`modules/haskell/nix-haskell-flake/files/nix/haskell.nix.tpl` renders the flake-parts module
that creates development shells. Its `baseDevPackages` list conditionally adds service
packages. Its `shellHook` conditionally exports PostgreSQL and ClickHouse runtime paths and
creates their local directories. Redis belongs in both locations: `pkgs.redis` supplies
`redis-server` and `redis-cli`, while `REDIS_SOCKET` and `REDIS_LOG` form the stable generated
environment contract. The path should live below `$PWD/redis`, where `$PWD` is the generated
project's root when the shell is entered.

`modules/haskell/nix-haskell-flake/files/process-compose.yaml.tpl` is the service-supervisor
template. Process-compose is a local process supervisor: it starts long-running development
services, polls readiness probes, restarts failed processes, and shuts them down together.
The template already conditionally emits PostgreSQL and ClickHouse processes. A Redis block
must be independently conditional on `nix.redis`, so any combination of the three services
renders without stray processes. Redis must run in the foreground, bind only
`$REDIS_SOCKET`, disable TCP with port `0`, log to `$REDIS_LOG`, disable snapshots, and report
healthy only when `redis-cli -s "$REDIS_SOCKET" ping` succeeds.

`modules/haskell/nix-haskell-flake/files/gitignore-haskell.tpl` already ignores `db/`, and
`modules/haskell/nix-haskell-flake/files/gitignore-clickhouse.tpl` conditionally ignores
`clickhouse/`. Add `modules/haskell/nix-haskell-flake/files/gitignore-redis.tpl` containing
`redis/`, then register it with the same `append-line-if-absent` patch strategy. This keeps
the socket and log out of generated repositories and makes repeated generation idempotent.

User-facing module documentation lives at
`modules/haskell/nix-haskell-flake/README.md`. The two recipe READMEs at
`recipes/haskell-library-repo/README.md` and `recipes/haskell-cli-app-repo/README.md` enumerate
the inherited `nix.*` variables and must mention the new false-defaulted option. The
remediation blueprint at `blueprints/fix-nix-haskell-flake-customizations/prompt.md` also
enumerates optional module variables and must recognize `nix.redis`. Registry metadata lives
in `seihou-registry.dhall` and `mori.dhall`; generated discoverability documentation lives in
`okf-docs/modules/nix-haskell-flake.md`. Keep descriptions, version metadata, and variable
lists synchronized rather than leaving Redis visible only in `module.dhall`.

The current `modules/haskell/nix-haskell-flake/files/flake.lock` follows nixpkgs revision
`4df1b885d76a54e1aa1a318f8d16fd6005b6401f` through `haskell-nix-dev`. Mori has no registered
nixpkgs or process-compose source project, so no local dependency source was available for
those packages. The pinned nixpkgs package definition was therefore checked at that exact
upstream revision: `pkgs.redis` is Redis 8.8.0 and exposes `redis-server` plus `redis-cli`.
Redis's own 8.8.0 configuration confirms that port `0` disables TCP and that `unixsocket` and
`unixsocketperm` configure the local socket. The official CLI contract confirms `-s <socket>`.
No dependency bound or new lock entry is needed.

Mori did identify an existing, working consumer at
`mori://shinzui/shikumi/packages/shikumi-cache-redis`. That project already uses the intended
`REDIS_SOCKET` variable, `redis-server --port 0 --unixsocket ... --unixsocketperm 700`, and a
socket-based Redis CLI readiness probe. This plan incorporates that behavior directly, so an
implementer does not need the other checkout to proceed.

There was no `docs/adr/` directory at plan creation, so no relevant local ADR existed then.
Implementation uncovered a durable macOS UNIX-socket path constraint and established the
long-lived service interface in
[ADR 1](../adr/1-use-project-local-sockets-for-redis-development-services.md). The repository
has no profiled ADR bundle, so the record follows a plain filesystem Markdown convention
without OKF frontmatter.


## Plan of Work

Milestone 1 establishes the generated Redis interface. In
`modules/haskell/nix-haskell-flake/module.dhall`, bump the version from 0.13.2 to 0.14.0,
mention Redis in the description, and declare `nix.redis` next to the other datastore
toggles. Give it type `bool`, default `false`, `required = True`, a description that names
`REDIS_SOCKET`, the socket-only process-compose behavior, and the local `redis/` directory,
plus a prompt such as “Include Redis with a local socket-only server?”. Add a conditional
step for the new `gitignore-redis.tpl` patch.

In `modules/haskell/nix-haskell-flake/files/nix/haskell.nix.tpl`, add `pkgs.redis` to
`baseDevPackages` only when `nix.redis` is true. Add a separate Redis `shellHook` block that
exports these exact interfaces and creates their parent directory:

```bash
export REDIS_SOCKET="$PWD/redis/redis.sock"
export REDIS_LOG="$PWD/redis/redis.log"
mkdir -p "$PWD/redis"
mkdir -p .dev
```

Quote paths because a checkout path can contain spaces. Do not export a TCP host or port and
do not alter PostgreSQL or ClickHouse behavior.

In `modules/haskell/nix-haskell-flake/files/process-compose.yaml.tpl`, add an independently
conditional process named `redis` with this operational behavior:

```yaml
redis:
  command: redis-server --port 0 --unixsocket "$REDIS_SOCKET" --unixsocketperm 700 --logfile "$REDIS_LOG" --daemonize no --save ""
  readiness_probe:
    exec:
      command: redis-cli -s "$REDIS_SOCKET" ping
```

Retain the template's existing readiness timing and restart style unless live validation
shows Redis needs a service-specific adjustment. Add the new one-line
`modules/haskell/nix-haskell-flake/files/gitignore-redis.tpl`. At the end of Milestone 1,
`seihou validate-module modules/haskell/nix-haskell-flake` must report 13 variables, 9
prompts, 14 steps, and a valid module.

Milestone 2 synchronizes every public description of the module. Update
`modules/haskell/nix-haskell-flake/README.md` with version 0.14.0, Redis in its summary,
the `nix.redis` variable and prompt, the `REDIS_SOCKET`/`REDIS_LOG` contract, the conditional
process-compose process, the ignored `redis/` directory, and an enabled usage example. Update
the inherited-variable summaries in both recipe READMEs and the optional-variable inventory
in `blueprints/fix-nix-haskell-flake-customizations/prompt.md`. Update the
`nix-haskell-flake` descriptions in `seihou-registry.dhall` and `mori.dhall` so they list
Redis (and preserve ClickHouse where applicable), and update Mori's template version to
0.14.0. Use `seihou registry sync-versions` to synchronize Seihou's version field, validate
the registry, and regenerate `okf-docs/` with the Seihou OKF extension. At the end of this
milestone, all current metadata reports version 0.14.0 and the generated module doc lists
`nix.redis`.

Milestone 3 proves the feature from rendered output through a live server. Render one fixture
with Redis disabled and confirm it contains no Redis package, environment, process file, or
ignore entry. Render a second fixture with only Redis and process-compose enabled, with the
built-in Haskell package, formatting, and pre-commit disabled so the smoke test focuses on
the service. Inspect its output, evaluate the generated development shell, start
process-compose detached, and query Redis through the generated socket. Acceptance is `PONG`
from the socket, live configuration reporting port `0`, and clean shutdown. The fixture path
itself supplies project isolation; no TCP port allocation or project-name-derived port is
allowed.


## Concrete Steps

Run all authoring and repository validation commands from
`/Users/shinzui/Keikaku/bokuno/seihou-modules` (or the corresponding root of another checkout
of this repository). First edit the Milestone 1 and Milestone 2 files, then validate and
synchronize metadata:

```bash
seihou validate-module modules/haskell/nix-haskell-flake
seihou registry sync-versions
seihou registry validate
seihou extension run okf -- docs --dir . --out okf-docs
okf validate okf-docs
```

Expected key output after the edits is:

```text
✓ 13 variables declared
✓ 9 prompts defined
✓ 14 steps defined
Module 'nix-haskell-flake' is valid.
OK: 6 modules, 2 recipes, 3 blueprints, 0 prompts, all versions in sync.
OK: 11 concepts
```

Run a focused search to catch stale inventories without rewriting historical ExecPlans:

```bash
rg -n "nix\.clickhouse|nix\.postgresql|Toggleable process-compose|optional process-compose" \
  modules recipes blueprints seihou-registry.dhall mori.dhall okf-docs
```

Every current module or recipe inventory found by this command should either mention Redis or
clearly be scoped only to another service. Do not edit completed historical plans merely to
make old prose describe the new release.

Create isolated fixtures directly under `/tmp` so the project-local Redis socket remains below
macOS's 104-byte UNIX-socket-path limit. The local `.seihou/modules` symlinks make the fixtures
resolve the module being edited rather than an older installed copy:

```bash
repo_root="$(pwd)"
disabled_fixture="$(mktemp -d "/tmp/nix-haskell-redis-disabled.XXXXXX")"
enabled_fixture="$(mktemp -d "/tmp/nix-haskell-redis-enabled.XXXXXX")"

mkdir -p "$disabled_fixture/.seihou/modules" "$enabled_fixture/.seihou/modules"
ln -s "$repo_root/modules/haskell/nix-haskell-flake" \
  "$disabled_fixture/.seihou/modules/nix-haskell-flake"
ln -s "$repo_root/modules/haskell/nix-haskell-flake" \
  "$enabled_fixture/.seihou/modules/nix-haskell-flake"
```

Render the disabled fixture:

```bash
cd "$disabled_fixture"
seihou run nix-haskell-flake --no-save-prompted \
  --var project.name=redis-disabled \
  --var project.description="Redis disabled fixture" \
  --var nix.process-compose=true \
  --var nix.postgresql=false \
  --var nix.redis=false \
  --var nix.clickhouse=false \
  --var nix.treefmt=false \
  --var nix.pre-commit=false \
  --var nix.builtin-package=false

test -e process-compose.yaml
! rg -n "pkgs\.redis|REDIS_SOCKET|REDIS_LOG" nix/haskell.nix
! rg -n "redis-server|redis-cli" process-compose.yaml
! rg -n '^redis/$' .gitignore
```

The existence check must exit zero and the three negative searches must print nothing. This
keeps process-compose enabled while proving that `nix.redis=false` suppresses only Redis.
Then render the enabled fixture:

```bash
cd "$enabled_fixture"
seihou run nix-haskell-flake --no-save-prompted \
  --var project.name=redis-enabled \
  --var project.description="Redis enabled fixture" \
  --var nix.process-compose=true \
  --var nix.postgresql=false \
  --var nix.redis=true \
  --var nix.clickhouse=false \
  --var nix.treefmt=false \
  --var nix.pre-commit=false \
  --var nix.builtin-package=false

rg -n "pkgs\.redis|REDIS_SOCKET|REDIS_LOG" nix/haskell.nix
rg -n "redis-server --port 0|redis-cli -s" process-compose.yaml
rg -n '^redis/$' .gitignore

seihou run nix-haskell-flake --no-save-prompted \
  --var project.name=redis-enabled \
  --var project.description="Redis enabled fixture" \
  --var nix.process-compose=true \
  --var nix.postgresql=false \
  --var nix.redis=true \
  --var nix.clickhouse=false \
  --var nix.treefmt=false \
  --var nix.pre-commit=false \
  --var nix.builtin-package=false
test "$(rg -c '^redis/$' .gitignore)" -eq 1
```

Expected matches include `pkgs.redis`, `REDIS_SOCKET="$PWD/redis/redis.sock"`,
`REDIS_LOG="$PWD/redis/redis.log"`, the server's `--port 0` and `--unixsocket` flags, the
socket-based readiness probe, and one `redis/` ignore line.

Finally, evaluate and exercise the service from the enabled fixture:

```bash
cd "$enabled_fixture"
pc_control_socket="$enabled_fixture/.dev/process-compose-control.sock"
nix develop .#ghc9124 --command process-compose \
  --use-uds --unix-socket "$pc_control_socket" up --detached
nix develop .#ghc9124 --command bash -ceu '
  for attempt in {1..20}; do
    if test -S "$REDIS_SOCKET" && test "$(redis-cli -s "$REDIS_SOCKET" ping)" = PONG; then
      break
    fi
    sleep 0.25
  done
  test -S "$REDIS_SOCKET"
  test "$(redis-cli -s "$REDIS_SOCKET" ping)" = PONG
  test "$(redis-cli -s "$REDIS_SOCKET" --raw CONFIG GET port | tail -n 1)" = 0
  printf "%s\n" "$REDIS_SOCKET"
'
nix develop .#ghc9124 --command process-compose \
  --use-uds --unix-socket "$pc_control_socket" down
```

The printed socket must be inside the enabled fixture and the command must exit zero. The
Redis log and process-compose log are retained in the fixture if diagnosis is needed. Once
validation is recorded in this plan and no longer needed, remove only the two exact temporary
directories held in `disabled_fixture` and `enabled_fixture`.


## Validation and Acceptance

The change is accepted only when all of the following observable behaviors hold.

With `nix.redis=false`, a freshly rendered project has no `pkgs.redis`, no Redis environment
variables, no `redis` process, and no `redis/` ignore patch. This proves the feature is truly
optional and that the default does not enlarge existing development shells.

With `nix.redis=true`, `nix develop .#ghc9124` exposes both `redis-server` and `redis-cli`,
sets `REDIS_SOCKET` to the absolute path `<fixture>/redis/redis.sock`, sets `REDIS_LOG` beside
it, and creates their parent directory. The generated `.gitignore` contains exactly one
`redis/` line even after applying the module a second time.

With both `nix.redis=true` and `nix.process-compose=true`, `process-compose up --detached`
(using a fixture-local control socket when the default control port is occupied) starts Redis
and its readiness probe becomes healthy. `redis-cli -s "$REDIS_SOCKET" ping` returns exactly:

```text
PONG
```

The same live server reports `0` for `CONFIG GET port`. This proves it is not listening on
the global Redis TCP port; uniqueness comes solely from the project-local socket path.
`process-compose down` exits successfully and the service no longer answers through that
socket.

`seihou validate-module`, `seihou registry validate`, and `okf validate okf-docs` all exit
zero. The module README, Seihou registry, Mori template metadata, and generated OKF module
document all report version 0.14.0 and describe optional socket-only Redis. No new entry is
added to `flake.nix.tpl` or `flake.lock`.


## Idempotence and Recovery

The implementation is additive. `mkdir -p` is safe on every shell entry, the Redis ignore
step uses `append-line-if-absent`, and rerunning `seihou registry sync-versions` or the OKF
documentation generator converges on the same output. Reapplying the module to a fixture is
therefore a useful idempotence check; it must not duplicate `redis/` in `.gitignore`.

If the live probe fails, first run `process-compose down` from the enabled fixture with the same
control-port or control-socket arguments used for `up`, then read `redis/redis.log` and
`.dev/process-compose.log`. If Redis reports that the UNIX socket path is too long, use a shorter
checkout or fixture path; on macOS Redis 8.8.0 requires the full path to be under 104 bytes. A
stale socket left after an abnormal exit belongs only to that fixture and can be removed after
confirming no Redis process is using it; restarting the service then recreates the socket. Do
not delete a consumer project's whole `redis/` directory automatically, because future users
may deliberately change the development persistence policy.

Temporary fixtures are disposable, but delete only the exact directories returned by the
two `mktemp -d` commands. The repository working tree should contain only the planned source,
documentation, metadata, and ExecPlan changes. No migration operation is needed; if a
rendered consumer has hand-edited a managed file, Seihou's normal conflict detection must be
resolved rather than bypassed.


## Interfaces and Dependencies

`modules/haskell/nix-haskell-flake/module.dhall` must expose this Seihou variable interface:

```text
nix.redis : bool
default = false
required = true
```

When false, it contributes nothing. When true, it selects `pkgs.redis`, the Redis shell-hook
block, and the `redis/` ignore patch. When it is true together with `nix.process-compose`, it
also selects the `redis` process in
`modules/haskell/nix-haskell-flake/files/process-compose.yaml.tpl`.

The generated shell interface is:

```text
REDIS_SOCKET=<absolute project root>/redis/redis.sock
REDIS_LOG=<absolute project root>/redis/redis.log
```

Applications and tests connect to `REDIS_SOCKET`; process-compose and `redis-cli` use the
same value. `REDIS_LOG` is diagnostic output. No `REDIS_HOST`, TCP port, password, logical
database number, or production persistence contract is introduced by this feature.

The only runtime package dependency is `pkgs.redis` from the nixpkgs already followed by the
generated flake. It supplies the `redis-server` and `redis-cli` executables. The server
command depends on Redis 8.8.0's stable configuration arguments `--port`, `--unixsocket`,
`--unixsocketperm`, `--logfile`, `--daemonize`, and `--save`; the readiness and acceptance
commands depend on `redis-cli -s <socket>`. `pkgs.process-compose` remains conditional on the
existing `nix.process-compose` variable and gains no new dependency or flake input.

Plan revision note (2026-08-29): Implementation changed the fixture instructions to create
short paths directly under `/tmp` after Redis 8.8.0 demonstrated macOS's under-104-byte UNIX
socket requirement. The live process-compose commands now use a fixture-local control socket
because this execution environment already occupies process-compose's default control port
8080. These validation-harness changes preserve the generated Redis interface and are recorded
in the living sections and ADR 1.
