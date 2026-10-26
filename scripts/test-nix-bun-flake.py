#!/usr/bin/env python3
"""Verify opt-in rendering/ownership/evaluation; --native adds sandbox builds.

Requires Seihou, Nix and access to pinned upstream sources. No global module
installation, local node_modules, real consumer migration or moving release pins.
"""
import argparse
import importlib.util
import json
from pathlib import Path
import shutil
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[1]
FIXTURES = ROOT / 'scripts/fixtures/nix-bun-flake'
spec = importlib.util.spec_from_file_location('bun_updater', ROOT / 'scripts/update-nix-bun-flake.py')
updater = importlib.util.module_from_spec(spec)
spec.loader.exec_module(updater)
FEATURE_FILES = ['nix/bun2nix-package.nix', 'nix/bun2nix-module.nix']


def run(args, cwd, input=None, succeeds=True):
    result = subprocess.run(args, cwd=cwd, input=input, text=True, capture_output=True)
    if (result.returncode == 0) != succeeds:
        raise AssertionError(f'{args}: exit {result.returncode}\n{result.stdout}\n{result.stderr}')
    return result


def nix(project, *args):
    return run(['nix', args[0], '--no-write-lock-file', *args[1:]], project).stdout.strip()


def evaluate_matrix(work):
    canonical = (updater.FILES / 'flake.lock').read_bytes()
    for hooks in ['false', 'true']:
        for enabled in ['false', 'true']:
            project = work / f'{hooks}-{enabled}'
            project.mkdir()
            updater.render(project, hooks, enabled)
            assert (project / 'flake.lock').read_bytes() == canonical
            for path in FEATURE_FILES:
                assert (project / path).exists() == (enabled == 'true')
            assert ('./nix/bun2nix-module.nix' in (project / 'flake.nix').read_text()) == (enabled == 'true')
            assert not (project / 'bun-deps.nix').exists()
            extension = (project / 'flake.module.nix.example').read_bytes()
            (project / 'flake.module.nix').write_bytes(extension)
            for system in updater.SYSTEMS:
                shell = f'.#devShells.{system}.default'
                nix(project, 'eval', '--raw', shell + '.drvPath')
                inputs = json.loads(nix(project, 'eval', '--json', shell + '.nativeBuildInputs',
                    '--apply', 'xs: map (p: p.drvPath) xs'))
                names = json.loads(nix(project, 'eval', '--json', f'.#packages.{system}',
                    '--apply', 'builtins.attrNames'))
                assert ('bun2nix' in names) == (enabled == 'true')
                assert 'default' not in names, 'Opt-in helper invented an application output'
                if enabled == 'true':
                    helper = f'.#packages.{system}.bun2nix'
                    assert nix(project, 'eval', '--raw', helper + '.drvPath') in inputs
                    nix(project, 'eval', '--raw', helper + '.hook.drvPath')
                    assert nix(project, 'eval', '--json', helper + '.fetchBunDeps',
                               '--apply', 'x: builtins.isFunction x || (builtins.isAttrs x && x ? __functor)') == 'true'
                else:
                    assert not any('bun2nix' in path for path in inputs)
            # Real regeneration preserves the copied unmanaged extension.
            run(['seihou', 'run', 'nix-bun-flake', '--no-save-prompted', '--no-commands',
                 '--var', 'project.name=toolchain-check', '--var', 'project.description=Toolchain check',
                 '--var', f'nix.pre-commit={hooks}', '--var', f'nix.bun2nix={enabled}'], project)
            assert (project / 'flake.module.nix').read_bytes() == extension
    print('Evaluation: four toggle combinations, three systems, same helper in shell/package, extension preserved.', flush=True)


def update(project, enabled, retain_orphan=False):
    args = ['seihou', 'update', 'nix-bun-flake', '--no-commands', '--var', f'nix.bun2nix={enabled}']
    if retain_orphan:
        # This fixture has exactly one edited orphan. Prove --force has no other
        # conflict to resolve before applying its retainTracked choice.
        args += ['--force']
    plan = json.loads(run(args + ['--dry-run', '--json'], project).stdout)
    if retain_orphan:
        resolutions = [(f['path'], f['classification'], f['resolution'])
                       for f in plan['files'] if f['resolution'] is not None]
        assert resolutions == [(FEATURE_FILES[0], 'editedOrphan', 'retainTracked')]
        assert not any(f['classification'] == 'conflict' for f in plan['files'])
    return run(args + ['--json'], project)


def ownership(work):
    project = work / 'ownership'
    project.mkdir()
    updater.render(project, 'false')  # Omitted/default option remains disabled.
    manifest_path = project / '.seihou/manifest.json'
    base_owners = set(json.loads(manifest_path.read_text())['files']['.gitignore']['applications'])
    # Establish a second owner by actual generation, never by editing receipts.
    coowner = project / '.seihou/modules/fixture-coowner'
    (coowner / 'files').mkdir(parents=True)
    schema = (updater.MODULE / 'module.dhall').read_text().split('in  S.Module::', 1)[0]
    (coowner / 'module.dhall').write_text(schema + '''in S.Module::{
      , name = "fixture-coowner"
      , version = Some "0.1.0"
      , steps = [ S.Step::{ strategy = "template", src = "ignore.tpl",
          dest = ".gitignore", patch = Some "append-line-if-absent" } ]
      }
''')
    (coowner / 'files/ignore.tpl').write_text('.fixture-artifacts\n')
    run(['seihou', 'run', 'fixture-coowner', '--no-save-prompted', '--no-commands'], project)
    shared_owners = json.loads(manifest_path.read_text())['files']['.gitignore']['applications']
    assert len(shared_owners) == 2
    foreign_owners = set(shared_owners) - base_owners
    assert len(foreign_owners) == 1
    authored = {
        'flake.module.nix': (project / 'flake.module.nix.example').read_bytes(),
        'bun.lock': b'authored lock\n', 'bun-deps.nix': b'authored expression\n',
        'index.ts': b'console.log("authored app")\n',
        'nix/bun2nix.nix': b'# existing custom wrapper\n',
    }
    for name, content in authored.items():
        (project / name).write_bytes(content)
    package = json.loads((project / 'package.json').read_text())
    generated_package = (project / 'package.json').read_bytes()
    package['scripts']['build'] = 'bun build index.ts'
    package['packageManager'] = 'bun@1.4.2'
    (project / 'package.json').write_text(json.dumps(package, indent=2) + '\n')
    original_package = (project / 'package.json').read_bytes()
    # A custom input survives the same real three-way update as application edits.
    flake = project / 'flake.nix'
    flake.write_text(flake.read_text().replace('  inputs = {',
        '  inputs = {\n    custom.follows = "nixpkgs";'))
    for enabled in ['true', 'false', 'true']:
        update(project, enabled)
        assert (project / 'package.json').read_bytes() == original_package
        assert json.loads(manifest_path.read_text())['files']['.gitignore']['applications'] == shared_owners
        assert not (project / 'nix/pre-commit.nix').exists(), 'Update lost saved hook preference'
        assert 'custom.follows' in flake.read_text()
        for name, content in authored.items():
            assert (project / name).read_bytes() == content, name
        for path in FEATURE_FILES:
            assert (project / path).exists() == (enabled == 'true')
    # Noninteractive Seihou requires --force even to preview an edited orphan.
    edited = project / FEATURE_FILES[0]
    edited.write_text(edited.read_text() + '\n# project annotation\n')
    original_edited = edited.read_bytes()
    update(project, 'false', retain_orphan=True)
    assert edited.read_bytes() == original_edited
    assert not (project / FEATURE_FILES[1]).exists()
    assert './nix/bun2nix-module.nix' not in flake.read_text()
    system = nix(project, 'eval', '--impure', '--raw', '--expr', 'builtins.currentSystem')
    assert 'bun2nix' not in json.loads(nix(project, 'eval', '--json', f'.#packages.{system}',
                                          '--apply', 'builtins.attrNames'))
    # Re-enable without discarding the retained edit, then test full module removal.
    update(project, 'true')
    assert edited.read_bytes() == original_edited
    # Restore only this test annotation so normal removal needs no conflict override.
    edited.write_bytes((updater.FILES / FEATURE_FILES[0]).read_bytes())
    (project / 'package.json').write_bytes(generated_package)
    run(['seihou', 'remove', 'nix-bun-flake'], project, input='y\n')
    assert not (project / 'package.json').exists(), 'Base module removal contract changed'
    for path in FEATURE_FILES:
        assert not (project / path).exists()
    for name, content in authored.items():
        assert (project / name).read_bytes() == content
    remaining_owners = json.loads(manifest_path.read_text())['files']['.gitignore']['applications']
    # .gitignore has no base-module removal step; preserve its existing contract
    # without imposing new receipt-cleanup semantics on this feature.
    assert foreign_owners <= set(remaining_owners) <= set(shared_owners)
    assert '.fixture-artifacts' in (project / '.gitignore').read_text()
    print('Ownership: enable/disable/update/removal preserve authored files, custom inputs and edited orphans.', flush=True)


def prepare_native(project, layout):
    project.mkdir()
    updater.render(project, 'false', 'true')
    shutil.copytree(FIXTURES / layout, project, dirs_exist_ok=True)
    assert not (project / 'node_modules').exists()


def native(project, layout, fixtures=FIXTURES):
    """Portable native acceptance on a previously rendered temporary project."""
    system = nix(project, 'eval', '--impure', '--raw', '--expr', 'builtins.currentSystem')
    assert system in updater.SYSTEMS
    lock = (project / 'bun.lock').read_bytes()
    helper = ['nix', 'run', '.#bun2nix', '--no-write-lock-file', '--option', 'sandbox', 'true', '--']

    def generate(source, dest):
        run(helper + ['--lock-file', str(source), '--output-file', str(dest)], project)

    run(['nix', 'build', '.#bun2nix', '--no-link', '--no-write-lock-file',
         '--option', 'sandbox', 'true'], project)
    if layout == 'single':
        help_text = nix(project, 'develop', '--option', 'sandbox', 'true',
                        '--command', 'bun2nix', '--help')
        assert '--lock-file' in help_text and '--output-file' in help_text
    generate(fixtures / 'v1.lock', project / 'v1-deps.nix')
    rejected = run(helper + ['--lock-file', str(fixtures / 'unsupported-v3.lock'),
                           '--output-file', str(project / 'rejected.nix')], project, succeeds=False)
    assert "Unsupported lockfile version: '3'" in rejected.stderr
    generate(project / 'bun.lock', project / 'regenerated.nix')
    assert (project / 'regenerated.nix').read_bytes() == (project / 'bun-deps.nix').read_bytes()
    if layout == 'single':
        assert (project / 'v1-deps.nix').read_bytes() == (project / 'bun-deps.nix').read_bytes()
    assert (project / 'bun.lock').read_bytes() == lock
    assert not (project / 'rejected.nix').exists()

    def identities():
        return tuple(nix(project, 'eval', '--raw', f'.#packages.{system}.{name}.drvPath')
                     for name in ['default', 'registry-cache'])

    def build(expected):
        run(['nix', 'build', '.#default', '--no-link', '--no-write-lock-file',
             '--option', 'sandbox', 'true'], project)
        assert nix(project, 'run', '.#default', '--option', 'sandbox', 'true') == expected
        assert not (project / 'node_modules').exists()

    expected = 'app-original:true' + (':shared-original' if layout == 'workspace' else '')
    build(expected)
    first = identities()
    # A second build with unchanged inputs must not schedule any application work.
    again = run(['nix', 'build', '.#default', '--no-link', '--no-write-lock-file',
                 '--option', 'sandbox', 'true', '--json'], project)
    assert 'will be built' not in again.stderr and "building '" not in again.stderr
    assert identities() == first
    app_source = project / ('packages/app/index.js' if layout == 'workspace' else 'index.js')
    app_source.write_text(app_source.read_text().replace('app-original', 'app-edited'))
    build(expected.replace('app-original', 'app-edited'))
    second = identities()
    assert first[0] != second[0] and first[1] == second[1]
    if layout == 'workspace':
        shared = project / 'packages/shared/index.js'
        shared.write_text(shared.read_text().replace('shared-original', 'shared-edited'))
        build('app-edited:true:shared-edited')
        third = identities()
        assert third[0] != second[0] and third[1] == first[1]
    else:
        # Exact v6 metadata was qualified against npm; regenerate rather than edit the expression.
        manifest = project / 'package.json'
        manifest.write_text(manifest.read_text().replace('7.0.0', '6.0.0'))
        shutil.copyfile(fixtures / 'single-v6.lock', project / 'bun.lock')
        generate(project / 'bun.lock', project / 'bun-deps.nix')
        assert identities()[1] != first[1]
        build('app-edited:true')
    run(['nix', 'flake', 'check', '--no-write-lock-file', '--option', 'sandbox', 'true'], project)
    print(f'Native {system} / {layout}: v1/v2 generation, v3 rejection, frozen sandbox build, output and cache identities passed.', flush=True)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--native', action='store_true', help='Also build both consumers on the host system')
    args = parser.parse_args()
    with tempfile.TemporaryDirectory(prefix='nix-bun-acceptance-') as tmp:
        work = Path(tmp)
        run(['seihou', 'validate-module', str(updater.MODULE)], ROOT)
        evaluate_matrix(work)
        ownership(work)
        if args.native:
            for layout in ['single', 'workspace']:
                project = work / layout
                prepare_native(project, layout)
                native(project, layout)
        else:
            print('Native builds: not requested (run with --native).', flush=True)


if __name__ == '__main__':
    main()
