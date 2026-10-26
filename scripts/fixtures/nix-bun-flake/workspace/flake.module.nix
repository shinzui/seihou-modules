# Fixture-owned application recipe; workspace sources never enter the registry cache.
{ ... }:
{
  perSystem = { config, pkgs, lib, ... }:
    let
      bun2nix = config.packages.bun2nix;
      workspacePaths = [ ./packages/app/package.json ./packages/shared/package.json ];
      workspaceNames = map (path: (builtins.fromJSON (builtins.readFile path)).name) workspacePaths;
      registryOnly = { copyPathToStore, fetchFromGitHub, fetchgit, fetchurl, ... }@args:
        builtins.removeAttrs (import ./bun-deps.nix args) workspaceNames;
      bunDeps = bun2nix.fetchBunDeps { bunNix = registryOnly; };
      src = builtins.path {
        path = ./.;
        name = "bun-fixture-source";
        filter = path: _:
          let relative = lib.removePrefix (toString ./. + "/") (toString path);
          in builtins.elem relative [
            "package.json" "bun.lock" "packages" "packages/app" "packages/shared"
            "packages/app/package.json" "packages/app/index.js"
            "packages/shared/package.json" "packages/shared/index.js"
          ];
      };
      app = pkgs.stdenvNoCC.mkDerivation {
        pname = "bun-workspace-fixture";
        version = "1.0.0";
        inherit src bunDeps;
        strictDeps = true;
        nativeBuildInputs = [ pkgs.bun bun2nix.hook ];
        bunInstallFlags = [ "--frozen-lockfile" "--linker=isolated" ]
          ++ lib.optional pkgs.stdenv.hostPlatform.isDarwin "--backend=symlink";
        dontRunLifecycleScripts = true;
        buildPhase = ''
          runHook preBuild
          bun --no-install packages/app/index.js > result.txt
          runHook postBuild
        '';
        installPhase = ''
          runHook preInstall
          mkdir -p "$out"
          cp result.txt "$out/result.txt"
          runHook postInstall
        '';
      };
    in {
      packages.default = app;
      packages.registry-cache = bunDeps;
      packages.fixture-bun = pkgs.bun;
      checks.fixture = app;
      apps.default = {
        type = "app";
        program = "${pkgs.writeShellScript "fixture-result" ''
          exec ${pkgs.coreutils}/bin/cat ${app}/result.txt
        ''}";
      };
    };
}
