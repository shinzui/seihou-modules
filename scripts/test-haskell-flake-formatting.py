#!/usr/bin/env python3
"""Verify that the scaffold's own formatter preserves the managed Haskell module."""

from itertools import product
from pathlib import Path
import re
import tempfile

from haskell_runtime_test_support import Commands, render, track


def main():
    destination = Path(tempfile.mkdtemp(prefix='haskell-flake-formatting-'))
    print(f'Formatter fixtures and logs: {destination}', flush=True)
    commands = Commands(destination / 'logs')
    feature_names = ('nix.postgresql', 'nix.kafka', 'nix.builtin-package')

    for index, values in enumerate(product(('false', 'true'), repeat=len(feature_names))):
        name = f'formatter-fixture-{index}'
        project = destination / name
        features = dict(zip(feature_names, values))
        features.update({'nix.treefmt': 'true', 'nix.pre-commit': 'true'})
        command = render(commands, project, name, features=features)
        track(commands, project)

        path = 'nix/haskell.nix'
        commands.run(['nix', 'fmt', '--no-write-lock-file', '--', path], project, f'{name}-format')
        commands.run(['git', 'diff', '--exit-code', '--', path], project, f'{name}-baseline')
        preview = commands.run(command + ['--dry-run'], project, f'{name}-preview')
        assert re.search(r'^\s*\[unchanged\]\s+nix/haskell\.nix\s', preview, re.MULTILINE), preview
        assert re.search(r'\b0 conflicts\b', preview), preview

    print('Haskell flake formatting and Seihou reapplication passed.', flush=True)


if __name__ == '__main__':
    main()
