let S =
      https://raw.githubusercontent.com/shinzui/seihou-schema/e9f91438f081fba90f40f987de93df9f74c7117d/package.dhall
        sha256:00f822087302b53f7ffe74e6505a633c59a0c2f206d12bfadb58a2fe211c0e40

in  S.Blueprint::{
    , name = "relaunch-fumadocs-docs"
    , version = Some "0.1.4"
    , description = Some
        "Relaunch a legacy Fumadocs documentation site: rehearse and apply the fumadocs-site recipe in place, install the writing skills, register with Mori, enable semantic SVG diagrams, add a source pin and release gates, then measure the content against the documented project and stop with a restart-or-refresh recommendation, a page list and a diagram catalog; never commits"
    , prompt = ./prompt.md as Text
    , vars =
      [ S.VarDecl::{
        , name = "docs.source-project"
        , type = "text"
        , default = Some ""
        , description = Some
            "Mori URI of the documented project, mori://<namespace>/<name>. Empty reads the first typed dependencyRefs entry of the site's mori.dhall."
        , required = False
        , validation = Some "(mori://[a-z0-9][a-z0-9-]*/[a-z0-9][a-z0-9._-]*)?"
        }
      , S.VarDecl::{
        , name = "docs.source-name"
        , type = "text"
        , default = Some ""
        , description = Some
            "Display name of the documented project, written into docs-source.json and shown by <TestedWith />. Empty uses the project's own spelling from its README."
        , required = False
        }
      , S.VarDecl::{
        , name = "relaunch.rehearsal-only"
        , type = "bool"
        , default = Some "false"
        , description = Some
            "Run every phase in a scratch clone and leave the real checkout, including its Mori registration, untouched"
        , required = False
        }
      ]
    , prompts =
      [ S.Prompt::{
        , var = "docs.source-project"
        , text =
            "Mori URI of the project this site documents? (mori://<namespace>/<name>; empty reads mori.dhall dependencyRefs)"
        }
      , S.Prompt::{
        , var = "docs.source-name"
        , text = "Display name of the documented project? (empty uses its README)"
        }
      ]
    , baseModules = [] : List S.Dependency.Type
    , files =
      [ S.Blueprint.BlueprintFile::{
        , src = "migration-ledger.md"
        , description = Some
            "Ledger template with the entry format; becomes docs/migration-ledger.md"
        }
      , S.Blueprint.BlueprintFile::{
        , src = "docs-source.json"
        , description = Some
            "Shape of the project-neutral source pin; write the real one with scripts/prepare-source-pin.mjs --init"
        }
      , S.Blueprint.BlueprintFile::{
        , src = "verification.schema.json"
        , description = Some
            "JSON Schema of docs/verification.json, the per-page verification register"
        }
      , S.Blueprint.BlueprintFile::{
        , src = "docs-gates.json"
        , description = Some
            "Site settings for the gates: OpenAPI directory, API base directory, generated pages, extra private text"
        }
      , S.Blueprint.BlueprintFile::{
        , src = "assess-content.mjs"
        , description = Some
            "Content assessment: measures the restart criteria and seeds the page list and diagram catalog; run from the site root, not copied"
        }
      , S.Blueprint.BlueprintFile::{
        , src = "scripts/doc-pages.mjs"
        , description = Some "Shared helpers for the gates: pages, pin, citations, OpenAPI operations, private text"
        }
      , S.Blueprint.BlueprintFile::{
        , src = "scripts/prepare-source-pin.mjs"
        , description = Some
            "Writes docs-source.json from mori.dhall and the project checkout, and creates a worktree of the pin"
        }
      , S.Blueprint.BlueprintFile::{
        , src = "scripts/check-source-refs.mjs"
        , description = Some "Gate: every <SourceRef> file and symbol exists at the pinned revision"
        }
      , S.Blueprint.BlueprintFile::{
        , src = "scripts/check-verification.mjs"
        , description = Some "Gate: every page has a register record verified at the pin"
        }
      , S.Blueprint.BlueprintFile::{
        , src = "scripts/check-doc-prose.mjs"
        , description = Some
            "Gate: private paths, shell prompts, marketing words and vague headings"
        }
      , S.Blueprint.BlueprintFile::{
        , src = "scripts/check-static-output.mjs"
        , description = Some
            "Gate: every page prerendered and searchable, and no private text in the built output"
        }
      , S.Blueprint.BlueprintFile::{
        , src = "scripts/check-doc-links.mjs"
        , description = Some
            "Gate: source-level internal links, accepting generated OpenAPI operation pages"
        }
      , S.Blueprint.BlueprintFile::{
        , src = "scripts/report-source-drift.mjs"
        , description = Some
            "Lists pages whose cited files changed between their verified revision and a candidate pin"
        }
      , S.Blueprint.BlueprintFile::{
        , src = "scripts/generate-api-index.mjs"
        , description = Some
            "Generates the HTTP API index page from the OpenAPI documents, with a --check mode"
        }
      , S.Blueprint.BlueprintFile::{
        , src = "src/components/source-ref.tsx"
        , description = Some
            "<SourceRef path symbol> commit-pinned permalinks and <TestedWith />, read from docs-source.json"
        }
      ]
    , allowedTools = Some
      [ "Read"
      , "Write"
      , "Edit"
      , "Glob"
      , "Grep"
      , "Bash(git *)"
      , "Bash(seihou *)"
      , "Bash(mori *)"
      , "Bash(nix *)"
      , "Bash(bun *)"
      , "Bash(node *)"
      , "Bash(python3 *)"
      , "Bash(just *)"
      , "Bash(dhall-to-json *)"
      , "Bash(container *)"
      , "Bash(curl *)"
      , "Bash(cd *)"
      , "Bash(cp *)"
      , "Bash(mv *)"
      , "Bash(rm *)"
      , "Bash(mkdir *)"
      , "Bash(ls *)"
      , "Bash(cat *)"
      , "Bash(find *)"
      , "Bash(diff *)"
      , "Bash(shasum *)"
      , "Bash(tar *)"
      , "Bash(pwd)"
      , "Bash(test *)"
      , "Bash(xargs *)"
      , "Bash(sort *)"
      , "Bash(head *)"
      , "Bash(tail *)"
      , "Bash(wc *)"
      , "Bash(grep *)"
      ]
    , migrations = [] : List S.BlueprintMigration.Type
    , tags = [ "typescript", "fumadocs", "docs", "migration", "diataxis", "mori" ]
    }
