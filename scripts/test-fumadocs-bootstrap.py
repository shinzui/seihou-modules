#!/usr/bin/env python3
"""Render the composed Fumadocs scaffold and test its shared tools/static output.

Requires Seihou, Nix, and network access. Uses a temporary project and permits
fresh npm releases only for that test install; no global Bun settings change.
"""
import json
from pathlib import Path
import shutil
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[1]


def run(args, cwd):
    result = subprocess.run(args, cwd=cwd, text=True, capture_output=True)
    if result.returncode:
        raise AssertionError(f'{args}:\n{result.stdout}\n{result.stderr}')
    return result.stdout


with tempfile.TemporaryDirectory(prefix='fumadocs-bootstrap-') as temp:
    project = Path(temp)
    for name in ['fumadocs', 'nix-bun-flake']:
        shutil.copytree(ROOT / 'modules/typescript' / name, project / '.seihou/modules' / name)
    command = ['seihou', 'run', 'fumadocs', '--no-save-prompted', '--no-commands']
    for key, value in {
        'project.name': 'acme-docs', 'project.description': 'Acme documentation',
        'docs.site-name': 'Acme Docs', 'docs.github-user': 'acme',
        'docs.font-flake': '/tmp/fumadocs-bootstrap-missing-fonts',
    }.items():
        command += ['--var', f'{key}={value}']
    run(command, project)
    canonical = (ROOT / 'modules/typescript/nix-bun-flake/files/flake.lock').read_bytes()
    assert (project / 'flake.lock').read_bytes() == canonical
    run(['nix', 'flake', 'lock'], project)
    run(['nix', 'flake', 'update'], project)
    assert (project / 'flake.lock').read_bytes() == canonical, 'Fumadocs drifted from the shared lock'
    assert not (project / 'nix/pre-commit.nix').exists(), 'Default composition enabled hooks'
    manifest = json.loads((project / 'package.json').read_text())
    assert 'typescript' not in manifest['devDependencies'], 'Local compiler shadows the Nix toolchain'

    # The unmanaged extension survives repeated generation and composes with the shell.
    extension = (project / 'flake.module.nix.example').read_bytes()
    (project / 'flake.module.nix').write_bytes(extension)
    run(command, project)
    assert (project / 'flake.module.nix').read_bytes() == extension
    print('Rendered composition; verified shared lock and preserved extension.', flush=True)
    output = run(['nix', 'develop', '--command', 'bash', '-c',
        'jq --version && tsc --version && bun install --minimum-release-age 0 && just check'], project)
    print(output[-2500:], flush=True)

    public = project / '.output/public'
    for route, title in [('_shell.html', 'Acme Docs'), ('docs/index.html', 'Acme Docs'),
                         ('docs/diagram-demo/index.html', 'Diagram demo')]:
        assert title in (public / route).read_text(), f'Missing prerendered page: {route}'
    markdown = (public / 'docs/diagram-demo.md').read_text()
    assert 'sequenceDiagram' in markdown and 'flowchart TD' in markdown
    assert (public / 'docs/index.md').is_file()
    assert (public / '_shell.html').is_file()
    assert list((public / '__tsr/staticServerFnCache').rglob('*.json')), 'Static server-function data is missing'

    # Use the actual Fumadocs client against the exported static index. Also render
    # both diagram syntaxes through the same rehype/component pipeline as the site.
    probe = project / '.artifacts/probe.ts'
    probe.parent.mkdir()
    probe.write_text('''import { staticClient } from "fumadocs-core/search/client/orama-static"
import { rehypeMermaid } from "../src/lib/rehype-mermaid"
import { renderMermaidSVG } from "beautiful-mermaid"
import type { Root } from "hast"
const data = await Bun.file(".output/public/api/search").json()
globalThis.fetch = (async () => Response.json(data)) as typeof fetch
const results = await staticClient().search("diagram")
if (!results.some((r) => r.url.startsWith("/docs/diagram-demo"))) {
  throw new Error("Static search did not find the diagram page")
}
for (const chart of ["flowchart TD\\n A-->B", "sequenceDiagram\\n A->>B: hello"]) {
  const tree: Root = { type: "root", children: [{ type: "element", tagName: "pre", properties: {}, children: [
    { type: "element", tagName: "code", properties: { className: ["language-mermaid"] }, children: [{ type: "text", value: chart }] }
  ] }] }
  rehypeMermaid()(tree)
  const node = tree.children[0]
  if (node.type !== "element" || node.tagName !== "Mermaid") throw new Error("Mermaid fence was not converted")
  const svg = renderMermaidSVG(String(node.properties.chart))
  if (!svg.includes("<svg")) throw new Error("Mermaid SVG did not render")
}
console.log("Static search, raw Markdown, and both Mermaid diagram syntaxes passed.")
''')
    print(run(['nix', 'develop', '--command', 'bun', str(probe)], project), flush=True)
    run(['nix', 'flake', 'check'], project)
    print('Fumadocs bootstrap passed.', flush=True)
