// The documented project's source at the pinned revision.
//
//   bun scripts/prepare-source-pin.mjs
//       Create a detached worktree of the pinned revision under .cache/docs-source/ and
//       print its path.
//   bun scripts/prepare-source-pin.mjs --init [--project mori://<ns>/<name>]
//       [--revision <rev>] [--version <version>] [--name <display name>]
//       [--environment <system>]...
//       Write docs-source.json. The project defaults to the first dependencyRefs entry
//       in mori.dhall, the revision to the project's current HEAD, the version to its
//       latest tag, the GitHub URL to its origin remote, and the environment to this
//       machine's Nix system. Refuses to overwrite an existing file without --force.
//
// The checkout is found with `mori path <project>`, or DOCS_SOURCE_ROOT when set.
import { execFileSync, spawnSync } from "node:child_process"
import { existsSync, mkdirSync, readFileSync, writeFileSync } from "node:fs"
import { join, resolve } from "node:path"

const root = resolve(import.meta.dirname, "..")
const pinPath = join(root, "docs-source.json")

// The documented project named by the site's mori.dhall: its first dependencyRefs entry.
export function documentedProject(siteRoot = root) {
  const moriFile = join(siteRoot, "mori.dhall")
  if (!existsSync(moriFile)) return null
  const text = readFileSync(moriFile, "utf8")
  const refs = text.match(/dependencyRefs\s*=\s*\[([\s\S]*?)\]/)?.[1] ?? ""
  const first = refs.match(/\{([^}]*)\}/)?.[1]
  if (!first) return null
  const namespace = first.match(/namespace\s*=\s*"([^"]+)"/)?.[1]
  const name = first.match(/\bname\s*=\s*"([^"]+)"/)?.[1]
  return namespace && name ? `mori://${namespace}/${name}` : null
}

export function sourceRoot(project) {
  if (process.env.DOCS_SOURCE_ROOT) return process.env.DOCS_SOURCE_ROOT
  const target = project ?? JSON.parse(readFileSync(pinPath, "utf8")).project
  const result = spawnSync("mori", ["path", target], { encoding: "utf8" })
  const path = result.status === 0 ? result.stdout.trim().split("\n").at(-1) : ""
  if (!path) {
    console.error(
      `Cannot find a checkout of ${target}: ${result.stderr?.trim() || "is mori on PATH?"}`,
    )
    console.error("Register the project with Mori, or set DOCS_SOURCE_ROOT.")
    process.exit(2)
  }
  return path
}

function git(repository, ...args) {
  const result = spawnSync("git", ["-C", repository, ...args], { encoding: "utf8" })
  return result.status === 0 ? result.stdout.trim() : null
}

// git@github.com:owner/repo.git and https://github.com/owner/repo(.git) become
// https://github.com/owner/repo.
function githubUrl(remote) {
  const match = remote?.match(/github\.com[:/]([^/]+)\/(.+?)(?:\.git)?\/?$/)
  return match ? `https://github.com/${match[1]}/${match[2]}` : null
}

function nixSystem() {
  const arch = { arm64: "aarch64", x64: "x86_64" }[process.arch] ?? process.arch
  return `${arch}-${process.platform}`
}

function option(args, name) {
  const index = args.indexOf(name)
  return index === -1 ? undefined : args[index + 1]
}

function init(args) {
  if (existsSync(pinPath) && !args.includes("--force")) {
    console.error("docs-source.json exists. Pass --force to replace it.")
    process.exit(2)
  }
  const project =
    option(args, "--project") ?? process.env.DOCS_SOURCE_PROJECT ?? documentedProject()
  if (!project) {
    console.error(
      "No documented project: add a dependencyRefs entry to mori.dhall, or pass --project.",
    )
    process.exit(2)
  }
  const repository = sourceRoot(project)
  const revision = git(repository, "rev-parse", `${option(args, "--revision") ?? "HEAD"}^{commit}`)
  if (!revision) {
    console.error(`Cannot resolve the revision in ${project}.`)
    process.exit(2)
  }
  const version =
    option(args, "--version") ?? git(repository, "describe", "--tags", "--abbrev=0", revision)
  if (!version) {
    console.error(`${project} has no tag at or before ${revision}. Pass --version.`)
    process.exit(2)
  }
  const github =
    option(args, "--github") ?? githubUrl(git(repository, "remote", "get-url", "origin"))
  if (!github) {
    console.error(
      "The source has no GitHub origin remote. Pass --github https://github.com/<owner>/<repo>.",
    )
    process.exit(2)
  }
  const environments = args.flatMap((arg, index) =>
    args[index - 1] === "--environment" ? [arg] : [],
  )
  const name = option(args, "--name") ?? project.split("/").at(-1)
  const contents = {
    project,
    name,
    github,
    revision,
    version,
    environments: environments.length ? environments : [nixSystem()],
  }
  writeFileSync(pinPath, `${JSON.stringify(contents, null, 2)}\n`)
  console.log(`wrote docs-source.json: ${project} at ${revision}`)
}

if (import.meta.main) {
  const args = process.argv.slice(2)
  if (args.includes("--init")) {
    init(args)
  } else {
    const { revision } = JSON.parse(readFileSync(pinPath, "utf8"))
    const worktree = join(root, ".cache/docs-source", revision)
    if (!existsSync(worktree)) {
      mkdirSync(join(root, ".cache/docs-source"), { recursive: true })
      execFileSync("git", ["-C", sourceRoot(), "worktree", "add", "--detach", worktree, revision], {
        stdio: ["ignore", "ignore", "inherit"],
      })
    }
    console.log(worktree)
  }
}
