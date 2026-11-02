#!/usr/bin/env python3
"""Exercise the real recipe and git-init offline, without changing personal caches."""

import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[1]


def main():
    with tempfile.TemporaryDirectory(prefix='seihou-client-repo-') as directory:
        work = Path(directory)
        installed = work / 'config/seihou/installed'
        for relative in ['modules/typescript/nix-bun-flake',
                         'modules/typescript/openapi-typescript-client',
                         'modules/typescript/openapi-typescript-client-dir',
                         'modules/git/git-init', 'recipes/openapi-typescript-client-repo']:
            source = ROOT / relative
            shutil.copytree(source, installed / source.name)
        tools = work / 'bin'
        tools.mkdir()
        gh = tools / 'gh'
        gh.write_text('''#!/usr/bin/env python3
import json
import os
from pathlib import Path
import subprocess
import sys
assert Path('package.json').is_file(), 'GitHub creation ran outside client folder'
subprocess.run(['git', 'cat-file', '-e', 'HEAD:src/client.ts'], check=True)
subprocess.run(['git', 'cat-file', '-e', 'HEAD:flake.nix'], check=True)
with open(os.environ['CLIENT_REPO_GH_LOG'], 'a') as handle:
    handle.write(json.dumps({'cwd': str(Path.cwd()), 'args': sys.argv[1:]}) + '\\n')
if sys.argv[1:3] == ['repo', 'create']:
    subprocess.run(['git', 'remote', 'add', 'origin', 'https://github.com/' + sys.argv[3] + '.git'], check=True)
''')
        gh.chmod(0o755)
        env = {**os.environ, 'XDG_CONFIG_HOME': str(work / 'config'),
               'PATH': str(tools) + os.pathsep + os.environ['PATH'],
               'GIT_AUTHOR_NAME': 'Recipe Test', 'GIT_AUTHOR_EMAIL': 'recipe@example.invalid',
               'GIT_COMMITTER_NAME': 'Recipe Test', 'GIT_COMMITTER_EMAIL': 'recipe@example.invalid',
               'CLIENT_REPO_GH_LOG': str(work / 'gh.jsonl')}

        def run(args, cwd=work, succeeds=True):
            result = subprocess.run(args, cwd=cwd, env=env, input='', text=True,
                                    capture_output=True, timeout=120)
            assert (result.returncode == 0) == succeeds, result.stdout + result.stderr
            return result.stdout + result.stderr

        def apply(cwd, name, extra=(), succeeds=True):
            cwd.mkdir(parents=True, exist_ok=True)
            return run(['seihou', 'run', 'openapi-typescript-client-repo', '--no-save-prompted',
                        '--var', f'project.name={name}', '--var', "project.description=Example client's $(touch should-not-exist)",
                        *extra], cwd, succeeds)

        # Dry-run plans the wrapper without creating the target or invoking gh.
        apply(work / 'preview', 'preview-client', ['--dry-run', '--var', 'git.githubOwner=preview-owner'])
        assert not (work / 'preview/preview-client').exists()
        assert not (work / 'gh.jsonl').exists()

        parent = work / "client's projects $(touch should-not-exist)"
        invocation = work / 'personal'
        apply(invocation, 'widgets-client', ['--var', f'repo.parentDir={parent}',
              '--var', 'git.githubOwner=personal-owner'])
        target = parent / 'widgets-client'
        package = json.loads((target / 'package.json').read_text())
        assert package['name'] == 'widgets-client'
        assert package['description'] == "Example client's $(touch should-not-exist)"
        assert not (target / 'should-not-exist').exists()
        assert run(['git', 'log', '-1', '--format=%s'], target).strip() == 'Initial commit'
        assert run(['git', 'status', '--porcelain'], target).strip() == ''
        assert 'personal-owner/widgets-client.git' in run(['git', 'remote', 'get-url', 'origin'], target)
        assert not (invocation / '.git').exists() and not (invocation / 'package.json').exists()
        assert (target / '.seihou/manifest.json').exists()
        ignore = (target / '.gitignore').read_text()
        assert 'node_modules' in ignore and '.claude/' in ignore

        # Context values are explicitly forwarded to the run in the new folder.
        run(['seihou', 'config', 'set', 'git.githubOwner', 'example-org', '--context', 'recipe-test'])
        run(['seihou', 'config', 'set', 'git.githubTeam', 'developers', '--context', 'recipe-test'])
        apply(work / 'organization', 'org-client', ['--context', 'recipe-test',
              '--var', 'git.githubVisibility=public', '--var', 'git.defaultBranch=main',
              '--var', 'git.githubTeamPermission=maintain'])
        org = work / 'organization/org-client'
        assert run(['git', 'branch', '--show-current'], org).strip() == 'main'
        calls = [json.loads(line) for line in (work / 'gh.jsonl').read_text().splitlines()]
        assert calls[0]['args'] == ['repo', 'create', 'personal-owner/widgets-client',
                                   '--private', '--source=.', '--remote=origin', '--push']
        assert calls[1]['args'][2:4] == ['example-org/org-client', '--public']
        assert calls[2]['args'] == ['api', '-X', 'PUT',
            '/orgs/example-org/teams/developers/repos/example-org/org-client',
            '-f', 'permission=maintain', '--silent']
        assert Path(calls[1]['cwd']) == org.resolve()

        # A second invocation refuses to overwrite an existing client.
        original = (target / 'package.json').read_bytes()
        output = apply(invocation, 'widgets-client', ['--var', f'repo.parentDir={parent}',
                       '--var', 'git.githubOwner=personal-owner'], succeeds=False)
        assert 'not an empty directory' in output
        assert (target / 'package.json').read_bytes() == original
        assert len((work / 'gh.jsonl').read_text().splitlines()) == 3
        for key, value in [('project.name', '../escape'), ('git.githubOwner', 'bad/owner')]:
            output = apply(work / ('invalid-' + key), 'invalid-client',
                           ['--var', 'git.githubOwner=example-owner', '--var', f'{key}={value}'], False)
            assert 'validation' in output.lower() or 'invalid' in output.lower()
            assert not (work / ('invalid-' + key) / 'invalid-client').exists()
        print('OpenAPI TypeScript client repo recipe passed (real Seihou/git, offline GitHub stub).')


if __name__ == '__main__':
    main()
