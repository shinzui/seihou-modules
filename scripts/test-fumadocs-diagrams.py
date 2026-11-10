#!/usr/bin/env python3
"""Render Fumadocs with SVG diagrams and a directory of OpenAPI documents.

Checks the docs.svg-diagrams option end to end (component, styles, gate and a real
page), that docs.openapi-spec may name a directory of several documents, that the
link check crawls real pages, and that a diagram color literal fails the gate.

Requires Seihou, Nix, and network access. Uses a temporary project and permits
fresh npm releases only for that test install; no global Bun settings change.
"""
import json
from pathlib import Path
import re
import shutil
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[1]
MODULE = ROOT / 'modules/typescript/fumadocs'

SVG = '''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 320 80">
  <rect class="node accent" x="10" y="20" width="120" height="40" rx="6"/>
  <text x="70" y="45" text-anchor="middle">Request</text>
  <path class="edge" d="M130 40 H186" marker-end="url(#arrow)"/>
  <rect class="node" x="190" y="20" width="120" height="40" rx="6"/>
  <text x="250" y="45" text-anchor="middle">Response</text>
</svg>
'''

PAGE = '''---
title: Request flow
description: One request and its response.
---

A request produces one response.

<Diagram src="overview/request-flow" alt="A request box with an arrow to a response box." />
'''

SECOND_DOCUMENT = {
    'openapi': '3.1.0',
    'info': {'title': 'Status API', 'version': '1.0.0'},
    'paths': {'/status': {'get': {'operationId': 'getStatus', 'summary': 'Read the status',
                                  'responses': {'200': {'description': 'The status'}}}}},
}


def run(args, cwd, succeeds=True):
    result = subprocess.run(args, cwd=cwd, text=True, capture_output=True)
    if (result.returncode == 0) != succeeds:
        raise AssertionError(f'{args}: exit {result.returncode}\n{result.stdout}\n{result.stderr}')
    return result.stdout + result.stderr


with tempfile.TemporaryDirectory(prefix='fumadocs-diagrams-') as temp:
    project = Path(temp)
    for name in ['fumadocs', 'nix-bun-flake']:
        shutil.copytree(ROOT / 'modules/typescript' / name, project / '.seihou/modules' / name)
    (project / 'openapi').mkdir()
    shutil.copy(MODULE / 'files/content/openapi.yaml', project / 'openapi/notes.yaml')
    (project / 'openapi/status.json').write_text(json.dumps(SECOND_DOCUMENT, indent=2))
    command = ['seihou', 'run', 'fumadocs', '--no-save-prompted', '--no-commands']
    for key, value in {
        'project.name': 'acme-docs', 'project.description': 'Acme documentation',
        'docs.site-name': 'Acme Docs', 'docs.github-user': 'acme',
        'docs.svg-diagrams': 'true', 'docs.openapi': 'true', 'docs.openapi-spec': 'openapi',
    }.items():
        command += ['--var', f'{key}={value}']
    run(command, project)

    assert 'Diagram,' in (project / 'src/components/mdx.tsx').read_text(), 'Diagram is not registered'
    assert '@import "./diagrams.css";' in (project / 'src/styles/app.css').read_text()
    assert (project / 'content/diagrams/README.md').is_file(), 'Authoring contract is missing'
    scripts = json.loads((project / 'package.json').read_text())['scripts']
    assert 'lint:diagrams' in scripts['check'], 'The check does not run the diagram gate'
    assert 'const FONTS_FLAKE = process.env.DOCS_FONT_FLAKE || ""' in (project / 'scripts/copy-fonts.mjs').read_text()

    (project / 'content/diagrams/overview').mkdir(parents=True)
    (project / 'content/diagrams/overview/request-flow.svg').write_text(SVG)
    (project / 'content/docs/request-flow.mdx').write_text(PAGE)
    meta_path = project / 'content/docs/meta.json'
    meta = json.loads(meta_path.read_text())
    meta['pages'].insert(1, 'request-flow')
    meta_path.write_text(json.dumps(meta, indent=2) + '\n')

    output = run(['nix', 'develop', '--command', 'bash', '-c',
                  'bun install --minimum-release-age 0 && oxfmt --write content/docs/meta.json openapi/status.json && just check && bun --bun run lint:links'], project)
    print(output[-1200:], flush=True)
    scanned = re.search(r'Successfully scanned (\d+) links', output)
    assert scanned and int(scanned.group(1)) > 1, 'The link check crawled no pages'

    public = project / '.output/public'
    assert 'Request flow' in (public / 'docs/request-flow/index.html').read_text()
    for operation, title in [('createNote', 'Create a note'), ('getStatus', 'Read the status')]:
        assert title in (public / f'docs/api/{operation}/index.html').read_text(), operation
    print('Diagram page, both OpenAPI documents and a real link crawl passed.', flush=True)

    svg = project / 'content/diagrams/overview/request-flow.svg'
    svg.write_text(SVG.replace('<rect class="node accent"', '<rect fill="#fff" class="node accent"'))
    failure = run(['nix', 'develop', '--command', 'bun', '--bun', 'run', 'lint:diagrams'], project,
                  succeeds=False)
    assert 'color literal' in failure, failure
    print('The diagram gate rejects a color literal.', flush=True)
    print('Fumadocs diagrams passed.', flush=True)
