# seihou-managed. A non-root Caddy image of the static site, built with nix2container.
{ runCommand, caddy, callPackage, nix2container }:
{ site, name, tag ? "latest", port ? "8080" }:
let
  caddyConfig = callPackage ./caddy-config.nix { } { inherit port; };
  # Caddy changes rarely and the site often, so each gets its own layer.
  runtimeLayer = nix2container.buildLayer { deps = [ caddy ]; };
  siteLayer = nix2container.buildLayer { deps = [ site ]; layers = [ runtimeLayer ]; };
  root = runCommand "${name}-container-root" { } ''
    mkdir -p $out/srv $out/etc/caddy
    ln -s ${site}/share/site $out/srv/site
    ln -s ${caddyConfig} $out/etc/caddy/Caddyfile
  '';
in
nix2container.buildImage {
  inherit name tag;
  layers = [ runtimeLayer siteLayer ];
  copyToRoot = root;
  config = {
    User = "65532:65532";
    ExposedPorts."${port}/tcp" = { };
    Entrypoint = [ "${caddy}/bin/caddy" ];
    Cmd = [ "run" "--config" "/etc/caddy/Caddyfile" "--adapter" "caddyfile" ];
  };
}
