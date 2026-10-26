#!/usr/bin/env python3
"""Refresh module-owned input revisions and fixed-output upstream tooling.

Run from any directory. Release the result with a module/registry version bump.
--check verifies committed files and reproducible locks without querying latest.
--write-lock regenerates only the canonical lock from committed revisions.
No arguments explicitly refresh upstream tool releases and pins.
"""
import argparse
import base64
import hashlib
import json
from pathlib import Path
import re
import shutil
import subprocess
import tempfile
import urllib.request

ROOT = Path(__file__).resolve().parents[1]
MODULE = ROOT / 'modules/typescript/nix-bun-flake'
FILES = MODULE / 'files'
BUN2NIX_VERSION = '2.1.2'
BUN2NIX_REV = '0f2a1f0b6f42cebe3b149bf62d38754c5e0e9729'


def get(url):
    return json.load(urllib.request.urlopen(url))


def run(args, cwd):
    result = subprocess.run(args, cwd=cwd, text=True, capture_output=True)
    if result.returncode:
        raise RuntimeError(f'{args}:\n{result.stdout}\n{result.stderr}')


def render(project, hooks, bun2nix="false"):
    installed = project / '.seihou/modules/nix-bun-flake'
    shutil.copytree(MODULE, installed)
    run(['seihou', 'run', 'nix-bun-flake', '--no-save-prompted', '--no-commands',
         '--var', 'project.name=toolchain-check', '--var', 'project.description=Toolchain check',
         '--var', f'nix.pre-commit={hooks}', '--var', f'nix.bun2nix={bun2nix}'], project)


def refresh():
    updates = {}
    template = (FILES / 'flake.nix.tpl').read_text()
    for repo, branch in [('NixOS/nixpkgs', 'nixpkgs-unstable'),
                         ('hercules-ci/flake-parts', 'main'), ('cachix/git-hooks.nix', 'master')]:
        rev = get(f'https://api.github.com/repos/{repo}/commits/{branch}')['sha']
        template = re.sub(r'github:' + re.escape(repo) + r'/[0-9a-f]{40}', f'github:{repo}/{rev}', template)
    version = get('https://registry.npmjs.org/bun2nix/latest')['version']
    release = get('https://api.github.com/repos/nix-community/bun2nix/releases/latest')
    assert release['tag_name'] == version, 'bun2nix npm/release disagreement'
    tag = get(f'https://api.github.com/repos/nix-community/bun2nix/git/ref/tags/{version}')['object']
    while tag['type'] == 'tag':
        tag = get(tag['url'])['object']
    assert tag['type'] == 'commit'
    # This source patch is deliberately release-qualified. Never auto-upgrade its gate.
    assert version == BUN2NIX_VERSION and tag['sha'] == BUN2NIX_REV, (
        'Qualify the new bun2nix source, patch and native fixtures before refreshing')
    template = re.sub(r'github:nix-community/bun2nix/[0-9a-f]{40}',
                      f"github:nix-community/bun2nix/{tag['sha']}", template)
    updates['flake.nix.tpl'] = template
    sources = json.loads((FILES / 'nix/tooling-sources.json').read_text())
    archives = {}

    def archive(name, version):
        key = f'{name}@{version}'
        if key in sources['archives']:
            archives[key] = sources['archives'][key]
        elif key not in archives:
            metadata = get(f'https://registry.npmjs.org/{name}/{version}')
            url = metadata['dist']['tarball']
            data = urllib.request.urlopen(url).read()
            archives[key] = {'name': name, 'url': url,
                             'hash': 'sha256-' + base64.b64encode(hashlib.sha256(data).digest()).decode()}
        return key

    specs = {}
    for name, old in sources['tools'].items():
        metadata = get(f'https://registry.npmjs.org/{name}/latest')
        version = metadata['version']
        repo = 'microsoft/TypeScript' if name == 'typescript' else 'oxc-project/oxc'
        tag = f'v{version}' if name == 'typescript' else f'{name}_v{version}'
        get(f'https://api.github.com/repos/{repo}/git/ref/tags/{tag}')
        common = [archive(name, version)]
        for dep, dep_version in (metadata.get('dependencies') or {}).items():
            if dep.startswith('@typescript/typescript-'):
                continue
            # Fail rather than silently introduce an incomplete dependency closure.
            dep_metadata = get(f'https://registry.npmjs.org/{dep}/{dep_version}')
            if dep_metadata.get('dependencies'):
                raise RuntimeError(f'{dep} now has transitive dependencies; update packaging first')
            common.append(archive(dep, dep_version))
        bindings = {}
        for system, key in old['bindings'].items():
            binding = sources['archives'][key]['name']
            bindings[system] = archive(binding, version)
        specs[name] = {'version': version, 'common': common, 'bindings': bindings}
    updates['nix/tooling-sources.json'] = json.dumps({'archives': archives, 'tools': specs}, indent=2) + '\n'
    bun = get('https://registry.npmjs.org/bun/latest')['version']
    assert get('https://api.github.com/repos/oven-sh/bun/releases/latest')['tag_name'] == f'bun-v{bun}'
    package = json.loads((FILES / 'package.json.tpl').read_text())
    package['devDependencies']['@types/bun'] = get('https://registry.npmjs.org/@types/bun/latest')['version']
    updates['package.json.tpl'] = json.dumps(package, indent=2) + '\n'
    for name, content in updates.items():
        (FILES / name).write_text(content)
    return bun


SYSTEMS = ['aarch64-darwin', 'aarch64-linux', 'x86_64-linux']


def verify_helper_pin():
    template = (FILES / 'flake.nix.tpl').read_text()
    assert f'github:nix-community/bun2nix/{BUN2NIX_REV}' in template
    assert get(f'https://registry.npmjs.org/bun2nix/{BUN2NIX_VERSION}')['version'] == BUN2NIX_VERSION
    tag = get(f'https://api.github.com/repos/nix-community/bun2nix/git/ref/tags/{BUN2NIX_VERSION}')['object']
    while tag['type'] == 'tag':
        tag = get(tag['url'])['object']
    assert tag['type'] == 'commit' and tag['sha'] == BUN2NIX_REV
    print('Verified qualified bun2nix pin against the exact npm release and upstream tag.', flush=True)


def verify_archives():
    """Check exact committed npm metadata and downloaded bytes; never query latest."""
    sources = json.loads((FILES / 'nix/tooling-sources.json').read_text())
    referenced = set()
    for name, spec in sources['tools'].items():
        assert set(spec['bindings']) == set(SYSTEMS), f'{name}: incomplete platform bindings'
        referenced.update(spec['common'])
        referenced.update(spec['bindings'].values())
    assert referenced == set(sources['archives']), 'Unreferenced or missing archive metadata'
    for key, archive in sources['archives'].items():
        name, version = key.rsplit('@', 1)
        assert name == archive['name']
        metadata = get(f'https://registry.npmjs.org/{name}/{version}')
        assert metadata['version'] == version
        assert metadata['dist']['tarball'] == archive['url']
        sha256, sha512 = hashlib.sha256(), hashlib.sha512()
        with urllib.request.urlopen(archive['url']) as response:
            while chunk := response.read(1024 * 1024):
                sha256.update(chunk)
                sha512.update(chunk)
        assert archive['hash'] == 'sha256-' + base64.b64encode(sha256.digest()).decode(), key
        assert metadata['dist']['integrity'] == 'sha512-' + base64.b64encode(sha512.digest()).decode(), key
    print('Verified exact committed tooling versions, registry metadata and archive hashes.', flush=True)


def verify_locks(write=False):
    with tempfile.TemporaryDirectory(prefix='nix-bun-lock-') as tmp:
        canonical = None
        for hooks in ['false', 'true']:
            for enabled in ['false', 'true']:
                project = Path(tmp) / f'{hooks}-{enabled}'
                project.mkdir()
                render(project, hooks, enabled)
                (project / 'flake.lock').unlink()
                run(['nix', 'flake', 'lock'], project)
                locked = (project / 'flake.lock').read_bytes()
                if canonical is None:
                    canonical = locked
                assert locked == canonical, 'Feature toggles changed the canonical lock'
                run(['nix', 'flake', 'update'], project)
                assert (project / 'flake.lock').read_bytes() == canonical, 'Full update moved module pins'
                for system in SYSTEMS:
                    run(['nix', 'eval', '--raw', f'.#devShells.{system}.default.drvPath'], project)
                extension = (project / 'flake.module.nix.example').read_bytes()
                (project / 'flake.module.nix').write_bytes(extension)
                for system in SYSTEMS:
                    run(['nix', 'eval', '--raw', f'.#devShells.{system}.default.drvPath'], project)
                assert (project / 'flake.module.nix').read_bytes() == extension
                print(f'Lock/evaluation: hooks={hooks}, bun2nix={enabled}, three systems passed.', flush=True)
        if write:
            (FILES / 'flake.lock').write_bytes(canonical)
        else:
            assert (FILES / 'flake.lock').read_bytes() == canonical, 'Shipped lock is stale; use --write-lock'
        return canonical


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    mode = parser.add_mutually_exclusive_group()
    mode.add_argument('--check', action='store_true', help='Verify immutable committed pins and archives')
    mode.add_argument('--write-lock', action='store_true', help='Regenerate only the lock from committed pins')
    args = parser.parse_args()
    before = {p: p.read_bytes() for p in MODULE.rglob('*') if p.is_file()}
    bun = None
    if not args.check and not args.write_lock:
        bun = refresh()
    if not args.write_lock:
        verify_helper_pin()
        verify_archives()
    canonical = verify_locks(write=not args.check)
    if bun is not None:
        nixpkgs = json.loads(canonical)['nodes']['nixpkgs']['locked']['rev']
        for name, expected in [('bun', bun), ('just', get('https://api.github.com/repos/casey/just/releases/latest')['tag_name'])]:
            result = subprocess.check_output(['nix', 'eval', '--raw',
                f'github:NixOS/nixpkgs/{nixpkgs}#legacyPackages.aarch64-darwin.{name}.version'], text=True)
            assert result == expected, f'nixpkgs has {name} {result}, upstream has {expected}'
    if args.check:
        assert before == {p: p.read_bytes() for p in MODULE.rglob('*') if p.is_file()}, '--check modified module files'
    elif args.write_lock:
        after = {p: p.read_bytes() for p in MODULE.rglob('*') if p.is_file()}
        assert set(before) == set(after)
        assert all(before[p] == after[p] for p in before if p != FILES / 'flake.lock'), '--write-lock modified other files'
    print('Verified four identical feature-toggle locks and immovable committed pins on all three systems.')


if __name__ == '__main__':
    main()
