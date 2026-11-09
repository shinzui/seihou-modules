#!/usr/bin/env python3
"""Create an authored Mori seed and verify its local registration."""
import json
from pathlib import Path
import re
import shlex
import subprocess
import sys

# Published contract: mori://shinzui/mori-schema; artifact URI pending for package.dhall.
SCHEMA = 'https://raw.githubusercontent.com/shinzui/mori-schema/3522f4a51181d73c9c90fc27a7c0838bd29ae95f/package.dhall'
SCHEMA_HASH = 'sha256:dcb19e2312e790bad14e622cc98a1281cd2298c5b564a2f0d0534d3c718d8803'


def command(args, root, as_json=False):
    result = subprocess.run(args, cwd=root, capture_output=True, text=True)
    if result.returncode:
        raise RuntimeError(f'Command failed ({result.returncode}): {shlex.join(args)}\n'
                           f'{result.stdout}{result.stderr}\n'
                           'Fix the manifest or local registry connection and rerun the recipe/helper. '
                           'Generated files are preserved; registration is not rolled back.')
    if as_json:
        return json.loads(result.stdout)
    return result.stdout


def dhall_text(value):
    """JSON string escapes are valid Dhall; additionally escape interpolation."""
    return json.dumps(value, ensure_ascii=False).replace('${', r'\${')


def manifest(name, description, namespace, source_namespace, source_project):
    return f'''let Schema = {SCHEMA}
      {SCHEMA_HASH}

in Schema.Project::{{
    , project = Schema.ProjectIdentity::{{
      , name = {dhall_text(name)}
      , namespace = {dhall_text(namespace)}
      , description = Some {dhall_text(description)}
      , type = Schema.PackageType.Other "Documentation"
      , language = Schema.Language.TypeScript
      , lifecycle = Schema.Lifecycle.Active
      }}
    , dependencyRefs = [ Schema.MoriRef::{{ namespace = {dhall_text(source_namespace)}, name = {dhall_text(source_project)} }} ]
    , docs = [ Schema.DocRef::{{ key = "site", kind = Schema.DocKind.Guide, audience = Schema.DocAudience.User, location = Schema.DocLocation.LocalDir "content/docs" }} ]
    }}
'''


def registry(root):
    # A failed lookup must never be mistaken for an unregistered identity.
    return command(['mori', 'registry', 'list', '--json'], root, as_json=True)


def identity_row(rows, namespace, name):
    return next((row for row in rows if (row['namespace'], row['name']) == (namespace, name)), None)


def check_manifest(root, namespace, name, source_namespace, source_project):
    command(['mori', 'validate'], root)
    # mori show --json in 7.2 omits dependencyRefs. Evaluate the typed manifest
    # directly rather than attempting to parse or rewrite authored Dhall text.
    cfg = command(['dhall-to-json', '--file', 'mori.dhall'], root, as_json=True)
    project = cfg['project']
    if (project['namespace'], project['name']) != (namespace, name):
        raise RuntimeError('Existing mori.dhall identity disagrees with the requested documentation identity. '
                           'Reconcile it manually; the file has been preserved.')
    if not any(ref['namespace'] == source_namespace and ref['name'] == source_project
               and all(ref.get(key) is None for key in ('kind', 'key', 'anchor'))
               for ref in cfg['dependencyRefs']):
        raise RuntimeError('mori.dhall lacks the required project-level dependencyRefs documented-project association. '
                           'Reconcile it manually; the file has been preserved.')


def main():
    config_dir = Path(__file__).resolve().parent
    root = config_dir.parent.parent.resolve()
    values = {}
    for key in ('project.name', 'project.description', 'mori.namespace', 'mori.source-namespace', 'mori.source-project'):
        # Templates add one newline; preserve all newlines supplied in the value.
        value = (config_dir / f'{key}.conf').read_bytes().decode('utf-8').removesuffix('\n')
        if not value.strip():
            raise RuntimeError(f'{key} is required.')
        if key != 'project.description' and not re.fullmatch('[a-z][a-z0-9-]*', value):
            raise RuntimeError(f'{key} must match [a-z][a-z0-9-]*.')
        values[key] = value
    name, namespace = values['project.name'], values['mori.namespace']
    source_namespace, source_project = values['mori.source-namespace'], values['mori.source-project']
    identity = f'mori://{namespace}/{name}'
    target = f'mori://{source_namespace}/{source_project}'
    if identity == target:
        raise RuntimeError('A documentation project cannot document itself; choose a distinct source project.')
    rows = registry(root)
    if identity_row(rows, source_namespace, source_project) is None:
        raise RuntimeError(f'Documented project {target} is not registered locally. Register it first, then rerun. '
                           'No documentation manifest or registration was created.')
    existing = identity_row(rows, namespace, name)
    if existing is not None and Path(existing['path']).resolve() != root:
        raise RuntimeError(f'{identity} is already registered at a different path: {existing["path"]}. '
                           'Choose another identity or reconcile explicitly with Mori.')
    path = root / 'mori.dhall'
    if not path.exists():
        # Exclusive creation avoids replacing a concurrently authored manifest.
        with path.open('x') as handle:
            handle.write(manifest(name, values['project.description'], namespace, source_namespace, source_project))
    check_manifest(root, namespace, name, source_namespace, source_project)
    command(['mori', 'register', '--local', '--path', str(root)], root)
    registered = command(['mori', 'registry', 'show', f'{namespace}/{name}', '--json'], root, as_json=True)
    if ((registered['namespace'], registered['name']) != (namespace, name)
            or Path(registered['path']).resolve() != root):
        raise RuntimeError('Registration readback did not match the documentation identity/path. Rerun after reconciliation.')
    relations = command(['mori', 'registry', 'relations', '--from', identity, '--json'], root, as_json=True)
    if not any(row['sourceRef'] == identity and row['targetRef'] == target
               and row['edgeKind'] == 'depends-on' and row['resolved'] for row in relations):
        raise RuntimeError('Registration readback lacks the resolved documented-project association. Rerun after reconciliation.')
    print(f'Registered {identity} at {root}; documented project: {target}')


if __name__ == '__main__':
    try:
        main()
    except (RuntimeError, OSError, ValueError, KeyError) as error:
        print(f'docs-mori-bootstrap: {error}', file=sys.stderr)
        sys.exit(1)
