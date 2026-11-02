#!/usr/bin/env python3
"""Create a client repository using resolved Seihou inputs as data, never shell code."""

from pathlib import Path
import subprocess
import sys


def main():
    config = Path('.seihou/openapi-typescript-client-dir')
    values = {}
    for path in config.glob('*.conf'):
        value = path.read_text().rstrip('\n')
        if value:
            values[path.stem] = value

    name = values['project.name']
    post_create = values.pop('repo.postCreateScript', None)
    if post_create:
        post_create = Path(post_create).expanduser().absolute()
        if not post_create.is_file():
            raise ValueError(f'Post-creation script does not exist: {post_create}')
    if values['mori.generate'] == 'true':
        for key in ['mori.namespace', 'mori.source-namespace', 'mori.source-project']:
            if not values.get(key):
                raise ValueError(f'{key} is required when mori.generate=true')
    target = Path(values.pop('repo.parentDir')).expanduser() / name
    if target.is_symlink() or (target.exists() and (not target.is_dir() or any(target.iterdir()))):
        raise ValueError(f'{target} already exists and is not an empty directory')

    # Resolve relative paths before entering the new project. Running the two
    # modules together generates all files before git-init creates its commit.
    target = target.absolute()
    target.mkdir(parents=True, exist_ok=True)
    args = ['seihou', 'run', 'openapi-typescript-client', '-m', 'git-init', '--no-save-prompted']
    values.update({'git.repoName': name, 'git.createGithub': 'true', 'git.initialCommit': 'true',
                   'openapi.schema': 'openapi.yaml'})
    for key, value in values.items():
        args.extend(['--var', f'{key}={value}'])
    subprocess.run(args, cwd=target, check=True)
    if post_create:
        subprocess.run([sys.executable, str(post_create)], check=True)
    print(f'Created {target} -> https://github.com/{values["git.githubOwner"]}/{name}')


if __name__ == '__main__':
    try:
        main()
    except (OSError, ValueError, subprocess.CalledProcessError) as error:
        print(f'openapi-typescript-client-dir: {error}', file=sys.stderr)
        sys.exit(1)
