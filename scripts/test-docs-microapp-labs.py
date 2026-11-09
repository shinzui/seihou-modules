#!/usr/bin/env python3
"""Qualify recipe closure and generated Applications through released Nagare v0.16.2 offline."""
import json
import os
from pathlib import Path
import shutil
import tempfile

from docs_microapp_test_support import ROOT, render, run

PLAN = 'docs/plans/13-bootstrap-documentation-microapps-with-tanstack-start-and-nagare-recipes.md'


def git_commit(project):
    run(['git', 'init', '-q'], project)
    run(['git', 'add', '-A'], project)
    run(['git', '-c', 'user.name=Fixture', '-c', 'user.email=fixture@example.invalid', 'commit', '-qm',
         'test: prepare recipe fixture\n\nExecPlan: ' + PLAN], project)


def install_closure(work):
    registry = work / 'registry'
    registry.mkdir()
    for source in ['modules/typescript/docs-microapp', 'modules/typescript/nix-bun-flake',
                   'modules/cloud/nagare-docs-config', 'recipes/docs-microapp-labs']:
        shutil.copytree(ROOT / source, registry / source)
    # The real public catalog, restricted to entries copied into this disposable registry.
    (registry / 'seihou-registry.dhall').write_text('''{ repoName = "fixture-registry", repoDescription = None Text, modules = [
{ name = "docs-microapp", path = "modules/typescript/docs-microapp", version = Some "0.1.0", description = None Text, tags = [] : List Text },
{ name = "nix-bun-flake", path = "modules/typescript/nix-bun-flake", version = Some "0.6.1", description = None Text, tags = [] : List Text },
{ name = "nagare-docs-config", path = "modules/cloud/nagare-docs-config", version = Some "0.1.0", description = None Text, tags = [] : List Text } ],
recipes = [ { name = "docs-microapp-labs", path = "recipes/docs-microapp-labs", version = Some "0.1.0", description = None Text, tags = [] : List Text } ], blueprints = [] : List { name : Text, path : Text, version : Optional Text, description : Optional Text, tags : List Text }, prompts = [] : List { name : Text, path : Text, version : Optional Text, description : Optional Text, tags : List Text } }
''')
    git_commit(registry)
    consumer = work / 'installed-consumer'
    consumer.mkdir()
    environment = {**os.environ, 'XDG_CONFIG_HOME': str(work / 'config')}
    run(['seihou', 'install', str(registry), '--module', 'docs-microapp-labs'], consumer, env=environment)
    installed = work / 'config/seihou/installed'
    assert {p.name for p in installed.iterdir()} == {'docs-microapp-labs', 'docs-microapp', 'nagare-docs-config', 'nix-bun-flake'}
    run(['seihou', 'run', 'docs-microapp-labs', '--no-commands', '--no-save-prompted',
         '--var', 'project.name=installed-docs', '--var', 'project.description=Installed docs',
         '--var', 'docs.site-name=Installed', '--var', 'nagare.service-name=reader',
         '--var', 'nagare.domain=reader.example.test'], consumer, env=environment)
    assert (consumer / 'nagare/Config.hs').exists() and (consumer / 'flake.lock').exists()
    print('Recipe install: acquired and rendered the four-artifact dependency closure in an isolated cache.', flush=True)


def check_pair(work, nagare, project_name, service_name, domain):
    project = work / project_name
    render(project, 'docs-microapp-labs', {'project.name': project_name, 'nagare.service-name': service_name, 'nagare.domain': domain})
    environment = {**os.environ, 'HOME': str(work / 'empty-home'), 'XDG_CONFIG_HOME': str(work / 'empty-config'), 'NAGARE_CONTEXT': '', 'DOCS_IMAGE_TAG': 'git-123456789abc'}
    summary = json.loads(run([nagare, 'app', 'check', '--file', 'nagare/Config.hs'], project, env=environment))
    assert summary == {'kind': 'application', 'name': service_name, 'namespace': 'personal', 'service': True, 'workers': 0, 'databases': 0, 'brokers': 0, 'tasks': 0}, summary
    source = (project / 'nagare/Config.hs').read_text()
    # Instrument the same generated program, compiled by app check's released packaged runtime,
    # to retain exactly the Application bytes also emitted to the real loader.
    probe = source.replace('import Nagare.Dsl.Config (emitApplication)', 'import Nagare.Dsl.Config (emitApplication, encodeApplication)\nimport qualified Data.ByteString.Lazy as LBS')
    probe = probe.replace('emitApplication (application', '(\\app -> LBS.writeFile "emitted.json" (encodeApplication app) >> emitApplication app) (application')
    (project / 'nagare/Probe.hs').write_text(probe)
    run([nagare, 'app', 'check', '--file', 'nagare/Probe.hs'], project, env=environment)
    emitted = json.loads((project / 'emitted.json').read_text())
    assert emitted['name'] == service_name and emitted['namespace'] == 'personal' and emitted['image'] == project_name, emitted
    service = emitted['service']
    assert service['name'] == service_name and service['image'] == project_name and service['port'] == 8080, service
    assert service['domains'] == [{'canonical': True, 'domain': domain, 'tls': {'mode': 'automatic'}}], service
    assert emitted['access'] == service['access'] == {'audience': None, 'permission': 'access', 'role': 'protected'}, emitted
    assert service['scaleMin'] == 0 and service['scaleMax'] == 2, service
    assert 'git-123456789abc' in json.dumps(service['build']) and '/healthz' in json.dumps(service['healthCheck']), service
    for tag in [None, 'latest', 'bad tag', 'git-123', 'git-ABCDEF123456']:
        env = dict(environment)
        if tag is None:
            env.pop('DOCS_IMAGE_TAG')
        else:
            env['DOCS_IMAGE_TAG'] = tag
        failure = run([nagare, 'app', 'check', '--file', 'nagare/Config.hs'], project, succeeds=False, env=env)
        assert 'DOCS_IMAGE_TAG' in failure, failure
    authored = source + '\n-- project-owned edit\n'
    (project / 'nagare/Config.hs').write_text(authored)
    render(project, 'docs-microapp-labs', {'project.name': project_name, 'nagare.service-name': 'changed-name', 'nagare.domain': 'changed.example.test'})
    run(['seihou', 'update', 'docs-microapp-labs', '--no-commands', '--json', '--include-shared-owners'], project)
    assert (project / 'nagare/Config.hs').read_text() == authored
    print(f'Offline Nagare: {service_name} at {domain}, independent image {project_name}; emitted policy/health/tag and seed ownership verified.', flush=True)


def main():
    with tempfile.TemporaryDirectory(prefix='docs-labs-acceptance-') as directory:
        work = Path(directory)
        install_closure(work)
        nagare = os.environ.get('NAGARECTL')
        if not nagare:
            link = work / 'nagare-runtime'
            run(['nix', 'build', 'github:shinzui/nagare/v0.16.2#nagarectl', '--out-link', str(link)], work)
            nagare = str(link / 'bin/nagarectl')
        check_pair(work, nagare, 'handbook-web', 'handbook', 'handbook.labs.example.test')
        check_pair(work, nagare, 'reference-web', 'reference-web', 'reference.example.test')
        for key, value in [('nagare.service-name', 'Bad_Name'), ('nagare.namespace', 'a'*64), ('nagare.domain', 'https://example.test'), ('nagare.domain', 'a..test'), ('nagare.domain', 'a.test;echo bad')]:
            project = work / 'invalid'
            try:
                render(project, 'docs-microapp-labs', {'nagare.service-name': 'valid', 'nagare.domain': 'valid.example.test', key: value})
            except AssertionError as error:
                assert 'validation' in str(error).lower() or 'pattern' in str(error).lower(), error
            else:
                raise AssertionError(f'Invalid input accepted: {key}={value}')
        oversized = work / 'oversized'
        render(oversized, 'docs-microapp-labs', {'nagare.service-name': 'valid', 'nagare.domain': '.'.join(['a'*63]*4)})
        environment = {**os.environ, 'HOME': str(work / 'empty-home'), 'XDG_CONFIG_HOME': str(work / 'empty-config'), 'DOCS_IMAGE_TAG': 'git-123456789abc'}
        assert 'domain too long' in run([nagare, 'app', 'check', '--file', 'nagare/Config.hs'], oversized, succeeds=False, env=environment)
        plain = work / 'plain'
        render(plain)
        assert not (plain / 'nagare').exists()
    print('Docs microapp Labs acceptance passed without a context or provider access.', flush=True)


if __name__ == '__main__':
    main()
