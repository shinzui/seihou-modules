"""Shared real Seihou consumer helpers; all state stays under the fixture."""
import contextlib
import http.client
import json
import os
import re
from pathlib import Path
import shutil
import socket
import subprocess
import time

ROOT = Path(__file__).resolve().parents[1]
VARS = {'project.name': 'fixture-docs', 'project.description': 'Fixture documentation', 'docs.site-name': 'Fixture Handbook'}


def run(args, cwd, succeeds=True, env=None):
    result = subprocess.run(args, cwd=cwd, env=env, text=True, capture_output=True)
    if (result.returncode == 0) != succeeds:
        raise AssertionError(f'{args}: exit {result.returncode}\n{result.stdout}\n{result.stderr}')
    return result.stdout + result.stderr


def render(project, target='docs-microapp', variables=None):
    project.mkdir(parents=True, exist_ok=True)
    for name, source in [('docs-microapp', 'modules/typescript/docs-microapp'), ('nix-bun-flake', 'modules/typescript/nix-bun-flake')]:
        shutil.copytree(ROOT / source, project / '.seihou/modules' / name, dirs_exist_ok=True)
    if target == 'docs-microapp-labs':
        shutil.copytree(ROOT / 'modules/cloud/nagare-docs-config', project / '.seihou/modules/nagare-docs-config', dirs_exist_ok=True)
        shutil.copytree(ROOT / 'recipes/docs-microapp-labs', project / '.seihou/modules/docs-microapp-labs', dirs_exist_ok=True)
    args = ['seihou', 'run', target, '--no-save-prompted', '--no-commands']
    for key, value in {**VARS, **(variables or {})}.items():
        args += ['--var', f'{key}={value}']
    run(args, project)


def collection(project):
    config = json.loads((project / 'content.config.json').read_text())
    config['projectUri'] = 'mori://example/handbook'
    for name in ['guides', 'decisions']:
        directory = project / 'content' / name
        directory.mkdir(parents=True, exist_ok=True)
        (directory / 'one.md').write_text(f'---\ntitle: {name.title()} record\ndocId: DOC-1\n---\n# {name.title()} record\n\n## Details\n\n[Welcome](../docs/index.md#code-examples)\n\n![Diagram](../diagram.svg)\n')
        config['documents'].append(f'content/{name}/one.md')
        config['bundles'].append({'name': name, 'directory': f'content/{name}'})
    (project / 'content/diagram.svg').write_text('<svg xmlns="http://www.w3.org/2000/svg" width="20" height="20"><rect width="20" height="20" fill="green"/></svg>')
    (project / 'content/docs/space page.md').write_text('# Space page\n\n[Reference][home]\n\n[home]: index.md#code-examples\n')
    config['documents'].append('content/docs/space page.md')
    config['assets'] = ['content/diagram.svg']
    (project / 'content.config.json').write_text(json.dumps(config, indent=2) + '\n')
    (project / 'content/unpublished.md').write_text('# PRIVATE_UNPUBLISHED_DOCUMENT\n')


def free_port():
    with socket.socket() as sock:
        sock.bind(('127.0.0.1', 0))
        return sock.getsockname()[1]


def get(port, path):
    connection = http.client.HTTPConnection('127.0.0.1', port, timeout=10)
    connection.request('GET', path)
    response = connection.getresponse()
    return response.status, response.read()


@contextlib.contextmanager
def server(project, content=None, command=None):
    port = free_port()
    env = {**os.environ, 'PORT': str(port), 'DOCS_CONTENT_ROOT': str(content or project)}
    with (project.parent / 'server.log').open('w+') as log:
        process = subprocess.Popen(command or ['bun', str(project / 'apps/docs/server.ts')], cwd=project.parent, env=env, stdout=log, stderr=subprocess.STDOUT)
        try:
            for _ in range(120):
                if process.poll() is not None:
                    log.seek(0)
                    raise AssertionError(log.read())
                try:
                    if get(port, '/healthz')[0] == 200:
                        break
                except OSError:
                    pass
                time.sleep(.25)
            else:
                raise AssertionError('Production server did not start')
            yield port
        finally:
            process.terminate()
            process.wait(timeout=15)


def http_checks(port):
    status, data = get(port, '/docs/content/docs/index')
    assert status == 200 and b'<h1' in data and b'Welcome' in data and b'--hls-light' in data, (status, data[:1000])
    assert b'&lt;literal-markup&gt;' in data
    assets = set(re.findall(rb'(?:href|src)="(/assets/[^"]+)"', data))
    assert any(p.endswith(b'.css') for p in assets) and any(p.endswith(b'.js') for p in assets)
    for asset in assets:
        assert get(port, asset.decode())[0] == 200, asset
    for p in ['/fonts/geist-serif.woff2', '/fonts/paper-mono.woff2']:
        status, data = get(port, p)
        assert status == 200 and data[:4] == b'wOF2', p
    for p in ['/docs/missing', '/docs/content/unpublished', '/published/content/unpublished.md']:
        assert get(port, p)[0] == 404, p
    assert json.loads(get(port, '/healthz')[1])['status'] == 'ok'
