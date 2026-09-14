# Project-local Redpanda on Apple Container — macOS only, opt-in (nix.redpanda).
# seihou-managed.
#
# The default dev flow targets the *shared* machine-wide Redpanda cluster (the
# one home/redpanda.nix runs at 127.0.0.1:9092); projects prefix their topics
# and coexist on it. This module is for the other case: a PRIVATE, throwaway
# cluster a test genuinely needs to have to itself. Its container/volume/network
# names are derived from the project name and its host ports are a distinct
# high block, so it never collides with the shared cluster or with another
# project's private cluster (ADR-2 of the redpanda-container flake: "a project
# needing a private cluster must choose its own ports explicitly").
#
# It reuses the redpanda-container flake's battle-tested lifecycle scripts
# (scripts.nix is a pure { pkgs, lib, cfg } function, and defaults.nix was built
# so a second instance is "a matter of passing different values"), re-exposing
# them under redpanda-local-{up,down,status,logs,purge} so they never shadow the
# global redpanda-* commands installed by home-manager.
#
# Apple Container exists only on Apple-Silicon macOS, so on any non-Darwin system
# this module contributes nothing (the toggle is inert; use the shared cluster or
# a docker-based broker there).
{ inputs, lib, ... }:
{
  perSystem = { pkgs, ... }:
    lib.optionalAttrs pkgs.stdenv.hostPlatform.isDarwin (
      let
        rc = inputs.redpanda-container;

        # Start from the flake's defaults (images, platform, container-side ports,
        # broker uid/gid, timeouts, package = pkgs.container) and override only the
        # bits that make this instance private and non-colliding.
        cfg = (import "${rc}/modules/home/defaults.nix" { inherit pkgs; }) // {
          network = "{{project.name}}-rp";
          brokerName = "{{project.name}}-rp-0";
          consoleName = "{{project.name}}-rp-console";
          volumeName = "{{project.name}}-rp-0-data";
          internalHost = "{{project.name}}-rp-0";

          # console-hosts scratch file. Project-scoped and cwd-independent (the
          # data itself lives in the named Apple Container volume, not here), so
          # nothing lands in the repo.
          stateDir = "\${XDG_STATE_HOME:-$HOME/.local/state}/redpanda-{{project.name}}";

          enableConsole = {{#if Eq nix.redpanda-console true}}true{{#else}}false{{/if}};

          # Host ports — a distinct high block so this cannot bind over the shared
          # cluster (9092/9644/8081/8082/8080). Override per project (or when
          # running two private clusters at once) via the redpanda.*-port vars.
          ports = {
            kafka = {{redpanda.kafka-port}};
            admin = {{redpanda.admin-port}};
            schemaRegistry = {{redpanda.schema-registry-port}};
            proxy = {{redpanda.proxy-port}};
            console = {{redpanda.console-port}};
          };
        };

        scripts = import "${rc}/modules/home/scripts.nix" { inherit pkgs lib cfg; };

        # Re-expose under redpanda-local-* so they don't shadow the global
        # redpanda-* commands from home/redpanda.nix.
        localScripts = map
          (n: pkgs.writeShellScriptBin
            (lib.replaceStrings [ "redpanda-" ] [ "redpanda-local-" ] n)
            ''exec ${scripts.${n}}/bin/${n} "$@"'')
          (builtins.attrNames scripts);
      in
      {
        # Merges with any extraDevPackages set in flake.module.nix.
        haskellProject.extraDevPackages = localScripts;
      }
    );
}
