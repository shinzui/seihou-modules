#!/usr/bin/env python3
"""Check safe existing-content adoption and both blueprint entry points."""
import json
from pathlib import Path
import shutil
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[1]


def run(args, cwd):
    result = subprocess.run(args, cwd=cwd, text=True, capture_output=True,
                            input='y\n' if args[1] == 'remove' else None)
    if result.returncode:
        raise AssertionError(f'{args}:\n{result.stdout}\n{result.stderr}')
    return result.stdout


run(['seihou', 'validate-blueprint', 'blueprints/upgrade-fumadocs'], ROOT)
with tempfile.TemporaryDirectory(prefix='fumadocs-adoption-') as temp:
    project = Path(temp)
    for name, source in {
        'fumadocs': 'modules/typescript/fumadocs',
        'nix-bun-flake': 'modules/typescript/nix-bun-flake',
        'upgrade-fumadocs': 'blueprints/upgrade-fumadocs',
    }.items():
        shutil.copytree(ROOT / source, project / '.seihou/modules' / name)
    content = project / 'content/docs/index.mdx'
    content.parent.mkdir(parents=True)
    original = b'---\ntitle: Existing documentation\n---\n\nPreserve this authored page.\n'
    content.write_bytes(original)
    command = ['seihou', 'run', 'fumadocs', '--no-save-prompted', '--no-commands',
               '--var', 'project.name=existing-docs', '--var', 'project.description=Existing docs',
               '--var', 'docs.site-name=Existing Docs', '--var', 'docs.github-user=acme',
               '--var', 'docs.font-flake=./fonts',
               '--var', 'docs.starter-content=false']
    run(command, project)
    run(command, project)
    canonical = (ROOT / 'modules/typescript/nix-bun-flake/files/flake.lock').read_bytes()
    assert (project / 'flake.lock').read_bytes() == canonical
    assert './nix/bun2nix-module.nix' not in (project / 'flake.nix').read_text()
    assert not (project / 'nix/bun2nix-module.nix').exists()
    assert not (project / 'nix/bun2nix-package.nix').exists()
    package = json.loads((project / 'package.json').read_text())
    assert 'bun2nix' not in package['dependencies']
    assert 'bun2nix' not in package['devDependencies']
    assert all('bun2nix' not in command for command in package['scripts'].values())
    # A consumer's package-manager choice is preserved through a real update of
    # the composed application, including the base module's shared owners.
    package['packageManager'] = 'bun@1.4.2'
    (project / 'package.json').write_text(json.dumps(package, indent=2) + '\n')
    run(['seihou', 'update', 'fumadocs', '--dry-run', '--no-commands'], project)
    run(['seihou', 'update', 'fumadocs', '--json', '--no-commands'], project)
    assert json.loads((project / 'package.json').read_text())['packageManager'] == 'bun@1.4.2'
    assert content.read_bytes() == original
    assert sorted(f.name for f in content.parent.iterdir()) == ['index.mdx']
    manifest_path = project / '.seihou/manifest.json'
    manifest = json.loads(manifest_path.read_text())
    assert not any(name.startswith('content/') for name in manifest['files'])
    for args in [['run', 'upgrade-fumadocs'],
                 ['migrate', 'upgrade-fumadocs', '--from', '0.1.2', '--to', '0.2.1'],
                 ['migrate', 'upgrade-fumadocs', '--from', '0.2.1', '--to', '0.3.0']]:
        before = json.loads(manifest_path.read_text())
        prompt = run(['seihou', 'agent', '--debug', *args], project)
        assert 'docs.starter-content=false' in prompt
        assert 'target-versions.json' in prompt
        after = json.loads(manifest_path.read_text())
        assert after['files'] == before['files'], 'Debug rendering changed file ownership'
        assert after['applications'] == before['applications'], 'Debug rendering changed module applications'
        if args[0] == 'migrate':
            assert after == before, 'Migration debug rendering changed the manifest'
    # The removal contract must retain documentation even after a fresh bootstrap.
    run(['seihou', 'remove', 'fumadocs', '--force'], project)
    assert content.read_bytes() == original
    run([a.replace('docs.starter-content=false', 'docs.starter-content=true') for a in command] + ['--force'], project)
    assert (content.parent / 'diagram-demo.mdx').is_file()
    content.write_bytes(original)
    run(['seihou', 'remove', 'fumadocs', '--force'], project)
    assert content.read_bytes() == original
    assert (content.parent / 'diagram-demo.mdx').is_file()
print('Fumadocs adoption: content preserved, unclaimed, repeatable; removal and blueprint prompts passed.')
