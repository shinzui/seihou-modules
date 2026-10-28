# SeihouModule

- [fumadocs](fumadocs.md) - Fumadocs documentation site on TanStack Start + Vite, layered on nix-bun-flake's dev shell: a static-SPA docs app with self-hosted custom fonts, zombie-mermaid diagrams, an interactive zoom/pan/expand widget for every diagram, and optional OpenAPI reference pages
- [gcp-kube-env](gcp-kube-env.md) - Checkout-local GCP project and Kubernetes context through direnv, with a private kubeconfig and a configurable env filename defaulting to .envrc.local
- [git-init](git-init.md) - Initialize a local git repo (default branch master), seed .gitignore with .claude/, .agents/, and .seihou/manifest.json.tmp, and optionally create a private GitHub repo via `gh` under a configured org or username, optionally granting an organization team access
- [haskell-cli-app](haskell-cli-app.md) - Tested two-package Haskell CLI with project-owned source/Cabal/changelog starters (Seihou 0.11.0.0+), current GHC shells and managed Nix package/check outputs
- [haskell-keiro-project](haskell-keiro-project.md) - Six-package Keiro bootstrap with project-owned domain/API/test starters (Seihou 0.11.0.0+), OpenAPI, optional Mori inventory and managed Nix/test tooling
- [haskell-library](haskell-library.md) - Single-package Haskell library with project-owned starters (Seihou 0.11.0.0+), optional tasty tests and a managed Nix dev shell
- [nix-bun-flake](nix-bun-flake.md) - Nix flake for Bun + TypeScript projects with oxlint linting, oxfmt formatting (semicolon-free, sorted imports), a just task runner, optional git-hooks.nix pre-commit checks, and opt-in pinned bun2nix build helpers
- [nix-haskell-flake](nix-haskell-flake.md) - Nix flake for Haskell projects consuming the haskell-nix-dev base flake (prebuilt GHC/HLS/cabal), with an exact canonical lock across feature toggles, an optional managed package-module import for composed scaffolds, an unmanaged user extension point, pinned nix2container service image support, local services, treefmt, and pre-commit hooks
- [repo-dir](repo-dir.md) - Create <repo.parentDir>/<repo.name> and bootstrap it by running git-init inside it with a matching GitHub repo; the GitHub user or organization comes from git.githubOwner, so per-context config picks the owner

