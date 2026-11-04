#!/usr/bin/env python3
"""Verify the opt-in Fumadocs site build and Caddy image through real Seihou runs.

Builds the site in the host sandbox and serves it with the generated Caddyfile.
--native-linux SYSTEM also builds, exports and inspects the image there.
Requires Seihou, Nix and network access; uses temporary projects.
"""
import argparse
import http.client
import json
import os
from pathlib import Path
import shutil
import socket
import subprocess
import tempfile
import time

ROOT = Path(__file__).resolve().parents[1]
PREVIOUS_RELEASE = 'd29fd4b8df8df983ce9e874051560f4bc824f70b'  # Last commit shipping fumadocs 0.3.0.
OPT_IN = {'docs.container': 'true', 'nix.bun2nix': 'true', 'nix.package-module': 'nix/fumadocs-container.nix'}
MANAGED = ['nix/fumadocs-container.nix', 'nix/fumadocs-site.nix', 'nix/caddy-config.nix', 'nix/container.nix']
VARS = {'project.name': 'acme-docs', 'project.description': 'Acme documentation',
        'docs.site-name': 'Acme Docs', 'docs.github-user': 'acme',
        'docs.font-flake': '/tmp/fumadocs-container-missing-fonts'}
EXTENSION = '''{ ... }: {
  perSystem = { config, pkgs, ... }: {
    docsContainer.fonts = ./fixture-fonts;
    CHECK
  };
}
'''
ARCHIVE_CHECK = r"""checks.fixtureArchiveCheck = pkgs.runCommand "docs-image-archive-check" {
      nativeBuildInputs = [ config.packages.dockerImage.copyTo pkgs.python3 ];
    } ''
      copy-to oci-archive:$TMPDIR/image.tar:acme-docs:latest --tmpdir "$TMPDIR"
      python3 - "$TMPDIR/image.tar" <<'PY'
import json, posixpath, sys, tarfile
def blob(archive, digest):
    return archive.extractfile('blobs/' + digest.replace(':', '/'))
with tarfile.open(sys.argv[1]) as archive:
    index = json.load(archive.extractfile('index.json'))
    manifest = json.load(blob(archive, index['manifests'][0]['digest']))
    config = json.load(blob(archive, manifest['config']['digest']))['config']
    assert config['User'] == '65532:65532', config
    assert config['Entrypoint'][0].endswith('/bin/caddy'), config
    assert config['Cmd'] == ['run', '--config', '/etc/caddy/Caddyfile', '--adapter', 'caddyfile'], config
    assert config['ExposedPorts'] == {'8080/tcp': {}}, config
    layers = []
    for layer in manifest['layers']:
        with tarfile.open(fileobj=blob(archive, layer['digest'])) as contents:
            layers.append({item.name.removeprefix('./').lstrip('/'): item for item in contents})
    def holders(path):
        return [layer for layer in layers if path.lstrip('/') in layer]
    caddy = config['Entrypoint'][0]
    site = holders('srv/site')[0]['srv/site'].linkname
    shell = site + '/_shell.html'
    assert len(holders(caddy)) == 1, caddy
    assert len(holders(shell)) == 1, shell
    assert holders(caddy)[0] is not holders(shell)[0], 'Runtime and site share a layer'
    assert holders('etc/caddy/Caddyfile'), 'Missing Caddyfile link'
    entry = holders(caddy)[0][caddy.lstrip('/')]
    if entry.issym():
        target = posixpath.normpath(posixpath.join(posixpath.dirname(entry.name), entry.linkname))
        entry = holders(caddy)[0][target.lstrip('/')]
    assert entry.isfile() and entry.mode & 0o111, caddy
    assert holders(site + '/fonts/Fixture-Regular.otf'), 'Configured fonts are missing'
print('Archive verified: user, command, port, site, Caddyfile and separate layers')
PY
      mkdir -p "$out"
      touch "$out/passed"
    '';"""


def run(args, cwd, succeeds=True):
    result = subprocess.run(args, cwd=cwd, text=True, capture_output=True)
    if (result.returncode == 0) != succeeds:
        raise AssertionError(f'{args}: exit {result.returncode}\n{result.stdout}\n{result.stderr}')
    return result


def nix(project, *args, succeeds=True):
    return run(['nix', args[0], '--no-write-lock-file', *args[1:]], project, succeeds=succeeds)


def render(project, **variables):
    project.mkdir()
    for name in ['fumadocs', 'nix-bun-flake']:
        shutil.copytree(ROOT / 'modules/typescript' / name, project / '.seihou/modules' / name)
    command = ['seihou', 'run', 'fumadocs', '--no-save-prompted', '--no-commands']
    for key, value in {**VARS, **variables}.items():
        command += ['--var', f'{key}={value}']
    run(command, project)
    run(['git', 'init', '-q'], project)
    run(['git', 'add', '-A'], project)


def package_names(project, system):
    return json.loads(nix(project, 'eval', '--json', f'.#packages.{system}', '--apply', 'builtins.attrNames').stdout)


def disabled_by_default(work):
    project = work / 'default'
    render(project)
    assert not any((project / path).exists() for path in MANAGED)
    assert 'fumadocs-container' not in (project / 'flake.nix').read_text()
    canonical = (ROOT / 'modules/typescript/nix-bun-flake/files/flake.lock').read_bytes()
    assert (project / 'flake.lock').read_bytes() == canonical
    assert package_names(project, 'x86_64-linux') == []
    print('Default: no managed files, packages or lock changes.', flush=True)


def requires_helper(work):
    project = work / 'no-helper'
    render(project, **{**OPT_IN, 'nix.bun2nix': 'false'})
    (project / 'bun-deps.nix').write_text('{ ... }: { }\n')
    run(['git', 'add', '-A'], project)
    failed = nix(project, 'eval', '--raw', '.#packages.x86_64-linux.docs-site.drvPath', succeeds=False)
    assert 'also requires nix.bun2nix=true' in failed.stderr, failed.stderr
    print('Missing helper: evaluation names the required variable.', flush=True)


def free_port():
    with socket.socket() as probe:
        probe.bind(('127.0.0.1', 0))
        return probe.getsockname()[1]


def get(port, path):
    connection = http.client.HTTPConnection('127.0.0.1', port, timeout=5)
    connection.request('GET', path)
    response = connection.getresponse()
    return response, response.read()


def serve_checks(project, caddy):
    site = (project / 'result-site/share/site').resolve()
    port = free_port()
    config = (project / 'result-caddy').read_text()
    assert '"/srv/site"' in config and ':8080 {' in config
    # Outside the project: a stray tracked file would change the site source.
    test_config = project.parent / 'Caddyfile.test'
    test_config.write_text(config.replace('/srv/site', str(site)).replace(':8080', f':{port}'))
    log = project.parent / 'caddy.log'
    # An unwritable home, as in the image: startup must not need one.
    process = subprocess.Popen([caddy, 'run', '--config', str(test_config), '--adapter', 'caddyfile'],
                               env={'HOME': '/nonexistent'}, stdout=log.open('w'), stderr=subprocess.STDOUT)
    try:
        for _ in range(40):
            try:
                get(port, '/')
                break
            except OSError:
                time.sleep(0.25)
        shell = (site / '_shell.html').read_bytes()
        for path in ['/docs', '/docs/', '/docs/diagram-demo', '/docs/diagram-demo/']:
            response, body = get(port, path)
            assert response.status == 200 and b'Acme Docs' in body and body != shell, path
            assert response.getheader('Cache-Control') == 'no-cache', path
        for path in ['/', '/no/such/page']:
            response, body = get(port, path)
            assert response.status == 200 and body == shell, path
        response, body = get(port, '/docs/diagram-demo.md')
        assert response.getheader('Content-Type').startswith('text/markdown') and b'sequenceDiagram' in body
        response, body = get(port, '/api/search')
        assert response.getheader('Content-Type') == 'application/json'
        json.loads(body)
        asset = sorted(os.listdir(site / 'assets'))[0]
        response, _ = get(port, f'/assets/{asset}')
        assert response.status == 200 and 'immutable' in response.getheader('Cache-Control')
        response, body = get(port, '/fonts/Fixture-Regular.otf')
        assert response.status == 200 and body == b'fixture font\n'
        assert response.getheader('Cache-Control') == 'public, max-age=86400'
        for path in ['/assets/missing.js', '/fonts/missing.otf']:
            response, _ = get(port, path)
            assert response.status == 404 and response.getheader('Cache-Control') is None, path
    finally:
        process.terminate()
        process.wait()
    entries = [json.loads(line) for line in log.read_text().splitlines() if line.startswith('{')]
    assert not [entry for entry in entries if entry.get('level') == 'error' and entry.get('logger') != 'http.log.access'], \
        log.read_text()
    print('Caddy: pages, shell fallback, Markdown, search, assets, fonts and 404s passed.', flush=True)


def image_checks(project):
    for system in ['x86_64-linux', 'aarch64-linux']:
        result = json.loads(nix(project, 'eval', '--json', f'.#packages.{system}.dockerImage', '--apply', """i: {
          name = i.imageName;
          tag = i.imageTag;
          image = i.drvPath;
          docker = i.copyToDockerDaemon.drvPath;
          registry = i.copyToRegistry.drvPath;
          archive = i.copyTo.drvPath;
        }""").stdout)
        assert (result['name'], result['tag']) == ('acme-docs', 'latest'), result
        assert all(result[key].endswith('.drv') for key in ['image', 'docker', 'registry', 'archive'])
    names = package_names(project, 'aarch64-darwin')
    assert 'dockerImage' not in names and 'docs-site' in names, names
    print('Image: Linux image and helpers evaluate; Darwin omits it.', flush=True)


def enabled(work, native_linux):
    project = work / 'enabled'
    render(project, **OPT_IN)
    assert all((project / path).exists() for path in MANAGED)
    # Before generation the shell works and no output pretends the site can build.
    assert package_names(project, 'x86_64-linux') == ['bun2nix']
    # The shell's own Caddy, not one inherited from the caller's PATH.
    caddy = nix(project, 'develop', '--command', 'bash', '-c', 'command -v caddy').stdout.splitlines()[-1]
    assert caddy.startswith('/nix/store/'), caddy
    run(['nix', 'develop', '--no-write-lock-file', '--command', 'bun', 'install', '--minimum-release-age', '0'], project)
    run(['nix', 'run', '.#bun2nix', '--no-write-lock-file', '--', '--lock-file', 'bun.lock',
         '--output-file', 'bun-deps.nix'], project)
    (project / 'fixture-fonts').mkdir()
    (project / 'fixture-fonts/Fixture-Regular.otf').write_text('fixture font\n')
    (project / 'flake.module.nix').write_text(EXTENSION.replace('CHECK', ''))
    run(['git', 'add', '-A'], project)
    image_checks(project)
    system = nix(project, 'eval', '--impure', '--raw', '--expr', 'builtins.currentSystem').stdout
    nix(project, 'build', f'.#packages.{system}.docs-site', '-o', 'result-site', '--option', 'sandbox', 'true')
    nix(project, 'build', f'.#packages.{system}.docs-caddy-config', '-o', 'result-caddy')
    serve_checks(project, caddy)
    before = nix(project, 'eval', '--raw', f'.#packages.{system}.docs-site.drvPath').stdout
    (project / 'nix/caddy-config.nix').write_text((project / 'nix/caddy-config.nix').read_text() + '# edit\n')
    run(['git', 'add', '-A'], project)
    assert nix(project, 'eval', '--raw', f'.#packages.{system}.docs-site.drvPath').stdout == before, \
        'Nix configuration invalidated the site build'
    (project / 'nix/caddy-config.nix').write_bytes(
        (ROOT / 'modules/typescript/fumadocs/files/nix/caddy-config.nix').read_bytes())
    run(['git', 'add', '-A'], project)
    if native_linux:
        (project / 'flake.module.nix').write_text(EXTENSION.replace('CHECK', ARCHIVE_CHECK))
        run(['git', 'add', '-A'], project)
        nix(project, 'build', f'.#checks.{native_linux}.fixtureArchiveCheck', '--no-link', '--print-build-logs')
        (project / 'flake.module.nix').write_text(EXTENSION.replace('CHECK', ''))
        run(['git', 'add', '-A'], project)
        print(f'Native image {native_linux}: built, exported to oci-archive and inspected.', flush=True)
    return project


def lifecycle(project):
    """Real updates preserve project-owned files and remove only managed ones."""
    # An extension must stop using docsContainer before the feature is disabled.
    (project / 'flake.module.nix').write_text('{ ... }: { perSystem = { pkgs, ... }: { bunProject.extraDevPackages = [ pkgs.jq ]; }; }\n')
    authored = {name: (project / name).read_bytes()
                for name in ['flake.module.nix', 'bun.lock', 'bun-deps.nix', 'fixture-fonts/Fixture-Regular.otf']}
    update = ['seihou', 'update', 'fumadocs', '--no-commands', '--json', '--include-shared-owners']
    run(update + ['--var', 'docs.container=false', '--var', 'nix.bun2nix=false'], project)
    assert not any((project / path).exists() for path in MANAGED)
    assert all((project / name).read_bytes() == data for name, data in authored.items())
    # The saved import stays but is inert while its file is absent.
    run(['git', 'add', '-A'], project)
    assert package_names(project, 'x86_64-linux') == []
    run(update + [arg for key, value in OPT_IN.items() for arg in ('--var', f'{key}={value}')], project)
    assert all((project / path).exists() for path in MANAGED)
    assert all((project / name).read_bytes() == data for name, data in authored.items())
    print('Lifecycle: disable and re-enable preserve authored files.', flush=True)


def upgrade(work):
    """A real update from the release before this feature, then opting in."""
    project = work / 'upgrade'
    project.mkdir()
    for name in ['fumadocs', 'nix-bun-flake']:
        prefix = f'modules/typescript/{name}/'
        files = run(['git', 'ls-tree', '-r', '--name-only', PREVIOUS_RELEASE, '--', prefix], ROOT).stdout.splitlines()
        for file in files:
            path = project / '.seihou/modules' / name / file.removeprefix(prefix)
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_bytes(subprocess.check_output(['git', 'show', f'{PREVIOUS_RELEASE}:{file}'], cwd=ROOT))
    assert 'version = Some "0.3.0"' in (project / '.seihou/modules/fumadocs/module.dhall').read_text()
    command = ['seihou', 'run', 'fumadocs', '--no-save-prompted', '--no-commands']
    for key, value in VARS.items():
        command += ['--var', f'{key}={value}']
    run(command, project)
    run(['git', 'init', '-q'], project)
    authored = b'{ ... }: { perSystem = { pkgs, ... }: { bunProject.extraDevPackages = [ pkgs.jq ]; }; }\n'
    (project / 'flake.module.nix').write_bytes(authored)
    lock = (project / 'flake.lock').read_bytes()
    shutil.rmtree(project / '.seihou/modules/fumadocs')
    shutil.copytree(ROOT / 'modules/typescript/fumadocs', project / '.seihou/modules/fumadocs')
    update = ['seihou', 'update', 'fumadocs', '--no-commands', '--json', '--include-shared-owners']
    flake = (project / 'flake.nix').read_bytes()
    run(update, project)
    assert not any((project / path).exists() for path in MANAGED)
    assert (project / 'flake.nix').read_bytes() == flake, 'Update changed a site that did not opt in'
    assert (project / 'flake.lock').read_bytes() == lock
    run(['git', 'add', '-A'], project)
    assert package_names(project, 'x86_64-linux') == []
    run(update + [arg for key, value in OPT_IN.items() for arg in ('--var', f'{key}={value}')], project)
    assert all((project / path).exists() for path in MANAGED)
    assert (project / 'flake.module.nix').read_bytes() == authored
    run(['git', 'add', '-A'], project)
    assert package_names(project, 'x86_64-linux') == ['bun2nix']
    print('Upgrade: 0.3.0 update stays inert, then opts in; extension and lock preserved.', flush=True)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--native-linux', choices=['x86_64-linux', 'aarch64-linux'])
    args = parser.parse_args()
    run(['seihou', 'validate-module', 'modules/typescript/fumadocs'], ROOT)
    with tempfile.TemporaryDirectory(prefix='fumadocs-container-') as temp:
        work = Path(temp)
        disabled_by_default(work)
        requires_helper(work)
        upgrade(work)
        lifecycle(enabled(work, args.native_linux))
    print('Fumadocs container acceptance passed.', flush=True)


if __name__ == '__main__':
    main()
