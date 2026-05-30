{
  description = "{{project.description}}";

  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
  inputs.flake-utils.url = "github:numtide/flake-utils";
  {{#if Eq nix.pre-commit true}}
  inputs.pre-commit-hooks.url = "github:cachix/git-hooks.nix";
  {{/if}}

  outputs = { self, nixpkgs, flake-utils{{#if Eq nix.pre-commit true}}, pre-commit-hooks{{/if}} }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
      in
      {
        checks = {
          {{#if Eq nix.pre-commit true}}
          pre-commit-check = pre-commit-hooks.lib.${system}.run {
            src = ./.;
            hooks = {
              oxlint = {
                enable = true;
                name = "oxlint";
                entry = "${pkgs.oxlint}/bin/oxlint";
                files = "\\.(c|m)?(j|t)sx?$";
                pass_filenames = false;
              };
              oxfmt = {
                enable = true;
                name = "oxfmt";
                entry = "${pkgs.oxfmt}/bin/oxfmt --check";
                files = "\\.(c|m)?(j|t)sx?$|\\.json$";
                pass_filenames = true;
              };
            };
          };
          {{/if}}
        };

        devShells.default = pkgs.mkShell {
          nativeBuildInputs = [
            pkgs.bun
            pkgs.just
            pkgs.oxlint
            pkgs.oxfmt
            pkgs.typescript
          ];

          shellHook = ''
            {{#if Eq nix.pre-commit true}}
            ${self.checks.${system}.pre-commit-check.shellHook}
            {{/if}}
            export LANG=en_US.UTF-8

            if [ ! -d node_modules ]; then
              echo "Run 'just install' (bun install) to fetch dependencies."
            fi
          '';
        };
      }
    );
}
