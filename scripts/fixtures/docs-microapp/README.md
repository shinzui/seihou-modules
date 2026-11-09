# Qualified documentation reader dependency set

`bun.lock` and `bun-deps.nix` qualify the generated `fixture-docs` workspace with
Bun 1.4.2 and the base module's pinned bun2nix helper. Consumer projects own and
generate their own locks; the module does not seed these fixture files.

Tests copy these files after real Seihou generation, install frozen dependencies,
and build through the generated Nix outputs. Workspace records in the dependency
expression are removed lazily by the app helper before registry-cache construction.
The workspace source directories intentionally do not live beside this expression.

On 2026-11-09, npm metadata and upstream release tags agreed on the selected
Start 1.169.5, Router 1.170.46, React 19.3.1, React Aria Components 1.22.1,
Vite 8.3.7, Vite React plugin 6.3.0, Tailwind 4.3.5 and Highlights 0.5.0.
The fixture lock retains the exact transitive closure. Owners include
`mori://TanStack/router`, `mori://adobe/react-spectrum`,
`mori://shadcn-ui/ui` and `mori://pierrecomputer/pierre/packages/@pierre/highlights`.
The current releases were verified upstream because the local Pierre corpus lags.

Refresh by rendering a new `fixture-docs` consumer, intentionally changing direct
pins in the module seeds, running `bun install` and the generated `bun2nix` helper,
then copying both files together and rerunning all three acceptance scripts.
No script uses fake dependency hashes or bypasses frozen Nix installation.
