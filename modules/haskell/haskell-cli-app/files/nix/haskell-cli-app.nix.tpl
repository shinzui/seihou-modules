# Workspace package outputs for the two-package {{project.name}} CLI scaffold.
# seihou-managed by haskell-cli-app; project-specific customizations still
# belong in the unmanaged ../flake.module.nix imported by the base flake.
{ inputs, ... }:
{
  perSystem = { pkgs, ... }:
    let
      haskellPackages = pkgs.haskell.packages."{{ghc.version}}".override {
        overrides = hself: _hsuper: {
          "{{project.name}}-core" =
            hself.callCabal2nix "{{project.name}}-core" (inputs.self + "/{{project.name}}-core") { };
          "{{project.name}}-cli" =
            hself.callCabal2nix "{{project.name}}-cli" (inputs.self + "/{{project.name}}-cli") { };
        };
      };

      corePackage = haskellPackages."{{project.name}}-core";
      cliPackage = haskellPackages."{{project.name}}-cli";
    in
    {
      packages."{{project.name}}-core" = corePackage;
      packages."{{project.name}}-cli" = cliPackage;
      packages.default = cliPackage;
      {{#if Eq project.tests true}}
      checks."{{project.name}}-cli-test" = pkgs.haskell.lib.doCheck cliPackage;
      {{/if}}
    };
}
