{
  description = "<project description — copy verbatim from the old flake.nix>";

  inputs = {
    # The shared base flake. Provides the GHC 9.12.4 / cabal / HLS toolchain via
    # `mkDevShell`, and the single pinned nixpkgs the whole fleet follows.
    haskell-nix-dev.url = "github:shinzui/haskell-nix-dev";
    nixpkgs.follows = "haskell-nix-dev/nixpkgs";

    flake-parts.url = "github:hercules-ci/flake-parts";
    flake-parts.inputs.nixpkgs-lib.follows = "nixpkgs";

    treefmt-nix.follows = "haskell-nix-dev/treefmt-nix";

    pre-commit-hooks.url = "github:cachix/git-hooks.nix";
    pre-commit-hooks.inputs.nixpkgs.follows = "nixpkgs";

    # ---- PROJECT-SPECIFIC INPUTS ----
    # Keep every input the old flake declared (except flake-utils, which is
    # dropped). Common ones:
    #
    # Shared Haskell patch management (registry overlay), grafted onto the
    # haskell-nix-dev nixpkgs in flake.module.nix for the package build:
    # haskell-nix.url = "github:shinzui/haskell-nix";
    # haskell-nix.inputs.nixpkgs.follows = "nixpkgs";
    #
    # Non-flake source inputs the project bakes in (corpora, schemas, vendored
    # deps), pinned to a commit with `flake = false`:
    # some-src = {
    #   url = "github:owner/repo/<commit>";
    #   flake = false;
    # };
  };

  nixConfig = {
    extra-substituters = [ ];
    extra-trusted-public-keys = [ ];
  };

  # Thin flake-parts shell. The dev toolchain comes from the haskell-nix-dev base
  # flake (GHC 9.12.4 / cabal / HLS via mkDevShell); project wiring lives in the
  # imported ./nix modules; the package build and any custom checks live in
  # ./flake.module.nix.
  outputs = inputs@{ flake-parts, nixpkgs, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = nixpkgs.lib.systems.flakeExposed;

      imports =
        [
          ./nix/haskell.nix
          ./nix/treefmt.nix
          ./nix/pre-commit.nix
        ]
        ++ nixpkgs.lib.optional (builtins.pathExists ./flake.module.nix) ./flake.module.nix;
    };
}
