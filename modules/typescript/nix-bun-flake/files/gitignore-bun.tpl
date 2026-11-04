node_modules
dist
build
.direnv
# `nix build` links land at the root. Unanchored rules from earlier versions also
# ignored source files such as src/result-table.tsx, so undo those before anchoring.
!result
!result-*
/result
/result-*
*.log
.env
.env.local
bun.lock.bak
.DS_Store
