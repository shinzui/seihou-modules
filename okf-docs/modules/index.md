# SeihouModule

- [fumadocs](fumadocs.md) - Fumadocs documentation site on TanStack Start + Vite, layered on nix-bun-flake's dev shell: a static-SPA docs app with self-hosted custom fonts, beautiful-mermaid diagrams, and an interactive zoom/pan/expand widget for every diagram
- [git-init](git-init.md) - Initialize a local git repo (default branch master), seed .gitignore with .claude/, .agents/, and .seihou/manifest.json.tmp, and optionally create a private GitHub repo via `gh` under a configured org or username
- [haskell-cli-app](haskell-cli-app.md) - Haskell CLI app bootstrap: two cabal packages (core library + CLI exe) on GHC 9.12 / GHC2024, with lens + generic-lens, BSD-3 license, and a nix-haskell-flake dev shell
- [haskell-keiro-project](haskell-keiro-project.md) - Six-package Keiro bootstrap with a Nix development shell, workspace manifest, development recipes, and a project-specific implementation brief
- [haskell-library](haskell-library.md) - Haskell library bootstrap: a single cabal package on GHC 9.12 / GHC2024, with lens + generic-lens, BSD-3 license, an optional tasty test-suite, and a nix-haskell-flake dev shell
- [nix-bun-flake](nix-bun-flake.md) - Nix flake for Bun + TypeScript projects with oxlint linting, oxfmt formatting (semicolon-free, sorted imports), a just task runner, and optional git-hooks.nix pre-commit checks
- [nix-haskell-flake](nix-haskell-flake.md) - Nix flake for Haskell projects consuming the haskell-nix-dev base flake (prebuilt GHC/HLS/cabal); one rev-pinned base-flake URL that every other input follows, so a module version locks identically everywhere. Optional process-compose, PostgreSQL, socket-only Redis, ClickHouse, treefmt, and pre-commit

