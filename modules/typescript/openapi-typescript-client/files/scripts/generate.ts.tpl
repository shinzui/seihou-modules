const schema = "{{openapi.schema}}"
const mode = process.argv[2] ?? "generate"
if (!["generate", "check", "validate"].includes(mode))
  throw new Error("Expected generate, check, or validate")

const commands = [
  ["bun", "run", "--no-install", "redocly", "lint", schema, "--config", "redocly.yaml"],
  ...(mode === "validate"
    ? []
    : [
        [
          "bun",
          "run",
          "--no-install",
          "orval",
          "--config",
          "orval.config.ts",
          ...(mode === "check" ? ["--outdated"] : []),
        ],
      ]),
]
for (const command of commands) {
  const result = Bun.spawnSync(command, {
    env: { ...process.env, OPENAPI_INPUT: schema },
    stdout: "inherit",
    stderr: "inherit",
  })
  if (result.exitCode !== 0) process.exit(result.exitCode)
}
