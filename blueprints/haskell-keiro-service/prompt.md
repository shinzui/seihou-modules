# Implement {{project.name}} as a Keiro service

The `haskell-keiro-project` base module has supplied six initial Cabal libraries, the
`nix-haskell-flake` environment, a workspace manifest, and `docs/bootstrap-keiro.md`.
Read that generated brief in full and carry out its workflow. It is the implementation
contract for namespace {{project.namespace}} and context {{keiro.context}}.

Establish real domain requirements before adding aggregates. Implement the complete service,
validate it, and report evidence as required by the brief. Preserve existing implementation
when this runs on a partially bootstrapped project; inspect Git and Seihou diffs before edits.

The blueprint's `files/` contains historical reference sketches. They are not authoritative
release pins, current API signatures, or a domain specification. Read `files/standards-map.md`
and resolve the current normative documents through Mori. In particular, do not copy the old
single-file DSL workflow, index-state, package bounds, or Settei compatibility exclusions.
Reconcile every sketch with the verified released APIs and generated compilation contract.

Do not commit or push. Hand off the package tree, release evidence, build and test results,
configuration and runtime checks, and any remaining failures.
