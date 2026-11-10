// Measure a legacy documentation site against its documented project, and recommend
// whether to restart the content or refresh it.
//
//   node assess-content.mjs [--site <dir>] [--project mori://<ns>/<name>]
//     [--revision <rev>] [--since <date or site revision>] [--capabilities <file>]
//     [--private <regex>]... [--name <display name>] [--out <file.md>] [--json <file.json>]
//
// Run it from the site root, or pass --site. Nothing in the site is changed unless
// --out or --json names a file. The documented project is, in order: --project,
// DOCS_SOURCE_PROJECT, the "project" of docs-source.json, or the first dependencyRefs
// entry of the site's mori.dhall. Its checkout is DOCS_SOURCE_ROOT, or the last line of
// `mori path <project>`.
//
// The measures are the ones used to decide the first relaunch:
//   1. commits to the documented project since the docs were last written;
//   2. the share of cited source paths that no longer exist at the current revision,
//      and the share of pages citing at least one of them;
//   3. pages exposing private local paths or mori:// links;
//   4. the project's capabilities that no page mentions;
//   5. legacy structure outside Diátaxis (cookbook, FAQ, templates, demos).
// The recommendation is restart when most pages cite missing source, most pages expose
// private paths, or most capabilities are never mentioned. The decision stays with the
// operator: the report is evidence, not a verdict.
import { spawnSync } from "node:child_process"
import { existsSync, readFileSync, readdirSync, writeFileSync } from "node:fs"
import { homedir } from "node:os"
import { basename, join, relative, resolve } from "node:path"

const args = process.argv.slice(2)
const option = (name) => {
  const index = args.indexOf(name)
  return index === -1 ? undefined : args[index + 1]
}
const options = (name) => args.flatMap((arg, index) => (args[index - 1] === name ? [arg] : []))

function fail(message) {
  console.error(message)
  process.exit(2)
}

function run(command, commandArgs, cwd) {
  const result = spawnSync(command, commandArgs, {
    cwd,
    encoding: "utf8",
    maxBuffer: 256 * 1024 * 1024,
  })
  return result.status === 0 ? result.stdout.trim() : null
}

const git = (repository, ...gitArgs) => run("git", ["-C", repository, ...gitArgs])

const escapeRegExp = (text) => text.replace(/[.*+?^${}()|[\]\\]/g, "\\$&")

// ---------------------------------------------------------------------------
// The site and the documented project.

const site = resolve(option("--site") ?? process.cwd())
const docsRoot = join(site, "content/docs")
if (!existsSync(docsRoot))
  fail(`${docsRoot} does not exist. Run from the site root or pass --site.`)

function documentedProject() {
  const explicit = option("--project") ?? process.env.DOCS_SOURCE_PROJECT
  if (explicit) return explicit
  const pinFile = join(site, "docs-source.json")
  if (existsSync(pinFile)) {
    const { project } = JSON.parse(readFileSync(pinFile, "utf8"))
    if (project?.startsWith("mori://")) return project
  }
  const moriFile = join(site, "mori.dhall")
  if (!existsSync(moriFile)) return null
  const refs = readFileSync(moriFile, "utf8").match(/dependencyRefs\s*=\s*\[([\s\S]*?)\]/)?.[1]
  const first = refs?.match(/\{([^}]*)\}/)?.[1]
  const namespace = first?.match(/namespace\s*=\s*"([^"]+)"/)?.[1]
  const name = first?.match(/\bname\s*=\s*"([^"]+)"/)?.[1]
  return namespace && name ? `mori://${namespace}/${name}` : null
}

const project = documentedProject()
if (!project)
  fail("No documented project: add a typed dependencyRefs entry to mori.dhall, or pass --project.")

const sourceRoot =
  process.env.DOCS_SOURCE_ROOT ?? run("mori", ["path", project])?.split("\n").at(-1)
if (!sourceRoot || !existsSync(sourceRoot))
  fail(`Cannot find a checkout of ${project}. Register it with Mori or set DOCS_SOURCE_ROOT.`)

const revision = git(sourceRoot, "rev-parse", `${option("--revision") ?? "HEAD"}^{commit}`)
if (!revision) fail(`Cannot resolve the revision in ${project}.`)

// ---------------------------------------------------------------------------
// Pages.

function collect(directory, files = []) {
  for (const entry of readdirSync(directory, { withFileTypes: true })) {
    const path = join(directory, entry.name)
    if (entry.isDirectory()) collect(path, files)
    else if (/\.mdx?$/.test(entry.name)) files.push(path)
  }
  return files
}

const pages = collect(docsRoot)
  .toSorted()
  .map((file) => ({
    file,
    key: relative(docsRoot, file).replace(/\.mdx?$/, ""),
    source: readFileSync(file, "utf8"),
  }))
if (!pages.length) fail("content/docs has no pages.")

// ---------------------------------------------------------------------------
// Measure 1: commits since the docs were written.

const since = option("--since")
const contentLog =
  git(site, "log", "--format=%H %cI", "--", "content/docs")?.split("\n").filter(Boolean) ?? []
let writtenAt = null
let firstWrittenAt = null
if (since) {
  writtenAt = git(site, "log", "-1", "--format=%cI", since) ?? since
} else if (contentLog.length) {
  writtenAt = contentLog[0].split(" ")[1]
  firstWrittenAt = contentLog.at(-1).split(" ")[1]
}
const totalCommits = Number(git(sourceRoot, "rev-list", "--count", revision) ?? 0)
const commitsAfter = (date) =>
  date ? Number(git(sourceRoot, "rev-list", "--count", `--since=${date}`, revision) ?? 0) : null
const commitsSinceWritten = commitsAfter(writtenAt)
const commitsSinceFirst = commitsAfter(firstWrittenAt)
const baseline = writtenAt
  ? git(sourceRoot, "rev-list", "-1", `--before=${writtenAt}`, revision)
  : null

// ---------------------------------------------------------------------------
// Measure 2: cited source paths that no longer exist.

function treeAt(rev) {
  if (!rev) return new Set()
  const listing = git(sourceRoot, "ls-tree", "-r", "-t", "--name-only", rev) ?? ""
  return new Set(listing.split("\n").filter(Boolean))
}
const currentTree = treeAt(revision)
const baselineTree = treeAt(baseline)
const topLevel = new Set([...currentTree, ...baselineTree].filter((path) => !path.includes("/")))

const remote = git(sourceRoot, "remote", "get-url", "origin") ?? ""
const github = remote.match(/github\.com[:/]([^/]+)\/(.+?)(?:\.git)?\/?$/)
const githubPattern = github
  ? new RegExp(
      `github\\.com/${escapeRegExp(github[1])}/${escapeRegExp(github[2])}/(?:blob|tree)/[^/\\s]+/([^\\s)"'\`#?]+)`,
      "g",
    )
  : null
const sourceDirectory = basename(sourceRoot)

function clean(path) {
  return path
    .replace(/[#?].*$/, "")
    .replace(/:\d+(?::\d+)?$/, "")
    .replace(/[.,;:)\]}'"]+$/, "")
    .replace(/\/$/, "")
    .replace(/^\.\//, "")
}

function citedPaths(source) {
  const found = new Set()
  // Citation components: <SourceRef path="..." />, or any <...Source path="..." />.
  for (const match of source.matchAll(/<[A-Z]\w*\b[^>]*?\bpath="([^"]+)"/g))
    found.add(clean(match[1]))
  // Permalinks into the project's GitHub repository.
  if (githubPattern) for (const match of source.matchAll(githubPattern)) found.add(clean(match[1]))
  // Local absolute paths into a checkout of the project.
  for (const match of source.matchAll(/(?:\/Users|\/home)\/[^\s`'"()<>\]]+/g)) {
    const path = match[0]
    if (path.startsWith(`${sourceRoot}/`)) found.add(clean(path.slice(sourceRoot.length + 1)))
    else {
      const marker = `/${sourceDirectory}/`
      const index = path.indexOf(marker)
      if (index !== -1) found.add(clean(path.slice(index + marker.length)))
    }
  }
  // Relative paths in inline code whose first segment is a top-level entry of the source.
  for (const match of source.matchAll(/`([\w@.+-]+(?:\/[\w@.+-]+)+\/?)`/g)) {
    const path = clean(match[1])
    if (topLevel.has(path.split("/")[0])) found.add(path)
  }
  found.delete("")
  return found
}

const allCited = new Set()
const missing = new Set()
const pageMeasures = pages.map((page) => {
  const cited = citedPaths(page.source)
  const absent = [...cited].filter((path) => !currentTree.has(path))
  for (const path of cited) allCited.add(path)
  for (const path of absent) missing.add(path)
  return { ...page, cited: cited.size, missing: absent }
})
const citingPages = pageMeasures.filter((page) => page.cited > 0)
// Citations counted once per page that makes them, as well as once per distinct path.
const citations = pageMeasures.reduce((total, page) => total + page.cited, 0)
const missingCitations = pageMeasures.reduce((total, page) => total + page.missing.length, 0)
const pagesWithMissing = pageMeasures.filter((page) => page.missing.length > 0)

// ---------------------------------------------------------------------------
// Measure 3: private paths exposed.

const privateText = new RegExp(
  [
    "/Users/",
    "/home/[a-z]",
    "mori://",
    "file:///",
    ...[homedir(), sourceRoot, site].filter((path) => path.split("/").length > 3).map(escapeRegExp),
    ...options("--private"),
  ].join("|"),
)
for (const page of pageMeasures) page.private = privateText.test(page.source)
const privatePages = pageMeasures.filter((page) => page.private)

// ---------------------------------------------------------------------------
// Measure 4: capabilities no page mentions.

const stopWords = new Set(
  "a an and are as at be by for from in into is it its of on or that the this to with without your use using via how what".split(
    " ",
  ),
)
const normalize = (text) =>
  text
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, " ")
    .trim()
const stem = (word) => (word.length > 4 ? word.replace(/(ies|es|s)$/, "") : word)
const significant = (text) =>
  normalize(text)
    .split(" ")
    .filter((word) => word.length >= 4 && !stopWords.has(word))
    .map(stem)

function frontmatterField(text, field) {
  const block = text.match(/^---\n([\s\S]*?)\n---/)?.[1] ?? ""
  return block
    .match(new RegExp(`^${field}:\\s*(.*)$`, "m"))?.[1]
    ?.trim()
    .replace(/^["']|["']$/g, "")
}

function capabilities() {
  const listFile = option("--capabilities")
  if (listFile)
    return {
      from: listFile,
      items: readFileSync(listFile, "utf8")
        .split("\n")
        .map((line) => line.trim())
        .filter(Boolean)
        .map((title) => ({ title, slug: normalize(title).replaceAll(" ", "-") })),
    }
  const capabilityDir = "docs/capabilities"
  const capabilityFiles = [...currentTree].filter(
    (path) =>
      path.startsWith(`${capabilityDir}/`) &&
      path.endsWith(".md") &&
      !/\/(index|log|README)\.md$/i.test(path),
  )
  if (capabilityFiles.length)
    return {
      from: `${capabilityDir}/ at ${revision.slice(0, 12)}`,
      items: capabilityFiles.toSorted().map((path) => {
        const text = git(sourceRoot, "show", `${revision}:${path}`) ?? ""
        const title =
          frontmatterField(text, "title") ?? text.match(/^#\s+(.*)$/m)?.[1] ?? basename(path, ".md")
        return { title, slug: basename(path, ".md"), path }
      }),
    }
  // Fall back to the README: bullets under a "provides", "features" or "capabilities"
  // heading, else its second- and third-level headings.
  const readmePath = [...currentTree].find((path) => /^readme\.md$/i.test(path))
  const readme = readmePath ? (git(sourceRoot, "show", `${revision}:${readmePath}`) ?? "") : ""
  const generic =
    /^(getting started|installation|install|usage|license|licence|contributing|development|development and validation|repository map|requirements|quick ?start|build|building|testing|tests|changelog|status|faq|support|acknowledg.*|credits|table of contents|overview|introduction)$/i
  const lines = readme.split("\n")
  const items = []
  let inFeatures = false
  let fence = false
  for (const line of lines) {
    if (/^\s*```/.test(line)) fence = !fence
    if (fence) continue
    const heading = line.match(/^(#{2,3})\s+(.*?)\s*$/)
    if (heading) {
      inFeatures = /provides|features|capabilit/i.test(heading[2])
      continue
    }
    if (inFeatures) {
      const bullet = line.match(/^\s*[-*]\s+(?:\*\*([^*]+)\*\*|([^:—–.]+))/)
      if (bullet) items.push((bullet[1] ?? bullet[2]).trim())
    }
  }
  if (!items.length)
    for (const line of lines) {
      const heading = line.match(/^#{2,3}\s+(.*?)\s*$/)
      if (heading && !generic.test(normalize(heading[1]))) items.push(heading[1])
    }
  return {
    from: readmePath ? `${readmePath} at ${revision.slice(0, 12)}` : "nothing (no README)",
    items: [...new Set(items)].map((title) => ({
      title,
      slug: normalize(title).replaceAll(" ", "-"),
    })),
  }
}

const pageWords = pageMeasures.map((page) => ({
  text: ` ${normalize(page.source)} `,
  words: new Set(normalize(page.source).split(" ").map(stem)),
}))
function mentioned({ title, slug }) {
  const phrases = [normalize(title), normalize(slug)].filter(Boolean)
  const words = [...new Set([...significant(slug), ...significant(title)])]
  return pageWords.some(
    (page) =>
      phrases.some((phrase) => page.text.includes(` ${phrase} `)) ||
      (significant(slug).length > 0 && significant(slug).every((word) => page.words.has(word))) ||
      (words.length > 0 && significant(title).every((word) => page.words.has(word))),
  )
}
const capabilityList = capabilities()
for (const capability of capabilityList.items) capability.mentioned = mentioned(capability)
const unmentioned = capabilityList.items.filter((capability) => !capability.mentioned)

// ---------------------------------------------------------------------------
// Measure 5: structure outside Diátaxis.

const formOfSegment = {
  tutorial: "tutorial",
  tutorials: "tutorial",
  "how-to": "how-to",
  "how-tos": "how-to",
  "how-to-guides": "how-to",
  guides: "how-to",
  reference: "reference",
  api: "reference",
  explanation: "explanation",
  explanations: "explanation",
  concepts: "explanation",
  walkthrough: "walkthrough",
  walkthroughs: "walkthrough",
}
const legacySegment =
  /^(cookbook|cookbooks|recipes?|faqs?|_templates|templates|demo|demos|diagram-demo|examples?|tips|misc|troubleshooting|blog|changelog)$/i
for (const page of pageMeasures) {
  const segments = page.key.split("/")
  const legacy = segments.find(
    (segment) => legacySegment.test(segment) || /(^|-)(faq|cookbook|demo)(-|$)/i.test(segment),
  )
  const form = segments.map((segment) => formOfSegment[segment]).find(Boolean)
  page.form = legacy
    ? null
    : (form ?? (page.key === "index" || page.key.endsWith("/index") ? "landing" : null))
  page.legacy = legacy ?? null
}
const legacyPages = pageMeasures.filter((page) => page.legacy)
const unclassified = pageMeasures.filter((page) => !page.legacy && !page.form)

// ---------------------------------------------------------------------------
// Recommendation.

const share = (part, whole) => (whole ? part / whole : 0)
const percent = (value) => `${(value * 100).toFixed(0)}%`
const criteria = [
  {
    name: "pages citing missing source",
    value: share(pagesWithMissing.length, pages.length),
    text: `${pagesWithMissing.length} of ${pages.length} pages cite at least one path missing at the current revision`,
  },
  {
    name: "pages exposing private paths",
    value: share(privatePages.length, pages.length),
    text: `${privatePages.length} of ${pages.length} pages expose a private local path or mori:// link`,
  },
  {
    name: "capabilities never mentioned",
    value: share(unmentioned.length, capabilityList.items.length),
    text: `${unmentioned.length} of ${capabilityList.items.length} capabilities are mentioned on no page`,
  },
]
const met = criteria.filter((criterion) => criterion.value > 0.5)
const signals = [
  commitsSinceWritten !== null && share(commitsSinceWritten, totalCommits) > 0.5
    ? `${commitsSinceWritten} of the project's ${totalCommits} commits are newer than the last content change, so most of the product postdates the pages`
    : null,
  share(missing.size, allCited.size) >= 0.25
    ? `${percent(share(missing.size, allCited.size))} of cited paths no longer exist`
    : null,
  share(legacyPages.length + unclassified.length, pages.length) > 0.25
    ? `${legacyPages.length + unclassified.length} of ${pages.length} pages have no Diátaxis form`
    : null,
].filter(Boolean)
const recommendation = met.length ? "restart" : "refresh"
const reasoning = met.length
  ? `Restart: ${met.map((criterion) => criterion.text).join("; ")}. Editing pages in this state to the writing rules costs more than writing them fresh from the pinned source. Keep the legacy pages in Git history under a tag, prove the platform upgrade on them first, and measure before deleting anything.`
  : `Refresh: no restart criterion holds (${criteria.map((criterion) => `${criterion.name} ${percent(criterion.value)}`).join(", ")}). Keep the accurate pages, rewrite the ones listed below, and add pages for the capabilities no page mentions.`

// ---------------------------------------------------------------------------
// Proposed pages and diagrams. These are seeds from the measures; the agent refines
// them with the technical-docs skill before the operator confirms them.

const has = (pattern) => [...currentTree].some((path) => pattern.test(path))
const pinName = existsSync(join(site, "docs-source.json"))
  ? JSON.parse(readFileSync(join(site, "docs-source.json"), "utf8")).name
  : undefined
const name =
  option("--name") ?? (pinName?.startsWith("<") ? undefined : pinName) ?? project.split("/").at(-1)
const slugOf = (title) => normalize(title).replaceAll(" ", "-")
const proposed = {
  landing: [],
  tutorial: [],
  "how-to": [],
  reference: [],
  explanation: [],
  walkthrough: [],
}
proposed.landing.push({ page: "index", title: `${name} documentation`, basis: "entry page" })
proposed.tutorial.push({
  page: "tutorials/first-run",
  title: `Install ${name} and complete a first run`,
  basis: "the README's getting-started path",
})
for (const capability of capabilityList.items) {
  const slug = slugOf(capability.slug ?? capability.title)
  proposed["how-to"].push({
    page: `how-to/${slug}`,
    title: capability.title,
    basis: capability.path ?? "capability",
    covered: capability.mentioned,
  })
  proposed.explanation.push({
    page: `explanation/${slug}`,
    title: `How ${capability.title.replace(/^./, (c) => c.toLowerCase())} works`,
    basis: capability.path ?? "capability",
    covered: capability.mentioned,
  })
}
if (has(/(^|\/)(openapi[^/]*|[^/]*-openapi)\.(json|ya?ml)$/i))
  proposed.reference.push({
    page: "api/index",
    title: "HTTP API operations",
    basis: "OpenAPI documents in the source; generate with generate-api-index.mjs",
  })
if (has(/(^|\/)app\/Main\.hs$|\.cabal$|(^|\/)cmd\/|(^|\/)src\/bin\/|(^|\/)cli\//i))
  proposed.reference.push({
    page: "reference/cli",
    title: "CLI reference",
    basis: "a command-line entry point; consider generating it from the parser",
  })
if (has(/(^|\/)(config|configuration|settings)[^/]*\.(json|dhall|ya?ml|toml|schema\.json)$/i))
  proposed.reference.push({
    page: "reference/configuration",
    title: "Configuration reference",
    basis: "configuration files; generate from the program's own schema output where it has one",
  })
if (has(/^docs\/(terminology|glossary)\//i))
  proposed.reference.push({
    page: "reference/glossary",
    title: "Glossary",
    basis: "a terminology bundle; consider generating it",
  })
if (has(/^docs\/(adr|adrs|decisions)\//i))
  proposed.explanation.push({
    page: "explanation/design-decisions",
    title: "Design decisions",
    basis: "decision records in the source",
  })

const diagrams = [
  {
    file: "system-overview.svg",
    page: "index",
    shows: `The parts of ${name} and how a request or run moves through them`,
  },
  ...proposed.explanation
    .filter((entry) => entry.basis !== "decision records in the source")
    .map((entry) => ({
      file: `${entry.page.split("/").at(-1)}.svg`,
      page: entry.page,
      shows: `The structure or sequence behind ${entry.title.replace(/^How /, "").replace(/ works$/, "")}`,
    })),
]

// ---------------------------------------------------------------------------
// Report.

const result = {
  project,
  revision,
  site: basename(site),
  measuredAt: new Date().toISOString(),
  measures: {
    pages: pages.length,
    contentLastWritten: writtenAt,
    contentFirstWritten: firstWrittenAt,
    projectCommitsTotal: totalCommits,
    projectCommitsSinceLastWritten: commitsSinceWritten,
    projectCommitsSinceFirstWritten: commitsSinceFirst,
    citedPaths: allCited.size,
    missingCitedPaths: missing.size,
    missingCitedPathShare: share(missing.size, allCited.size),
    citations,
    missingCitations,
    pagesCiting: citingPages.length,
    pagesCitingMissing: pagesWithMissing.length,
    pagesExposingPrivatePaths: privatePages.length,
    capabilities: capabilityList.items.length,
    capabilitiesFrom: capabilityList.from,
    capabilitiesUnmentioned: unmentioned.length,
    pagesOutsideDiataxis: legacyPages.length,
    pagesWithoutForm: unclassified.length,
  },
  recommendation,
  reasoning,
  signals,
  missingPaths: [...missing].toSorted(),
  unmentionedCapabilities: unmentioned.map((capability) => capability.title),
  pageInventory: pageMeasures.map(
    ({ key, cited, missing: absent, private: exposed, form, legacy }) => ({
      key,
      form,
      legacy,
      cited,
      missing: absent.length,
      private: exposed,
    }),
  ),
  proposedPages: proposed,
  proposedDiagrams: diagrams,
}

const md = []
const line = (text = "") => md.push(text)
const m = result.measures
line(`# Content assessment`)
line()
line(
  `Site \`${result.site}\`, documenting ${project} at revision \`${revision}\`. Measured ${result.measuredAt.slice(0, 10)} by the relaunch-fumadocs-docs blueprint's assess-content.mjs.`,
)
line()
line(`## Measures`)
line()
line(`| Measure | Value |`)
line(`| --- | --- |`)
line(`| Pages under content/docs | ${m.pages} |`)
line(`| Content last changed | ${m.contentLastWritten ?? "unknown"} |`)
line(
  `| Project commits since the content last changed | ${m.projectCommitsSinceLastWritten ?? "unknown"} of ${m.projectCommitsTotal} |`,
)
line(
  `| Project commits since the content was first written | ${m.projectCommitsSinceFirstWritten ?? "unknown"} of ${m.projectCommitsTotal} |`,
)
line(
  `| Cited source paths missing at the current revision | ${m.missingCitedPaths} of ${m.citedPaths} (${percent(m.missingCitedPathShare)}) |`,
)
line(
  `| Citations (distinct paths per page) missing at the current revision | ${m.missingCitations} of ${m.citations} (${percent(share(m.missingCitations, m.citations))}) |`,
)
line(
  `| Pages citing at least one missing path | ${m.pagesCitingMissing} of ${m.pages} (${m.pagesCiting} pages cite source at all) |`,
)
line(
  `| Pages exposing private local paths or mori:// links | ${m.pagesExposingPrivatePaths} of ${m.pages} |`,
)
line(
  `| Capabilities no page mentions | ${m.capabilitiesUnmentioned} of ${m.capabilities}, from ${m.capabilitiesFrom} |`,
)
line(`| Pages in legacy structure outside Diátaxis | ${m.pagesOutsideDiataxis} |`)
line(`| Other pages with no Diátaxis form | ${m.pagesWithoutForm} |`)
line()
line(`## Recommendation: ${recommendation}`)
line()
line(reasoning)
if (signals.length) {
  line()
  line(`Further signals: ${signals.join("; ")}.`)
}
line()
line(
  `The capability check is a word match and can miss a capability a page describes in other words. Confirm the list below by reading it against the pages before relying on it.`,
)
line()
line(`## Capabilities no page mentions`)
line()
for (const capability of unmentioned) line(`- ${capability.title}`)
if (!unmentioned.length) line(`None.`)
line()
line(`## Missing cited paths`)
line()
for (const path of result.missingPaths.slice(0, 200)) line(`- \`${path}\``)
if (result.missingPaths.length > 200)
  line(`- and ${result.missingPaths.length - 200} more (see the JSON report)`)
if (!result.missingPaths.length) line(`None.`)
line()
line(`## Page inventory`)
line()
line(`| Page | Form | Legacy structure | Cited | Missing | Private |`)
line(`| --- | --- | --- | --- | --- | --- |`)
for (const page of result.pageInventory)
  line(
    `| ${page.key} | ${page.form ?? "none"} | ${page.legacy ?? ""} | ${page.cited} | ${page.missing} | ${page.private ? "yes" : ""} |`,
  )
line()
line(`## Proposed pages`)
line()
line(
  `Seeded from the measures. Each entry still needs one named reader, and the list needs the operator's confirmation before any page is written.`,
)
for (const [form, entries] of Object.entries(proposed)) {
  line()
  line(`### ${form}`)
  line()
  for (const entry of entries)
    line(
      `- \`${entry.page}\`: ${entry.title} (${entry.basis}${entry.covered === false ? "; no page covers it today" : ""})`,
    )
  if (!entries.length) line(`None proposed.`)
}
line()
line(`## Proposed diagrams`)
line()
line(`| File under content/diagrams | Page | Shows |`)
line(`| --- | --- | --- |`)
for (const diagram of diagrams) line(`| ${diagram.file} | ${diagram.page} | ${diagram.shows} |`)
line()

const markdown = md.join("\n")
const out = option("--out")
const jsonOut = option("--json")
if (out) writeFileSync(resolve(out), markdown)
if (jsonOut) writeFileSync(resolve(jsonOut), `${JSON.stringify(result, null, 2)}\n`)
if (!out) console.log(markdown)
else console.log(`wrote ${out}: recommendation ${recommendation}`)
