dist
dist-*
cabal-dev
.direnv
cabal.project.local
db/
# `nix build` links land at the root. Unanchored rules from earlier versions also
# ignored source files such as src/result-table.tsx, so undo those before anchoring.
!result
!result-*
/result
/result-*
