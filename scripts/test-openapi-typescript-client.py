#!/usr/bin/env python3
"""Qualify the pinned generator, real Seihou composition, and independent ESM consumers.

Uses temporary project-local module copies; never changes the personal module cache.
The compiler is the shared shell's TypeScript 7+, with no compiler downloaded by this test.
"""
import argparse
import copy
import hashlib
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


def run(args, cwd, succeeds=True, env=None):
    result = subprocess.run(args, cwd=cwd, text=True, capture_output=True, env=env)
    if (result.returncode == 0) != succeeds:
        raise AssertionError(f'{args}: exit {result.returncode}\n{result.stdout}\n{result.stderr}')
    return result.stdout + result.stderr


def snapshot(project):
    root = project / 'src/generated'
    return {str(p.relative_to(root)): hashlib.sha256(p.read_bytes()).hexdigest()
            for p in root.rglob('*') if p.is_file()}


def task(project, name, succeeds=True):
    return run(['bun', 'run', name], project, succeeds)


def consumer(project, work):
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
    project = work / 'toolchain'
    shutil.copytree(FIXTURE, project)
    run(['bun', 'install', '--frozen-lockfile', '--minimum-release-age', '0'], project)
    # Keep the observed built-in valid-error failure executable.
    probe_schema = json.loads((project / 'openapi.json').read_text())
    probe_schema['paths'] = {'/widgets/{id}': probe_schema['paths']['/widgets/{id}']}
    del probe_schema['paths']['/widgets/{id}']['get']['responses']['204']
    (project / 'probe.json').write_text(json.dumps(probe_schema))
    (project / 'probe.config.ts').write_text("""import {defineConfig} from 'orval'
export default defineConfig({probe:{input:'probe.json',output:{target:'probe/api.ts',schemas:{path:'probe/models',type:'zod'},client:'fetch',override:{fetch:{runtimeValidation:true,includeHttpResponseReturnType:true,forceSuccessResponse:false,useRuntimeFetcher:true,httpClientInjection:'factory'}}}}})
""")
    run(['bun', 'run', '--no-install', 'orval', '--config', 'probe.config.ts'], project)
    (project / 'probe.ts').write_text("""import {getWidgets} from './probe/api.ts'
try {
 await getWidgets(async () => Response.json({message:'Not found'}, {status:404})).getWidget('missing')
 throw new Error('Built-in behavior changed; requalify the adapter')
} catch (error) { if (error.name !== 'ZodError') throw error }
console.log('Reproduced built-in valid-404 ZodError.')
""")
    print(run(['bun', 'probe.ts'], project).strip(), flush=True)
    task(project, 'generate')
    print(task(project, 'typecheck').strip(), flush=True)
    task(project, 'test')
    task(project, 'build')
    task(project, 'generated-check')
    consumer(project, work)
    # Both expected TypeScript failures and a rejected older compiler are observable.
    old = work / 'old-compiler'
    old.mkdir()
    (old / 'tsc').write_text('#!/bin/sh\necho "Version 6.0.3"\n')
    (old / 'tsc').chmod(0o755)
    env = {**os.environ, 'PATH': str(old) + os.pathsep + os.environ['PATH']}
    output = run(['bun', 'scripts/compiler.ts', '--noEmit'], project, False, env)
    assert 'TypeScript 7+ is required' in output
    original = (project / 'openapi.json').read_bytes()
    baseline = snapshot(project)
    for relative in ['raw/api.ts', 'client/registry.ts', 'client/contracts.ts']:
        target = project / 'src/generated' / relative
        saved = target.read_bytes()
        target.unlink()
        before = snapshot(project)
        task(project, 'generated-check', False)
        assert snapshot(project) == before, 'Freshness repaired missing output'
        target.write_bytes(saved)
    for relative in ['raw/obsolete.ts', 'client/obsolete.ts']:
        target = project / 'src/generated' / relative
        target.write_text('// obsolete\n')
        before = snapshot(project)
        task(project, 'generated-check', False)
        assert snapshot(project) == before
        target.unlink()
    changed = json.loads(original)
    changed['info']['title'] = 'Changed widgets'
    (project / 'openapi.json').write_text(json.dumps(changed))
    task(project, 'generated-check', False)
    assert snapshot(project) == baseline
    task(project, 'generate')
    task(project, 'generated-check')
    once = snapshot(project)
    task(project, 'generate')
    assert snapshot(project) == once
    task(project, 'build')
    consumer(project, work / 'second')
    (project / 'openapi.json').write_bytes(original)
    # Invalid documents and unqualified semantics leave BOTH generated trees alone.
    def invalid_document(change, label):
        document = json.loads(original)
        change(document)
        (project / 'openapi.json').write_text(json.dumps(document))
        before = snapshot(project)
        output = task(project, 'generate', False)
        assert snapshot(project) == before, label
        task(project, 'generated-check', False)
        assert snapshot(project) == before
        return output
    mutations = [
        (lambda d: d.update(openapi='no'), 'structure'),
        (lambda d: d['components']['schemas']['Widget'].update(properties={'id': {'$ref': '#/components/schemas/Missing'}}), 'unresolved ref'),
        (lambda d: d['paths']['/widgets/{id}']['get'].update(parameters=[]), 'missing path declaration'),
        (lambda d: d['paths']['/widgets']['post'].update(operationId='getWidget'), 'duplicate operation'),
        (lambda d: d['paths']['/widgets/{id}']['get']['parameters'].append(copy.deepcopy(d['paths']['/widgets/{id}']['get']['parameters'][0])), 'duplicate parameter'),
        (lambda d: d['components']['schemas']['Widget'].update(unevaluatedProperties=False), 'unsupported keyword'),
        (lambda d: d['components']['schemas']['Widget']['properties']['id'].update({'$ref':'https://example.invalid/schema.json'}), 'remote ref'),
        (lambda d: d['paths']['/widgets/{id}']['get']['responses'].update(default={'description':'Default'}), 'default status'),
        (lambda d: d['paths']['/widgets/{id}']['get']['responses'].update({'4XX':{'description':'Range'}}), 'range status'),
        (lambda d: d['paths']['/widgets/{id}']['get']['responses']['200'].update(content={'text/plain':{'schema':{'type':'string'}}}), 'non-JSON media'),
    ]
    for change, label in mutations:
        invalid_document(change, label)
    # Repeat the semantic and type checks for OpenAPI 3.0's nullable spelling.
    document = json.loads(original)
    def nullable(value):
        if isinstance(value, dict):
            if isinstance(value.get('type'), list) and 'null' in value['type']:
                value['type'] = next(x for x in value['type'] if x != 'null')
                value['nullable'] = True
            for child in value.values(): nullable(child)
        elif isinstance(value, list):
            for child in value: nullable(child)
    nullable(document)
    document['openapi'] = '3.0.3'
    (project / 'openapi.json').write_text(json.dumps(document))
    task(project, 'generate')
    task(project, 'typecheck')
    task(project, 'test')
    # JSON document in a nested directory with a local external component.
    document = json.loads(original)
    spec = project / 'spec'
    (spec / 'schemas').mkdir(parents=True)
    (spec / 'schemas/widget.json').write_text(json.dumps(document['components']['schemas']['Widget']))
    document['components']['schemas']['Widget'] = {'$ref': './schemas/widget.json'}
    (spec / 'api.json').write_text(json.dumps(document))
    script = project / 'scripts/generate.ts'
    script.write_text(script.read_text().replace("const schema = 'openapi.json'", "const schema = 'spec/api.json'"))
    task(project, 'generate')
    task(project, 'typecheck')
    task(project, 'test')
    task(project, 'generated-check')
    print('OpenAPI client toolchain qualification passed.', flush=True)


def render(work):
    raise NotImplementedError('Rendering follows successful toolchain qualification')


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--toolchain-only', action='store_true')
    parser.add_argument('--render-only', action='store_true')
    args = parser.parse_args()
    with tempfile.TemporaryDirectory(prefix='openapi-client-acceptance-') as temp:
        work = Path(temp)
        if not args.render_only:
            qualify(work)
        if not args.toolchain_only:
            render(work)
        if not args.render_only and not args.toolchain_only:
            print('OpenAPI client bootstrap passed.', flush=True)


if __name__ == '__main__':
    main()
