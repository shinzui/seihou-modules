#!/usr/bin/env python3
"""Qualify the pinned generator, real Seihou composition, and independent ESM consumers.

Uses temporary project-local module copies; never changes the personal module cache.
The compiler is the shared shell's TypeScript 7+, with no compiler downloaded by this test.
"""
import argparse
import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[1]
FIXTURE = ROOT / 'scripts/fixtures/openapi-typescript-client'
MODULE = ROOT / 'modules/typescript/openapi-typescript-client'
BASE = ROOT / 'modules/typescript/nix-bun-flake'
SYSTEMS = ['aarch64-darwin', 'aarch64-linux', 'x86_64-linux']


def run(args, cwd, succeeds=True, env=None, input=None):
    if args[0] == 'seihou':
        args = [os.environ.get('SEIHOU', 'seihou'), *args[1:]]
    result = subprocess.run(args, cwd=cwd, text=True, capture_output=True, env=env, input=input)
    if (result.returncode == 0) != succeeds:
        raise AssertionError(f'{args}: exit {result.returncode}\n{result.stdout}\n{result.stderr}')
    return result.stdout + result.stderr


def task(project, name, succeeds=True):
    return run(['bun', 'run', name], project, succeeds)


def consumer(project, work, revision=False):
    consumer = work / 'consumer'
    consumer.mkdir(exist_ok=True, parents=True)
    run(['npm', 'pack', '--ignore-scripts', '--pack-destination', str(consumer)], project)
    archive = next(consumer.glob('*.tgz'))
    (consumer / 'package.json').write_text('{"name":"consumer","type":"module","private":true}')
    run(['bun', 'add', '--minimum-release-age', '0', str(archive)], consumer)
    package = json.loads((project / 'package.json').read_text())['name']
    (consumer / 'test.ts').write_text(f'''import {{ make }} from {json.dumps(package)}
const api = make({{ baseUrl: 'http://localhost' }})
void api.getWidget('id')
// @ts-expect-error path is required
void api.getWidget()
// @ts-expect-error required request fields
void api.createWidget({{}})
async function example() {{
  const response = await api.getWidget('id')
  if (response.status === 404) {{
    const message: string = response.data.message
    // @ts-expect-error wrong status branch
    response.data.id
    return message
  }}
}}
void example
''')
    if revision:
        with (consumer / 'test.ts').open('a') as handle:
            handle.write('''\nasync function changedSchema() {
  const result = await api.getWidget('id')
  if (result.status === 200) {
    const revision: number | undefined = result.data.revision
    // @ts-expect-error revised schema retains a numeric field
    const wrong: string = result.data.revision
    return revision
  }
}
void changedSchema
''')
    (consumer / 'tsconfig.json').write_text(json.dumps({'compilerOptions': {
        'strict': True, 'exactOptionalPropertyTypes': True, 'noUncheckedIndexedAccess': True,
        'module': 'NodeNext', 'moduleResolution': 'NodeNext', 'target': 'ES2022',
        'lib': ['ES2022', 'DOM', 'DOM.Iterable'], 'types': [], 'skipLibCheck': False,
        'noEmit': True}, 'files': ['test.ts']}))
    # Run the same checked compiler selector in this independent directory.
    print(run(['bun', str(project / 'scripts/compiler.ts'), '--noEmit'], consumer).strip(), flush=True)
    assert not (consumer / 'node_modules/orval').exists()
    assert not (consumer / 'node_modules/bun-types').exists()
    (consumer / 'request.mjs').write_text(f'''import {{ createServer }} from 'node:http'
import {{ make }} from {json.dumps(package)}
const server = createServer((req, res) => {{
  res.writeHead(404, {{'content-type': 'application/json'}})
  res.end(JSON.stringify({{message: 'Not found'}}))
}})
await new Promise(resolve => server.listen(0, '127.0.0.1', resolve))
try {{
  const api = make({{baseUrl: `http://127.0.0.1:${{server.address().port}}`}})
  const result = await api.getWidget('missing')
  if (result.status !== 404 || result.data.message !== 'Not found') throw new Error('Bad package response')
  console.log('Independent package request passed.')
}} finally {{ await new Promise(resolve => server.close(resolve)) }}
''')
    for runtime in ['node', 'bun']:
        run([runtime, 'request.mjs'], consumer)
    contents = run(['tar', '-tzf', str(archive)], consumer).splitlines()
    assert all(p == 'package/package.json' or p.startswith('package/dist/') or p in ['package/README.md', 'package/LICENSE'] for p in contents), contents


def qualify(work):
    for name in ['orval.config.ts', 'scripts/compiler.ts', 'src/client.ts', 'src/index.ts',
                 'redocly.yaml', 'tsconfig.json', 'tsconfig.build.json']:
        assert (FIXTURE / name).read_bytes() == (MODULE / 'files' / name).read_bytes(), name
    assert (FIXTURE / 'scripts/generate.ts').read_text().replace('const schema = "openapi.json"', 'const schema = "{{openapi.schema}}"') == (MODULE / 'files/scripts/generate.ts.tpl').read_text()
    project = work / 'toolchain'
    shutil.copytree(FIXTURE, project)
    run(['bun', 'install', '--frozen-lockfile', '--minimum-release-age', '0'], project)
    task(project, 'generate')
    task(project, 'typecheck')
    task(project, 'test')
    task(project, 'build')
    task(project, 'generated-check')
    consumer(project, work)
    assert not json.loads((project / 'package.json').read_text()).get('dependencies'), 'Client has no runtime dependencies'
    generated = project / 'src/generated/api.ts'
    original = generated.read_bytes()
    generated.write_bytes(original + b'\n// stale\n')
    task(project, 'generated-check', False)
    assert generated.read_bytes() == original + b'\n// stale\n', 'Native outdated check must not repair output'
    task(project, 'generate')
    assert generated.read_bytes() == original
    generated.unlink()
    task(project, 'generated-check', False)
    task(project, 'generate')
    schema = project / 'openapi.json'
    original_schema = schema.read_bytes()
    schema.write_text('{"openapi":"invalid"}')
    task(project, 'generate', False)
    assert generated.read_bytes() == original, 'Invalid document replaced the client'
    schema.write_bytes(original_schema)
    old = work / 'old-compiler'
    old.mkdir()
    (old / 'tsc').write_text('#!/bin/sh\necho "Version 6.0.3"\n')
    (old / 'tsc').chmod(0o755)
    env = {**os.environ, 'PATH': str(old) + os.pathsep + os.environ['PATH']}
    assert 'TypeScript 7+ is required' in run(['bun', 'scripts/compiler.ts', '--noEmit'], project, False, env)
    print('OpenAPI client toolchain qualification passed.', flush=True)


def application(project, schema='openapi.yaml', force=False, variables=None, succeeds=True):
    args = ['seihou', 'run', 'openapi-typescript-client', '--no-save-prompted', '--no-commands',
            '--var', 'project.name=example-api-client', '--var', 'project.description=Example API client',
            '--var', f'openapi.schema={schema}']
    if force: args.append('--force')
    for name, value in (variables or {}).items():
        args.extend(['--var', f'{name}={value}'])
    return run(args, project, succeeds, input='')


def copy_modules(project):
    project.mkdir(parents=True, exist_ok=True)
    for name in ['nix-bun-flake', 'openapi-typescript-client']:
        shutil.copytree(ROOT / 'modules/typescript' / name, project / '.seihou/modules' / name)
        if os.environ.get('SEIHOU_SCHEMA_PACKAGE'):
            descriptor = project / '.seihou/modules' / name / 'module.dhall'
            text = descriptor.read_text()
            text = 'let S = ' + os.environ['SEIHOU_SCHEMA_PACKAGE'] + '\n' + text[text.index('in '):]
            descriptor.write_text(text)


def evaluate(project, systems=SYSTEMS):
    for system in systems:
        prefix = f'.#devShells.{system}.default'
        run(['nix', 'eval', '--no-write-lock-file', '--raw', prefix + '.drvPath'], project)
        names = json.loads(run(['nix', 'eval', '--no-write-lock-file', '--json', prefix + '.nativeBuildInputs',
                              '--apply', 'xs: map (p: p.name) xs'], project))
        assert any(name.startswith('typescript-7.') for name in names), names
    assert (project / 'flake.lock').read_bytes() == (BASE / 'files/flake.lock').read_bytes()


def mori_render(work):
    variables = {'mori.generate': 'true', 'mori.namespace': 'example',
                 'mori.source-namespace': 'provider', 'mori.source-project': 'widgets-service'}
    for index, schema in enumerate(['openapi.yaml', 'spec/api.json']):
        project = work / f'mori-{index}'
        copy_modules(project)
        if schema != 'openapi.yaml':
            (project / schema).parent.mkdir()
            (project / schema).write_bytes((FIXTURE / 'openapi.json').read_bytes())
        application(project, schema, variables=variables)
        run(['mori', 'validate'], project)
        data = json.loads(run(['dhall-to-json', '--file', 'mori.dhall'], project))
        assert data['project']['name'] == 'example-api-client'
        assert data['project']['namespace'] == 'example'
        assert data['project']['type'] == 'Client'
        assert data['project']['language'] == 'TypeScript'
        package, = data['packages']
        assert package['name'] == 'example-api-client'
        assert package['type'] == 'Client' and package['language'] == 'TypeScript'
        assert package['runtime'] == {'deployable': False, 'exposesApi': False}
        source = package['apiSource']
        assert source['project'] == 'provider/widgets-service'
        assert source['projectRef']['namespace'] == 'provider'
        assert source['projectRef']['name'] == 'widgets-service'
        assert source.get('specPath') is None, 'API source paths belong to the producer, not the local generator input'
        assert all(repo.get('localPath') is None for repo in data['repos'])
        assert source.get('api') is None
        assert data['dependencies'] == ['provider/widgets-service']
        assert data['dependencyRefs'] == [source['projectRef']]
        assert data['apis'] == [], 'Client must not claim ownership of the provider API'
        path = project / 'mori.dhall'
        authored = path.read_text() + '\n-- project-owned metadata\n'
        path.write_text(authored)
        changed = {**variables, 'mori.source-project': 'another-service'}
        application(project, schema, force=True, variables=changed)
        run(['seihou', 'update', 'openapi-typescript-client', '--no-commands', '--force', '--json'], project)
        application(project, schema, variables={'mori.generate': 'false'})
        assert path.read_text() == authored, 'Rerun/update/opt-out changed authored inventory'
        run(['seihou', 'remove', 'openapi-typescript-client'], project)
        assert path.read_text() == authored, 'Removal deleted project inventory'

    for missing in ['mori.namespace', 'mori.source-namespace', 'mori.source-project']:
        project = work / f'missing-{missing}'
        copy_modules(project)
        output = application(project, variables={k: v for k, v in variables.items() if k != missing}, succeeds=False)
        assert missing in output, output
        assert not (project / 'package.json').exists(), 'Missing metadata must fail before writes'
    for name in ['mori.namespace', 'mori.source-namespace', 'mori.source-project']:
        project = work / f'invalid-{name}'
        copy_modules(project)
        output = application(project, variables={**variables, name: '../bad'}, succeeds=False)
        assert 'validation' in output.lower() or 'invalid' in output.lower(), output
        assert not (project / 'package.json').exists()

    project = work / 'mori-existing'
    copy_modules(project)
    application(project)
    assert not (project / 'mori.dhall').exists(), 'Default application must skip Mori'
    path = project / 'mori.dhall'
    authored = '-- existing project inventory\n'
    path.write_text(authored)
    application(project, force=True, variables=variables)
    assert path.read_text() == authored, 'First opt-in overwrote existing inventory'
    path.unlink()
    application(project, force=True, variables=variables)
    assert not path.exists(), 'Rerun recreated intentionally deleted inventory'
    print('OpenAPI client Mori inventory rendering passed.', flush=True)


def render(work, bootstrap=False):
    project = work / 'rendered'
    copy_modules(project)
    sentinel = b'{ ... }: { } # unmanaged client fixture\n'
    (project / 'flake.module.nix').write_bytes(sentinel)
    application(project)
    assert (project / 'flake.lock').read_bytes() == (BASE / 'files/flake.lock').read_bytes()
    assert not (project / 'nix/pre-commit.nix').exists()
    assert not (project / 'nix/bun2nix-module.nix').exists()
    assert './nix/openapi-typescript-client.nix' in (project / 'flake.nix').read_text()
    assert 'watch_file nix/openapi-typescript-client.nix' in (project / '.envrc').read_text()
    manifest = json.loads((project / '.seihou/manifest.json').read_text())
    assert not any(path.startswith(('src/generated/', 'dist/')) or path == 'bun.lock' for path in manifest['files'])
    evaluate(project)
    print(run(['nix', 'develop', '--command', 'bash', '-c',
               'command -v node && node --version && tsc --version && bun --version'], project).strip(), flush=True)
    if bootstrap:
        output = run(['nix', 'develop', '--command', 'bash', '-c',
                      'bun install --minimum-release-age 0 && just generate && just check'], project)
        print(output[-1800:], flush=True)
        run(['bun', 'install', '--frozen-lockfile', '--minimum-release-age', '0'], project)
        consumer(project, work / 'scaffold-package')
    # Edit every base-overlapping seed and delete both an overlapping and a client-only seed.
    seeds = ['package.json', 'tsconfig.json', '.oxlintrc.json', '.oxfmtrc.json', 'justfile',
             'tsconfig.build.json', 'src/client.ts', 'README.md', 'scripts/generate.ts']
    for path in seeds:
        file = project / path
        if path in ['tsconfig.json', 'tsconfig.build.json']:
            file.unlink()
        else:
            file.write_bytes(file.read_bytes() + b'\n')
    expected = {path: (project / path).read_bytes() if (project / path).exists() else None for path in seeds}
    for force in [False, True]:
        application(project, force=force)
        output = run(['seihou', 'update', 'openapi-typescript-client', '--no-commands', '--json',
                      *(['--force'] if force else [])], project)
        for path, data in expected.items():
            actual = (project / path).read_bytes() if (project / path).exists() else None
            assert actual == data, f'Seed changed on rerun/update: {path}\n{output}'
    assert (project / 'flake.module.nix').read_bytes() == sentinel
    # Actual command products are project-owned and survive removal.
    for path in ['src/generated/sentinel.ts', 'dist/sentinel.js', 'bun.lock']:
        file = project / path
        if not file.exists():
            file.parent.mkdir(parents=True, exist_ok=True)
            file.write_text('project-owned\n')
    products = {path: (project / path).read_bytes() for path in ['src/generated/sentinel.ts', 'dist/sentinel.js', 'bun.lock']}
    # A separate root keeps the base alive. Its default binding must survive client retirement.
    coowner = project / '.seihou/modules/fixture-client-coowner'
    (coowner / 'files').mkdir(parents=True)
    schema_import = (project / '.seihou/modules/nix-bun-flake/module.dhall').read_text().split('in ', 1)[0]
    (coowner / 'module.dhall').write_text(schema_import + '''in S.Module::{
      , name = "fixture-client-coowner"
      , version = Some "0.1.0"
      , dependencies = [ S.Dependency::{ module = "nix-bun-flake", vars = [ { name = "nix.pre-commit", value = "false" }, { name = "bun.starter-files", value = "false" }, { name = "nix.package-module", value = "nix/openapi-typescript-client.nix" } ] } ]
      , steps = [] : List S.Step.Type
      }''')
    run(['seihou', 'run', 'fixture-client-coowner', '--no-save-prompted', '--no-commands',
         '--var', 'project.name=example-api-client', '--var', 'project.description=Example API client'], project)
    preview = run(['seihou', 'remove', 'openapi-typescript-client', '--dry-run'], project)
    assert 'openapi-typescript-client' in preview
    run(['seihou', 'remove', 'openapi-typescript-client'], project)
    for path, data in {**expected, **products, 'flake.module.nix': sentinel}.items():
        actual = (project / path).read_bytes() if (project / path).exists() else None
        assert actual == data, f'Removal changed seed/product: {path}'
    assert (project / 'nix/bun.nix').exists()
    assert not (project / 'nix/openapi-typescript-client.nix').exists()
    watched = run(['bash', '-c', 'watch_file() { printf "%s\\n" "$@"; }; use() { :; }; source_env_if_exists() { :; }; shellHook=""; source .envrc'], project)
    assert 'nix/openapi-typescript-client.nix' not in watched.splitlines(), 'Surviving base watches a removed module'
    names = run(['nix', 'eval', '--no-write-lock-file', '--json', '.#devShells.aarch64-darwin.default.nativeBuildInputs', '--apply', 'xs: map (p: p.name) xs'], project)
    assert 'nodejs-' not in names, 'Surviving shell still imports the removed client tool module'
    evaluate(project)
    run(['seihou', 'remove', 'nix-bun-flake', '--force'], project, input='y\n')
    for path, data in expected.items():
        actual = (project / path).read_bytes() if (project / path).exists() else None
        assert actual == data, f'Later base removal changed a retired client seed: {path}'
    # Last-root removal must preserve child seeds despite inherited base removal steps.
    last = work / 'last-root'
    copy_modules(last)
    application(last)
    package = (last / 'package.json').read_bytes()
    run(['seihou', 'remove', 'openapi-typescript-client', '--dry-run'], last)
    run(['seihou', 'remove', 'openapi-typescript-client'], last)
    assert (last / 'package.json').read_bytes() == package
    assert (last / 'tsconfig.json').exists() and (last / 'justfile').exists()
    assert not (last / 'flake.nix').exists()
    # Custom schema paths are validated by Seihou and do not get an invented schema/example test.
    custom = work / 'custom-path'
    copy_modules(custom)
    (custom / 'spec').mkdir()
    (custom / 'spec/api.json').write_bytes((FIXTURE / 'openapi.json').read_bytes())
    application(custom, 'spec/api.json')
    assert not (custom / 'openapi.yaml').exists()
    assert not (custom / 'tests/client.test.ts').exists()
    assert 'const schema = "spec/api.json"' in (custom / 'scripts/generate.ts').read_text()
    for invalid in ['/tmp/spec.json', '../api.json', 'x/../api.json', 'x spec.json', 'x;echo.json', 'x$(echo).yaml', 'x.yml/../../z.json']:
        output = run(['seihou', 'run', 'openapi-typescript-client', '--no-save-prompted', '--no-commands',
                      '--var', 'project.name=example-api-client', '--var', 'project.description=Example',
                      '--var', f'openapi.schema={invalid}'], custom, False)
        assert 'validation' in output.lower() or 'invalid' in output.lower(), output
    print('OpenAPI client rendering passed.', flush=True)

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--toolchain-only', action='store_true')
    parser.add_argument('--render-only', action='store_true')
    parser.add_argument('--mori-only', action='store_true', help='Qualify optional Mori inventory without the client toolchain or Nix evaluations')
    args = parser.parse_args()
    with tempfile.TemporaryDirectory(prefix='openapi-client-acceptance-') as temp:
        work = Path(temp)
        if not args.toolchain_only or args.mori_only:
            mori_render(work)
        if args.mori_only:
            return
        if not args.render_only:
            qualify(work)
        if not args.toolchain_only:
            render(work, bootstrap=not args.render_only)
        if not args.render_only and not args.toolchain_only:
            print('OpenAPI client bootstrap passed.', flush=True)


if __name__ == '__main__':
    main()
