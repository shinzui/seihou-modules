# Tooling only; application compiler/runtime selection stays in nix/haskell.nix.
# mori://shinzui/hurl-workbench and mori://shinzui/hinagata
{ ... }: {
  perSystem = { pkgs, ... }: {
    haskellProject.extraDevPackages = [
      pkgs.hurl
      pkgs.dhall
      (pkgs.writeShellScriptBin "hurl-workbench" ''
        exec nix shell github:shinzui/hurl-workbench/a29d26ad5e90aa762de88be18f06fddf67b6d02f#default -c hurl-workbench "$@"
      '')
      (pkgs.writeShellScriptBin "hinagata" ''
        exec nix shell github:shinzui/hinagata/a0c1059743e5957e66e4b8cee9e485ad89471937#default -c hinagata "$@"
      '')
    ];
  };
}
