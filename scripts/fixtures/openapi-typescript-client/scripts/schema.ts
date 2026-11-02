import { readFile, realpath } from "node:fs/promises"
import { dirname, resolve, relative, isAbsolute } from "node:path"

// This is a deliberately bounded OpenAPI adapter, not a general JSON Schema converter.
type ObjectValue = Record<string, any>
const keywords = new Set([
  "$ref",
  "title",
  "description",
  "type",
  "properties",
  "required",
  "additionalProperties",
  "items",
  "enum",
  "const",
  "nullable",
  "oneOf",
  "anyOf",
  "allOf",
  "discriminator",
  "readOnly",
  "writeOnly",
  "deprecated",
  "example",
  "examples",
  "minimum",
  "maximum",
  "exclusiveMinimum",
  "exclusiveMaximum",
  "minLength",
  "maxLength",
  "pattern",
  "minItems",
  "maxItems",
  "format",
])
export function fail(location: string, message: string): never {
  throw new Error(`${location}: ${message}`)
}

export async function localReferences(file: string, visited = new Set<string>()) {
  const path = await realpath(file)
  if (visited.has(path)) return
  visited.add(path)
  const value = Bun.YAML.parse(await readFile(path, "utf8"))
  const walk = async (node: any, pointer: string): Promise<void> => {
    if (!node || typeof node !== "object") return
    if (node.$ref) {
      const ref = String(node.$ref).split("#")[0]!.replace(/^\.\//, "")
      if (ref) {
        if (!/^(?:[A-Za-z0-9_-]+\/)*[A-Za-z0-9_.-]+\.(?:ya?ml|json)$/.test(ref)) {
          fail(
            `${path}${pointer}`,
            "only local YAML/JSON references without traversal are supported",
          )
        }
        const target = await realpath(resolve(dirname(path), ref))
        const rel = relative(process.cwd(), target)
        if (rel.startsWith("..") || isAbsolute(rel)) fail(pointer, "reference escapes the project")
        await localReferences(target, visited)
      }
    }
    for (const [key, child] of Object.entries(node)) await walk(child, `${pointer}/${key}`)
  }
  await walk(value, "#")
}

export function prepare(document: ObjectValue) {
  const source = structuredClone(document)
  delete source.servers
  const original = source.components?.schemas ?? {}
  // Bundling an external file can introduce a lower-case component plus a named alias.
  // Preserve the document's public PascalCase alias and retarget every reference.
  const renamed = new Map<string, string>()
  for (const [name, value] of Object.entries<ObjectValue>(original)) {
    const target = value.$ref?.match(/^#\/components\/schemas\/([a-z][A-Za-z0-9]*)$/)?.[1]
    if (/^[A-Z][A-Za-z0-9]*$/.test(name) && target && original[target]) {
      original[name] = original[target]
      renamed.set(target, name)
    }
  }
  for (const name of renamed.keys()) delete original[name]
  for (const name of Object.keys(original)) {
    if (/^[a-z][A-Za-z0-9]*$/.test(name)) {
      const target = name[0]!.toUpperCase() + name.slice(1)
      if (original[target]) fail("#/components/schemas", `component name collision: ${name}`)
      original[target] = original[name]
      delete original[name]
      renamed.set(name, target)
    }
  }
  function retarget(value: any) {
    if (!value || typeof value !== "object") return
    const target = value.$ref?.match(/^#\/components\/schemas\/([A-Za-z][A-Za-z0-9]*)$/)?.[1]
    if (renamed.has(target)) value.$ref = `#/components/schemas/${renamed.get(target)}`
    for (const child of Object.values(value)) retarget(child)
  }
  retarget(source)
  const components: ObjectValue = {}
  function schema(value: any, direction: "Input" | "Output", at: string): any {
    if (!value || typeof value !== "object" || Array.isArray(value))
      fail(at, "boolean/untyped schemas are unsupported")
    for (const key of Object.keys(value)) {
      if (!keywords.has(key)) fail(`${at}/${key}`, `unsupported schema keyword ${key}`)
    }
    if (Array.isArray(value.type) && (value.type.length !== 2 || !value.type.includes("null")))
      fail(at, "only nullable type arrays are supported")
    if (
      !value.$ref &&
      !value.type &&
      !value.oneOf &&
      !value.anyOf &&
      !value.allOf &&
      !value.properties
    )
      fail(at, "an explicit schema type or composition is required")
    if (
      value.enum &&
      Object.keys(value).some((key) =>
        ["minimum", "maximum", "minLength", "maxLength", "pattern", "format"].includes(key),
      )
    )
      fail(at, "constraints alongside enum are unsupported")
    if (value.allOf) {
      const seen = new Set<string>()
      for (const member of value.allOf) {
        const branch = member.$ref ? original[member.$ref.split("/").at(-1)] : member
        if (
          !branch ||
          branch.type !== "object" ||
          branch.additionalProperties === false ||
          (branch.additionalProperties && typeof branch.additionalProperties === "object") ||
          branch.allOf ||
          branch.oneOf ||
          branch.anyOf
        )
          fail(at, "allOf requires open object branches with disjoint properties")
        for (const name of Object.keys(branch.properties ?? {})) {
          if (seen.has(name)) fail(at, "allOf branches must have disjoint properties")
          seen.add(name)
        }
      }
    }
    const result: ObjectValue = { ...value }
    if (result.$ref) {
      const match = /^#\/components\/schemas\/([A-Za-z][A-Za-z0-9]*)$/.exec(result.$ref)
      if (!match || !original[match[1]!]) fail(at, "expected a bundled component schema reference")
      if (
        Object.keys(result).some(
          (k) => !["$ref", "description", "title", "readOnly", "writeOnly"].includes(k),
        )
      )
        fail(at, "validation siblings of $ref are unsupported")
      return { $ref: `${result.$ref}${direction}` }
    }
    if (result.format && !["date", "date-time", "uuid", "email", "uri"].includes(result.format))
      fail(`${at}/format`, "unsupported format")
    if (result.discriminator) delete result.discriminator // oneOf keeps exclusive validation, including tagged unions.
    if (result.properties || result.type === "object") {
      result.type = "object"
      result.additionalProperties ??= true
      const excluded: string[] = []
      result.properties = Object.fromEntries(
        Object.entries<ObjectValue>(result.properties ?? {}).flatMap(([name, child]) => {
          const resolved = child.$ref ? (original[child.$ref.split("/").at(-1)] ?? child) : child
          if (
            (direction === "Input" && (child.readOnly || resolved.readOnly)) ||
            (direction === "Output" && (child.writeOnly || resolved.writeOnly))
          ) {
            excluded.push(name)
            return []
          }
          return [[name, schema(child, direction, `${at}/properties/${name}`)]]
        }),
      )
      if ((result.required ?? []).some((name: string) => !(name in (value.properties ?? {}))))
        fail(at, "required must name a declared property")
      if (result.required)
        result.required = result.required.filter((name: string) => !excluded.includes(name))
      if (typeof result.additionalProperties === "object")
        result.additionalProperties = schema(
          result.additionalProperties,
          direction,
          `${at}/additionalProperties`,
        )
    }
    if (result.items) result.items = schema(result.items, direction, `${at}/items`)
    for (const key of ["oneOf", "anyOf", "allOf"]) {
      if (result[key])
        result[key] = result[key].map((entry: any, i: number) =>
          schema(entry, direction, `${at}/${key}/${i}`),
        )
    }
    delete result.readOnly
    delete result.writeOnly
    return result
  }
  for (const [name, value] of Object.entries(original)) {
    if (!/^[A-Z][A-Za-z0-9]*$/.test(name))
      fail(`#/components/schemas/${name}`, "use PascalCase component names")
    for (const direction of ["Input", "Output"] as const)
      components[`${name}${direction}`] = schema(value, direction, `#/components/schemas/${name}`)
  }
  source.components = { ...source.components, schemas: components }
  const registry: {
    name: string
    method: string
    path: string
    responses: Record<string, string | null>
  }[] = []
  const used = new Set<string>()
  for (const [path, item] of Object.entries<ObjectValue>(source.paths)) {
    if (!/^\/(?:[A-Za-z0-9_{}~.-]+\/?)*$/.test(path))
      fail(`#/paths/${path}`, "unsupported path syntax")
    for (const [method, operation] of Object.entries<ObjectValue>(item)) {
      if (method === "parameters") continue
      if (!["get", "post", "put", "patch", "delete", "head", "options"].includes(method))
        fail(path, `unsupported path item ${method}`)
      delete operation.servers
      const name = operation.operationId
      if (!/^[a-z][A-Za-z0-9]*$/.test(name) || used.has(name))
        fail(path, "unique camelCase operationId is required")
      used.add(name)
      if (operation.callbacks) fail(path, "callbacks are unsupported")
      delete item.servers
      const projectParameters = (parameters: any[]) =>
        parameters.map((parameter, i) => {
          if (parameter.$ref || parameter.content || parameter.in === "cookie")
            fail(`${path}/parameters/${i}`, "referenced/content/cookie parameters are unsupported")
          const shape = parameter.schema
          const scalar = (value: any) =>
            value && ["string", "number", "integer", "boolean"].includes(value.type)
          if (parameter.in === "path") {
            if (
              shape?.type !== "string" ||
              (parameter.style && parameter.style !== "simple") ||
              parameter.allowReserved
            )
              fail(`${path}/parameters/${i}`, "path parameters require simple encoded strings")
          } else if (parameter.in === "query") {
            if (shape?.type === "array") {
              if (
                !scalar(shape.items) ||
                (parameter.style ?? "form") !== "form" ||
                parameter.explode === false
              )
                fail(
                  `${path}/parameters/${i}`,
                  "query arrays require exploded form style and scalar items",
                )
            } else if (shape?.type === "object") {
              if (
                parameter.style !== "deepObject" ||
                parameter.explode === false ||
                shape.additionalProperties !== false ||
                !Object.values(shape.properties ?? {}).every(scalar)
              )
                fail(
                  `${path}/parameters/${i}`,
                  "query objects require closed flat scalar properties and exploded deepObject style",
                )
            } else if (!scalar(shape) || (parameter.style ?? "form") !== "form")
              fail(
                `${path}/parameters/${i}`,
                "query parameters require scalar form style, arrays, or deepObject",
              )
          } else
            fail(
              `${path}/parameters/${i}`,
              "declare path/query parameters; pass transport headers through make/options",
            )
          parameter.schema = schema(parameter.schema, "Input", `${path}/parameters/${i}/schema`)
          return parameter
        })
      operation.parameters = projectParameters([
        ...(item.parameters ?? []),
        ...(operation.parameters ?? []),
      ])
      if (operation.requestBody) {
        if (operation.requestBody.$ref) fail(path, "referenced request bodies are unsupported")
        const content = operation.requestBody.content
        if (Object.keys(content).join() !== "application/json")
          fail(path, "request bodies must use application/json")
        content["application/json"].schema = schema(
          content["application/json"].schema,
          "Input",
          `${path}/${method}/requestBody`,
        )
      }
      const responses: Record<string, string | null> = {}
      for (const [status, response] of Object.entries<ObjectValue>(operation.responses)) {
        if (!/^[1-5][0-9]{2}$/.test(status))
          fail(
            `${path}/${method}/responses/${status}`,
            "only explicit response statuses are supported",
          )
        if (response.$ref) fail(path, "referenced response objects are unsupported")
        const content = response.content
        if (!content || Object.keys(content).length === 0) responses[status] = null
        else {
          if (Object.keys(content).join() !== "application/json")
            fail(path, "responses must use application/json or no content")
          if (["204", "205", "304"].includes(status))
            fail(path, "this status cannot declare a body")
          content["application/json"].schema = schema(
            content["application/json"].schema,
            "Output",
            `${path}/${method}/responses/${status}/content/application~1json/schema`,
          )
          responses[status] = `${name[0]!.toUpperCase()}${name.slice(1)}${status}Response`
        }
      }
      registry.push({ name, method: method.toUpperCase(), path, responses })
    }
    delete item.parameters
  }
  for (const [index, operation] of registry.entries()) {
    const parts = operation.path.split("/")
    for (const other of registry.slice(index + 1)) {
      const otherParts = other.path.split("/")
      if (
        operation.method === other.method &&
        parts.length === otherParts.length &&
        parts.every(
          (part, i) =>
            part === otherParts[i] ||
            /^\{[^}]+\}$/.test(part) ||
            /^\{[^}]+\}$/.test(otherParts[i]!),
        )
      ) {
        fail(`#/paths/${operation.path}`, `ambiguous transport route overlaps ${other.path}`)
      }
    }
  }
  // Unused schema components are also qualified above, so no hidden constraint is dropped.
  return { document: source, registry }
}
