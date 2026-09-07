#!/usr/bin/env python3
"""Exercise actual Seihou rendering without modifying user module installations."""
import hashlib
import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[1]

def run(args, cwd, success=True):
    result = subprocess.run(args, cwd=cwd, text=True, capture_output=True, stdin=subprocess.DEVNULL)
    if success and result.returncode:
        raise AssertionError(f'{args}:\n{result.stdout}\n{result.stderr}')
    return result

def snapshot(project):
    return {str(p.relative_to(project)): hashlib.sha256(p.read_bytes()).hexdigest()
            for p in project.rglob('*') if p.is_file() and '.seihou' not in p.parts}

for name, namespace, context in [('sample-service', 'SampleService', 'contacts'), ('other', 'Other', 'other-domain')]:
    project = Path(tempfile.mkdtemp(prefix='seihou-keiro-bootstrap-'))
    modules = project / '.seihou/modules'
    modules.mkdir(parents=True)
    for module in ['haskell-keiro-project', 'nix-haskell-flake']:
        shutil.copytree(ROOT / 'modules/haskell' / module, modules / module)
    shutil.copytree(ROOT / 'blueprints/haskell-keiro-service', modules / 'haskell-keiro-service')
    run(['seihou', 'validate-blueprint', str(modules / 'haskell-keiro-service')], project)
    variables = {'project.name': name, 'project.namespace': namespace,
                 'project.description': 'A bootstrap smoke test', 'keiro.context': context,
                 'project.author': 'Test Author', 'project.maintainer': 'test@example.com',
                 'project.copyright-year': '2026', 'haskell.index-state': '2026-09-07T00:00:00Z',
                 'ghc.version': 'ghc9124', 'nix.treefmt': 'true', 'nix.pre-commit': 'true',
                 'nix.redis': 'false', 'nix.clickhouse': 'false', 'nix.kafka': 'false'}
    command = ['seihou', 'run', 'haskell-keiro-project', '--no-save-prompted', '--no-commands']
    for key, value in variables.items():
        command += ['--var', f'{key}={value}']
    run(command, project)
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
    workspace = (project / f'domain/{context}.keiro-workspace').read_text()
    assert f'module {namespace}\n' in workspace
    assert f'runtime-package {name}-core' in workspace
    assert f'spec {context}/shared.keiro' in workspace
    assert 'packages.default =' not in (project / 'nix/haskell.nix').read_text()
    assert 'postgres:' in (project / 'process-compose.yaml').read_text()
    run(['just', '--list'], project)
    just_dump = run(['just', '--dump'], project).stdout
    assert 'create-database:' in just_dump and f'domain/{context}.keiro-workspace' in just_dump
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
    result = run(command, project, success=False)
    # The CLI may report a protected file without failing the whole command.
    assert readme.read_text() == edited, 'Reapplication overwrote a user edit'
    assert 'conflict' in (result.stdout + result.stderr).lower(), result.stdout
    print(f'PASS {name}: six packages, workspace, Nix composition, just recipes, rerun, edit protection')
    print(f'Build fixture: {project}')

registry = json.loads(run(['dhall-to-json', '--file', str(ROOT / 'seihou-registry.dhall')], ROOT).stdout)
assert any(m['name'] == 'haskell-keiro-project' for m in registry['modules'])
run(['dhall', '--file', str(ROOT / 'mori.dhall')], ROOT)
print('PASS registry and Mori descriptors')
