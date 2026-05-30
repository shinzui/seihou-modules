{
  "name": "{{project.name}}",
  "version": "0.1.0",
  "description": "{{project.description}}",
  "type": "module",
  "module": "src/index.ts",
  "private": true,
  "scripts": {
    "typecheck": "tsc --noEmit",
    "lint": "oxlint",
    "lint:fix": "oxlint --fix",
    "format": "oxfmt --write .",
    "format:check": "oxfmt --check ."
  },
  "devDependencies": {
    "@types/bun": "latest"
  }
}
