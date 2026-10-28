#!/usr/bin/env python3
"""Render Fumadocs with OpenAPI enabled and test its static API reference.

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


with tempfile.TemporaryDirectory(prefix='fumadocs-openapi-') as temp:
    project = Path(temp)
    for name in ['fumadocs', 'nix-bun-flake']:
        shutil.copytree(ROOT / 'modules/typescript' / name, project / '.seihou/modules' / name)
    command = ['seihou', 'run', 'fumadocs', '--no-save-prompted', '--no-commands']
    for key, value in {
        'project.name': 'acme-docs', 'project.description': 'Acme documentation',
        'docs.site-name': 'Acme Docs', 'docs.github-user': 'acme',
        'docs.font-flake': '/tmp/fumadocs-openapi-missing-fonts', 'docs.openapi': 'true',
    }.items():
        command += ['--var', f'{key}={value}']
    run(command, project)
    manifest = json.loads((project / 'package.json').read_text())
    assert 'fumadocs-openapi' in manifest['dependencies']
    assert (project / 'openapi.yaml').is_file(), 'Starter OpenAPI document is missing'
    meta = json.loads((project / 'content/docs/meta.json').read_text())
    assert meta['pages'][-1] == 'api', 'Generated pages are not in the sidebar'
    output = run(['nix', 'develop', '--command', 'bash', '-c',
        'bun install --minimum-release-age 0 && just check'], project)
    print(output[-1500:], flush=True)

    public = project / '.output/public'
    for operation, title, path in [('listNotes', 'List notes', 'GET /notes'),
                                   ('createNote', 'Create a note', 'POST /notes'),
                                   ('getNote', 'Get a note', 'GET /notes/{id}')]:
        assert title in (public / f'docs/api/{operation}/index.html').read_text(), operation
        markdown = (public / f'docs/api/{operation}.md').read_text()
        assert f'## {path}' in markdown, f'{operation}.md lacks its operation'
        assert '### components/schemas/Note' in markdown, f'{operation}.md lacks referenced schemas'
    # Note references NewNote through allOf; the Markdown follows references transitively.
    assert '### components/schemas/NewNote' in (public / 'docs/api/getNote.md').read_text()
    assert '/docs/api/listNotes' in (public / 'docs/index.html').read_text(), 'Sidebar lacks API pages'

    probe = project / '.artifacts/probe.ts'
    probe.parent.mkdir()
    probe.write_text('''import { staticClient } from "fumadocs-core/search/client/orama-static"
const data = await Bun.file(".output/public/api/search").json()
globalThis.fetch = (async () => Response.json(data)) as typeof fetch
const results = await staticClient().search("Create a note")
if (!results.some((r) => r.url.startsWith("/docs/api/createNote"))) {
  throw new Error("Static search did not find the OpenAPI operation")
}
console.log("Static search finds OpenAPI operations.")
''')
    print(run(['nix', 'develop', '--command', 'bun', str(probe)], project), flush=True)
    print('Fumadocs OpenAPI passed.', flush=True)
