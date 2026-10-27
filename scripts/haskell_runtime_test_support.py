"""Real Seihou/Nix fixture helpers. Evidence stays outside the owning repository."""
import json
import os
from pathlib import Path
import shutil
import subprocess
import time

ROOT = Path(__file__).resolve().parents[1]
SYSTEM = 'aarch64-darwin'
SELECTION = {
    'runtimeSelection': {'name': 'keiro-runtime', 'generation': 2, 'channel': 'github',
                         'configuration': {'compiler': 'ghc9124', 'disableProfiling': True, 'disableHaddock': True}},
    'applicationSelections': {'heni': 1, 'hinagata': 1, 'kioku': 8, 'okf': 5,
                             'openapi-hs': 1, 'relay-pagination': 3,
                             'servant-openapi-hs': 1, 'shikumi-baikai': 9,
                             'shoko': 1, 'typesafe-hs': 1},
}


class Commands:
    def __init__(self, destination):
        self.destination = Path(destination)
        self.destination.mkdir(parents=True, exist_ok=True)
        self.records = []

    def run(self, args, cwd, label, success=True, env=None):
        start = time.monotonic()
        result = subprocess.run([str(x) for x in args], cwd=cwd, capture_output=True, text=True, env=env)
        prefix = self.destination / f'{len(self.records):03d}-{label}'
        prefix.with_suffix('.stdout').write_text(result.stdout)
        prefix.with_suffix('.stderr').write_text(result.stderr)
        record = {'command': [str(x) for x in args], 'cwd': str(cwd),
                  'elapsed_seconds': time.monotonic() - start, 'exit_code': result.returncode,
                  'stdout': prefix.with_suffix('.stdout').name, 'stderr': prefix.with_suffix('.stderr').name}
        self.records.append(record)
        (self.destination / 'commands.json').write_text(json.dumps(self.records, indent=2) + '\n')
        print(f'{label}: exit {result.returncode}, {record["elapsed_seconds"]:.2f}s', flush=True)
        assert (result.returncode == 0) == success, f'{args}\n{result.stdout[-1800:]}\n{result.stderr[-3500:]}'
        return result.stdout if success else result.stdout + result.stderr


def copy_modules(project, revision=None):
    for name in ['nix-haskell-flake', 'haskell-cli-app']:
        target = project / '.seihou/modules' / name
        if revision is None:
            shutil.copytree(ROOT / 'modules/haskell' / name, target, symlinks=True)
        else:
            prefix = 'modules/haskell/' + name + '/'
            files = subprocess.check_output(['git', 'ls-tree', '-r', '--name-only', revision, '--', prefix], cwd=ROOT, text=True).splitlines()
            for file in files:
                path = target / file.removeprefix(prefix)
                path.parent.mkdir(parents=True, exist_ok=True)
                path.write_bytes(subprocess.check_output(['git', 'show', revision + ':' + file], cwd=ROOT))


def render(commands, project, name, cli=False, features=None, revision=None):
    project.mkdir(parents=True)
    copy_modules(project, revision)
    values = {'project.name': name, 'project.description': 'Retained runtime integration fixture',
              'nix.process-compose': 'false', 'nix.postgresql': 'false', 'nix.treefmt': 'false',
              'nix.pre-commit': 'false', 'nix.kafka': 'false', 'nix.redis': 'false',
              'nix.clickhouse': 'false', 'nix.redpanda': 'false', 'nix.redpanda-console': 'false',
              'nix.builtin-package': 'false' if cli else 'true'}
    if cli:
        values.update({'project.namespace': 'RuntimeFixture', 'project.author': 'Fixture',
                       'project.maintainer': 'fixture@example.invalid', 'project.tests': 'true'})
    values.update(features or {})
    command = ['seihou', 'run', 'haskell-cli-app' if cli else 'nix-haskell-flake',
               '--no-save-prompted', '--no-commands']
    for key, value in values.items():
        command += ['--var', f'{key}={value}']
    commands.run(command, project, name + '-render')
    return command


def runtime_extension(project, name, root_package=False):
    source = ''
    if root_package:
        source = '''
      packageSource = builtins.path {
        path = inputs.self;
        name = "''' + name + '''-source";
        filter = path: _type:
          builtins.elem (builtins.head (pkgs.lib.splitString "/"
            (pkgs.lib.removePrefix "${inputs.self}/" (toString path))))
            [ "''' + name + '''.cabal" "src" "app" "test" "assets" ];
      };
'''
    text = '''{ inputs, ... }: {
  perSystem = { pkgs, ... }: {
    haskellProject = {
      runtime = builtins.fromJSON (builtins.readFile ./runtime-test-selection.json);
      shellHook = "export RUNTIME_FIXTURE_HOOK=original";
''' + source + '''    };
  };
}
'''
    (project / 'runtime-test-selection.json').write_text(json.dumps(SELECTION, indent=2) + '\n')
    (project / 'flake.module.nix').write_text(text)
    return text


def root_package(project, name):
    (project / 'src').mkdir()
    (project / 'app').mkdir()
    (project / 'test').mkdir()
    (project / 'assets').mkdir()
    (project / 'assets/message.txt').write_text('root-resource\n')
    (project / 'src/Demo.hs').write_text('module Demo (answer) where\nimport Data.Text (Text)\nimport Data.Text qualified as T\nanswer :: Text\nanswer = T.pack (show (41 :: Int))\n')
    (project / 'app/Main.hs').write_text('module Main where\nimport Demo\nimport Data.Text.IO qualified as T\nmain :: IO ()\nmain = T.putStrLn answer\n')
    (project / 'test/Main.hs').write_text('module Main where\nimport Demo\nimport Data.Text qualified as T\nmain :: IO ()\nmain = if T.null answer then fail "empty answer" else pure ()\n')
    (project / (name + '.cabal')).write_text('''cabal-version: 3.0
name: ''' + name + '''
version: 0.1.0.0
license: BSD-3-Clause
build-type: Simple
extra-source-files: assets/message.txt
library
  hs-source-dirs: src
  exposed-modules: Demo
  build-depends: base, text
  default-language: GHC2024
executable ''' + name + '''
  hs-source-dirs: app
  main-is: Main.hs
  build-depends: base, text, ''' + name + '''
  default-language: GHC2024
test-suite fixture-test
  type: exitcode-stdio-1.0
  hs-source-dirs: test
  main-is: Main.hs
  build-depends: base, text, ''' + name + '''
  default-language: GHC2024
''')
    (project / 'cabal.project').write_text('packages: .\n')


def track(commands, project):
    commands.run(['git', 'init', '--initial-branch=master'], project, 'git-init')
    commands.run(['git', 'add', '.'], project, 'git-track')


def eval_json(commands, project, path, label):
    return json.loads(commands.run(['nix', 'eval', '--json', '--no-write-lock-file', '.#' + path], project, label))
