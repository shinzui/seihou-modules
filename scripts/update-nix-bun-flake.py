#!/usr/bin/env python3
"""Refresh module-owned input revisions and fixed-output upstream tooling.

Run from any directory. Release the result with a module/registry version bump.
--check verifies current files and reproducible locks without changing the repo.
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


def get(url):
    return json.load(urllib.request.urlopen(url))


def run(args, cwd):
    subprocess.run(args, cwd=cwd, check=True)


def render(project, hooks):
    installed = project / '.seihou/modules/nix-bun-flake'
    shutil.copytree(MODULE, installed)
    run(['seihou', 'run', 'nix-bun-flake', '--no-save-prompted', '--no-commands',
         '--var', 'project.name=toolchain-check', '--var', 'project.description=Toolchain check',
         '--var', f'nix.pre-commit={hooks}'], project)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--check', action='store_true')
    args = parser.parse_args()
    updates = {}
    template = (FILES / 'flake.nix.tpl').read_text()
    for repo, branch in [('NixOS/nixpkgs', 'nixpkgs-unstable'),
                         ('hercules-ci/flake-parts', 'main'), ('cachix/git-hooks.nix', 'master')]:
        rev = get(f'https://api.github.com/repos/{repo}/commits/{branch}')['sha']
        template = re.sub(r'github:' + re.escape(repo) + r'/[0-9a-f]{40}', f'github:{repo}/{rev}', template)
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
    stale = [name for name, content in updates.items() if (FILES / name).read_text() != content]
    if args.check and stale:
        raise SystemExit('Upstream updates available: ' + ', '.join(stale))
    if not args.check:
        for name, content in updates.items():
            (FILES / name).write_text(content)

    with tempfile.TemporaryDirectory(prefix='nix-bun-lock-') as tmp:
        work = Path(tmp)
        canonical = None
        for hooks in ['true', 'false']:
            project = work / hooks
            project.mkdir()
            render(project, hooks)
            (project / 'flake.lock').unlink()  # Prove the seed is derivable from the pinned inputs.
            run(['nix', 'flake', 'lock'], project)
            locked = (project / 'flake.lock').read_bytes()
            if canonical is None:
                canonical = locked
            assert locked == canonical, 'Feature toggles changed the canonical lock'
            run(['nix', 'flake', 'update'], project)
            assert (project / 'flake.lock').read_bytes() == canonical, 'Full update moved module pins'
            for system in ['aarch64-darwin', 'aarch64-linux', 'x86_64-linux']:
                run(['nix', 'eval', '--raw', f'.#devShells.{system}.default.drvPath'], project)
            shutil.copyfile(project / 'flake.module.nix.example', project / 'flake.module.nix')
            run(['nix', 'eval', '--raw', '.#devShells.aarch64-darwin.default.drvPath'], project)
        if args.check:
            assert (FILES / 'flake.lock').read_bytes() == canonical, 'Shipped lock is stale'
        else:
            (FILES / 'flake.lock').write_bytes(canonical)
        # Ensure the channel actually supplies the latest runtime and task runner.
        nixpkgs = json.loads(canonical)['nodes']['nixpkgs']['locked']['rev']
        for name, expected in [('bun', bun), ('just', get('https://api.github.com/repos/casey/just/releases/latest')['tag_name'])]:
            result = subprocess.check_output(['nix', 'eval', '--raw',
                f'github:NixOS/nixpkgs/{nixpkgs}#legacyPackages.aarch64-darwin.{name}.version'], text=True)
            assert result == expected, f'nixpkgs has {name} {result}, upstream has {expected}'
    print('Verified current releases, identical feature-toggle locks, and immovable module pins.')


if __name__ == '__main__':
    main()
