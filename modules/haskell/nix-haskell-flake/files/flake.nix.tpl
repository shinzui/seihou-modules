{
  description = "{{project.description}}";

  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
  inputs.flake-utils.url = "github:numtide/flake-utils";
  {{#if Eq nix.treefmt true}}
  inputs.treefmt-nix.url = "github:numtide/treefmt-nix";
  {{/if}}
  {{#if Eq nix.pre-commit true}}
  inputs.pre-commit-hooks.url = "github:cachix/git-hooks.nix";
  {{/if}}

  outputs = { self, nixpkgs, flake-utils{{#if Eq nix.treefmt true}}, treefmt-nix{{/if}}{{#if Eq nix.pre-commit true}}, pre-commit-hooks{{/if}} }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
        haskellPackages = pkgs.haskell.packages."{{ghc.version}}";
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
          default = haskellPackages.{{project.name}};
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

        devShells.default = pkgs.mkShell {
          nativeBuildInputs = [
            pkgs.zlib
            pkgs.just
            pkgs.cabal-install
            pkgs.pkg-config
            {{#if Eq nix.postgresql true}}
            pkgs.postgresql
            {{/if}}
            (haskellPackages.ghcWithPackages (ps: [
              ps.haskell-language-server
            ]))
          ]
          ++ pkgs.lib.optional {{nix.process-compose}} pkgs.process-compose;

          shellHook = ''
            {{#if Eq nix.pre-commit true}}
            ${self.checks.${system}.pre-commit-check.shellHook}
            {{/if}}
            export LANG=en_US.UTF-8
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
        };
      }
    );
}
