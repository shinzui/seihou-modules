# seihou-managed. Customize through docsContainer options in ../flake.module.nix.
{ inputs, ... }:
{
  perSystem = { config, lib, pkgs, system, ... }:
    let
      name = "{{project.name}}";
      sourceRoot = ../.;
      # Stays absent until bun-deps.nix is generated and added to Git.
      ready = builtins.pathExists (sourceRoot + "/bun-deps.nix");
      bun2nix =
        assert lib.assertMsg (config.packages ? bun2nix)
          "docs.container=true also requires nix.bun2nix=true: run seihou update fumadocs with --var nix.bun2nix=true";
        config.packages.bun2nix;
      site = pkgs.callPackage ./fumadocs-site.nix { inherit bun2nix; } {
        inherit name sourceRoot;
        inherit (config.docsContainer) fonts;
      };
    in
    {
      options.docsContainer.fonts = lib.mkOption {
        type = lib.types.nullOr lib.types.path;
        default = null;
        description = "Directory copied into public/fonts for the Nix build; the local font flake is unavailable in the sandbox.";
      };
      config = {
        bunProject.extraDevPackages = [ pkgs.caddy ];
        packages = lib.optionalAttrs ready ({
          docs-site = site;
          docs-caddy-config = pkgs.callPackage ./caddy-config.nix { } { };
        } // lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
          dockerImage = pkgs.callPackage ./container.nix {
            nix2container = inputs.nix2container.packages.${system}.nix2container;
          } { inherit site name; };
        });
      };
    };
}
