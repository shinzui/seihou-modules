#!/usr/bin/env python3
"""Exercise real Seihou ownership/update/migration with a deterministic CLI provider."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile

from haskell_runtime_test_support import Commands, ROOT, SYSTEM, copy_modules, render, root_package, track

BLUEPRINT = ROOT / 'blueprints/upgrade-haskell-runtime'
CHECKER = ROOT / 'scripts/check-haskell-runtime-adoption.py'
ORIGINS = json.loads((BLUEPRINT / 'files/target-versions.json').read_text())['recorded_origins']


def provider_environment(destination):
    binary = destination / 'provider-bin'
    binary.mkdir(parents=True)
    provider = binary / 'claude'
    provider.write_text('''#!/usr/bin/env python3
import json,os,subprocess,sys
from pathlib import Path
counter=Path(os.environ['RUNTIME_PROVIDER_COUNTER'])
count=int(counter.read_text())+1 if counter.exists() else 1
counter.write_text(str(count))
if count==int(os.environ.get('RUNTIME_PROVIDER_FAIL_AT','0')):
    sys.exit(23)
command=json.loads(os.environ.get('RUNTIME_PROVIDER_COMMAND','[]'))
if command:
    result=subprocess.run(command,capture_output=True,text=True)
    if result.returncode:
        print(result.stdout,file=sys.stderr);print(result.stderr,file=sys.stderr);sys.exit(result.returncode)
print(json.dumps({'result':'deterministic fixture complete','is_error':False,'session_id':'controlled-fixture'}))
''')
    provider.chmod(0o755)
    environment = {k: v for k, v in os.environ.items() if not k.startswith('SEIHOU_AGENT_') and k != 'SEIHOU_CONTEXT'}
    environment.update(PATH=str(binary) + os.pathsep + os.environ['PATH'],
                       XDG_CONFIG_HOME=str(destination / 'seihou-config'),
                       RUNTIME_PROVIDER_COUNTER=str(destination / 'provider-count'))
    # Nix trust/cache configuration remains inherited by native verification,
    # which uses the original environment, not this discovery-only environment.
    return environment


def copy_blueprint(project):
    shutil.copytree(BLUEPRINT, project / '.seihou/modules/upgrade-haskell-runtime', symlinks=True)


def manifest(project):
    p = project / '.seihou/manifest.json'
    return json.loads(p.read_text()) if p.exists() else {}


def attendance(project):
    return manifest(project).get('blueprintMigrations', [])


def checker(commands, project, before, output, native=False, success=True):
    args = [sys.executable, str(CHECKER), '--project', str(project), '--output', str(output)]
    args += ['--before', str(before)] if before else ['--inventory']
    if native:
        args += ['--native']
    return commands.run(args, project, 'checker-' + output.stem, success=success)


def shared_owner(commands, project):
    module = project / '.seihou/modules/authored-ignore'
    (module / 'files').mkdir(parents=True)
    (module / 'files/ignore').write_text('# Authored precedence\n*.private\n!important.private\n')
    (module / 'module.dhall').write_text('''let S = https://raw.githubusercontent.com/shinzui/seihou-schema/2b4035b7e720a9b30642a8a27551592175732ee5/package.dhall
 sha256:21716b4aee783d8eb8b12c754050880fa710e881ecda85925f855ef34cc34a55
in S.Module::{ name = "authored-ignore", version = Some "0.1.0", steps =
 [ S.Step::{ strategy = "template", src = "ignore", dest = ".gitignore", patch = Some "append-line-if-absent" } ] }
''')
    commands.run(['seihou', 'run', 'authored-ignore', '--no-commands'], project, 'shared-ignore-owner')


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--output-dir', type=Path)
    args = parser.parse_args()
    destination = (args.output_dir or Path(tempfile.mkdtemp(prefix='runtime-adoption-'))).absolute()
    commands = Commands(destination / 'logs')
    environment = provider_environment(destination)
    cases = []
    for version in ['legacy', '0.30.0', '0.31.0']:
        project = destination / version
        name = 'fixture-adoption'
        if version == 'legacy':
            seed = destination / 'legacy-canonical-source'
            repeat = render(commands, seed, name, revision=ORIGINS['0.31.0'])
            project.mkdir()
            for path in ['flake.nix', 'flake.lock', 'nix/haskell.nix', '.envrc', '.gitignore', 'flake.module.nix.example']:
                target = project / path
                target.parent.mkdir(parents=True, exist_ok=True)
                shutil.copy2(seed / path, target)
            copy_modules(project)
            repeat = [str(x) for x in repeat]
        else:
            repeat = render(commands, project, name, revision=ORIGINS[version])
        root_package(project, name)
        extension = '{ ... }: { perSystem = { pkgs, ... }: { haskellProject.extraDevPackages = [ pkgs.ripgrep ]; }; }\n'
        (project / 'flake.module.nix').write_text(extension)
        (project / '.envrc.local').write_text('export AUTHORED_FIXTURE=preserved\n')
        (project / 'process-compose.override.yaml').write_text('processes: {}\n')
        shared_owner(commands, project)
        copy_blueprint(project)
        track(commands, project)
        before = destination / (version + '-before.json')
        checker(commands, project, None, before)
        original = manifest(project)
        debug = ['seihou', 'agent', '--debug']
        commands.run(debug + ['run', 'upgrade-haskell-runtime', '--no-baseline'], project, 'debug-run', env=environment)
        assert manifest(project)['files'] == original['files']
        assert manifest(project)['applications'] == original['applications']
        snapshot = manifest(project)
        commands.run(debug + ['migrate', 'upgrade-haskell-runtime', '--from', '0.30.0', '--to', '0.32.0'], project, 'debug-migrate', env=environment)
        assert manifest(project) == snapshot
        if version == 'legacy':
            # A bounded transformation is executed through the actual provider
            # entry point. Save only unmanaged colliders; retain the co-owner.
            backup = destination / 'legacy-unmanaged-backup'
            backup.mkdir()
            for path in ['flake.nix', 'flake.lock', 'nix/haskell.nix', '.envrc', 'flake.module.nix.example']:
                target = backup / path
                target.parent.mkdir(parents=True, exist_ok=True)
                shutil.move(project / path, target)
            environment['RUNTIME_PROVIDER_COMMAND'] = json.dumps(repeat)
            commands.run(['seihou', 'agent', 'run', 'upgrade-haskell-runtime', '--no-baseline', '--batch', '--provider', 'claude-cli'], project, 'legacy-provider-adoption', env=environment)
            environment.pop('RUNTIME_PROVIDER_COMMAND')
            assert not attendance(project), 'Legacy adoption fabricated migration edges'
        else:
            for module in ['nix-haskell-flake', 'haskell-cli-app']:
                shutil.rmtree(project / '.seihou/modules' / module)
            copy_modules(project)
            # A managed customization is preserved by a real three-way update.
            envrc = project / '.envrc'
            envrc.write_text(envrc.read_text() + '\n# Authored managed-file customization\n')
            if version == '0.31.0':
                flake = project / 'flake.nix'
                original_flake = flake.read_text()
                flake.write_text(original_flake.replace('58a2c26c5be7cdf222fba6323939a67d3c62f193', 'local-conflicting-pin'))
                previous_manifest = manifest(project)
                commands.run(['seihou', 'update', 'nix-haskell-flake', '--json', '--include-shared-owners', '--no-commands'], project, 'conflicting-managed-merge', success=False)
                assert manifest(project) == previous_manifest, 'A rejected merge changed canonical metadata'
                flake.write_text(original_flake)
            commands.run(['seihou', 'update', 'nix-haskell-flake', '--dry-run', '--json', '--include-shared-owners', '--no-commands'], project, 'preview-update')
            commands.run(['seihou', 'update', 'nix-haskell-flake', '--json', '--include-shared-owners', '--no-commands'], project, 'apply-update')
            assert '# Authored managed-file customization' in envrc.read_text()
            migration = ['seihou', 'agent', 'migrate', 'upgrade-haskell-runtime', '--from', version, '--to', '0.32.0', '--provider', 'claude-cli']
            if version == '0.30.0':
                counter = Path(environment['RUNTIME_PROVIDER_COUNTER'])
                environment['RUNTIME_PROVIDER_FAIL_AT'] = str(int(counter.read_text()) + 2)
                commands.run(migration, project, 'interrupt-second-edge', success=False, env=environment)
                completed = attendance(project)
                assert len(completed) == 1, completed
                environment.pop('RUNTIME_PROVIDER_FAIL_AT')
                commands.run(migration, project, 'resume-migration', env=environment)
                assert len(attendance(project)) == 2
            else:
                environment['RUNTIME_PROVIDER_FAIL_AT'] = str(int(Path(environment['RUNTIME_PROVIDER_COUNTER']).read_text()) + 1)
                commands.run(migration, project, 'nonzero-provider', success=False, env=environment)
                assert not attendance(project)
                environment.pop('RUNTIME_PROVIDER_FAIL_AT')
                commands.run(migration, project, 'ordered-migration', env=environment)
            count = Path(environment['RUNTIME_PROVIDER_COUNTER']).read_text()
            commands.run(migration, project, 'attended-noop', env=environment)
            assert Path(environment['RUNTIME_PROVIDER_COUNTER']).read_text() == count
        # Nix reads all owned source, and Cabal uses the shell package database.
        commands.run(['git', 'add', '-N', '.'], project, 'track-new-files')
        configuration = destination / (version + '-cabal.config')
        configuration.write_text('active-repositories: :none\nstore-dir: ' + str(destination / (version + '-cabal-store')) + '\n')
        inherited = os.environ.get('CABAL_CONFIG')
        os.environ['CABAL_CONFIG'] = str(configuration)
        accepted = destination / (version + '-accepted.json')
        try:
            checker(commands, project, before, accepted, native=True)
            assert json.loads(accepted.read_text())['accepted']
            commands.run(['nix', 'develop', '--no-write-lock-file', '--command', 'rg', '--version'], project, 'preserved-custom-tool')
            commands.run(['seihou', 'update', 'nix-haskell-flake', '--json', '--include-shared-owners', '--no-commands'], project, 'repeat-normal-update')
            assert (project / 'flake.module.nix').read_text() == extension
            checker(commands, project, before, destination / (version + '-repeat.json'), native=True)
            # An attended edge does not grant acceptance: corrupt actual source,
            # rerun the independent checker, and replace a previous success.
            source = project / 'src/Demo.hs'
            content = source.read_text()
            source.write_text(content + '\n-- forbidden migration edit\n')
            checker(commands, project, before, accepted, success=False)
            assert json.loads(accepted.read_text())['accepted'] is False
            source.write_text(content)
            if version == '0.31.0':
                # A copied/wrong retained configuration is an adoption failure,
                # including after a genuine migration attendance receipt.
                path = project / 'flake.module.nix'
                path.write_text(extension.replace('haskellProject.extraDevPackages', 'haskellProject.runtime = { runtimeSelection = { name = "keiro-runtime"; generation = 2; channel = "github"; configuration = { compiler = "ghc9141"; disableProfiling = true; disableHaddock = true; }; }; applicationSelections = {}; }; haskellProject.extraDevPackages'))
                checker(commands, project, before, accepted, success=False)
                assert json.loads(accepted.read_text())['accepted'] is False
                path.write_text(extension)
            checker(commands, project, before, accepted, native=True)
        finally:
            if inherited is None:
                os.environ.pop('CABAL_CONFIG', None)
            else:
                os.environ['CABAL_CONFIG'] = inherited
        cases.append({'case': version, 'status': 'passed', 'receipt': accepted.name,
                      'attendance_edges': len(attendance(project)), 'source_sha256': hashlib.sha256((project / 'src/Demo.hs').read_bytes()).hexdigest()})
    (destination / 'receipt.json').write_text(json.dumps({'status': 'passed', 'system': SYSTEM, 'cases': cases,
        'qualification': 'Real installed Seihou CLI with bounded deterministic provider; no real model launched. Native builds use actual Nix/GHC/Cabal. Local origins are genuine, not claimed remote releases.'}, indent=2) + '\n')
    print('Haskell adoption passed: ' + str(destination))


if __name__ == '__main__':
    main()
