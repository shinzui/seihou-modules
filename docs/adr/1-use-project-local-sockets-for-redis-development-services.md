# Use project-local sockets for Redis development services

## Status

Accepted on 2026-08-29.

## Context

The `nix-haskell-flake` Seihou module generates local development shells and optional
process-compose services. A Redis service that listens on its default TCP port 6379 prevents
two generated projects from running Redis concurrently without manual port coordination.
Hand-editing generated Nix or process-compose files to solve that collision also creates
conflicts during later Seihou updates.

An existing consumer at `mori://shinzui/shikumi/packages/shikumi-cache-redis` established the
environment name `REDIS_SOCKET` and a working socket-only Redis command. A UNIX-domain socket
is a filesystem path used for local inter-process communication, so a path beneath each
checkout naturally isolates projects without allocating a global TCP port.

UNIX-domain socket paths have operating-system limits. Redis 8.8.0 on macOS rejects a socket
whose full encoded path is 104 bytes or longer. The generated path therefore works only when
the checkout path plus `/redis/redis.sock` remains below the platform limit.

## Decision

`nix-haskell-flake` exposes a required Boolean variable named `nix.redis` with a default of
`false`. When enabled, it adds `pkgs.redis` from the module's existing nixpkgs lock, exports
`REDIS_SOCKET="$PWD/redis/redis.sock"` and `REDIS_LOG="$PWD/redis/redis.log"`, creates the
project-local `redis/` directory, and ignores that directory in Git.

When `nix.process-compose` is also enabled, the generated `redis` process runs in the foreground
with TCP disabled by `--port 0`, owner-only socket permissions via `--unixsocketperm 700`, and
snapshot persistence disabled via `--save ""`. Its readiness probe uses
`redis-cli -s "$REDIS_SOCKET" ping`, which tests the same connection path as consumers.

The feature is additive and ships as module version 0.14.0 without a migration operation.
Projects with an overlong checkout path must shorten or relocate the checkout; the module does
not silently move the Redis socket into a shared global temporary directory because that would
break the project-local interface and weaken isolation and discoverability.

## Consequences

Redis-enabled projects can run concurrently without competing for port 6379, and Redis-disabled
projects retain their previous generated shell and files. Applications have a single explicit
local connection contract, `REDIS_SOCKET`, and no Redis host or TCP port contract.

The checkout path becomes part of service viability on platforms with short UNIX-socket limits.
Failures are diagnosed in `redis/redis.log`; on macOS, a message that the socket path is too long
requires using a shorter checkout path. Process-compose's own control port or control socket is
independent of Redis and may still need runner-specific configuration when its default port 8080
is occupied.
