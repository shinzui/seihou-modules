import { mkdtemp, mkdir, readFile, readdir, rename, rm, symlink, writeFile } from "node:fs/promises"
import { tmpdir } from "node:os"
import { dirname, join, resolve, relative } from "node:path"

import { localReferences, prepare } from "./schema.ts"

const schema = "openapi.json"
const mode = process.argv[2] ?? "generate"
if (!["generate", "check", "validate"].includes(mode))
  throw new Error("Expected generate, check, or validate")
const temporary = await mkdtemp(join(tmpdir(), "openapi-client-"))
function run(args: string[], env = process.env) {
  const result = Bun.spawnSync(args, { env, stdout: "inherit", stderr: "inherit" })
  if (result.exitCode !== 0) throw new Error(`${args.join(" ")} failed (${result.exitCode})`)
}
async function tree(root: string): Promise<Map<string, string>> {
  const result = new Map<string, string>()
  async function walk(dir: string) {
    for (const entry of await readdir(dir, { withFileTypes: true }).catch((e) => {
      if (e.code === "ENOENT") return []
      throw e
    })) {
      const path = join(dir, entry.name)
      if (entry.isDirectory()) await walk(path)
      else if (entry.isFile()) result.set(relative(root, path), await readFile(path, "utf8"))
      else throw new Error(`Unexpected generated entry: ${path}`)
    }
  }
  await walk(root)
  return result
}
try {
  await localReferences(resolve(schema))
  run(["bun", "run", "--no-install", "redocly", "lint", schema, "--config", "redocly.yaml"])
  const bundle = join(temporary, "bundle.json")
  run([
    "bun",
    "run",
    "--no-install",
    "redocly",
    "bundle",
    schema,
    "--config",
    "redocly.yaml",
    "--output",
    bundle,
  ])
  const prepared = prepare(JSON.parse(await readFile(bundle, "utf8")))
  if (mode === "validate") {
    await rm(temporary, { recursive: true, force: true })
    process.exit(0)
  }
  const input = join(temporary, "prepared.json")
  await writeFile(input, JSON.stringify(prepared.document, null, 2))
  const generated = resolve("src/generated")
  const raw = mode === "check" ? join(generated, "raw") : join(temporary, "generated/raw")
  const env = { ...process.env, OPENAPI_INPUT: input, OPENAPI_RAW: raw }
  run(
    [
      "bun",
      "run",
      "--no-install",
      "orval",
      "--config",
      "orval.config.ts",
      ...(mode === "check" ? ["--outdated"] : []),
    ],
    env,
  )
  let rawTree = await tree(raw)
  if (mode === "check") {
    const expected = join(temporary, "expected/raw")
    run(["bun", "run", "--no-install", "orval", "--config", "orval.config.ts"], {
      ...env,
      OPENAPI_RAW: expected,
    })
    const expectedTree = await tree(expected)
    const changed = [...new Set([...rawTree.keys(), ...expectedTree.keys()])].filter(
      (p) => rawTree.get(p) !== expectedTree.get(p),
    )
    if (changed.length) throw new Error(`Stale raw generated client: ${changed.join(", ")}`)
    rawTree = expectedTree
  }
  if (!rawTree.has("api.ts") || !rawTree.has("validators.ts"))
    throw new Error("Missing raw client output")
  const client = new Map<string, string>()
  for (const [path, contents] of rawTree) {
    let normalized = contents.replace(
      /(from\s+['"])(\.[^'"]+)(['"])/g,
      (_all, start, specifier, end) => {
        const resolved = join(dirname(path), specifier)
        const target =
          specifier.endsWith(".js") && rawTree.has(resolved.slice(0, -3) + ".ts")
            ? specifier
            : rawTree.has(`${resolved}.ts`)
              ? `${specifier}.js`
              : rawTree.has(`${resolved}/index.ts`)
                ? `${specifier}/index.js`
                : null
        if (!target) throw new Error(`Unqualified generated import ${path}: ${specifier}`)
        return `${start}${target}${end}`
      },
    )
    // Orval 8.46.0 ignores exactOptional for nullish properties. Preserve wire nullability.
    if (path === "validators.ts")
      normalized = normalized
        .replaceAll(".nullish()", ".nullable().exactOptional()")
        .replace(/: zod\.ZodType<([A-Za-z0-9]+)>/g, ": zod.ZodType<$1, $1>")
    // Empty responses have no JSON value. The transport rejects empty declared JSON first.
    if (path === "api.ts")
      normalized = normalized
        .replaceAll(
          "fetchFn: typeof globalThis.fetch",
          "fetchFn: (input: RequestInfo | URL, init?: RequestInit) => Promise<Response>",
        )
        .replaceAll("body ? JSON.parse(body) : {}", "body ? JSON.parse(body) : undefined")
        .replaceAll("body !== null ? body : ''", "undefined")
    client.set(path, normalized)
  }
  const references = prepared.registry.flatMap((op) =>
    Object.values(op.responses).filter((x): x is string => x !== null),
  )
  client.set(
    "registry.ts",
    `// Generated from the same qualified schema as the operations.\nimport { ${references.join(", ")} } from './validators.js'\nimport type { ResponseRegistry } from '../../transport.js'\nexport const registry = ${JSON.stringify(prepared.registry, null, 2).replace(/"([A-Z][A-Za-z0-9]*Response)"/g, "$1")} satisfies ResponseRegistry\n`,
  )
  const proofs = prepared.registry.flatMap((op) =>
    Object.entries(op.responses)
      .filter(([, ref]) => ref)
      .flatMap(([status, ref]) => {
        const model = `Extract<api.${op.name}Response, { status: ${status} }>['data']`
        return [
          `Assert<Equal<z.input<typeof validators.${ref}>, ${model}>>`,
          `Assert<Equal<z.output<typeof validators.${ref}>, ${model}>>`,
        ]
      }),
  )
  client.set(
    "contracts.ts",
    `// Compile-time proof in both assignability directions for every response.\nimport type * as api from './api.js'\nimport type * as validators from './validators.js'\nimport type * as z from 'zod'\ntype Equal<A, B> = 0 extends (1 & A) | (1 & B) ? false : [A] extends [B] ? [B] extends [A] ? true : false : false\ntype Assert<T extends true> = T\nexport type ResponseContracts = [${proofs.join(",\n")}]\n`,
  )
  const staged = join(temporary, "generated")
  await Promise.all(
    [...client].map(async ([path, contents]) => {
      await mkdir(dirname(join(staged, "client", path)), { recursive: true })
      await writeFile(join(staged, "client", path), contents)
    }),
  )
  await symlink(resolve("node_modules"), join(temporary, "node_modules"), "dir")
  await writeFile(join(temporary, "package.json"), '{"type":"module"}')
  await writeFile(join(temporary, "transport.ts"), await readFile("src/transport.ts", "utf8"))
  await writeFile(
    join(temporary, "tsconfig.json"),
    JSON.stringify({
      compilerOptions: {
        target: "ES2022",
        module: "NodeNext",
        moduleResolution: "NodeNext",
        lib: ["ES2022", "DOM", "DOM.Iterable"],
        types: [],
        strict: true,
        exactOptionalPropertyTypes: true,
        noUncheckedIndexedAccess: true,
        noEmit: true,
      },
      include: ["generated/client", "transport.ts"],
    }),
  )
  run(["bun", "scripts/compiler.ts", "-p", join(temporary, "tsconfig.json")])
  if (mode === "check") {
    const actual = await tree(join(generated, "client"))
    const unexpected = [...new Set([...client.keys(), ...actual.keys()])].filter(
      (path) => client.get(path) !== actual.get(path),
    )
    // Raw Orval detects changed/missing files; this also rejects obsolete raw files.
    const expectedRaw = new Set(
      [...client.keys()].filter((p) => !["registry.ts", "contracts.ts"].includes(p)),
    )
    for (const path of rawTree.keys()) if (!expectedRaw.has(path)) unexpected.push(`raw/${path}`)
    if (unexpected.length) throw new Error(`Stale generated client: ${unexpected.join(", ")}`)
    console.log("Generated client is current.")
  } else {
    // All validation/generation finishes before the previous tree is replaced.
    await mkdir(dirname(generated), { recursive: true })
    const backup = `${generated}.previous`
    await rm(backup, { recursive: true, force: true })
    const exists = await rename(generated, backup).then(
      () => true,
      (e) => {
        if (e.code === "ENOENT") return false
        throw e
      },
    )
    try {
      await rename(staged, generated)
    } catch (e) {
      if (exists) await rename(backup, generated)
      throw e
    }
    await rm(backup, { recursive: true, force: true })
  }
} finally {
  await rm(temporary, { recursive: true, force: true })
}
