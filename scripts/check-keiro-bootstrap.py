#!/usr/bin/env python3
"""Exercise actual Seihou rendering without modifying user module installations."""
import hashlib
import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import re
import pty
import select
import time

ROOT = Path(__file__).resolve().parents[1]

def run(args, cwd, success=True):
    result = subprocess.run(args, cwd=cwd, text=True, capture_output=True, stdin=subprocess.DEVNULL)
    if success and result.returncode:
        raise AssertionError(f'{args}:\n{result.stdout}\n{result.stderr}')
    return result

def snapshot(project):
    return {str(p.relative_to(project)): hashlib.sha256(p.read_bytes()).hexdigest()
            for p in project.rglob('*') if p.is_file() and '.seihou' not in p.parts}

def render(name="sample-service", namespace="SampleService", apply=True, **overrides):
    project = Path(tempfile.mkdtemp(prefix='seihou-keiro-bootstrap-'))
    modules = project / '.seihou/modules'
    modules.mkdir(parents=True)
    for module in ['haskell-keiro-project', 'nix-haskell-flake']:
        shutil.copytree(ROOT / 'modules/haskell' / module, modules / module)
    shutil.copytree(ROOT / 'blueprints/haskell-keiro-service', modules / 'haskell-keiro-service')
    variables = {'project.name': name, 'project.namespace': namespace,
                 'project.description': 'A bootstrap smoke test',
                 'project.author': 'Test Author', 'project.maintainer': 'test@example.com',
                 'project.copyright-year': '2026', 'haskell.index-state': '2026-10-26T00:00:00Z',
                 'ghc.version': 'ghc9124', 'nix.treefmt': 'true', 'nix.pre-commit': 'true',
                 'nix.redis': 'false', 'nix.clickhouse': 'false', 'nix.kafka': 'false'}
    variables.update(overrides)
    command = ['seihou', 'run', 'haskell-keiro-project', '--no-save-prompted', '--no-commands']
    for key, value in variables.items():
        command += ['--var', f'{key}={value}']
    result = run(command, project, success=False) if apply else None
    return project, command, result

def cabal_dependencies(path):
    result = set()
    scope = 'Regular'
    for line in path.read_text().splitlines():
        if line.startswith('test-suite '):
            scope = 'Test'
        elif line.startswith(('library', 'executable ')):
            scope = 'Regular'
        match = re.fullmatch(r'\s*(?:, )?([\w.:\-]+)\s+([><=^].*)', line)
        if match:
            result.add((*match.groups(), scope))
    return result


def check_inventory(project):
    run(['dhall', '--file', 'mori.dhall'], project)
    data = json.loads(run(['dhall-to-json', '--file', 'mori.dhall'], project).stdout)
    run(['mori', 'validate'], project)
    run(['mori', 'show', '--json'], project)
    assert len(data['packages']) == 6
    owners = json.loads((ROOT / 'scripts/keiro-dependency-owners.json').read_text())
    refs = {(r['namespace'], r['name'], r['key']) for r in data['dependencyRefs']}
    for package in data['packages']:
        assert package['path'] == package['name']
        cabal = cabal_dependencies(project / package['path'] / (package['name'] + '.cabal'))
        expected = set()
        for name, bounds, scope in cabal:
            if name == 'base' or scope != 'Regular' or name == package['name']:
                continue
            owner = owners.get(name)
            lookup = '/'.join(owner) + ':' + name if owner else name
            source = 'Local' if name.startswith(data['project']['name'] + '-') else 'Hackage'
            expected.add((lookup, bounds, scope, source))
            if owner:
                assert (*owner, name) in refs
        actual = set()
        for dep in package['dependencies']:
            actual.add((dep['name'], dep['versionConstraint'], dep['scope'], dep['source']))
        assert expected == actual, (package['name'], expected ^ actual)
    api, = data['apis']
    assert api['name'] == api['owner'] == data['project']['name'] + '-api'
    assert api['specPath'] == 'docs/openapi.json' and api['type'] == 'OpenAPI'
    assert api['ownerRef']['namespace'] == data['project']['namespace']
    assert api['ownerRef']['name'] == data['project']['name']
    assert api['ownerRef']['key'] == api['owner']
    assert not (project / 'docs/openapi.json').exists(), 'Descriptor must not fabricate a schema'
    return data


def interactive(answer, agent=False):
    project, command, _ = render(apply=False, **{'mori.generate': 'false'})
    # A fresh run with no saved application answers is needed to test prompting.
    # render used --no-save-prompted; explicit values are only in its argv.
    master, slave = pty.openpty()
    argv = (["seihou", "agent", "--debug", "run", "haskell-keiro-service"] + command[5:-2]) if agent else command[:-2]
    proc = subprocess.Popen(argv, cwd=project, stdin=slave, stdout=slave, stderr=slave)
    os.close(slave)
    output = b''
    answered = namespace = proceeded = False
    deadline = time.monotonic() + 60
    try:
        while time.monotonic() < deadline:
            ready, _, _ = select.select([master], [], [], 0.2)
            if ready:
                try:
                    chunk = os.read(master, 65536)
                except OSError:
                    break
                if not chunk:
                    break
                output += chunk
                if not answered and b'Generate an initial mori.dhall' in output:
                    os.write(master, (answer + '\n').encode())
                    answered = True
                if not namespace and b'Mori organization/user namespace?' in output:
                    os.write(master, b'interactive-org\n')
                    namespace = True
                if not proceeded and b'Proceed? [Y/n]' in output:
                    os.write(master, b'y\n')
                    proceeded = True
            if proc.poll() is not None:
                break
        try:
            status = proc.wait(timeout=5)
        except subprocess.TimeoutExpired as error:
            raise AssertionError(output.decode(errors="replace")[-6000:]) from error
        assert status == 0, output.decode(errors="replace")[-3000:]
    finally:
        if proc.poll() is None:
            proc.kill()
            proc.wait()
        os.close(master)
    assert output.count(b"Generate an initial mori.dhall") == 1, output.decode(errors="replace")[-6000:]
    assert answered, output.decode(errors='replace')[-3000:]
    enabled = answer == 'true'
    assert namespace == enabled
    assert (project / 'mori.dhall').exists() == enabled
    if enabled:
        assert check_inventory(project)['project']['namespace'] == 'interactive-org'


def extra_checks():
    project, command, result = render(**{'mori.generate': 'true', 'mori.namespace': 'example', 'nix.pg-database': 'custom_db', 'nix.redpanda': 'true', 'nix.redpanda-console': 'false', 'redpanda.kafka-port': '19092', 'redpanda.console-port': '18080'})
    assert result.returncode == 0, result.stderr
    data = check_inventory(project)
    assert data['project']['namespace'] == 'example'
    assert data['okfBundles'] == []
    bundle_expression = '[Schema.OkfBundle::{name="requests",path="docs/requests",okfVersion="0.2",profile=Some "docs/requests/profile.dhall"}]'
    extended, _, extended_result = render(**{'mori.generate': 'true', 'mori.namespace': 'example', 'mori.okf-bundles': bundle_expression})
    assert extended_result.returncode == 0, extended_result.stderr
    extended_data = check_inventory(extended)
    assert extended_data['okfBundles'][0]['name'] == 'requests'
    assert extended_data['okfBundles'][0]['profile'] == 'docs/requests/profile.dhall'

    nix = (project / 'nix/haskell.nix').read_text()
    assert 'export PGDATABASE=custom_db' in nix
    broker = (project / 'nix/redpanda.nix').read_text()
    assert '19092' in broker and '18080' in broker and 'sample-service' in broker
    assert 'isDarwin' in broker and 'false' in broker
    assert (project / 'flake.lock').read_bytes() == (ROOT / 'modules/haskell/nix-haskell-flake/files/flake.lock').read_bytes()
    assert 'keiro-dev-tools.nix' in (project / 'flake.nix').read_text()
    assert not (project / 'flake.module.nix').exists()
    assert '{{base_url}}/health/live' in (project / 'tests/api/health.hurl').read_text()
    assert (project / '.gitignore').read_text().splitlines().count('.artifacts/') == 1
    before = snapshot(project)
    run(command, project)
    assert snapshot(project) == before
    run(command + ['--var', 'mori.namespace=another-org'], project)
    changed = snapshot(project)
    assert changed == before, 'Saved seed settlement must preserve the authored descriptor'
    assert check_inventory(project)['project']['namespace'] == 'example'
    run(command, project)
    for relative in ['mori.dhall', 'tests/fixtures/bootstrap/fixture.sql', 'domain/sample-service.keiro-workspace']:
        path = project / relative
        original = path.read_text()
        path.write_text(original + '\n-- authored edit\n')
        result = run(command + ['--force'], project)
        assert 'keep settled' in (result.stdout + result.stderr).lower()
        assert path.read_text() == original + '\n-- authored edit\n'
        path.write_text(original)
    opted_out = command + ['--var', 'mori.generate=false']
    run(opted_out, project)
    assert (project / 'mori.dhall').exists(), 'Opt-out must preserve prior descriptor'
    project, _, result = render(**{'mori.generate': 'true'})
    assert result.returncode and 'mori.namespace' in result.stderr
    assert not (project / 'cabal.project').exists(), 'Missing namespace must fail before writes'
    project, _, result = render(**{'mori.generate': 'true', 'mori.namespace': '../bad'})
    assert result.returncode and not (project / 'cabal.project').exists()
    project, _, result = render(**{'project.name': '../bad'})
    assert result.returncode and not (project / 'cabal.project').exists()
    project, command, result = render(**{'mori.generate': 'false'})
    assert result.returncode == 0
    assert not (project / 'mori.dhall').exists()
    assert not (project / 'nix/redpanda.nix').exists()
    # Existing authored descriptors are protected on first opt-in too.
    path = project / 'mori.dhall'
    path.write_text('-- existing authored descriptor\n')
    result = run(command + ['--var', 'mori.generate=true', '--var', 'mori.namespace=another-org'], project)
    assert path.read_text() == '-- existing authored descriptor\n'
    assert 'keep existing' in (result.stdout + result.stderr).lower()
    broker_project, _, result = render(**{'nix.redpanda': 'true', 'nix.redpanda-console': 'true', 'nix.kafka': 'false'})
    assert result.returncode == 0, result.stderr
    assert 'enableConsole = true' in (broker_project / 'nix/redpanda.nix').read_text()
    interactive('')
    interactive('false')
    interactive('true')
    for answer in ['', 'false', 'true']:
        interactive(answer, agent=True)
    print('PASS Mori inventory/Cabal parity, interactive opt-in/skip, missing identity, opt-out, ownership, broker/PG controls, canonical lock')


def main():
    for name, namespace, context in [('sample-service', 'SampleService', 'contacts'), ('other', 'Other', None)]:
        project, command, result = render(name, namespace, **({'keiro.context': context} if context else {}))
        assert result.returncode == 0, result.stderr
        variables = {'project.name': name, 'project.namespace': namespace,
                     'project.description': 'A bootstrap smoke test'}
        if context:
            variables['keiro.context'] = context
        assert len(list(project.glob('*/*.cabal'))) == 6
        for role in ['core', 'api', 'migrations', 'workers', 'server', 'client']:
            cabal = project / f'{name}-{role}' / f'{name}-{role}.cabal'
            contents = cabal.read_text()
            assert f'name: {name}-{role}' in contents
            assert '{{' not in contents
            if role in ['core', 'migrations']:
                assert f', {name}-' not in contents
            if role in ['workers', 'client']:
                assert f', {name}-server' not in contents
            run(['cabal', 'check'], cabal.parent)
        workspace = (project / f'domain/{name}.keiro-workspace').read_text()
        assert f'module {namespace}\n' in workspace
        assert f'runtime-package {name}-core' in workspace
        assert f'spec {name}/shared.keiro' in workspace
        assert f'context {context or name}' in (project / f'domain/{name}/shared.keiro').read_text()
        assert f'service {name}' in workspace
        assert 'packages.default =' not in (project / 'nix/haskell.nix').read_text()
        assert 'postgres:' in (project / 'process-compose.yaml').read_text()
        run(['just', '--list'], project)
        just_dump = run(['just', '--dump'], project).stdout
        assert 'create-database:' in just_dump and f'domain/{name}.keiro-workspace' in just_dump
        for path in [project / 'README.md', project / 'docs/bootstrap-keiro.md', project / 'justfile']:
            assert '{{' not in path.read_text(), path
        # Exercise the process-compose entry point without touching a live database.
        mocks = project / '.artifacts/mock-bin'
        mocks.mkdir(parents=True)
        psql = mocks / 'psql'
        psql.write_text('#!/bin/sh\ncat > "$BOOTSTRAP_SQL_CAPTURE"\nprintf "%s\\n" "$BOOTSTRAP_DB_EXISTS"\n')
        createdb = mocks / 'createdb'
        createdb.write_text('#!/bin/sh\nprintf "%s\\n" "$@" > "$BOOTSTRAP_CREATEDB_CAPTURE"\n')
        psql.chmod(0o755)
        createdb.chmod(0o755)
        sql = project / '.artifacts/query.sql'
        created = project / '.artifacts/createdb.args'
        env = dict(os.environ, PATH=str(mocks) + os.pathsep + os.environ['PATH'],
                   PGDATABASE=name, BOOTSTRAP_SQL_CAPTURE=str(sql),
                   BOOTSTRAP_CREATEDB_CAPTURE=str(created), BOOTSTRAP_DB_EXISTS='')
        subprocess.run(['just', 'create-database'], cwd=project, env=env, check=True, capture_output=True)
        assert "datname = :'db'" in sql.read_text()
        assert created.read_text().splitlines() == ['--', name]
        created.unlink()
        env['BOOTSTRAP_DB_EXISTS'] = '1'
        subprocess.run(['just', 'create-database'], cwd=project, env=env, check=True, capture_output=True)
        assert not created.exists(), 'Existing database must not be recreated'
        debug = ['seihou', 'agent', '--debug', 'run', 'haskell-keiro-service', '--no-baseline']
        for key, value in variables.items():
            debug += ['--var', f'{key}={value}']
        prompt = run(debug, project).stdout
        assert 'docs/bootstrap-keiro.md' in prompt and namespace in prompt
        before = snapshot(project)
        run(command, project)
        assert snapshot(project) == before, 'Repeated generation changed files'
        readme = project / 'README.md'
        readme.write_text(readme.read_text() + '\nUser-owned implementation notes.\n')
        edited = readme.read_text()
        result = run(command + ['--force'], project)
        assert readme.read_text() == edited, 'Reapplication overwrote a user edit'
        assert 'keep settled' in (result.stdout + result.stderr).lower(), result.stdout
        readme.unlink()
        run(command + ['--force'], project)
        assert not readme.exists(), 'Settled seed deletion must be preserved'
        print(f'PASS {name}: six packages, workspace, Nix composition, just recipes, rerun, edit protection')
        print(f'Build fixture: {project}')

    extra_checks()
    registry = json.loads(run(['dhall-to-json', '--file', str(ROOT / 'seihou-registry.dhall')], ROOT).stdout)
    assert any(m['name'] == 'haskell-keiro-project' for m in registry['modules'])
    run(['dhall', '--file', str(ROOT / 'mori.dhall')], ROOT)
    print('PASS registry and Mori descriptors')


if __name__ == "__main__":
    main()
