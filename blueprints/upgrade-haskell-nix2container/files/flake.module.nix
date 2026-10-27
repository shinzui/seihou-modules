# Reference only: merge into the consumer's UNMANAGED flake.module.nix.
# Replace service/package details with inventoried values. Keep this file tracked.
{ inputs, ... }:
{
  perSystem = { self', pkgs, system, ... }: {
    packages = pkgs.lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
      dockerImage = inputs.nix2container.packages.${system}.nix2container.buildImage {
        name = "service";
        tag = "latest";
        copyToRoot = pkgs.buildEnv {
          name = "service-image-root";
          paths = [ pkgs.cacert pkgs.coreutils pkgs.bashInteractive ];
          pathsToLink = [ "/bin" "/etc" ];
        };
        config = {
          Cmd = [ "${self'.packages.default}/bin/service" ];
          ExposedPorts = { "8080/tcp" = { }; };
          Env = [ "SSL_CERT_FILE=${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt" ];
        };
      };
    };
  };
}
