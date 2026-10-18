#!/usr/bin/env python3
"""Render and exercise actual bare and retained-runtime Haskell scaffolds."""
import argparse
import json
import os
from pathlib import Path
import subprocess
import tempfile

from haskell_runtime_test_support import Commands, ROOT, SYSTEM, render, runtime_extension, root_package, track, eval_json



def native_cabal_and_edit(commands, project, name, cli, identity):
    configuration = project / '.runtime-test-cabal-config'
    configuration.write_text('active-repositories: :none\nstore-dir: ' + str(project / '.runtime-test-store') + '\n')
    environment = os.environ | {'CABAL_CONFIG': str(configuration)}
    cabal = ['nix', 'develop', '--no-write-lock-file', '--command', 'cabal']
    commands.run(cabal + ['build', '--offline', '-j2', 'all'], project, 'cabal-build', env=environment)
    commands.run(cabal + ['test', '--offline', '-j2', 'all'], project, 'cabal-test', env=environment)
    path = project / (name + '-cli/src/RuntimeFixture/Cli.hs' if cli else 'src/Demo.hs')
    content = path.read_text()
    edited = content.replace('Retained runtime integration fixture', 'Edited runtime integration fixture') if cli else content.replace('(41 :: Int)', '(42 :: Int)')
    assert edited != content
    try:
        path.write_text(edited)
        changed = eval_json(commands, project, 'devShells.' + SYSTEM + '.default.packageSetIdentity', 'source-edit-identities')
        assert changed['compiler'] == identity['compiler']
        assert changed['dependencies'] == identity['dependencies']
        key = name + '-cli' if cli else name
        assert changed['ownPackages'][key] != identity['ownPackages'][key]
        if cli:
            assert changed['ownPackages'][name + '-core'] == identity['ownPackages'][name + '-core']
        commands.run(cabal + ['build', '--offline', '-j2', 'all'], project, 'cabal-edit-build', env=environment)
        commands.run(cabal + ['test', '--offline', '-j2', 'all'], project, 'cabal-edit-test', env=environment)
        output = commands.run(cabal + ['run', '--offline', 'exe:' + name, '--'] + (['--help'] if cli else []), project, 'cabal-edit-run', env=environment)
        assert ('Edited runtime integration fixture' in output) if cli else ('42' in output.splitlines())
        commands.run(['nix', 'build', '.#default', '--no-link', '--no-write-lock-file'], project, 'nix-edit-build')
    finally:
        path.write_text(content)


def negative_cases(commands, project, extension):
    path = project / 'flake.module.nix'
    probes = [
        ('shared-override', 'applicationOverlays = [ (_: previous: { aeson = previous.aeson; }) ];', ['shadows channel packages', 'aeson']),
        ('undeclared-owned', 'applicationOverlays = [ (final: _: { stray = final."fixture-root-runtime"; }) ];', ['stray']),
        ('second-compiler', 'extraDevPackages = [ pkgs.haskell.packages.ghc9124.ghc ];', ['second compiler']),
    ]
    try:
        for label, declaration, reasons in probes:
            path.write_text(extension.replace('haskellProject = {', 'haskellProject = {\n' + declaration))
            error = commands.run(['nix', 'eval', '--raw', '.#devShells.' + SYSTEM + '.default.drvPath'], project, label, success=False)
            assert all(reason.lower() in error.lower() for reason in reasons), error[-2000:]
        explicit_pkgs = extension.replace('perSystem = { pkgs, ... }: {', '''perSystem = { system, pkgs, ... }: {
          _module.args.pkgs = (import inputs.nixpkgs { inherit system; }).extend (_: previous: {
            zlib = previous.zlib.overrideAttrs (_: { name = "mismatched-native-zlib"; });
          });''')
        path.write_text(explicit_pkgs)
        error = commands.run(['nix', 'eval', '--raw', '.#devShells.' + SYSTEM + '.default.drvPath'], project, 'explicit-native-mismatch', success=False)
        assert 'nixpkgs does not match the retained runtime toolchain' in error, error[-2000:]
        selection_path = project / 'runtime-test-selection.json'
        selection = selection_path.read_text()
        for label, change, reason in [
            ('wrong-compiler', lambda d: d['runtimeSelection']['configuration'].update(compiler='ghc9141'), 'compiler must match'),
            ('incomplete-selection', lambda d: d.pop('applicationSelections'), 'applicationSelections'),
        ]:
            path.write_text(extension)
            value = json.loads(selection)
            change(value)
            selection_path.write_text(json.dumps(value) + '\n')
            try:
                error = commands.run(['nix', 'eval', '--raw', '.#devShells.' + SYSTEM + '.default.drvPath'], project, label, success=False)
                assert reason.lower() in error.lower() or (label == 'incomplete-selection' and 'missing complementary groups' in error), error[-2000:]
            finally:
                selection_path.write_text(selection)
        path.write_text(extension.replace('haskellProject = {', 'haskellProject = {\nwithHls = true;'))
        # The primary supports HLS; an explicitly requested unsupported secondary fails.
        extra = (project / 'nix/haskell.nix').read_text()
        original_module = extra
        extra = extra.replace('devShells.default = primaryShell;', 'devShells.ghc9141 = mkBareShell "ghc9141";\n      devShells.default = primaryShell;')
        (project / 'nix/haskell.nix').write_text(extra)
        try:
            error = commands.run(['nix', 'eval', '--raw', '.#devShells.' + SYSTEM + '.ghc9141.drvPath'], project, 'unsupported-explicit-hls', success=False)
            assert 'HLS explicitly requested but unavailable' in error
        finally:
            (project / 'nix/haskell.nix').write_text(original_module)
    finally:
        path.write_text(extension)


def legacy_api_case(commands, destination):
    project = destination / 'legacy-api'
    name = 'fixture-legacy-api'
    render(commands, project, name)
    root_package(project, name)
    (project / 'flake.module.nix').write_text('{ ... }: { }\n')
    flake = project / 'flake.nix'
    flake.write_text(flake.read_text()
        .replace('21933607e80ec4660a28a125a6f4c0707e358caf', '206ecd25bcb4a07581210bdae3e6f43c8fd179d8')
        .replace('e5a7c2c50080b3364f0f0fd667240c560596d0ed', '58a2c26c5be7cdf222fba6323939a67d3c62f193'))
    old_lock = subprocess.check_output(['git', 'show', 'cc1b70c7:modules/haskell/nix-haskell-flake/files/flake.lock'], cwd=ROOT)
    (project / 'flake.lock').write_bytes(old_lock)
    track(commands, project)
    expression = ('let a = builtins.getFlake "git+file://' + str(project) + '"; in '
                  '!(a.inputs.haskell-nix.lib ? mkProjectDevShell) && '
                  '!(a.inputs.haskell-nix-dev.lib.' + SYSTEM + ' ? mkProjectShell)')
    assert json.loads(commands.run(['nix', 'eval', '--json', '--impure', '--expr', expression], project, 'legacy-absent-apis'))
    commands.run(['nix', 'build', '.#default', '--no-link', '--no-write-lock-file'], project, 'legacy-old-input-build')
    commands.run(['nix', 'develop', '--no-write-lock-file', '--command', 'ghc', '--numeric-version'], project, 'legacy-old-input-shell')
    assert (project / 'flake.lock').read_bytes() == old_lock
    return {'case': 'legacy-api', 'status': 'passed', 'qualification': 'New module with original published inputs lacking both new shell APIs; bare mode builds and enters without forcing them.'}


def services_case(commands, destination):
    project = destination / 'service fixture'
    name = 'fixture-services'
    repeat = render(commands, project, name, features={
        'nix.postgresql': 'true', 'nix.pg-package': 'postgresql_18', 'nix.pg-database': 'fixture_services',
        'nix.redis': 'true', 'nix.kafka': 'true', 'nix.process-compose': 'true', 'nix.pre-commit': 'true',
        'nix.treefmt': 'true',
    })
    root_package(project, name)
    extension = runtime_extension(project, name, root_package=True)
    extension = extension.replace('shellHook = "export RUNTIME_FIXTURE_HOOK=original";', '''
      inputsFrom = [ (pkgs.mkShell { shellHook = "export RUNTIME_INHERITED=preserved"; }) ];
      extraDevPackages = [ pkgs.ripgrep ];
      extraBuildInputs = [ pkgs.curl ];
      shellHook = ''
        export RUNTIME_FIXTURE_HOOK_COUNT="$(( ''${RUNTIME_FIXTURE_HOOK_COUNT:-0} + 1 ))"
      '';
''')
    (project / 'flake.module.nix').write_text(extension)
    (project / '.envrc.local').write_text('export AUTHORED_ENVRC=preserved\n')
    track(commands, project)
    command = '''set -eu
test "$RUNTIME_FIXTURE_HOOK_COUNT" = 1
test "$RUNTIME_INHERITED" = preserved
test "$PGHOST" = "$PWD/db"
test "$PGDATA" = "$PWD/db/db"
test "$PGDATABASE" = fixture_services
test "$PG_CONNECTION_STRING" = "postgresql://$(jq -rn --arg x "$PGHOST" '$x|@uri')/fixture_services"
test "$REDIS_SOCKET" = "$PWD/redis/redis.sock"
test "$REDIS_LOG" = "$PWD/redis/redis.log"
test "$(command -v ghc)" = "$NIX_GHC"
pkg-config --exists libpq openssl rdkafka zlib
psql --version
rg --version
'''
    commands.run(['nix', 'develop', '--no-write-lock-file', '--command', 'bash', '-c', command], project, 'services-native-shell')
    assert not (project / 'db/db/postmaster.pid').exists(), 'A fixture must not start a database service'
    assert os.path.lexists(project / '.git/hooks/pre-commit')
    assert os.path.lexists(project / '.git/hooks/commit-msg')
    message = project / '.fixture-commit-message'
    message.write_text('test: valid fixture\n')
    hook = ['nix', 'develop', '--no-write-lock-file', '--command', 'git', 'hook', 'run', 'commit-msg', '--', str(message)]
    commands.run(hook, project, 'valid-commit-message')
    message.write_text('test: invalid' + chr(92) + 'nmessage\n')
    error = commands.run(hook, project, 'invalid-commit-message', success=False)
    assert 'Commit message contains a literal' in error
    assert '--port 0' in (project / 'process-compose.yaml').read_text()
    commands.run(repeat, project, 'services-repeat-render')
    assert (project / 'flake.module.nix').read_text() == extension
    assert (project / '.envrc.local').read_text() == 'export AUTHORED_ENVRC=preserved\n'
    return {'case': 'services', 'status': 'passed', 'qualification': 'Real native/header inputs, compatible inherited hook, single compiler, hook exactly once, quoted PostgreSQL paths and project-local Redis environment; no service started.'}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--output-dir', type=Path)
    parser.add_argument('--case', choices=['root-bare', 'root-runtime', 'cli-bare', 'cli-runtime'])
    args = parser.parse_args()
    destination = (args.output_dir or Path(tempfile.mkdtemp(prefix='haskell-runtime-bootstrap-'))).absolute()
    commands = Commands(destination / 'logs')
    cases = [args.case] if args.case else ['root-bare', 'root-runtime', 'cli-bare', 'cli-runtime']
    results = []
    for case in cases:
        cli = case.startswith('cli-')
        runtime = case.endswith('-runtime')
        name = 'fixture-' + case
        project = destination / case
        repeat = render(commands, project, name, cli=cli)
        if not cli:
            root_package(project, name)
        if runtime:
            extension = runtime_extension(project, name, root_package=not cli)
        else:
            extension = '{ ... }: { }\n'
            (project / 'flake.module.nix').write_text(extension)
        track(commands, project)
        canonical = (ROOT / 'modules/haskell/nix-haskell-flake/files/flake.lock').read_bytes()
        assert (project / 'flake.lock').read_bytes() == canonical
        commands.run(['nix', 'flake', 'lock'], project, case + '-lock')
        assert (project / 'flake.lock').read_bytes() == canonical
        before = eval_json(commands, project, 'packages.' + SYSTEM + '.default.drvPath', case + '-package')
        shell = eval_json(commands, project, 'devShells.' + SYSTEM + '.default.drvPath', case + '-shell')
        identity = eval_json(commands, project, 'devShells.' + SYSTEM + '.default.packageSetIdentity', case + '-identity') if runtime else None
        if runtime:
            assert before in identity['ownPackages'].values()
            assert identity['runtimeSelection']['generation'] == 2
        commands.run(['nix', 'build', '.#default', '--no-link', '--no-write-lock-file', '--print-build-logs'], project, case + '-build')
        commands.run(['nix', 'develop', '--no-write-lock-file', '--command', 'sh', '-c',
                      'test "$(ghc --numeric-version)" = 9.12.4 && cabal --numeric-version && ghc-pkg latest text && pkg-config --modversion zlib'], project, case + '-compiler')
        commands.run(repeat, project, case + '-repeat-render')
        assert (project / 'flake.module.nix').read_text() == extension
        assert (project / 'flake.lock').read_bytes() == canonical
        if runtime:
            (project / 'flake.module.nix').write_text(extension.replace('RUNTIME_FIXTURE_HOOK=original', 'RUNTIME_FIXTURE_HOOK=changed'))
            after = eval_json(commands, project, 'packages.' + SYSTEM + '.default.drvPath', case + '-hook-package')
            assert before == after, 'Shell-only hook changed the application recipe'
            changed_shell = eval_json(commands, project, 'devShells.' + SYSTEM + '.default.drvPath', case + '-hook-shell')
            assert shell != changed_shell
            (project / 'flake.module.nix').write_text(extension)
            native_cabal_and_edit(commands, project, name, cli, identity)
            if not cli:
                negative_cases(commands, project, extension)
        results.append({'case': case, 'package': before, 'shell': shell, 'identity': identity, 'status': 'passed'})
    if not args.case:
        results += [legacy_api_case(commands, destination), services_case(commands, destination)]
    (destination / 'receipt.json').write_text(json.dumps({'status': 'passed', 'system': SYSTEM, 'cases': results}, indent=2) + '\n')
    print('Haskell runtime bootstrap passed: ' + str(destination), flush=True)


if __name__ == '__main__':
    main()
