# Bun Nix acceptance fixtures

`single/` and `workspace/` contain complete project-owned manifests, sources and
application recipes. Bun 1.4.2 generated their v2 locks with `bun install --lockfile-only`;
the pinned patched bun2nix 2.1.2 generated their expressions. No local dependency
installation is committed or used to build them.

The dependency `is-number` is exactly 7.0.0, verified against npm metadata and the
upstream 7.0.0 tag (`98e8ff1da1a89f93d1397a24d7413ed15421c139`). The intentional
cache-change case is 6.0.0, verified against npm metadata and upstream tag
`b0953635829711e7dceec0eaa92bc56521a546eb`. Its supported public function was checked
in project `mori://jonschlinkert/is-number`, project-relative `index.js` (source-file
artifact URI pending). Both lock fixtures carry the registry's exact integrity hash.

`v1.lock` represents the same compact registry tuples in v1 (without v2's
`configVersion`). `unsupported-v3.lock` deliberately changes only the fixture's
format number for a negative test. `single-v6.lock` changes the exact dependency
and registry integrity together. These are test data, never migration instructions
for production locks.

Run from the repository root:

```bash
python3 scripts/test-nix-bun-flake.py
python3 scripts/test-nix-bun-flake.py --native
```

The native mode renders temporary projects through real Seihou operations, then
checks generation, frozen sandbox installation, output, source-edit cache reuse,
dependency invalidation and unchanged-build reuse. Repeat native mode on each
supported system. The workspace source and manifests enter only the application;
local generated records are removed lazily before constructing the registry cache.
