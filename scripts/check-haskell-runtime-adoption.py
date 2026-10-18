#!/usr/bin/env python3
"""Run the same standalone checker shipped with the adoption blueprint."""
from pathlib import Path
import runpy

runpy.run_path(str(Path(__file__).resolve().parents[1] / 'blueprints/upgrade-haskell-runtime/files/check-haskell-runtime-adoption.py'), run_name='__main__')
