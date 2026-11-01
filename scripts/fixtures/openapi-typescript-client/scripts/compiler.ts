import { delimiter, join, resolve } from 'node:path'

// Package runners prepend dependency executables to PATH. Ignore all of them.
const compiler = (process.env.PATH ?? '').split(delimiter)
  .filter((entry) => !resolve(entry).split('/').includes('node_modules'))
  .map((entry) => join(entry, 'tsc')).find((entry) => Bun.file(entry).size > 0)
if (!compiler) throw new Error('TypeScript 7+ tsc is required on the development shell PATH')
const version = Bun.spawnSync([compiler, '--version'], { stdout: 'pipe', stderr: 'pipe' })
const selected = version.stdout.toString().trim()
if (version.exitCode !== 0 || !/^Version (\d+)\./.test(selected) || Number(selected.match(/\d+/)?.[0]) < 7) {
  throw new Error(`TypeScript 7+ is required; selected ${compiler}: ${selected}`)
}
console.log(`Compiler: ${compiler} (${selected})`)
const result = Bun.spawnSync([compiler, ...process.argv.slice(2)], { stdout: 'inherit', stderr: 'inherit' })
process.exit(result.exitCode)
