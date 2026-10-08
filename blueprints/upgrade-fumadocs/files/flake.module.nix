# Optional project-owned extension: retain pnpm and Node workflows if needed.
{ ... }:
{
  perSystem = { pkgs, ... }: {
    bunProject.extraDevPackages = [ pkgs.nodejs_22 pkgs.pnpm_11 ];
  };
}
