#!/usr/bin/env python3
"""Generate catalog docs, adapting source-qualified edges for Seihou 0.15.

The released exporter always links recipe modules inside its own bundle. Render
local edges with that exporter, then restore external edges as canonical links
before validating the final bundle. No external templates are vendored.
"""
import json
from pathlib import Path
import shutil
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[1]
SOURCE_PROJECTS = {'https://github.com/shinzui/agent-seihou.git': 'mori://shinzui/agent-seihou'}


def run(args, cwd=ROOT):
    return subprocess.run(args, cwd=cwd, check=True, text=True, capture_output=True).stdout


def evaluate(path):
    return json.loads(run(['dhall-to-json', '--file', str(path)]))


def dhall_text(value):
    return json.dumps(value, ensure_ascii=False).replace('${', r'\${')


def main():
    catalog = evaluate(ROOT / 'seihou-registry.dhall')
    with tempfile.TemporaryDirectory(prefix='seihou-docs-') as directory:
        staging = Path(directory)
        shutil.copyfile(ROOT / 'seihou-registry.dhall', staging / 'seihou-registry.dhall')
        external_recipes = []
        for kind, descriptor in [('modules', 'module.dhall'), ('recipes', 'recipe.dhall'),
                                 ('blueprints', 'blueprint.dhall'), ('prompts', 'prompt.dhall')]:
            for entry in catalog[kind]:
                dest = staging / entry['path']
                dest.parent.mkdir(parents=True, exist_ok=True)
                if kind != 'recipes':
                    dest.symlink_to(ROOT / entry['path'], target_is_directory=True)
                    continue
                recipe = evaluate(ROOT / entry['path'] / descriptor)
                external = [edge for edge in recipe['modules'] if edge.get('source')]
                if not external:
                    dest.symlink_to(ROOT / entry['path'], target_is_directory=True)
                    continue
                for edge in external:
                    if edge['source'] not in SOURCE_PROJECTS:
                        raise ValueError(f'Add the canonical Mori project URI for source {edge["source"]}')
                # Keep the original typed descriptor and override only its member list.
                # The original file resolves any relative imports from its real path.
                dest.mkdir()
                members = []
                for edge in recipe['modules']:
                    if edge.get('source'):
                        continue
                    bindings = '[ ' + ', '.join('{ name = ' + dhall_text(v['name']) + ', value = ' + dhall_text(v['value']) + ' }'
                                              for v in edge['vars']) + ' ]' if edge['vars'] else '[] : List { name : Text, value : Text }'
                    members.append('{ module = ' + dhall_text(edge['module']) + ', source = None Text, vars = ' + bindings + ' }')
                if not members:
                    raise ValueError('The adapter requires at least one local recipe member')
                (dest / descriptor).write_text(f'({ROOT / entry["path"] / descriptor}) // {{ modules = [ '
                                               + ', '.join(members) + ' ] }\n')
                external_recipes.append((entry['name'], recipe['modules']))
        out = staging / 'generated'
        print(run(['seihou', 'extension', 'run', 'okf', '--', 'docs', '--dir', str(staging), '--out', str(out), '--force']).strip())
        for name, edges in external_recipes:
            document = out / 'recipes' / f'{name}.md'
            text = document.read_text()
            start = text.index('## Composes\n\n') + len('## Composes\n\n')
            end = text.find('\n## ', start)
            end = len(text) if end < 0 else end
            lines = []
            for edge in edges:
                name = edge['module']
                if edge.get('source'):
                    link = f'[{name}]({SOURCE_PROJECTS[edge["source"]]}/templates/{name}) (from `{edge["source"]}`)'
                else:
                    link = f'[{name}](/modules/{name}.md)'
                bindings = ', '.join(f'`{v["name"]}` = `{v["value"]}`' for v in sorted(edge['vars'], key=lambda v: v['name']))
                lines.append('- ' + link + (f' (with {bindings})' if bindings else ''))
            document.write_text(text[:start] + '\n'.join(lines) + '\n' + text[end:])
        print(run(['okf', 'validate', str(out), '--strict', '--profile', str(out / 'profile.dhall'), '--profile-enforce']).strip())
        # As with the exporter's --force, remove obsolete generated concepts too.
        # Only replace this repository's generated tree after validation passes.
        destination = ROOT / 'okf-docs'
        if destination.exists():
            shutil.rmtree(destination)
        shutil.copytree(out, destination)


if __name__ == '__main__':
    main()
