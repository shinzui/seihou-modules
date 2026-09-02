# Haskell project wiring: dev shells (via the haskell-nix-dev base flake) and the
# project package (via callCabal2nix). seihou-managed — to add project-specific
# dev tools without editing this file, set `haskellProject.extraDevPackages` from
# ./flake.module.nix (see flake.module.nix.example).
{ inputs, lib, flake-parts-lib, ... }:
{
  options.perSystem = flake-parts-lib.mkPerSystemOption ({ ... }: {
    options.haskellProject.extraDevPackages = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = [ ];
      example = lib.literalExpression "[ pkgs.ghciwatch pkgs.haskellPackages.hpack ]";
      description = ''
        Extra packages to add to the dev shell. Set this from ./flake.module.nix
        to add project-specific tooling without editing the generated
        ./nix/haskell.nix.
      '';
    };
  });

  config.perSystem = { system, pkgs, config, ... }:
    let
      hsdev = inputs.haskell-nix-dev.lib.${system};
      {{#if Eq nix.builtin-package true}}
      haskellPackages = pkgs.haskell.packages."{{ghc.version}}";
      {{/if}}

      baseDevPackages = [
        pkgs.zlib
        pkgs.just
        pkgs.pkg-config
        {{#if Eq nix.postgresql true}}
        # All three postgres entries are load-bearing for anything that builds
        # postgresql-libpq (hasql, postgresql-simple, persistent-postgresql, ...).
        # `pkgs.postgresql` is only the `out` output; `lib/pkgconfig/libpq.pc`
        # lives in `dev`, and that .pc file in turn declares
        # `Requires.private: libssl libcrypto`, which postgresql.dev does not
        # propagate. Drop either `.dev` and pkg-config cannot resolve libpq at
        # all, so postgresql-libpq dies in its configure step.
        #
        # This failure hides well: once that unit is in the cabal store a plain
        # `cabal build` never reconfigures it, so the shell looks fine until
        # something forces a fresh configure -- `cabal build --enable-profiling`
        # does exactly that, because the profiling way changes the unit-id hash.
        {{#if IsSet nix.pg-extensions}}
        # Postgres rebuilt with the requested extensions (e.g. pg_partman),
        # so their .control/.sql land in share and CREATE EXTENSION works.
        # pkgs.postgresql.dev below still supplies the matching libpq headers.
        (pkgs.postgresql.withPackages (pgp: [ {{nix.pg-extensions}} ]))
        {{#else}}
        pkgs.postgresql
        {{/if}}
        pkgs.postgresql.dev
        pkgs.openssl.dev
        pkgs.jq
        {{/if}}
        {{#if Eq nix.kafka true}}
        # librdkafka (nixpkgs: rdkafka). hw-kafka-client links -lrdkafka; both
        # the runtime lib and its .dev (headers + pkg-config) are needed.
        pkgs.rdkafka
        pkgs.rdkafka.dev
        {{/if}}
        {{#if Eq nix.clickhouse true}}
        pkgs.clickhouse
        {{/if}}
        {{#if Eq nix.redis true}}
        pkgs.redis
        {{/if}}
        {{#if Eq nix.process-compose true}}
        pkgs.process-compose
        {{/if}}
      ];

      shellHook = ''
        {{#if Eq nix.pre-commit true}}
        ${config.pre-commit.installationScript}
        {{/if}}
        {{#if Eq nix.postgresql true}}

        export PGHOST="$PWD/db"
        export PGDATA="$PGHOST/db"
        export PGLOG=$PGHOST/postgres.log
        export PGDATABASE={{#if IsSet nix.pg-database}}{{nix.pg-database}}{{#else}}{{project.name}}{{/if}}
        export PG_CONNECTION_STRING=postgresql://$(jq -rn --arg x $PGHOST '$x|@uri')/$PGDATABASE

        mkdir -p $PGHOST
        mkdir -p .dev

        if [ ! -d $PGDATA ]; then
          initdb --auth=trust --no-locale --encoding=UTF8
        fi
        {{/if}}
        {{#if Eq nix.clickhouse true}}

        # Local, rootless ClickHouse. The server (started by process-compose, or
        # manually with `clickhouse-server --path=$CLICKHOUSE_HOME/ …`) keeps all
        # of its state under CLICKHOUSE_HOME and uses clickhouse's embedded
        # default config. Override the ports here (or in an unmanaged .envrc/
        # flake.module.nix) if two projects need to run side by side.
        export CLICKHOUSE_HOME="$PWD/clickhouse"
        export CLICKHOUSE_TCP_PORT=9000
        export CLICKHOUSE_HTTP_PORT=8123

        mkdir -p $CLICKHOUSE_HOME
        mkdir -p .dev
        {{/if}}
        {{#if Eq nix.redis true}}

        # Local Redis communicates only through a project-local UNIX-domain
        # socket. TCP is disabled by the process-compose command.
        export REDIS_SOCKET="$PWD/redis/redis.sock"
        export REDIS_LOG="$PWD/redis/redis.log"

        mkdir -p "$PWD/redis"
        mkdir -p .dev
        {{/if}}
        {{#if Eq nix.kafka true}}

        # Make librdkafka discoverable to GHC's linker, the C preprocessor, and
        # pkg-config (hw-kafka-client links -lrdkafka).
        export CPATH="${pkgs.rdkafka.dev}/include''${CPATH:+:$CPATH}"
        export LIBRARY_PATH="${pkgs.rdkafka}/lib''${LIBRARY_PATH:+:$LIBRARY_PATH}"
        export PKG_CONFIG_PATH="${pkgs.rdkafka.dev}/lib/pkgconfig''${PKG_CONFIG_PATH:+:$PKG_CONFIG_PATH}"
        {{/if}}
      '';

      mkProjectShell = ghc: hsdev.mkDevShell {
        inherit ghc;
        extraNativeBuildInputs = baseDevPackages ++ config.haskellProject.extraDevPackages;
        withHls = true;
        inherit shellHook;
      };
    in
    {
      {{#if Eq nix.builtin-package true}}
      packages.default = haskellPackages.callCabal2nix "{{project.name}}" inputs.self { };

      {{/if}}
      devShells.default = mkProjectShell "{{ghc.version}}";
      devShells."{{ghc.version}}" = mkProjectShell "{{ghc.version}}";
      {{#if IsSet ghc.secondary}}
      devShells."{{ghc.secondary}}" = mkProjectShell "{{ghc.secondary}}";
      {{/if}}
    };
}
