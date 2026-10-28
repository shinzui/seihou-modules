{
  "name": "{{project.name}}",
  "version": "0.1.0",
  "private": true,
  "description": "{{project.description}}",
  "type": "module",
  "scripts": {
    "dev": "vite dev",
    "build": "vite build",
    "start": "serve .output/public --config ../../serve.json",
    "preview": "vite preview",
    "typecheck": "bun --bun fumadocs-mdx && tsc --noEmit",
    "lint": "oxlint",
    "lint:fix": "oxlint --fix",
    "format": "oxfmt --write .",
    "format:check": "oxfmt --check .",
    "lint:links": "linkinator .output/public --config linkinator.config.json",
    "check": "bun run typecheck && bun run lint && bun run format:check && bun run build",
    "postinstall": "bun --bun fumadocs-mdx",
    "copy-fonts": "bun scripts/copy-fonts.mjs",
    "predev": "bun run copy-fonts",
    "prebuild": "bun run copy-fonts"
  },
  "dependencies": {
    "@tanstack/react-router": "1.170.46",
    "@tanstack/react-start": "1.169.4",
    "@tanstack/start-static-server-functions": "1.167.44",
    "@zombie-mermaid/svg-renderer": "^5.11.1",
    "elkjs": "^0.12.1",
    "fumadocs-core": "16.17.9",
    "fumadocs-mdx": "15.4.10",
{{#if Eq docs.openapi true}}
    "fumadocs-openapi": "12.5.6",
{{/if}}
    "fumadocs-ui": "16.17.9",
    "lucide-react": "^1.63.0",
    "react": "^19.3.1",
    "react-dom": "^19.3.1",
    "tailwind-merge": "^3.7.0"
  },
  "devDependencies": {
    "@tailwindcss/vite": "^4.3.3",
    "@types/bun": "1.4.2",
    "@types/hast": "^3.0.5",
    "@types/mdx": "2.0.14",
    "@types/node": "^26.6.6",
    "@types/react": "^19.3.0",
    "@types/react-dom": "^19.3.0",
    "@vitejs/plugin-react": "^6.1.2",
    "linkinator": "^8.1.0",
    "nitro": "3.0.260903-beta",
    "serve": "^14.2.6",
    "srvx": "^1.0.8",
    "tailwindcss": "^4.3.3",
    "vite": "^8.3.5"
  }
}
