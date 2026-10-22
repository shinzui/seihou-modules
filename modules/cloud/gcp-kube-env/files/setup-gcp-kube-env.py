#!/usr/bin/env python3
"""Materialize this checkout's private cloud settings from Seihou's parameters."""

import json
import os
from pathlib import Path
import re
import shlex
import stat
import subprocess
import tempfile

BEGIN = '# >>> seihou:gcp-kube-env'
END = '# <<< seihou:gcp-kube-env'


def read_file(path):
    if path.is_symlink():
        raise ValueError(f'Refusing to replace symlink: {path}')
    return path.read_text() if path.exists() else ''


def write_file(path, content, private=False, temp_dir=None):
    """Replace atomically, retaining public file modes and restricting credentials."""
    mode = 0o600 if private else (stat.S_IMODE(path.stat().st_mode) if path.exists() else 0o644)
    if path.exists() and path.read_text() == content:
        if private:
            path.chmod(mode)
        return
    with tempfile.NamedTemporaryFile(mode='w', dir=temp_dir or path.parent, delete=False) as handle:
        temp_path = Path(handle.name)
        try:
            os.chmod(temp_path, mode)
            handle.write(content)
            handle.close()
            os.replace(temp_path, path)
        finally:
            temp_path.unlink(missing_ok=True)


def managed_env(existing, block):
    lines = existing.splitlines(keepends=True)
    starts = [i for i, line in enumerate(lines) if line.rstrip('\r\n') == BEGIN]
    ends = [i for i, line in enumerate(lines) if line.rstrip('\r\n') == END]
    if not starts and not ends:
        return existing + ('\n' if existing and not existing.endswith('\n') else '') + block
    if len(starts) != 1 or len(ends) != 1 or starts[0] >= ends[0]:
        raise ValueError('Malformed gcp-kube-env block; expected one matching pair of markers')
    return ''.join(lines[:starts[0]]) + block + ''.join(lines[ends[0] + 1:])


def append_lines(existing, additions):
    result = existing
    for line in additions:
        if line not in result.splitlines():
            result += ('\n' if result and not result.endswith('\n') else '') + line + '\n'
    return result


def git(root, *args):
    # Inspect this checkout's normal index, even when invoked from a Git hook
    # or a caller that exports an alternate index or work tree.
    env = {key: value for key, value in os.environ.items() if not key.startswith('GIT_')}
    result = subprocess.run(['git', *args], cwd=root, env=env, text=True, capture_output=True)
    if result.returncode not in (0, 1):
        raise ValueError(f'Cannot verify Git protection: {result.stderr.strip()}')
    return result


def require_untracked(root, paths):
    result = git(root, 'ls-files', '--cached', '-z', '--', *paths)
    if result.returncode or result.stdout:
        raise ValueError('Private output paths must be untracked in Git: ' + ', '.join(paths))


def require_ignored(root, paths):
    for path in paths:
        if git(root, 'check-ignore', '--quiet', '--', path).returncode:
            raise ValueError(f'Private output is not ignored by Git: {path}; fix conflicting ignore rules')


def main():
    root = Path(__file__).resolve().parents[1]
    values = (root / '.seihou/gcp-kube-env.conf').read_text().splitlines()
    if len(values) != 3:
        raise ValueError('Expected three single-line settings: gcp.project, k8s.context, env.file')
    project, context, filename = values
    if not re.fullmatch(r'[a-z][a-z0-9-]{4,28}[a-z0-9]', project):
        raise ValueError('gcp.project must be a Google Cloud project ID (6-30 lowercase letters, digits, hyphens)')
    if not context or any(ord(char) < 32 or ord(char) == 127 for char in context):
        raise ValueError('k8s.context must be a nonempty single-line context name')
    if (not re.fullmatch(r'[A-Za-z0-9._-]+', filename)
            or filename in {'.', '..', '.envrc', '.gitignore', '.direnv'}):
        raise ValueError('env.file must be a checkout-root filename other than .envrc, .gitignore, or .direnv')

    private_dir = root / '.direnv'
    if private_dir.is_symlink():
        raise ValueError('Refusing to write kubeconfig through a .direnv symlink')
    kube_path = private_dir / 'gcp-kube-env.kubeconfig'
    env_path = root / filename
    loader_path = root / '.envrc'
    ignore_path = root / '.gitignore'
    existing_env = read_file(env_path)
    existing_loader = read_file(loader_path)
    existing_ignore = read_file(ignore_path)
    if kube_path.is_symlink():
        raise ValueError('Refusing to replace a kubeconfig symlink')
    private_paths = [filename, '.direnv']
    require_untracked(root, private_paths)

    block = '\n'.join([
        BEGIN,
        f'export CLOUDSDK_CORE_PROJECT={shlex.quote(project)}',
        f'export GOOGLE_CLOUD_PROJECT={shlex.quote(project)}',
        f'export KUBECONFIG={shlex.quote(str(kube_path))}',
        END, '',
    ])
    env_content = managed_env(existing_env, block)
    loader_content = append_lines(existing_loader, [f'source_env_if_exists {shlex.quote(filename)}'])
    ignore_content = append_lines(existing_ignore, [f'/{filename}', '/.direnv/'])

    # Retargeting from an already activated checkout must consult the user's
    # source config, rather than the old single-context snapshot we generated.
    source_env = os.environ.copy()
    if (source_env.get('KUBECONFIG')
            and Path(source_env['KUBECONFIG']).expanduser().resolve() == kube_path):
        source_env.pop('KUBECONFIG')
    result = subprocess.run([
        'kubectl', '--context', context, 'config', 'view',
        '--minify', '--flatten', '--raw', '-o', 'json',
    ], env=source_env, text=True, capture_output=True)
    if result.returncode:
        raise ValueError(f'Cannot read kube context {context!r}: {result.stderr.strip()}')
    config = json.loads(result.stdout)
    contexts = config.get('contexts', [])
    if len(contexts) != 1 or contexts[0].get('name') != context:
        raise ValueError('kubectl did not return the requested single-context configuration')
    config['current-context'] = context

    # Install and verify exclusions before creating credentials or temporary
    # files. If a later write fails, any remaining private files stay ignored.
    write_file(ignore_path, ignore_content)
    require_ignored(root, [filename, '.direnv/'])
    private_dir.mkdir(exist_ok=True)
    require_ignored(root, [filename, '.direnv/gcp-kube-env.kubeconfig'])
    write_file(kube_path, json.dumps(config, indent=2) + '\n', private=True)
    write_file(env_path, env_content, private=True, temp_dir=private_dir)
    write_file(loader_path, loader_content)
    print(f'gcp-kube-env: configured {filename} for project {project} and context {context}')


if __name__ == '__main__':
    try:
        main()
    except (OSError, ValueError) as error:
        raise SystemExit(f'gcp-kube-env: {error}') from None
