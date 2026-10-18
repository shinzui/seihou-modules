# Workspace package outputs for the two-package {{project.name}} CLI scaffold.
# seihou-managed by haskell-cli-app; project-specific customizations still
# belong in the unmanaged ../flake.module.nix imported by the base flake.
{ inputs, ... }:
{
  perSystem = { pkgs, config, ... }:
    let
      haskellPackages = config.haskellProject.applicationScope;
      corePackage = haskellPackages."{{project.name}}-core";
      cliPackage = haskellPackages."{{project.name}}-cli";
    in
    {
      haskellProject.ownPackages = [ "{{project.name}}-core" "{{project.name}}-cli" ];
      haskellProject.applicationOverlays = [ (hself: _hsuper: {
        "{{project.name}}-core" =
          hself.callCabal2nix "{{project.name}}-core"
            (builtins.path {
              path = inputs.self + "/{{project.name}}-core";
              name = "{{project.name}}-core-source";
            }) { };
        "{{project.name}}-cli" =
          hself.callCabal2nix "{{project.name}}-cli"
            (builtins.path {
              path = inputs.self + "/{{project.name}}-cli";
              name = "{{project.name}}-cli-source";
            }) { };
      }) ];
      packages."{{project.name}}-core" = corePackage;
      packages."{{project.name}}-cli" = cliPackage;
      packages.default = cliPackage;
      {{#if Eq project.tests true}}
      checks."{{project.name}}-cli-test" = pkgs.haskell.lib.doCheck cliPackage;
      {{/if}}
    };
}
