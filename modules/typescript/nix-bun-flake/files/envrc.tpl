watch_file nix/bun.nix
watch_file nix/bun2nix-package.nix
watch_file nix/bun2nix-module.nix
watch_file nix/tooling.nix
watch_file nix/pre-commit.nix
{{#if IsSet nix.package-module}}
if [ -f {{nix.package-module}} ]; then
  watch_file {{nix.package-module}}
fi
{{/if}}
watch_file flake.module.nix
use flake
eval "$shellHook"
source_env_if_exists .envrc.local
