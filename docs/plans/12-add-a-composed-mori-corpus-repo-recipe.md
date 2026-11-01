---
id: 12
slug: add-a-composed-mori-corpus-repo-recipe
title: "Add a composed mori-corpus-repo recipe"
kind: exec-plan
created_at: 2026-11-01T23:24:39Z
provenance:
  created_by:
    model: "gpt-6.1-sol"
    harness: "codex-cli"
    at: 2026-11-01T23:24:39Z
---

# Add a composed mori-corpus-repo recipe

This ExecPlan is a living document. The sections Progress, Surprises & Discoveries,
Decision Log, and Outcomes & Retrospective must be kept up to date as work proceeds.
If durable project context changes, update or create ADRs in docs/adr/ in the same change.
Record friction met while implementing in the friction-log bundle as it occurs (see FRICTION.md).


## Purpose / Big Picture

Add `mori-corpus-repo`, a recipe that extends `github-repo` using Seihou 0.14's single-base recipe inheritance. Given an upstream GitHub repository, a corpus project name, and a parent directory, it creates a separate wrapper repository named `<corpus-project-name>-project`, initializes Git, creates and tracks a matching GitHub remote under the configured owner, and bootstraps the wrapper as a Mori corpus. A corpus is a repository that contains third-party source and Mori metadata for browsing and maintaining that source. The upstream repository is input to Mori; it is not the wrapper's `origin` remote.

For `https://github.com/orval-labs/orval`, project name `orval`, parent `/tmp/corpora`, and configured owner `example-user`, the result is `/tmp/corpora/orval-project` tracking `example-user/orval-project`. Bootstrap runs in that directory and uses the supplied upstream URL. The ordinary `github-repo` recipe retains its existing behavior.

This session creates the plan only. Implementation is blocked on the Mori contract described below. The user is implementing that dependency separately; this plan does not authorize changing Mori or creating a live GitHub repository during planning.


## Progress

- [ ] Milestone 1: Prove a supported Mori command bootstraps an initialized wrapper with an existing remote, supplied upstream and project name, and no terminal input.
- [ ] Milestone 2: Implement and verify the inherited recipe, derived wrapper name, and ordered GitHub creation followed by corpus bootstrap, while preserving ordinary `github-repo` behavior.
- [ ] Milestone 3: Publish consistent discovery metadata and documentation, and pass isolated recipe, failure/recovery, and real Mori integration acceptance checks.

Handoff (2026-11-01): No implementation milestones are complete. Mori's current guided command is interactive. Its pending repository-driven implementation also requires an empty target and derives identity from the upstream; those rules do not yet support this recipe's initialized target or an independently supplied corpus project name. Resolve Milestone 1 before implementing against guessed flags.


## Surprises & Discoveries

(None yet.)


## Decision Log

2026-11-01: Extend `github-repo` through `extends`, retain its `repo-dir` member, and append a small corpus-bootstrap module. This preserves the shared GitHub creation workflow and its context-aware owner, visibility, team and branch settings. Do not copy its module list or launch `github-repo` as an unrelated nested recipe.

2026-11-01: Add an optional `repo.nameSuffix` setting to `repo-dir`, defaulting to the empty string. The child recipe binds it to `-project` and constrains that value. `repo.name` is the user-supplied corpus project name in the child; the effective folder and GitHub name are `repo.name` plus the suffix. This computes the name at execution without assuming that literal recipe bindings interpolate other variables. Existing callers with no suffix keep the same folder and remote names.

2026-11-01: Require a supported unattended Mori path that accepts the repository already created by `github-repo`. Seihou captures command input/output, so the legacy interactive Claude session cannot be the recipe's execution path. Do not pipe canned conversational answers, access `/dev/tty`, or launch an interactive agent in the background. The first version selects all discovered packages through Mori's explicit unattended selection facility; package-subset configuration is outside this plan.

2026-11-01: Preserve the base recipe's initial commit and push. Mori may add its own bootstrap commits, but this recipe adds no final push. The requested remote remains attached after bootstrap, and bootstrap failures retain the wrapper for inspection and direct recovery.

2026-11-01: Retain the base workflow's explicit `git-init` installation prerequisite. The published install example selects both the new root recipe and `git-init`. Seihou's dependency descriptor has no acquisition-only or conditional member field, so repairing discovery of commands invoked by another module would require a broader module-execution change. That work is outside this recipe plan.


## Outcomes & Retrospective

(To be filled during and after implementation.)


## Context and Orientation

This repository publishes Dhall descriptors, which are typed configuration files consumed by Seihou. `seihou-registry.dhall` lists installable modules and recipes. `mori.dhall` separately exposes templates to Mori; `seihou registry sync-versions` does not update it. `README.md` is the human catalog. `okf-docs/` is generated using the Seihou OKF extension and must not be edited by hand.

`recipes/github-repo/recipe.dhall` currently contains only the `repo-dir` module. `modules/git/repo-dir/module.dhall` resolves parent directory, name and GitHub settings, rejects a nonempty target, creates the target, changes into it, and runs `seihou run git-init` with the resolved settings. That nested invocation is deliberate: its manifest, `.gitignore`, initial commit and remote belong inside the new wrapper. `modules/git/git-init/module.dhall` runs Git initialization and `gh repo create ... --source=. --remote=origin --push`. Parent invocation state is separately recorded by Seihou; the base README already documents this behavior. Commands can have external effects that Seihou does not roll back.

The installed runtime was verified as `seihou v0.14.0.0 (b371308)`. Its authoritative [release](https://github.com/shinzui/seihou/releases/tag/v0.14.0.0), published 2026-11-01, introduces one typed `extends` reference, inherited member overrides, and oldest-base-first composition. A recipe reference has `recipe`, optional `source`, and optional `versionRange`; member overrides have `module` and `vars` containing literal `name`/`value` pairs. A descriptor can declare prompts for its own inputs and explicitly override inherited prompts. Running a recipe does not fetch missing members; installing the root acquires its declared recipe/module closure. Keep the separate nested `git-init` runtime dependency discoverable: the current `repo-dir` declares it only in its command text.

Locate upstream code through `mori registry show shinzui/seihou --full` and `mori registry show shinzui/seihou-schema --full`. For `mori://shinzui/seihou`, relevant project-relative files are `seihou-cli/help/recipes.md`, `seihou-core/src/Seihou/Composition/Recipe.hs`, `seihou-core/src/Seihou/Effect/ProcessInterp.hs`, and `docs/adr/0024-recipes-extend-one-origin-aware-base.md` (artifact-level URIs for these files are pending). The process interpreter calls `readCreateProcessWithExitCode` with empty input; shell commands do not inherit an interactive terminal. Inheritance preserves the oldest member as primary and appends child members, so repository creation must finish before the corpus module's command starts. Use the schema pin emitted by the released author's scaffolding commands, verifying its upstream commit before adding a pin; the schema repository currently has no release tags. Do not adopt unrelated uncommitted schema additions.

The latest Mori release observed through GitHub was `v7.1.0.0`. Installed `mori agent bootstrap --help` exposes `--corpus`, `--name`, `--namespace`, and `--upstream OWNER`. That last flag is an owner, not a repository URL. Current corpus bootstrap directly starts an interactive Claude session. The separately maintained prerequisite is `mori://shinzui/mori/plans/310-bootstrap-corpus-repositories-unattended-with-package-selection`. It proposes `--repo`, `--path`, `--package`, `--all-packages`, and `--no-input`, while preserving guided mode without `--repo`. At plan creation it rejects nonempty destinations and explicit identity flags in repository-driven mode. Therefore its completion alone does not prove compatibility here: this wrapper already has `.git`, a commit, a remote and a Seihou manifest. Custom corpus names can also differ from the upstream basename. Mori must expose and document those supported behaviors before this plan proceeds. Mori URI resolution for that new plan failed against the current registry; retain the canonical URI and locate the file under the project root returned by `mori registry show shinzui/mori --full`.

ADR discovery scanned filenames and headings under local `docs/adr/`; none governs recipe inheritance or corpus bootstrap. No local ADR is relevant. The upstream single-base design described above is contextual evidence from `mori://shinzui/seihou` and its project-relative ADR path, not an invented registered ADR handle. At implementation completion, promote any proven repository-wide composition constraint into a local ADR following `agents/skills/exec-plan/ADR.md`.


## Plan of Work

### Milestone 1 — Establish the Mori integration contract


Read the current prerequisite plan, released CLI help and source through Mori discovery. Verify the release supporting repository input, explicit target, independently supplied corpus project name, and unattended package selection. Record its exact executable version and command here. If there is no released compatibility path, keep this milestone open and report the precise missing behavior; do not implement the dependency in this repository. Do not assume `--name` can be combined with the proposed `--repo`, or invent an existing-repository switch.

Using a disposable Git wrapper with an initial commit and a local bare `origin`, prove the supported command bootstraps that exact root without creating a nested `<name>-project` directory, replacing the remote, discarding the initial commit, or demanding an empty target. Use an isolated Mori registry and explicit no-input/all-package policy. Supply an upstream fixture whose repository basename differs from the requested corpus project name, so name transport is exercised. Confirm `mori validate` succeeds and registry/configuration identify the requested project and upstream. A captured subprocess with closed stdin must terminate successfully; a real terminal alone is insufficient. Record the command and concise evidence, then replace the pending invocation in this plan with the actual public syntax. This establishes the producer/consumer boundary before expanding recipe code.

### Milestone 2 — Compose the recipe and derive its target


Update `modules/git/repo-dir/module.dhall` so its shared `target` shell fragment validates the name and optional suffix and derives one effective folder/remote name. Use that same effective name for directory creation, nested `git.repoName`, and success output. Keep `repo.nameSuffix` optional with an empty default and no prompt; existing `github-repo` calls must behave identically. Reject invalid combined names before creating a directory or calling GitHub. Do not assume Seihou templates perform shell escaping: transport each user value safely, including parent paths containing spaces and apostrophes, and reject malformed name/URL values before any external creation.

Add `modules/mori/mori-corpus-bootstrap/module.dhall` containing the command that enters the same target and invokes the Milestone 1 Mori command. Declare the variables it consumes: `corpus.repo`, `repo.parentDir`, `repo.name`, and `repo.nameSuffix`. Normalize/validate an upstream URL as GitHub HTTPS `https://github.com/OWNER/REPO` with an optional `.git` suffix; reject credentials, unexpected hosts, query/fragment parts, extra path segments and invalid components. The child recipe declares required `corpus.repo` and `repo.name` inputs and prompts for the upstream and corpus project name. Keep GitHub owner selection separate from the upstream owner. Validate required binaries and the supported Mori capability before the inherited creation command makes a directory or remote; implement the prerequisite checks as `repo.requireMoriCorpus`, an optional boolean `repo-dir` guard defaulting to false and enabled by the child, since an appended module runs too late for this check. The guard checks availability/help, without launching agents, discovery or bootstrap.

Create `recipes/mori-corpus-repo/recipe.dhall` with `extends` referencing the local registry's `github-repo`, one appended `mori-corpus-bootstrap` member, and `moduleOverrides` on inherited `repo-dir` binding `repo.nameSuffix=-project` and enabling the prerequisite guard. Declare a child constraint requiring the suffix to remain exactly `-project`, since CLI values outrank literal bindings. Override the inherited `repo.name` question to say “Corpus project name?”; do not ask users for the derived wrapper name. The normal owner, parent, visibility and team prompts remain available. Required corpus inputs and their validation must resolve before any command executes. Do not add a second independent Git initializer.

Keep `git-init` as an explicitly documented install selection alongside the new root, matching the base recipe's nested-command prerequisite. Do not add it as an ordinary recipe member or module dependency: that would run its file generation and Git commands in the invocation directory. Verify the documented two-selection install acquires the inherited base and declared modules automatically, plus the separately selected nested initializer.

Add `scripts/test-mori-corpus-repo.py`, using real Seihou resolution/execution in a temporary HOME/cache and fake `gh`/`mori` executables. Keep real Git and optionally use a local bare remote to verify remote tracking. Prove the parent/base composition, one effective wrapper name, input transport, cwd and ordering. The fake Mori process must assert the Git repository, initial commit and `origin` exist before it is called. Validate two different corpus names and a project name different from the upstream basename. Ordinary `github-repo` coverage must prove its name, flags and GitHub settings remain unchanged. Milestone acceptance is a passing isolated script and a dry-run showing one inherited `repo-dir` followed by one corpus-bootstrap member.

### Milestone 3 — Complete discovery, documentation and acceptance


Add the helper module and recipe to `seihou-registry.dhall`, and expose both in `mori.dhall` with accurate names, paths, tags, versions and required variables. Bump changed existing artifact versions and keep registry/descriptor versions consistent. Expose existing `github-repo` to Mori too if needed to make the inheritance relationship discoverable. Update `README.md`, `recipes/github-repo/README.md`, `modules/git/repo-dir/README.md`, and new READMEs beside the recipe and helper. Document the Seihou 0.14 minimum, proven Mori version, credentials/prerequisites, derived naming, context-aware remote owner, upstream input, all-package policy, parent manifest behavior, failure recovery and absence of an extra final push. Update `git-init` documentation only if its acquisition/execution contract changes.

Run descriptor/registry checks and regenerate `okf-docs/` through its generator. Verify an isolated install selecting `mori-corpus-repo` and `git-init` acquires the inherited base, helper, `repo-dir`, and nested initializer. Use an immutable local Git fixture or isolated install environment so no user cache is overwritten. Run the real Mori proof from Milestone 1 through the composed recipe with fake GitHub creation and an isolated registry. This must prove actual Mori output, not just a recorded argument vector. A live GitHub smoke run is optional and requires a deliberately selected disposable owner/repository; it is not required during planning or automatic tests. Record concise acceptance evidence, triage implementation friction, and distill any durable architectural findings before marking the plan complete.


## Concrete Steps

Run discovery from the repository root. None of these commands creates a remote repository:

```bash
cd /Users/shinzui/Keikaku/bokuno/seihou-modules
mori registry list
mori registry search seihou
mori registry search mori
mori registry show shinzui/seihou --full
mori registry docs shinzui/seihou
mori registry show shinzui/seihou-schema --full
mori registry show shinzui/mori --full
mori registry docs shinzui/mori
gh api repos/shinzui/seihou/releases/latest --jq '{tag_name,html_url}'
gh api repos/shinzui/seihou-schema/tags --jq 'map({name,commit:.commit.sha})'
gh api repos/shinzui/mori/releases/latest --jq '{tag_name,html_url}'
seihou --version
mori agent bootstrap --help
```

At creation Seihou reports `v0.14.0.0`, its upstream release tag agrees, schema tags are empty, and the current Mori help lacks repository/path/no-input options. A newer version number alone does not clear the existing-target and custom-name requirements. Verify upstream tags and the authoritative Hackage package registry before selecting any new executable bound. Consult schema source through Mori and use the released CLI's authoring-generated pin rather than the mutable local schema checkout.

After Milestone 1 is accepted and its exact command is recorded, scaffold and implement from this repository root:

```bash
seihou new-module mori-corpus-bootstrap
seihou new-recipe mori-corpus-repo --module mori-corpus-bootstrap
```

Move the scaffolds to `modules/mori/mori-corpus-bootstrap/` and `recipes/mori-corpus-repo/`, respectively, then add inheritance/settings as described above. After implementation:

```bash
seihou validate-module modules/git/repo-dir
seihou validate-module modules/mori/mori-corpus-bootstrap
seihou validate-recipe recipes/github-repo </dev/null
seihou validate-recipe recipes/mori-corpus-repo </dev/null
python3 scripts/test-mori-corpus-repo.py
seihou registry sync-versions
seihou registry validate
seihou extension run okf -- docs --dir . --out okf-docs --force
git diff --check
```

All checks must exit zero. The isolated test prints successful cases and makes no GitHub API writes. It must include the documented installation and a dry-run. Update these commands if the real generated descriptor shape requires a different authoring path, preserving the same public acceptance.

After the artifacts are published, a user installs and runs them as follows. `example-user` stands for the wrapper owner; it is independent of `orval-labs`:

```bash
seihou install https://github.com/shinzui/seihou-modules.git --module mori-corpus-repo --module git-init
seihou config set git.githubOwner example-user --context personal
seihou run mori-corpus-repo --context personal --no-save-prompted \
  --var corpus.repo=https://github.com/orval-labs/orval \
  --var repo.name=orval \
  --var repo.parentDir=/tmp/corpora \
  --var git.githubVisibility=private
```

Expected result: `/tmp/corpora/orval-project` is initialized, `origin` tracks `example-user/orval-project`, and supported Mori corpus bootstrap completes there using `orval-labs/orval`. Calling without the three main inputs prompts for them; `orval-project` is derived. These are proposed public recipe commands, not commands to run against production during plan creation.


## Validation and Acceptance

`python3 scripts/test-mori-corpus-repo.py` must exercise installed recipe inheritance through real Seihou. Confirm that `orval` yields exactly `orval-project`, that the new remote belongs to the selected GitHub context owner, and that bootstrap receives the upstream URL and corpus name separately. Assert execution order, noninteractive completion, correct working directory, no extra wrapper nesting and retained remote/initial history. Validate parent directories with spaces and apostrophes, `.git` URL suffix handling, and custom project names independent of upstream names.

Missing/unsupported Mori, malformed inputs and nonempty targets must fail before GitHub creation. GitHub failure must prevent bootstrap. Bootstrap failure must return nonzero, retain the created wrapper/remote and name its recovery path without reporting overall success. Rerunning against a nonempty target must not recreate GitHub or import the source again. Dry-run and `--no-commands` must not create directories, Git repositories, GitHub remotes or agent sessions. Test ordinary `github-repo` with suffix absent, visibility/team/context settings, and no enclosing-directory Git initialization introduced by dependency acquisition.

The real Mori integration proof uses an isolated registry and public corpus command on an initialized local wrapper with a local remote. Inspect `mori validate`, `mori show --full`, `git remote -v`, Git history and generated corpus metadata; confirm the supplied upstream and selected all-package policy. A fake executable's success is not sufficient for this criterion. Record exact released version and command after the pending Mori behavior exists. Compilation, descriptor validation and the upstream plan's completed checkboxes cannot substitute for this proof.


## Idempotence and Recovery

Descriptor validation and dry-run are repeatable and do not execute bootstrap. Tests use disposable HOME/config/cache paths, local Git remotes and a scratch Mori registry, never the developer's normal installed modules or registered projects. Preserve unrelated working-tree changes and stay on the current branch.

Repository creation is a one-shot operation. Preserve `repo-dir`'s refusal of nonempty destinations, including failed or completed wrappers. Do not delete, reset, force-push, replace `origin`, unregister projects or retry subtree import automatically. If GitHub creation fails, retain any local repository and identify it. If bootstrap fails after remote creation, report that the wrapper and remote already exist, print the failed phase and target path, and provide the exact supported direct Mori recovery command established in Milestone 1. Recovery must not rerun `github-repo`; use a new empty destination only after the operator deliberately chooses a new name, or inspect/recover the existing wrapper through supported Mori/Git commands.

Changes to recipe code do not make external effects transactional. Never claim a GitHub repository or registration was rolled back merely because Seihou reports a command failure. Success output from the corpus helper occurs only after Mori returns success and the integration contract's completion checks hold.


## Interfaces and Dependencies

The recipe's public inputs are `corpus.repo` (required upstream GitHub HTTPS URL), `repo.name` (required corpus project name), and inherited `repo.parentDir`. GitHub destination settings remain `git.githubOwner`, `git.githubVisibility`, `git.defaultBranch`, and optional team settings. The child enforces `repo.nameSuffix=-project` and binds `repo.requireMoriCorpus=true`. The latter defaults to false in `repo-dir` so ordinary GitHub initialization needs no Mori executable.

Seihou must be at least the verified inheritance release `0.14.0.0`; descriptors use its published `Recipe`, `RecipeReference` and `RecipeModuleOverride` shapes. Locate these at `mori://shinzui/seihou-schema/packages/seihou-schema`; do not guess interpolation or member-condition APIs. Runtime dependencies are Git, authenticated `gh`, Seihou for the nested initializer, and Mori's supported corpus-bootstrap implementation with its own runner/skill prerequisites. Reuse that public Mori command rather than embedding another corpus-writing agent prompt here.

The external prerequisite is `mori://shinzui/mori/plans/310-bootstrap-corpus-repositories-unattended-with-package-selection`, extended or otherwise satisfied by supported existing-wrapper and custom-project-name behavior. Its proposed flags are not yet a released contract for this plan. Do not fill that gap with invented flags or changes to another repository. All three implementation milestones remain pending until the first supported integration proof passes.

No intention is active: the user explicitly skipped intention association. Future implementation commits use Conventional Commits and include `ExecPlan: docs/plans/12-add-a-composed-mori-corpus-repo-recipe.md`. Record the first later substantive edit through `agents/skills/exec-plan/record-provenance.ts` with verified current-agent identity. Record implementation friction through `agents/skills/exec-plan/record-friction.ts`, then triage it at completion.
