{
  description = "{{project.description}}";

  inputs.haskell-nix-dev.url = "github:shinzui/haskell-nix-dev";
  inputs.nixpkgs.follows = "haskell-nix-dev/nixpkgs";
  inputs.flake-utils.follows = "haskell-nix-dev/flake-utils";
  {{#if Eq nix.treefmt true}}
  inputs.treefmt-nix.follows = "haskell-nix-dev/treefmt-nix";
  {{/if}}
  {{#if Eq nix.pre-commit true}}
  inputs.pre-commit-hooks.url = "github:cachix/git-hooks.nix";
  {{/if}}

  # TODO(haskell-nix-dev EP-2): fill in the Cachix substituter URL and public key once the
  # base flake's binary cache is published, so the first `nix develop` downloads prebuilt
  # GHC/HLS/cabal instead of compiling HLS from source. Left empty (inert) until then.
  nixConfig = {
    extra-substituters = [ ];
    extra-trusted-public-keys = [ ];
  };

  outputs = { self, nixpkgs, haskell-nix-dev, flake-utils{{#if Eq nix.treefmt true}}, treefmt-nix{{/if}}{{#if Eq nix.pre-commit true}}, pre-commit-hooks{{/if}} }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
        hsdev = haskell-nix-dev.lib.${system};
        haskellPackages = pkgs.haskell.packages."{{ghc.version}}";

        commonNativeBuildInputs = [
          pkgs.zlib
          pkgs.just
          pkgs.pkg-config
          {{#if Eq nix.postgresql true}}
          pkgs.postgresql
          {{/if}}
        ] ++ pkgs.lib.optional {{nix.process-compose}} pkgs.process-compose;

        commonShellHook = ''
          {{#if Eq nix.pre-commit true}}
          ${self.checks.${system}.pre-commit-check.shellHook}
          {{/if}}
          {{#if Eq nix.postgresql true}}

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
          extraNativeBuildInputs = commonNativeBuildInputs;
          withHls = true;
          shellHook = commonShellHook;
        };
        {{#if Eq nix.treefmt true}}
        treefmtEval = treefmt-nix.lib.evalModule pkgs ./treefmt.nix;
        formatter = treefmtEval.config.build.wrapper;
        {{/if}}
      in
      {
        {{#if Eq nix.treefmt true}}
        formatter = formatter;

        {{/if}}
        packages = {
          default = haskellPackages.callCabal2nix "{{project.name}}" ./. { };
        };

        checks = {
          {{#if Eq nix.treefmt true}}
          formatting = treefmtEval.config.build.check self;
          {{/if}}
          {{#if Eq nix.pre-commit true}}
          pre-commit-check = pre-commit-hooks.lib.${system}.run {
            src = ./.;
            hooks = {
              {{#if Eq nix.treefmt true}}
              treefmt.package = formatter;
              treefmt.enable = true;
              {{/if}}
            };
          };
          {{/if}}
        };

        devShells = {
          default = mkProjectShell "{{ghc.version}}";
          "{{ghc.version}}" = mkProjectShell "{{ghc.version}}";
          {{#if IsSet ghc.secondary}}
          "{{ghc.secondary}}" = mkProjectShell "{{ghc.secondary}}";
          {{/if}}
        };
      });
}
