index-state: {{haskell.index-state}}
with-compiler: ghc-9.12.4

packages:
  {{project.name}}-core
  {{project.name}}-api
  {{project.name}}-migrations
  {{project.name}}-workers
  {{project.name}}-server
  {{project.name}}-client

-- Created by the workspace scaffolder after the real domain is authored.
optional-packages:
  {{project.name}}-core/src/keiro-dsl-conformance.workspace.*/*.cabal

tests: True
test-show-details: direct
