#!/usr/bin/env python3
"""Real Seihou upgrade and Nix image checks; optional Linux archive build."""
import argparse
import hashlib
import json
from pathlib import Path
import shutil
import tempfile

from haskell_runtime_test_support import Commands, ROOT, render, track


def extension(project):
    # Exercise the shipped example verbatim, with a tiny executable instead of
    # paying for an unrelated Haskell build to validate the image builder API.
    example = (project / 'flake.module.nix.example').read_text()
    start = example.index('    #   packages = pkgs.lib.optionalAttrs')
    end = example.index('    #   };', start) + len('    #   };')
    block = '\n'.join(line.replace('    #   ', '    ', 1)
                      for line in example[start:end].splitlines())
    block = block.replace('packages = pkgs.lib.optionalAttrs',
                          'packages = { default = pkgs.hello; } // pkgs.lib.optionalAttrs')
    return '''{ inputs, ... }: {
  perSystem = { self', pkgs, system, ... }: {
    haskellProject.extraDevPackages = [ pkgs.ripgrep ];
''' + block + '''
  };
}
'''


def evaluate(commands, project, system, label):
    return json.loads(commands.run([
        'nix', 'eval', '--json', '--no-write-lock-file',
        '.#packages.' + system, '--apply', '''p: {
          names = builtins.attrNames p;
          package = p.default.drvPath;
        }'''], project, label))


def image_checks(commands, project):
    for system in ['x86_64-linux', 'aarch64-linux']:
        result = json.loads(commands.run([
            'nix', 'eval', '--json', '--no-write-lock-file',
            '.#packages.' + system + '.dockerImage', '--apply', '''i: {
              name = i.imageName;
              tag = i.imageTag;
              image = i.drvPath;
              docker = i.copyToDockerDaemon.drvPath;
              registry = i.copyToRegistry.drvPath;
              archive = i.copyTo.drvPath;
            }'''], project, system + '-image-and-transports'))
        assert result['name'] == 'hello' and result['tag'] == 'latest', result
        assert all(result[key].endswith('.drv') for key in ['image', 'docker', 'registry', 'archive'])
    systems = json.loads(commands.run(['nix', 'eval', '--json', '--no-write-lock-file',
                                      '.#packages', '--apply', 'builtins.attrNames'],
                                     project, 'supported-systems'))
    assert 'aarch64-darwin' in systems
    for system in [s for s in systems if s.endswith('-darwin')]:
        assert 'dockerImage' not in evaluate(commands, project, system, system + '-guard')['names']


NATIVE_CHECK = r'''
    checks.fixtureArchiveCheck = pkgs.runCommand "nix2container-archive-check" {
      nativeBuildInputs = [ self'.packages.dockerImage.copyTo pkgs.python3 ];
    } ''
      copy-to docker-archive:$TMPDIR/image.tar:hello:latest --tmpdir "$TMPDIR"
      python3 - "$TMPDIR/image.tar" <<'PY'
import json, posixpath, sys, tarfile
with tarfile.open(sys.argv[1]) as archive:
    manifest = json.load(archive.extractfile('manifest.json'))[0]
    assert manifest['RepoTags'] == ['docker.io/library/hello:latest'], manifest
    config = json.load(archive.extractfile(manifest['Config']))['config']
    assert config['Cmd'][0].endswith('/bin/hello'), config
    assert config['ExposedPorts'] == {'8080/tcp': {}}, config
    assert any(x.startswith('SSL_CERT_FILE=') for x in config['Env']), config
    members = {}
    for layer in manifest['Layers']:
        with tarfile.open(fileobj=archive.extractfile(layer)) as contents:
            members.update((x.name.removeprefix('./').lstrip('/'), x) for x in contents)
    # buildEnv may link a whole directory to a package's tree. Resolve those
    # links within the archive inventory, without extracting or following host paths.
    def resolve(path):
        path = posixpath.normpath('/' + path.lstrip('/')).lstrip('/')
        for _ in range(40):
            parts = path.split('/')
            for i in range(1, len(parts) + 1):
                prefix = '/'.join(parts[:i])
                item = members.get(prefix)
                if item is not None and (item.issym() or item.islnk()):
                    base = posixpath.dirname(prefix) if item.issym() else ""
                    target = posixpath.join(base, item.linkname)
                    path = posixpath.normpath('/' + posixpath.join(target, *parts[i:]).lstrip('/')).lstrip('/')
                    break
            else:
                return members.get(path)
        raise AssertionError('Archive symlink loop: ' + path)
    for binary in ['bin/bash', 'bin/ls', config['Cmd'][0]]:
        entry = resolve(binary)
        assert entry is not None and entry.isfile() and entry.mode & 0o111, binary
    certificate = resolve('etc/ssl/certs/ca-bundle.crt')
    assert certificate is not None and certificate.isfile() and certificate.size > 0, 'Missing TLS roots'
    configured_cert = next(x.split('=', 1)[1] for x in config['Env'] if x.startswith('SSL_CERT_FILE='))
    assert resolve(configured_cert).name == certificate.name, 'Certificate environment points to another file'
print('Archive verified: executable closure, runtime tools, TLS roots, command, environment and ports')
PY
      mkdir -p "$out"
      touch "$out/passed"
    '';
'''


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--native-linux', choices=['x86_64-linux', 'aarch64-linux'])
    args = parser.parse_args()
    destination = Path(tempfile.mkdtemp(prefix='seihou-nix2container-')).resolve()
    commands = Commands(destination / 'evidence')
    project = destination / 'consumer'
    render(commands, project, 'hello', revision='2eaba137a2b8c4f425be1a6e59cb0ff9b0d80b42', features={'nix.builtin-package': 'false'})
    old_module = project / '.seihou/modules/nix-haskell-flake/module.dhall'
    assert 'version = Some "0.36.0"' in old_module.read_text(), 'Fixture requires the recorded pre-migration release'
    original_lock = json.loads((project / 'flake.lock').read_text())
    old_extension = '''{ inputs, ... }: {
  perSystem = { self', pkgs, system, ... }: {
    haskellProject.extraDevPackages = [ pkgs.ripgrep ];
    packages = { default = pkgs.hello; } // pkgs.lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
      dockerImage = pkgs.dockerTools.buildLayeredImage {
        name = "hello";
        tag = "latest";
        contents = [ pkgs.cacert pkgs.coreutils pkgs.bashInteractive ];
        config = {
          Cmd = [ "${self'.packages.default}/bin/hello" ];
          ExposedPorts = { "8080/tcp" = { }; };
          Env = [ "SSL_CERT_FILE=${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt" ];
        };
      };
    };
  };
}
'''
    path = project / 'flake.module.nix'
    path.write_text(old_extension)
    authored = project / 'authored.txt'
    authored.write_text('Preserve consumer source\n')
    authored_hash = hashlib.sha256(authored.read_bytes()).hexdigest()
    flake = project / 'flake.nix'
    custom = '''    consumer-extra = {
      url = "github:nlewo/nix2container/e503eb81630a0c5d7ec244e08e0733650235d8f1";
      flake = false;
    };
'''
    flake.write_text(flake.read_text().replace('  inputs = {\n', '  inputs = {\n' + custom))
    track(commands, project)
    commands.run(['nix', 'flake', 'lock'], project, 'custom-input-lock')
    before_lock = json.loads((project / 'flake.lock').read_text())
    before_packages = {s: evaluate(commands, project, s, s + '-before')['package']
                       for s in ['x86_64-linux', 'aarch64-darwin']}
    blueprint = project / '.seihou/modules/upgrade-haskell-nix2container'
    shutil.copytree(ROOT / 'blueprints/upgrade-haskell-nix2container', blueprint)
    before_debug = (project / '.seihou/manifest.json').read_bytes()
    prompt = commands.run(['seihou', 'agent', '--debug', 'migrate',
                           'upgrade-haskell-nix2container', '--from', '0.36.0', '--to', '0.37.0'],
                          project, 'read-only-migration-prompt')
    assert 'copyToDockerDaemon' in prompt and 'fakeRootCommands' in prompt
    assert (project / '.seihou/manifest.json').read_bytes() == before_debug
    target = project / '.seihou/modules/nix-haskell-flake'
    # Replace only the project-local installed module, keeping its genuine origin.
    shutil.copytree(ROOT / 'modules/haskell/nix-haskell-flake', target, dirs_exist_ok=True)
    update = ['seihou', 'update', 'nix-haskell-flake', '--json', '--include-shared-owners', '--no-commands']
    commands.run(update + ['--dry-run'], project, 'preview-managed-update')
    commands.run(update, project, 'apply-managed-update')
    assert path.read_text() == old_extension, 'Managed upgrade took over the user extension'
    assert custom in flake.read_text(), 'Three-way update lost custom input'
    commands.run(['nix', 'flake', 'lock'], project, 'merged-input-lock')
    after_lock = json.loads((project / 'flake.lock').read_text())
    for node, value in original_lock['nodes'].items():
        if node != 'root':
            assert after_lock['nodes'][node] == value, 'Moved existing pin: ' + node
    extra_node = before_lock['nodes']['root']['inputs']['consumer-extra']
    after_extra = after_lock['nodes']['root']['inputs']['consumer-extra']
    assert after_lock['nodes'][after_extra] == before_lock['nodes'][extra_node]
    n2c = after_lock['nodes'][after_lock['nodes']['root']['inputs']['nix2container']]
    assert n2c['inputs']['nixpkgs'] == ['nixpkgs']
    assert n2c['locked']['rev'] == 'e503eb81630a0c5d7ec244e08e0733650235d8f1'
    migrated = extension(project)
    path.write_text(migrated)
    commands.run(['git', 'add', '-N', '.'], project, 'track-new-files')
    image_checks(commands, project)
    for system, expected in before_packages.items():
        assert evaluate(commands, project, system, system + '-unchanged-package')['package'] == expected
    # A subsequent genuine update must preserve the image and custom lock nodes.
    commands.run(update, project, 'repeat-managed-update')
    assert path.read_text() == migrated
    assert hashlib.sha256(authored.read_bytes()).hexdigest() == authored_hash
    commands.run(['nix', 'flake', 'lock'], project, 'repeat-lock')
    assert json.loads((project / 'flake.lock').read_text()) == after_lock
    # Optional images stay disabled when a consumer only refreshes the example.
    path.write_text('{ ... }: { perSystem = { pkgs, ... }: { packages.default = pkgs.hello; }; }\n')
    assert 'dockerImage' not in evaluate(commands, project, 'x86_64-linux', 'library-no-image')['names']
    path.write_text(migrated)
    if args.native_linux:
        path.write_text(migrated.replace('    haskellProject.extraDevPackages',
                                        NATIVE_CHECK + '\n    haskellProject.extraDevPackages'))
        commands.run(['nix', 'build', '.#checks.' + args.native_linux + '.fixtureArchiveCheck',
                      '--no-link', '--no-write-lock-file', '--print-build-logs'], project, 'native-archive-check')
    (destination / 'receipt.json').write_text(json.dumps({
        'status': 'passed', 'native_archive': args.native_linux, 'daemon_smoke': 'not run',
        'qualification': 'Real CLI update and bounded image translation fixture; no coding agent or registry push.'}, indent=2) + '\n')
    print('nix2container acceptance passed: ' + str(destination))


if __name__ == '__main__':
    main()
