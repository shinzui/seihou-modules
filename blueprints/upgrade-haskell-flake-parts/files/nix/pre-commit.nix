# git-hooks.nix (pre-commit) as a flake-parts module. The dev shell installs the
# hooks via `config.pre-commit.installationScript` (see ./haskell.nix). Besides
# treefmt, add every custom hook the old flake had. Custom hook scripts live
# alongside this file under nix/ (e.g. nix/check-cli-module-placement.sh) and are
# referenced with a relative path.
{ inputs, ... }:
{
  imports = [ inputs.pre-commit-hooks.flakeModule ];

  perSystem = { config, pkgs, ... }: {
    pre-commit.settings.hooks = {
      treefmt = {
        enable = true;
        package = config.treefmt.build.wrapper;
      };

      # Custom hooks the project had go here, e.g. a system-language script hook:
      # cli-module-placement = {
      #   enable = true;
      #   name = "cli-module-placement";
      #   entry = "${pkgs.bash}/bin/bash ${./check-cli-module-placement.sh}";
      #   language = "system";
      #   pass_filenames = false;
      # };
    };
  };
}
