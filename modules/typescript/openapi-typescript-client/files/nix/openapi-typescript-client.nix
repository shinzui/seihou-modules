# seihou-managed; project additions belong in ../flake.module.nix.
{ ... }:
{
  perSystem = { pkgs, lib, ... }: {
    # Orval 8.46.0 requires Node >=22.18.0. Keep the base Bun/TS/Oxc pins.
    bunProject.extraDevPackages =
      assert lib.versionAtLeast pkgs.nodejs_22.version "22.18.0";
      [ pkgs.nodejs_22 ];
  };
}
