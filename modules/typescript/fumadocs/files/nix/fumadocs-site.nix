# seihou-managed. Builds the static site from bun.lock and the generated bun-deps.nix.
{ lib, stdenvNoCC, bun, bun2nix }:
{ name, sourceRoot, fonts ? null }:
let
  manifest = builtins.fromJSON (builtins.readFile (sourceRoot + "/package.json"));
  excluded = [
    ".direnv" ".git" ".nitro" ".output" ".source" ".tanstack" ".vite"
    "flake.lock" "flake.module.nix" "flake.nix" "nix" "node_modules" "result"
  ];
in
stdenvNoCC.mkDerivation {
  pname = name;
  version = manifest.version;
  # Nix configuration and local build products never invalidate the site.
  src = builtins.path {
    path = sourceRoot;
    name = "${name}-source";
    filter = path: _:
      let relative = lib.removePrefix (toString sourceRoot + "/") (toString path);
      in !(builtins.elem (lib.head (lib.splitString "/" relative)) excluded);
  };
  bunDeps = bun2nix.fetchBunDeps { bunNix = sourceRoot + "/bun-deps.nix"; };
  strictDeps = true;
  nativeBuildInputs = [ bun bun2nix.hook ];
  bunInstallFlags = [ "--frozen-lockfile" "--linker=isolated" ]
    ++ lib.optional stdenvNoCC.hostPlatform.isDarwin "--backend=symlink";
  # Lifecycle scripts stay off, so generate what postinstall would have.
  dontRunLifecycleScripts = true;
  dontUseBunPatch = true;
  dontUseBunCheck = true;
  dontFixup = true;
  # Prerendering crawls a loopback preview server, which macOS sandboxes otherwise refuse.
  __darwinAllowLocalNetworking = true;
  buildPhase = ''
    runHook preBuild
    bun --bun fumadocs-mdx
    ${lib.optionalString (fonts != null) ''
      mkdir -p public/fonts
      cp -R ${fonts}/. public/fonts/
      chmod -R u+w public/fonts
    ''}
    bun --bun run build
    # A failed crawl still exits 0, so never publish a site missing its documentation.
    if [ ! -f .output/public/docs/index.html ] \
      || [ -z "$(find .output/public/__tsr/staticServerFnCache -name '*.json' -print -quit 2>/dev/null)" ]; then
      echo "Prerendering did not produce /docs and its server-function data; the site is incomplete" >&2
      exit 1
    fi
    runHook postBuild
  '';
  installPhase = ''
    runHook preInstall
    mkdir -p "$out/share"
    cp -R .output/public "$out/share/site"
    runHook postInstall
  '';
  meta.description = manifest.description;
}
