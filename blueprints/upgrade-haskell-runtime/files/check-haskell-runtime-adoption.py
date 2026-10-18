#!/usr/bin/env python3
"""Independently verify a Haskell module adoption; attendance is not acceptance."""
import argparse
from datetime import datetime, timezone
import hashlib
import json
import os
from pathlib import Path
import re
import subprocess
import sys
import time
from urllib.parse import quote

SCHEMA = 1
MODULE_INPUTS = {'haskell-nix', 'haskell-nix-dev', 'nixpkgs', 'flake-parts', 'treefmt-nix', 'pre-commit-hooks', 'redpanda-container'}
MIGRATION_PATHS = {'flake.nix', 'flake.lock', 'flake.module.nix', 'flake.module.nix.example', '.envrc', '.gitignore',
                   'nix/haskell.nix', 'nix/haskell-cli-app.nix', 'nix/treefmt.nix', 'nix/pre-commit.nix',
                   'nix/redpanda.nix', 'process-compose.yaml', 'cabal.project'}
IGNORED_ROOTS = {'.git', '.seihou', '.dev', '.direnv', 'dist-newstyle', 'node_modules', 'db', 'redis', 'clickhouse', 'result'}


def digest(data):
    return hashlib.sha256(data).hexdigest()


def canonical(value):
    return json.dumps(value, sort_keys=True, separators=(',', ':')).encode()


def file_identity(path):
    if path.is_symlink():
        return {'kind': 'symlink', 'target': os.readlink(path)}
    if path.is_dir():
        if not os.path.lexists(path / '.git'):
            raise ValueError('Initialize the declared submodule before inventory: ' + str(path))
        revision = subprocess.check_output(['git', '-C', str(path), 'rev-parse', 'HEAD'], text=True).strip()
        dirty = subprocess.check_output(['git', '-C', str(path), 'status', '--porcelain', '--untracked-files=all'], text=True)
        if dirty:
            raise ValueError('Inventory requires a clean declared submodule; preserve and verify its dirty work separately: ' + str(path))
        return {'kind': 'gitlink', 'revision': revision}
    return {'kind': 'file', 'sha256': digest(path.read_bytes())}


def source_inventory(project):
    result = subprocess.run(['git', 'ls-files', '--cached', '--others', '--exclude-standard', '-z'], cwd=project, capture_output=True)
    if result.returncode:
        raise ValueError('Inventory requires a Git checkout; initialize or rehearse in an isolated checkout first.')
    names = set(result.stdout.decode().split('\0')) - {''}
    names |= {p for p in ['.envrc.local', 'process-compose.override.yaml', 'process-compose.override.yml'] if os.path.lexists(project / p)}
    values = {}
    for name in sorted(names):
        first = name.split('/')[0]
        if first in IGNORED_ROOTS or first.startswith('.runtime-test') or name in MIGRATION_PATHS:
            continue
        path = project / name
        values[name] = file_identity(path)
    return values


def application_inventory(project):
    path = project / '.seihou/manifest.json'
    manifest = json.loads(path.read_text()) if path.exists() else {}
    applications = {}
    for app in manifest.get('applications', []):
        normalized = json.loads(json.dumps(app))
        # Older manifests omit this engine-defaulted empty list. Preserve any
        # real commands while ignoring serialization of the same empty value.
        normalized.setdefault('checkoutCommands', [])
        if normalized.get('target', {}).get('name') in {'nix-haskell-flake', 'haskell-cli-app'}:
            normalized.pop('appliedAt', None)
            normalized.pop('targetVersion', None)
        for instance in normalized.get('instances', []):
            if instance.get('name') in {'nix-haskell-flake', 'haskell-cli-app'}:
                instance.pop('version', None)
        applications[app['applicationId']] = {'sha256': digest(canonical(normalized)), 'target': app.get('target')}
    versions = {m['name']: m.get('version') for m in manifest.get('modules', [])}
    owners = {name: sorted(info.get('applications', [])) for name, info in manifest.get('files', {}).items()}
    ignore = project / '.gitignore'
    ignore_lines = [digest(line.encode()) for line in ignore.read_text().splitlines() if line.strip()] if ignore.exists() else []
    return {'applications': applications, 'module_versions': versions, 'manifest_version': manifest.get('version'),
            'file_owners': owners, 'gitignore_ordered_lines': ignore_lines,
            'managed_paths': sorted(manifest.get('files', {}))}


def nix_string(value):
    return json.dumps(value).replace('${', '\\${')


def observe(project, system, owned, run):
    if any(not re.fullmatch(r'[A-Za-z0-9][A-Za-z0-9-]*', name) for name in owned):
        raise ValueError('Invalid owned package name')
    uri = 'git+file://' + quote(str(project), safe='/')
    expression = '''let
      app = builtins.getFlake ''' + nix_string(uri) + ''';
      system = ''' + nix_string(system) + ''';
      shell = app.devShells.${system}.default or null;
      identity = if shell != null then shell.packageSetIdentity or null else null;
      scope = if shell != null && shell ? applicationScope then shell.applicationScope
        else app.legacyPackages.${system}.haskellPackages or null;
      root = app.packages.${system}.default;
      names = builtins.fromJSON ''' + nix_string(json.dumps(owned)) + ''';
      ownNames = if names != [] then names
        else if identity != null then builtins.attrNames identity.ownPackages else [];
      original = app.lib.runtimeSelection or null;
      compiler = if scope != null then scope.ghc else root.compiler;
      tools = app.inputs.haskell-nix-dev.lib.${system}.ghcVersions;
      keys = builtins.filter (name: tools.${name}.compiler.drvPath == compiler.drvPath) (builtins.attrNames tools);
      compilerKey = if builtins.length keys == 1 then builtins.head keys else null;
      configured = if identity != null then {
        inherit (identity) runtimeSelection applicationSelections;
      } else if original != null then {
        runtimeSelection = {
          name = original.runtime;
          inherit (original) generation channel;
          configuration = { compiler = compilerKey; inherit (original) disableProfiling disableHaddock; };
        };
        inherit (original) applicationSelections;
      } else null;
      retained = if original != null && scope != null then
        app.inputs.haskell-nix.lib.mkRuntimePackageSet original else null;
      dependencyFacts = if identity != null then identity.dependencies else if retained != null then
        builtins.mapAttrs (name: _: if builtins.hasAttr name scope && scope.${name} != null
          then { derivation = scope.${name}.drvPath; }
          else { kind = "compiler-provided"; compiler = compiler.drvPath; }) retained.metadata.ownership else {};
      dependencies = builtins.mapAttrs (_: entry: if entry ? derivation
        then { inherit (entry) derivation; } else { inherit (entry) kind compiler; }) dependencyFacts;
      data = {
        root = root.drvPath;
        compiler = compiler.drvPath;
        compilerVersion = compiler.version;
        inherit compilerKey configured dependencies ownNames;
        managedRuntime = identity != null;
        owned = if scope == null then {} else builtins.listToAttrs
          (map (name: { inherit name; value = scope.${name}.drvPath; }) ownNames);
        hls = if shell != null then shell.hlsIdentity or null else null;
        checks = builtins.attrNames (app.checks.${system} or {});
        formatter = builtins.hasAttr system (app.formatter or {});
        inputs = builtins.mapAttrs (_: input: {
          rev = input.rev or null;
          narHash = input.narHash or null;
        }) app.inputs;
      };
    in builtins.fromJSON (builtins.unsafeDiscardStringContext (builtins.toJSON data))'''
    return json.loads(run(['nix', 'eval', '--json', '--impure', '--expr', expression], 'identities'))


def normalized_cabal(project):
    path = project / 'cabal.project'
    if not path.exists():
        return None
    text = re.sub(r'(https://raw\.githubusercontent\.com/shinzui/haskell-nix/)[0-9a-f]{40}(/)', r'\1<CHANNEL>\2', path.read_text())
    return digest(text.encode())


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--project', type=Path, required=True)
    parser.add_argument('--project-uri')
    parser.add_argument('--inventory', action='store_true')
    parser.add_argument('--before', type=Path)
    parser.add_argument('--target', type=Path, default=Path(__file__).with_name('target-versions.json'))
    parser.add_argument('--output', type=Path, required=True)
    parser.add_argument('--system', default='aarch64-darwin')
    parser.add_argument('--owned-package', action='append', default=[])
    parser.add_argument('--native', action='store_true', help='Run the project build, shell compiler, Cabal build/tests and applicable checks. Review hooks and use an isolated project.')
    args = parser.parse_args()
    project = args.project.absolute()
    output = args.output.absolute()
    if str(project).startswith('/nix/store') or output.is_relative_to(project):
        parser.error('Use a real checkout and keep evidence outside it.')
    output.parent.mkdir(parents=True, exist_ok=True)
    logs = output.parent / (output.stem + '-logs')
    logs.mkdir(exist_ok=True)
    commands = []
    report = {'schema_version': SCHEMA, 'project': str(project), 'project_uri': args.project_uri,
              'verified_at': datetime.now(timezone.utc).isoformat(), 'accepted': False,
              'commands': commands, 'acceptance_scope': 'Source, ownership, explicit input/runtime identities and executed native checks; no hosted-CI or performance assertion.'}

    def write():
        temporary = output.with_suffix(output.suffix + '.tmp')
        temporary.write_text(json.dumps(report, indent=2) + '\n')
        temporary.replace(output)

    def run(command, label):
        started = time.monotonic()
        result = subprocess.run(command, cwd=project, capture_output=True, text=True)
        prefix = logs / f'{len(commands):03d}-{label}'
        prefix.with_suffix('.stdout').write_text(result.stdout)
        prefix.with_suffix('.stderr').write_text(result.stderr)
        commands.append({'command': command, 'elapsed_seconds': time.monotonic() - started,
                         'exit_code': result.returncode, 'stdout': prefix.with_suffix('.stdout').name,
                         'stderr': prefix.with_suffix('.stderr').name})
        write()
        if result.returncode:
            raise ValueError(label + ' failed: ' + result.stderr[-1800:])
        return result.stdout

    try:
        before = json.loads(args.before.read_text()) if args.before else None
        owned = args.owned_package or (before['identities']['ownNames'] if before else [])
        identities = observe(project, args.system, owned, run)
        state = {'source_files': source_inventory(project), 'seihou': application_inventory(project),
                 'cabal_normalized_sha256': normalized_cabal(project), 'identities': identities}
        if args.inventory:
            report.update(state, status='inventory', system=args.system)
            write()
            return
        if before is None:
            raise ValueError('--before is required for validation')
        target = json.loads(args.target.read_text())
        for name, required in target['pins'].items():
            if identities['inputs'].get(name, {}).get('rev') != required:
                raise ValueError('Unexpected input selection for ' + name)
        for name, info in before['identities']['inputs'].items():
            if name not in MODULE_INPUTS and identities['inputs'].get(name) != info:
                raise ValueError('Custom input changed: ' + name)
        for name, info in before['source_files'].items():
            path = project / name
            if not os.path.lexists(path) or file_identity(path) != info:
                raise ValueError('Authored source changed: ' + name)
        if state['cabal_normalized_sha256'] != before['cabal_normalized_sha256']:
            raise ValueError('Cabal project changed beyond the matching channel import pin')
        for app_id, info in before['seihou']['applications'].items():
            if state['seihou']['applications'].get(app_id) != info:
                raise ValueError('Existing Seihou application changed: ' + app_id)
        for name, owners in before['seihou']['file_owners'].items():
            if not set(owners).issubset(state['seihou']['file_owners'].get(name, [])):
                raise ValueError('Existing shared file owners changed: ' + name)
        ignore_lines = iter(state['seihou']['gitignore_ordered_lines'])
        if not all(any(current == previous for current in ignore_lines)
                   for previous in before['seihou']['gitignore_ordered_lines']):
            raise ValueError('Authored gitignore lines were removed or reordered')
        if state['seihou']['module_versions'].get('nix-haskell-flake') != target['modules']['nix-haskell-flake']:
            raise ValueError('Target module was not recorded by Seihou')
        for name, version in target['modules'].items():
            if name in state['seihou']['module_versions'] and state['seihou']['module_versions'][name] != version:
                raise ValueError('A composed module is stale: ' + name)
        if 'flake.module.nix' in state['seihou']['managed_paths']:
            raise ValueError('The unmanaged extension was claimed by a module')
        newly_claimed = set(state['seihou']['managed_paths']) - set(before['seihou']['managed_paths'])
        # The canonical formatter configuration is a module-generated seed in
        # legacy projects too. Its bytes must still match the source inventory;
        # only that unchanged configuration may acquire genuine module ownership.
        claimed_source = newly_claimed.intersection(before['source_files']) - {'fourmolu.yaml'}
        if claimed_source:
            raise ValueError('Authored source was claimed by a new module: ' + ', '.join(sorted(claimed_source)))
        if identities['compiler'] != before['identities']['compiler']:
            raise ValueError('Compiler identity changed')
        if before['identities']['configured'] is not None:
            if not owned:
                raise ValueError('A retained baseline needs explicit --owned-package names')
            for field in ['configured', 'dependencies', 'owned', 'root']:
                if identities[field] != before['identities'][field]:
                    raise ValueError('Existing retained/production identity changed: ' + field)
            if not identities['managedRuntime']:
                raise ValueError('The primary shell does not use the checked retained scope')
        if identities['managedRuntime']:
            matches = [entry for entry in target['qualified_runtime_configurations']
                       if args.system in entry['systems'] and identities['configured'] == entry['selection']]
            if not matches:
                raise ValueError('Runtime selection has not been qualified by this release')
        if not args.native:
            raise ValueError('Identity checks passed; --native is required for an accepted adoption report')
        run(['nix', 'build', '.#default', '--no-link', '--no-write-lock-file', '--print-build-logs'], 'ordinary-build')
        compiler_output = run(['nix', 'develop', '--no-write-lock-file', '--command', 'ghc', '--numeric-version'], 'shell-compiler')
        if identities['compilerVersion'] not in compiler_output.splitlines():
            raise ValueError('Shell compiler differs from the selected recipe')
        # Explicit owned targets avoid unintentionally testing every upstream
        # source-repository package imported by the consumer's Cabal policy.
        targets = identities['ownNames'] or ['all']
        run(['nix', 'develop', '--no-write-lock-file', '--command', 'cabal', 'build', '--offline', '-j2', *targets], 'cabal-build')
        run(['nix', 'develop', '--no-write-lock-file', '--command', 'cabal', 'test', '--offline', '-j2', *targets], 'cabal-tests')
        for check in ['consumer-overlay', 'cohort-parity', 'library-extension']:
            if check in identities['checks']:
                run(['nix', 'build', '.#checks.' + args.system + '.' + check, '--no-link', '--no-write-lock-file'], check)
        if identities['formatter']:
            run(['nix', 'fmt', '--no-write-lock-file', '--', '--ci'], 'format')
        if identities['hls'] is not None:
            run(['nix', 'develop', '--no-write-lock-file', '--command', 'haskell-language-server-wrapper', '--version'], 'hls-version')
        if observe(project, args.system, owned, run) != identities:
            raise ValueError('Identities changed during verification')
        for name, info in before['source_files'].items():
            if file_identity(project / name) != info:
                raise ValueError('A validation command changed authored source: ' + name)
        report.update(state, accepted=True, status='passed', system=args.system,
                      before_sha256=digest(args.before.read_bytes()), target_sha256=digest(args.target.read_bytes()),
                      cabal_comparison_basis='Installed-package reuse; source-complete cohort comparison remains an independent owner check.')
        write()
        print('Accepted adoption report: ' + str(output))
    except Exception as error:
        report.update(status='failed', error=str(error))
        write()
        print(str(error), file=sys.stderr)
        raise SystemExit(1)


if __name__ == '__main__':
    main()
