#!/usr/bin/env python3
"""Real source acquisition and local registration, isolated from shared registries.

Requires Seihou 0.15, Mori 7.2, its matching mori-migrations, PostgreSQL tools,
dhall-to-json and Git. MORI_BIN / MORI_MIGRATIONS select released executables.
The script always starts its own PostgreSQL cluster and overrides connection settings.
"""
from contextlib import contextmanager
import importlib.util
import json
import os
from pathlib import Path
import shutil
import socket
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[1]
EXTERNAL = 'https://github.com/shinzui/agent-seihou.git'
PLAN = 'docs/plans/14-add-a-containerized-fumadocs-project-recipe-with-technical-writing-skills-and-mori-registration.md'


def run(args, cwd, env=None, succeeds=True, input_text=None):
    result = subprocess.run([str(arg) for arg in args], cwd=cwd, env=env, capture_output=True, text=True, input=input_text)
    if (result.returncode == 0) != succeeds:
        raise AssertionError(f'{args}: exit {result.returncode}\n{result.stdout}\n{result.stderr}')
    return result.stdout + (result.stderr if not succeeds else '')


def commit(path):
    run(['git', 'init', '-q', '-b', 'master'], path)
    run(['git', 'add', '-A'], path)
    run(['git', '-c', 'user.name=Fixture', '-c', 'user.email=fixture@example.invalid',
         'commit', '-qm', 'test: snapshot recipe registry\n\nExecPlan: ' + PLAN], path)


@contextmanager
def private_registry(work, env):
    data, sockets = work / 'pg', work / 'socket'
    sockets.mkdir()
    with socket.socket() as probe:
        probe.bind(('127.0.0.1', 0))
        port = probe.getsockname()[1]
    run(['initdb', '-D', data, '-A', 'trust', '-U', 'fixture', '--no-locale', '-E', 'UTF8'], work, env)
    run(['pg_ctl', '-D', data, '-l', work / 'postgres.log', '-o',
         f'-F -k {sockets} -p {port} -h 127.0.0.1', '-w', 'start'], work, env)
    try:
        env = {**env, 'MORI_PG_CONNECTION_STRING': f'host={sockets} port={port} dbname=postgres user=fixture',
               'PGHOST': str(sockets), 'PGPORT': str(port), 'PGUSER': 'fixture', 'PGDATABASE': 'postgres',
               'PG_CONNECTION_STRING': f'host={sockets} port={port} dbname=postgres user=fixture'}
        migrations = os.environ.get('MORI_MIGRATIONS', 'mori-migrations')
        run([migrations, 'up'], work, env)
        yield env, data
    finally:
        run(['pg_ctl', '-D', data, '-m', 'immediate', '-w', 'stop'], work, env)


def snapshot_registries(work, agent):
    primary, external = work / 'primary', work / 'external'
    primary.mkdir()
    external.mkdir()
    for path in ['modules/typescript/fumadocs', 'modules/typescript/nix-bun-flake',
                 'modules/mori/docs-mori-bootstrap', 'recipes/fumadocs-project']:
        shutil.copytree(ROOT / path, primary / path)
    for name in ['technical-docs', 'agent-gitignore']:
        shutil.copytree(agent / 'modules' / name, external / 'modules' / name)
    # Use actual catalogs, filtered to the snapshot contents, through Dhall.
    for source, dest, modules, recipes in [
        (ROOT, primary, ['fumadocs', 'nix-bun-flake', 'docs-mori-bootstrap'], ['fumadocs-project']),
        (agent, external, ['technical-docs', 'agent-gitignore'], []),
    ]:
        catalog = json.loads(run(['dhall-to-json', '--file', source / 'seihou-registry.dhall'], ROOT))
        def entries(field, names):
            result = []
            for entry in catalog[field]:
                if entry['name'] in names:
                    result.append('{ name = ' + json.dumps(entry['name']) + ', path = ' + json.dumps(entry['path'])
                                  + ', version = Some ' + json.dumps(entry['version'])
                                  + ', description = None Text, tags = [] : List Text }')
            return '[ ' + ', '.join(result) + ' ]' if result else '[] : List { name : Text, path : Text, version : Optional Text, description : Optional Text, tags : List Text }'
        (dest / 'seihou-registry.dhall').write_text('{ repoName = "fixture", repoDescription = None Text, modules = '
                                                  + entries('modules', modules) + ', recipes = ' + entries('recipes', recipes)
                                                  + ', blueprints = ' + entries('blueprints', []) + ', prompts = ' + entries('prompts', []) + ' }\n')
        commit(dest)
    return primary, external


def render(project, env, name='handbook-web', namespace='writers', source_namespace='products',
           source_project='widget-engine', commands=True, extra=None, succeeds=True):
    project.mkdir(exist_ok=True)
    variables = {'project.name': name, 'project.description': 'Documentation', 'docs.site-name': 'Handbook',
                 'docs.github-user': 'fixture', 'mori.namespace': namespace,
                 'mori.source-namespace': source_namespace, 'mori.source-project': source_project, **(extra or {})}
    args = ['seihou', 'run', 'fumadocs-project', '--no-save-prompted']
    if not commands:
        args.append('--no-commands')
    for key, value in variables.items():
        args += ['--var', f'{key}={value}']
    return run(args, project, env, succeeds)


def helper(project, env, succeeds=True):
    return run(['python3', '.seihou/docs-mori-bootstrap/bootstrap-docs.py'], project, env, succeeds)


def main():
    agent = Path(run(['mori', 'path', 'mori://shinzui/agent-seihou'], ROOT).strip().splitlines()[-1])
    spec = importlib.util.spec_from_file_location('bootstrap', ROOT / 'modules/mori/docs-mori-bootstrap/files/bootstrap-docs.py')
    bootstrap = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(bootstrap)
    with tempfile.TemporaryDirectory(prefix='fumadocs-project-', dir='/tmp') as directory:
        work = Path(directory).resolve()
        primary, external = snapshot_registries(work, agent)
        binaries = work / 'bin'
        binaries.mkdir()
        mori = shutil.which(os.environ.get('MORI_BIN', 'mori'))
        assert mori, 'MORI_BIN must name the released Mori 7.2 executable'
        (binaries / 'mori').symlink_to(mori)
        env = {key: value for key, value in os.environ.items() if not key.startswith(('MORI_', 'PG', 'GIT_CONFIG_'))}
        env.update({'PATH': str(binaries) + os.pathsep + os.environ['PATH'],
                    'HOME': str(work / 'home'), 'XDG_CONFIG_HOME': str(work / 'config'),
                    'XDG_CACHE_HOME': str(work / 'cache'), 'XDG_STATE_HOME': str(work / 'state'),
                    # Retain the descriptor's real source edge; redirect only Git transport.
                    'GIT_CONFIG_COUNT': '1', 'GIT_CONFIG_KEY_0': f'url.{external}.insteadOf', 'GIT_CONFIG_VALUE_0': EXTERNAL})
        Path(env['HOME']).mkdir()
        assert 'v7.2.0.0' in run(['mori', '--version'], work, env)
        with private_registry(work, env) as (env, pgdata):
            # Set up a target whose identity is deliberately unrelated to its directory.
            target = work / 'source-checkout'
            target.mkdir()
            (target / 'content/docs').mkdir(parents=True)
            (target / 'mori.dhall').write_text(bootstrap.manifest('widget-engine', 'Engine', 'products', 'unused', 'unused').replace(
                'dependencyRefs = [ Schema.MoriRef::{ namespace = "unused", name = "unused" } ]',
                'dependencyRefs = [] : List Schema.MoriRef.Type'))
            run(['mori', 'register', '--local', '--path', target], target, env)
            run(['seihou', 'install', primary, '--module', 'fumadocs-project'], work, env)
            installed = work / 'config/seihou/installed'
            assert {p.name for p in installed.iterdir()} == {'fumadocs-project', 'fumadocs', 'nix-bun-flake',
                                                           'technical-docs', 'agent-gitignore', 'docs-mori-bootstrap'}
            consumer = work / 'unrelated-checkout'
            before = run(['mori', 'registry', 'list', '--json'], work, env)
            render(consumer, env, commands=False)
            assert not (consumer / 'mori.dhall').exists()
            assert run(['mori', 'registry', 'list', '--json'], work, env) == before
            for name in ['tech-docs', *['tech-docs-' + form for form in ['tutorial', 'how-to', 'reference', 'explanation', 'walkthrough']]]:
                source = consumer / 'agents/skills' / name
                assert (source / 'SKILL.md').is_file() and (source / 'WRITING-RULES.md').is_file()
                for discovery in ['.claude', '.codex', '.agents']:
                    link = consumer / discovery / 'skills' / name
                    assert link.is_symlink() and link.resolve() == source.resolve()
            assert (consumer / 'nix/fumadocs-container.nix').exists()
            assert (consumer / 'nix/bun2nix-module.nix').exists()
            assert 'nix/fumadocs-container.nix' in (consumer / 'flake.nix').read_text()
            saved = (consumer / '.seihou/manifest.json').read_text()
            origins = {module['name']: module['origin'] for module in json.loads(saved)['modules']}
            assert all(origins[name]['url'] == EXTERNAL for name in ['technical-docs', 'agent-gitignore'])
            assert all(origins[name]['kind'] == 'local' for name in ['fumadocs', 'nix-bun-flake', 'docs-mori-bootstrap'])
            assert (installed / 'docs-mori-bootstrap/files/bootstrap-docs.py').read_bytes() == (primary / 'modules/mori/docs-mori-bootstrap/files/bootstrap-docs.py').read_bytes()
            assert next(module for module in json.loads(saved)['modules'] if module['name'] == 'fumadocs')['version'] == '0.4.0'
            print('Acquisition: two real Git registries, six artifacts, three container bindings and eighteen skill links verified.', flush=True)
            render(consumer, env)
            cfg = json.loads(run(['dhall-to-json', '--file', 'mori.dhall'], consumer, env))
            assert cfg['packages'] == [] and cfg['repos'] == [] and len(cfg['dependencyRefs']) == 1
            assert cfg['docs'][0]['key'] == 'site' and cfg['docs'][0]['location'] == 'content/docs'
            registered = json.loads(run(['mori', 'registry', 'show', 'writers/handbook-web', '--json', '--full'], consumer, env))
            assert registered['path'] == str(consumer)
            assert 'content/docs' in json.dumps(registered['docs'])
            assert 'handbook-web' in run(['mori', 'registry', 'relations', '--to', 'mori://products/widget-engine', '--json'], consumer, env)
            authored = (consumer / 'mori.dhall').read_text().replace('in Schema.Project::{', 'in Schema.Project::{\n    , standards = [ "house-style" ]')
            (consumer / 'mori.dhall').write_text(authored)
            render(consumer, env)
            assert (consumer / 'mori.dhall').read_text() == authored
            second = work / 'another-checkout'
            render(second, env, name='reference-web', namespace='editors')
            rows = json.loads(run(['mori', 'registry', 'list', '--json'], work, env))
            assert len(rows) == 3 and sum(row['name'] == 'handbook-web' for row in rows) == 1
            for label, kwargs, message in [
                ('missing', {'source_project': 'missing'}, 'not registered locally'),
                ('self', {'name': 'widget-engine', 'namespace': 'products'}, 'cannot document itself'),
                ('collision', {}, 'different path'),
                ('invalid', {'namespace': 'Invalid'}, 'validation'),
                ('empty', {'source_project': ''}, 'validation'),
            ]:
                failed = work / label
                output = render(failed, env, succeeds=False, **kwargs)
                assert message in output.lower(), output
                assert not (failed / 'mori.dhall').exists()
            config = consumer / '.seihou/docs-mori-bootstrap/mori.source-project.conf'
            config.write_text('\n')
            assert 'required' in helper(consumer, env, succeeds=False)
            config.write_text('another-project\n')
            assert 'not registered locally' in helper(consumer, env, succeeds=False)
            config.write_text('widget-engine\n')
            bad = authored.replace('name = "widget-engine"', 'name = "wrong-target"')
            (consumer / 'mori.dhall').write_text(bad)
            assert 'required project-level' in helper(consumer, env, succeeds=False)
            assert (consumer / 'mori.dhall').read_text() == bad
            (consumer / 'mori.dhall').write_text(authored.replace('name = "handbook-web"', 'name = "different"'))
            assert 'identity disagrees' in helper(consumer, env, succeeds=False)
            (consumer / 'mori.dhall').write_text('{ invalid Dhall')
            assert 'mori validate' in helper(consumer, env, succeeds=False)
            assert (consumer / 'mori.dhall').read_text() == '{ invalid Dhall'
            (consumer / 'mori.dhall').write_text(authored)
            escaped = 'Quotes " \\ Unicode 雪\n${env:HOME} $(touch SHOULD_NOT_EXIST) `touch SHOULD_NOT_EXIST`\n'
            # Test the helper's raw-value boundary independently of unrelated site JSON templates.
            second_config = second / '.seihou/docs-mori-bootstrap'
            (second / 'mori.dhall').unlink()
            (second_config / 'project.description.conf').write_text(escaped + '\n')
            helper(second, env)
            cfg = json.loads(run(['dhall-to-json', '--file', 'mori.dhall'], second, env))
            assert cfg['project']['description'] == escaped and not (second / 'SHOULD_NOT_EXIST').exists()
            # Fail exactly registration after successful real preflight/validation.
            gate = work / 'gate'
            gate.mkdir()
            (gate / 'mori').write_text('#!/usr/bin/env python3\nimport os,sys\n'
                                       'if sys.argv[1:2] == ["register"]:\n print("fixture registry write unavailable",file=sys.stderr);sys.exit(71)\n'
                                       + 'os.execv(' + repr(mori) + ', [' + repr(mori) + '] + sys.argv[1:])\n')
            (gate / 'mori').chmod(0o755)
            failure_env = {**env, 'PATH': str(gate) + os.pathsep + env['PATH']}
            failure = helper(second, failure_env, succeeds=False)
            assert 'register --local --path' in failure and 'rerun' in failure and (second / 'mori.dhall').exists()
            helper(second, env)
            # A real unavailable service must fail before manifest creation, then recover.
            recover = work / 'recover'
            render(recover, env, name='recovery-web', commands=False)
            run(['pg_ctl', '-D', pgdata, '-m', 'fast', '-w', 'stop'], work, env)
            try:
                failure = helper(recover, {**env, 'PGCONNECT_TIMEOUT': '2'}, succeeds=False)
                assert 'Command failed' in failure and not (recover / 'mori.dhall').exists()
            finally:
                run(['pg_ctl', '-D', pgdata, '-l', work / 'postgres.log', '-o',
                     f'-F -k {env["PGHOST"]} -p {env["PGPORT"]} -h 127.0.0.1', '-w', 'start'], work, env)
            helper(recover, env)
            print('Registry: real Mori 7.2 identities, paths, resolved relations, content discovery, reruns, rejection and recovery verified.', flush=True)
            # Ordinary Fumadocs still keeps its original dependency identity on update.
            plain = work / 'plain'
            plain.mkdir()
            run(['seihou', 'run', 'fumadocs', '--no-commands', '--no-save-prompted', '--var', 'project.name=plain',
                 '--var', 'project.description=Plain', '--var', 'docs.site-name=Plain'], plain, env)
            original = (plain / 'flake.nix').read_bytes()
            run(['seihou', 'update', 'fumadocs', '--no-commands', '--json', '--include-shared-owners'], plain, env)
            assert (plain / 'flake.nix').read_bytes() == original and not (plain / 'nix/fumadocs-container.nix').exists()
            content = (consumer / 'content/docs/index.mdx').read_bytes()
            run(['seihou', 'remove', 'docs-mori-bootstrap', '--force'], consumer, env, input_text='y\n')
            run(['seihou', 'remove', 'fumadocs', '--force'], consumer, env, input_text='y\n')
            assert (consumer / 'mori.dhall').read_text() == authored
            assert (consumer / 'content/docs/index.mdx').read_bytes() == content
            run(['mori', 'registry', 'show', 'writers/handbook-web', '--json'], work, env)
            print('Ownership: removal preserves authored manifest/content and registration; plain Fumadocs updates retain defaults.', flush=True)
    print('Fumadocs project acceptance passed.', flush=True)


if __name__ == '__main__':
    main()
