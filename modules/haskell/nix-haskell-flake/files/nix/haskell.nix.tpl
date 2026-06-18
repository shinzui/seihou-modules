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
      haskellPackages = pkgs.haskell.packages."{{ghc.version}}";

      baseDevPackages = [
        pkgs.zlib
        pkgs.just
        pkgs.pkg-config
        {{#if Eq nix.postgresql true || Eq nix.postgresql "true"}}
        pkgs.postgresql
        pkgs.jq
        {{/if}}
        {{#if Eq nix.process-compose true || Eq nix.process-compose "true"}}
        pkgs.process-compose
        {{/if}}
      ];

      shellHook = ''
        {{#if Eq nix.pre-commit true || Eq nix.pre-commit "true"}}
        ${config.pre-commit.installationScript}
        {{/if}}
        {{#if Eq nix.postgresql true || Eq nix.postgresql "true"}}

        export PGHOST="$PWD/db"
        export PGDATA="$PGHOST/db"
        export PGLOG=$PGHOST/postgres.log
        export PGDATABASE={{project.name}}
        export PG_CONNECTION_STRING=postgresql://$(jq -rn --arg x $PGHOST '$x|@uri')/$PGDATABASE

        mkdir -p $PGHOST
        mkdir -p .dev

        if [ ! -d $PGDATA ]; then
          initdb --auth=trust --no-locale --encoding=UTF8
        fi
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
      packages.default = haskellPackages.callCabal2nix "{{project.name}}" inputs.self { };

      devShells.default = mkProjectShell "{{ghc.version}}";
      devShells."{{ghc.version}}" = mkProjectShell "{{ghc.version}}";
      {{#if IsSet ghc.secondary}}
      devShells."{{ghc.secondary}}" = mkProjectShell "{{ghc.secondary}}";
      {{/if}}
    };
}
