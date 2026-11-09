#!/usr/bin/env python3
"""Sandbox app/snapshot builds, cache boundaries, nested publication and native image roundtrip.

On Darwin, discovers the matching SSH Nix builder (or --linux-runner). The native
runner needs passwordless sudo for an isolated temporary Docker daemon, unless
Docker is already available. No registry, provider or live deployment is used.
"""
import argparse
import hashlib
import json
import os
import platform
from pathlib import Path
import posixpath
import re
import shlex
import shutil
import subprocess
import tarfile
import tempfile
import time
import uuid

from docs_microapp_test_support import ROOT, collection, free_port, get, http_checks, render, run
import importlib.util

spec = importlib.util.spec_from_file_location('reader_acceptance', ROOT / 'scripts/test-docs-microapp.py')
reader = importlib.util.module_from_spec(spec)
spec.loader.exec_module(reader)
PLAN = 'docs/plans/13-bootstrap-documentation-microapps-with-tanstack-start-and-nagare-recipes.md'


def nix(project, *args, succeeds=True):
    return run(['nix', args[0], '--no-write-lock-file', *args[1:]], project, succeeds=succeeds)


def commit(project):
    if not (project / '.git').exists():
        run(['git', 'init', '-q'], project)
        with (project / '.git/info/exclude').open('a') as f:
            f.write('\n.seihou/\n')
    run(['git', 'add', '-A'], project)
    run(['git', '-c', 'user.name=Fixture', '-c', 'user.email=fixture@example.invalid', 'commit', '-qm',
         'test: prepare documentation image fixture\n\nExecPlan: ' + PLAN], project)


def derivations(project, system):
    return json.loads(nix(project, 'eval', '--json', f'.#packages.{system}', '--apply', '''p: {
      app = p.docs-app.drvPath; registry = p.docs-app.registryCache.drvPath; content = p.docs-content.drvPath;
    }''').splitlines()[0])


def host_checks(work):
    project = work / 'consumer'
    render(project)
    # Shell stays usable before lock generation; package errors explain the action.
    nix(project, 'eval', '--raw', '.#devShells.aarch64-darwin.default.drvPath')
    failure = nix(project, 'eval', '--raw', '.#packages.x86_64-linux.docs-app.drvPath', succeeds=False)
    assert 'bun install' in failure
    reader.install(project)
    collection(project)
    (project / 'flake.module.nix').write_text('''{ ... }: { perSystem = { pkgs, ... }: {
      packages.fixture-docker = pkgs.docker;
      packages.fixture-native-tools = pkgs.buildEnv { name = "docs-native-tools"; paths = [ pkgs.python3 pkgs.curl pkgs.bash ]; };
    }; }
''')
    commit(project)
    for system in ['aarch64-darwin', 'aarch64-linux', 'x86_64-linux']:
        names = json.loads(nix(project, 'eval', '--json', f'.#packages.{system}', '--apply', 'builtins.attrNames').splitlines()[0])
        assert ('docs-image' in names) == system.endswith('linux'), names
        derivations(project, system)
    host = run(['nix', 'eval', '--impure', '--raw', '--expr', 'builtins.currentSystem'], project).strip()
    nix(project, 'build', '.#docs-app', '.#docs-content', f'.#checks.{host}.docs-smoke', '--no-link', '--option', 'sandbox', 'true')
    baseline = derivations(project, host)
    with (project / 'content/docs/index.md').open('a') as f:
        f.write('\nA new publication revision.\n')
    commit(project)
    content_changed = derivations(project, host)
    assert baseline['app'] == content_changed['app'] and baseline['registry'] == content_changed['registry'], (baseline, content_changed)
    assert baseline['content'] != content_changed['content']
    with (project / 'apps/docs/src/routes/index.tsx').open('a') as f:
        f.write('\n// Application-only revision.\n')
    commit(project)
    app_changed = derivations(project, host)
    assert app_changed['app'] != content_changed['app'] and app_changed['registry'] == content_changed['registry']
    print('Cache evidence: ' + json.dumps({'baseline': baseline, 'contentEdit': content_changed, 'appEdit': app_changed}), flush=True)
    tag = nix(project, 'eval', '--raw', '.#lib.docsImageTag').strip()
    assert re.fullmatch(r'git-[0-9a-f]{12}', tag)
    with (project / 'content/docs/index.md').open('a') as f:
        f.write('\nDirty input.\n')
    assert 'clean committed Git revision' in nix(project, 'eval', '--raw', '.#lib.docsImageTag', succeeds=False)
    text = (project / 'content/docs/index.md').read_text().removesuffix('\nDirty input.\n')
    (project / 'content/docs/index.md').write_text(text)
    print('Nix: all systems evaluate, Darwin omits image, native sandbox app/content smoke passes, dirty publication tag refuses.', flush=True)
    return project, tag


def nested(work):
    root = work / 'nested'
    project = root / 'web'
    render(project)
    reader.install(project)
    (root / 'docs').mkdir()
    (root / 'docs/guide.md').write_text('# Parent repository guide\n')
    (root / 'publication.json').write_text(json.dumps({'schemaVersion': 1, 'projectUri': None, 'documents': ['docs/guide.md'], 'bundles': [], 'assets': []}))
    (project / 'flake.module.nix').write_text('{ ... }: { docsMicroapp.contentSource = ../.; docsMicroapp.contentConfig = "publication.json"; }\n')
    commit(root)
    host = run(['nix', 'eval', '--impure', '--raw', '--expr', 'builtins.currentSystem'], project).strip()
    nix(project, 'build', '.#docs-content', f'.#checks.{host}.docs-smoke', '--no-link', '--option', 'sandbox', 'true')
    print('Nested web flake: contentSource = ../. packages the parent repository selection through a real Git flake.', flush=True)


def inspect_archive(archive, expected):
    with tarfile.open(archive) as tar:
        manifest = json.load(tar.extractfile('manifest.json'))[0]
        config = json.load(tar.extractfile(manifest['Config']))['config']
        assert config['User'] == '65532:65532' and config['WorkingDir'] == '/app', config
        assert config['Cmd'] == ['/app/server.ts'] and config['Entrypoint'][0].endswith('/bin/bun'), config
        assert config['ExposedPorts'] == {'8080/tcp': {}} and 'DOCS_CONTENT_ROOT=/content' in config['Env']
        files = {}
        layers = {}
        for i, layer in enumerate(manifest['Layers']):
            with tarfile.open(fileobj=tar.extractfile(layer)) as content:
                for item in content:
                    name = item.name.removeprefix('./').lstrip('/')
                    files[name] = (item, content.extractfile(item).read() if item.isfile() else None)
                    layers[name] = i
        def read(path):
            parts = path.lstrip('/').split('/')
            for _ in range(40):
                for i in range(1, len(parts)+1):
                    key = '/'.join(parts[:i])
                    entry = files.get(key)
                    if entry and entry[0].issym():
                        link = entry[0].linkname
                        target = link if link.startswith('/') else posixpath.join('/'.join(parts[:i-1]), link)
                        parts = posixpath.normpath(posixpath.join(target, *parts[i:])).lstrip('/').split('/')
                        break
                else:
                    return files['/'.join(parts)][1]
            raise AssertionError('Archive symlink loop')
        inventory = json.loads(read('/content/content-inventory.json'))
        assert {f['path'] for f in inventory['files']} == expected
        for f in inventory['files']:
            assert hashlib.sha256(read('/content/' + f['path'])).hexdigest() == f['sha256']
        for font in ['geist-serif.woff2', 'paper-mono.woff2']:
            assert read('/app/dist/client/fonts/' + font)[:4] == b'wOF2'
        assert not any(p.endswith('/content/unpublished.md') for p in files)
        assert len(set(layers.values())) >= 3
    print('Archive: unprivileged command/port, separate layers, both fonts and exact checksummed content inventory.', flush=True)


NATIVE = r'''set -euo pipefail
cd "$1"
work="$2"
ref="$3"
tag="$4"
port="$5"
nix run .#packages.x86_64-linux.docs-image.copyTo -- "docker-archive:$work/image.tar:$ref" --tmpdir "$work"
docker_cli=$(command -v docker)
if "$docker_cli" info >/dev/null 2>&1; then
  docker_run=("$docker_cli")
  daemon_pid=""
else
  daemon=$(command -v dockerd)
  sudo -n "$daemon" --host "unix://$work/docker.sock" --data-root "$work/docker-data" --exec-root "$work/docker-exec" --pidfile "$work/docker.pid" --bridge none --iptables=false --ip6tables=false --ip-forward=false --ip-masq=false --storage-driver vfs >"$work/docker.log" 2>&1 &
  daemon_pid=$!
  docker_run=(sudo -n "$docker_cli" --host "unix://$work/docker.sock")
fi
container="docs-microapp-$tag-$$"
cleanup() {
  "${docker_run[@]}" rm -f "$container" >/dev/null 2>&1 || true
  if [ -n "$daemon_pid" ]; then
    sudo -n kill "$(cat "$work/docker.pid")" 2>/dev/null || true
    wait "$daemon_pid" 2>/dev/null || true
    sudo -n umount "$work/docker-exec/netns/default" 2>/dev/null || true
  fi
}
trap cleanup EXIT
for i in $(seq 1 120); do
  if "${docker_run[@]}" info >/dev/null 2>&1; then break; fi
  sleep .5
done
"${docker_run[@]}" load -i "$work/image.tar" >/dev/null
"${docker_run[@]}" run -d --network host --name "$container" --env "PORT=$port" "$ref" >/dev/null
for i in $(seq 1 120); do
  if curl -fsS "http://127.0.0.1:$port/healthz" >"$work/health.json"; then break; fi
  sleep .25
done
if ! curl -fsS "http://127.0.0.1:$port/docs/content/docs/index" >"$work/document.html"; then
  "${docker_run[@]}" logs "$container"
  exit 1
fi
printf 'DOCS_CONTAINER_READY\n'
read -r stop
'''


def discover_runner(system):
    config = json.loads(run(['nix', 'config', 'show', '--json'], ROOT))
    builders = config['builders']['value']
    if builders.startswith('@'):
        builders = Path(builders[1:]).read_text()
    for line in builders.splitlines():
        parts = line.split()
        if len(parts) > 1 and system in parts[1].split(',') and parts[0].startswith('ssh://'):
            return parts[0].removeprefix('ssh://')
    raise RuntimeError('A matching native Linux SSH runner is required; use --linux-runner or DOCS_LINUX_RUNNER')


def native(project, work, tag, system, runner):
    if system != 'x86_64-linux':
        raise RuntimeError('This acceptance path qualifies x86_64-linux; add a matching native runner before another system')
    bundle = work / 'consumer.bundle'
    run(['git', 'bundle', 'create', str(bundle), 'HEAD'], project)
    remote = run(['ssh', runner, 'mktemp -d /tmp/docs-microapp-native-XXXXXXXX'], project).strip()
    assert re.fullmatch(r'/tmp/docs-microapp-native-[A-Za-z0-9]+', remote), remote
    run(['scp', str(bundle), f'{runner}:{remote}/consumer.bundle'], project)
    run(['ssh', runner, f'git clone -q {shlex.quote(remote + "/consumer.bundle")} {shlex.quote(remote + "/consumer")}'], project)
    script = work / 'native.sh'
    script.write_text(NATIVE)
    run(['scp', str(script), f'{runner}:{remote}/native.sh'], project)
    port = free_port()
    # The same native Linux host builds, exports and executes the image. The isolated
    # daemon has no bridge, forwarding or iptables changes, and is stopped in the trap.
    command = f'cd {shlex.quote(remote + "/consumer")} && nix shell .#packages.x86_64-linux.fixture-docker .#packages.x86_64-linux.fixture-native-tools -c bash {shlex.quote(remote + "/native.sh")} {shlex.quote(remote + "/consumer")} {shlex.quote(remote)} fixture-docs:{tag} {tag} {port}'
    process = subprocess.Popen(['ssh', runner, command], cwd=project, text=True, stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=(work / 'native.log').open('w'))
    tunnel = None
    transcript = []
    try:
        for line in process.stdout:
            transcript.append(line)
            if line.strip() == 'DOCS_CONTAINER_READY':
                break
        else:
            raise AssertionError(''.join(transcript)[-4000:] + (work / 'native.log').read_text()[-4000:])
        local_port = free_port()
        tunnel = subprocess.Popen(['ssh', '-N', '-L', f'{local_port}:127.0.0.1:{port}', runner], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        for _ in range(100):
            try:
                if get(local_port, '/healthz')[0] == 200:
                    break
            except OSError:
                pass
            time.sleep(.1)
        run(['scp', f'{runner}:{remote}/image.tar', str(work / 'image.tar')], project)
        http_checks(local_port)
        health = json.loads(get(local_port, '/healthz')[1])
        revision = run(['git', 'rev-parse', 'HEAD'], project).strip()
        assert health['commit'] == revision
        assert revision.encode() in get(local_port, '/')[1]
        run(['bun', 'x', 'playwright', 'install', 'chromium'], project)
        run(['bun', 'run', 'test:e2e'], project, env={**os.environ, 'DOCS_TEST_URL': f'http://127.0.0.1:{local_port}'})
        run(['scp', f'{runner}:{remote}/image.tar', str(work / 'image.tar')], project)
        config = json.loads((project / 'content.config.json').read_text())
        inspect_archive(work / 'image.tar', set(config['documents'] + config['assets']))
        print('Native x86_64 Linux: image built/exported/run; health revision, deep SSR, JS, fonts and Chromium interactions passed.', flush=True)
    finally:
        if tunnel:
            tunnel.terminate(); tunnel.wait(timeout=15)
        if process.poll() is None:
            process.stdin.write('stop\n'); process.stdin.flush()
        process.wait(timeout=60)
        (work / 'native.stdout.log').write_text(''.join(transcript))
        run(['ssh', runner, 'sudo -n rm -rf -- ' + shlex.quote(remote)], project)
    assert process.returncode == 0, (work / 'native.log').read_text()[-8000:]


def apple_archive(project, archive):
    """Fast local runtime/browser check of an already exported Docker archive."""
    started = time.monotonic()
    project, archive = project.resolve(), archive.resolve()
    with tarfile.open(archive) as tar:
        manifest = json.load(tar.extractfile('manifest.json'))[0]
        architecture = json.load(tar.extractfile(manifest['Config']))['architecture']
    reference = 'docs-microapp-apple-' + uuid.uuid4().hex[:10]
    name = reference + '-test'
    port = free_port()
    with tempfile.TemporaryDirectory(prefix='docs-apple-') as directory:
        oci = Path(directory) / 'image.tar'
        run(['nix', 'shell', '--inputs-from', str(project), 'nixpkgs#skopeo', '-c',
             'skopeo', '--insecure-policy', 'copy', 'docker-archive:' + str(archive),
             'oci-archive:' + str(oci) + ':' + reference], project)
        run(['container', 'image', 'load', '--input', str(oci)], project)
        launched = False
        try:
            args = ['container', 'run', '--detach', '--rm', '--name', name, '--arch', architecture,
                    '--publish', f'127.0.0.1:{port}:8080']
            if architecture == 'amd64' and platform.machine() == 'arm64':
                args.append('--rosetta')
            run([*args, reference], project)
            launched = True
            for _ in range(150):
                try:
                    if get(port, '/healthz')[0] == 200:
                        break
                except OSError:
                    pass
                time.sleep(.1)
            http_checks(port)
            run(['bun', 'run', 'test:e2e'], project,
                env={**os.environ, 'DOCS_TEST_URL': f'http://127.0.0.1:{port}'})
        finally:
            if launched:
                run(['container', 'stop', name], project)
            run(['container', 'image', 'delete', reference], project)
    print(f'Apple Container: HTTP, local fonts, CSS/JS and Chromium passed in {time.monotonic()-started:.2f}s ({architecture}).', flush=True)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--native-linux', choices=['x86_64-linux'])
    parser.add_argument('--apple-archive', type=Path, help='Fast local Apple runtime check of an existing Docker archive')
    parser.add_argument('--apple-project', type=Path, help='Generated consumer with installed browser-test dependencies')
    parser.add_argument('--linux-runner', default=os.environ.get('DOCS_LINUX_RUNNER'))
    parser.add_argument('--workdir', type=Path)
    args = parser.parse_args()
    if args.apple_archive:
        if not args.apple_project:
            parser.error('--apple-project is required with --apple-archive')
        apple_archive(args.apple_project, args.apple_archive)
        return
    if not args.native_linux:
        parser.error('Select --apple-archive for a local runtime check or --native-linux for full native acceptance')
    runner = args.linux_runner or discover_runner(args.native_linux)
    def accept(work):
        work.mkdir(parents=True, exist_ok=True)
        project, tag = host_checks(work)
        nested(work)
        native(project, work, tag, args.native_linux, runner)
    if args.workdir:
        accept(args.workdir)
    else:
        with tempfile.TemporaryDirectory(prefix='docs-container-acceptance-') as directory:
            accept(Path(directory))
    print('Docs microapp container acceptance passed.', flush=True)


if __name__ == '__main__':
    main()
