# Unmanaged example. Copy the consumer's inventoried exact selection into
# ./runtime-selection.json; do not copy a moving default or guess generations.
{ ... }: {
  perSystem = { pkgs, config, ... }: {
    haskellProject = {
      runtime = builtins.fromJSON (builtins.readFile ./runtime-selection.json);
      # The root/CLI scaffold already declares its own packages. For custom
      # multi-package wiring declare every application recipe explicitly:
      # ownPackages = [ "example-core" "example-cli" ];
      # applicationOverlays = [ (final: _: {
      #   example-core = final.callCabal2nix "example-core" ./example-core { };
      #   example-cli = final.callCabal2nix "example-cli" ./example-cli { };
      # }) ];
      extraDevPackages = [ pkgs.ripgrep ];
      extraBuildInputs = [ pkgs.zlib ];
      withHls = null;
      shellHook = "export PROJECT_ENV=preserved";
    };
    # Custom outputs select config.haskellProject.applicationScope.<package>.
    # Preserve the full SDK scope and any separately accepted production tuning.
  };
}
