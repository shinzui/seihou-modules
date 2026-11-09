#!/usr/bin/env python3
"""Real Seihou, production HTTP/Chromium, explicit corpus and seed ownership acceptance."""
import argparse
import json
import os
from pathlib import Path
import shutil
import tempfile

from docs_microapp_test_support import ROOT, VARS, collection, get, http_checks, render, run, server

FIXTURE = ROOT / 'scripts/fixtures/docs-microapp'


def install(project):
    for name in ['bun.lock', 'bun-deps.nix']:
        shutil.copyfile(FIXTURE / name, project / name)
    run(['bun', 'install', '--frozen-lockfile', '--minimum-release-age', '0'], project)


def lifecycle(project):
    edited = {}
    for relative in ['apps/docs/src/routes/index.tsx', 'packages/ui/src/styles/globals.css',
                     'content.config.json', 'apps/docs/public/fonts/paper-mono.woff2.base64']:
        file = project / relative
        # Trailing whitespace preserves valid data while proving byte ownership.
        file.write_bytes(file.read_bytes() + b'\n')
        edited[relative] = file.read_bytes()
    removed = project / 'content/docs/index.md'
    removed.unlink()
    render(project)
    assert not removed.exists()
    assert all((project / f).read_bytes() == b for f, b in edited.items())
    module = project / '.seihou/modules/docs-microapp'
    managed = module / 'files/nix/docs-microapp.nix.tpl'
    managed.write_text(managed.read_text() + '# fixture update\n')
    run(['seihou', 'update', 'docs-microapp', '--no-commands', '--json', '--include-shared-owners'], project)
    assert (project / 'nix/docs-microapp.nix').read_text().endswith('# fixture update\n')
    assert not removed.exists()
    assert all((project / f).read_bytes() == b for f, b in edited.items())
    # A second composition with identical static bindings shares the same base instance.
    keeper = project / '.seihou/modules/fixture-keep-base'
    keeper.mkdir()
    descriptor = (ROOT / 'modules/typescript/docs-microapp/module.dhall').read_text()
    prefix = descriptor.split('in S.Module::')[0]
    dependency = descriptor.split('  , dependencies = ')[1].split('\n  , steps =')[0]
    (keeper / 'module.dhall').write_text(prefix + 'in S.Module::{ name = "fixture-keep-base", version = Some "0.1.0", dependencies = ' + dependency + ' }\n')
    args = ['seihou', 'run', 'fixture-keep-base', '--no-commands', '--no-save-prompted']
    for key, value in VARS.items():
        if key != 'docs.site-name':
            args += ['--var', f'{key}={value}']
    run(args, project)
    run(['seihou', 'remove', 'docs-microapp', '--force'], project)
    assert not (project / 'nix/docs-microapp.nix').exists()
    assert (project / 'flake.nix').exists() and not removed.exists()
    assert all((project / f).read_bytes() == b for f, b in edited.items())
    run(['git', 'add', '-A'], project)
    run(['nix', 'eval', '--raw', '.#devShells.aarch64-darwin.default.drvPath', '--no-write-lock-file'], project)
    print('Ownership: edited/deleted seeds survive rerun, update and removal; managed wiring updates/removes and base evaluates.', flush=True)


def acceptance(project):
    render(project)
    assert not (project / 'nagare').exists()
    install(project)
    # Route-tree generation precedes type checking.
    run(['bun', 'run', 'build'], project)
    run(['bun', 'run', 'check'], project)
    run(['bun', 'run', 'test'], project)
    run(['bun', 'x', 'playwright', 'install', 'chromium'], project)
    with server(project) as port:
        http_checks(port)
        run(['bun', 'run', 'test:e2e'], project, env={**os.environ, 'DOCS_TEST_URL': f'http://127.0.0.1:{port}'})
    print('Production: SSR, hydration, both loaded local fonts, themed tokens, exact copy, keyboard search and mobile navigation.', flush=True)
    collection(project)
    run(['bun', 'run', 'validate-content'], project)
    with server(project) as port:
        status, data = get(port, '/docs/content/guides/one')
        assert status == 200 and b'mori://example/handbook/okf/guides/concepts/DOC-1' in data
        assert b'/docs/content/docs/index#code-examples' in data
        assert get(port, '/docs/content/decisions/one')[0] == 200
        assert get(port, '/docs/content/docs/space%20page')[0] == 200
        assert get(port, '/published/content/diagram.svg')[0] == 200
        assert get(port, '/published/content/unpublished.md')[0] == 404
    run(['bun', 'scripts/content.ts', 'snapshot', str(project.parent / 'snapshot')], project)
    inventory = json.loads((project.parent / 'snapshot/content-inventory.json').read_text())
    assert {f['path'] for f in inventory['files']} == set(json.loads((project / 'content.config.json').read_text())['documents'] + ['content/diagram.svg'])
    # Source checkout and runtime package occupy separate directories; no installed dependencies in runtime.
    runtime = project.parent / 'runtime'
    target = runtime / 'apps/docs'
    target.mkdir(parents=True)
    for f in ['server.ts', 'site-name.txt']:
        shutil.copyfile(project / 'apps/docs' / f, target / f)
    shutil.copytree(project / 'apps/docs/dist', target / 'dist')
    source = project / 'content'
    source.rename(project / 'hidden-content')
    try:
        with server(runtime, content=project.parent / 'snapshot') as port:
            http_checks(port)
    finally:
        (project / 'hidden-content').rename(source)
    print('Publication: scoped bundle identities, anchored links, selected assets and isolated snapshot runtime.', flush=True)
    for file in project.rglob('*'):
        if file.is_file() and not any(part in {'.seihou', 'node_modules', 'dist', '.git'} for part in file.relative_to(project).parts):
            data = file.read_bytes()
            assert b'/Users/shinzui/' not in data and b'tan-platform' not in data and b'tan-product-management' not in data, file
    run(['git', 'init', '-q'], project)
    lifecycle(project)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--workdir', type=Path)
    args = parser.parse_args()
    if args.workdir:
        acceptance(args.workdir / 'consumer')
    else:
        with tempfile.TemporaryDirectory(prefix='docs-microapp-acceptance-') as directory:
            acceptance(Path(directory) / 'consumer')
    print('Docs microapp acceptance passed.', flush=True)


if __name__ == '__main__':
    main()
