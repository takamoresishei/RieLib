#!/usr/bin/env python3
"""Compile every source and distribution file, then run Luau contract tests."""
from pathlib import Path
import argparse
import os
import shutil
import subprocess
import tempfile
from build import ROOT, bundle_loader, build

parser = argparse.ArgumentParser()
parser.add_argument('--luau', default=os.environ.get('LUAU', 'luau'))
parser.add_argument('--compiler', default=os.environ.get('LUAU_COMPILE', 'luau-compile'))
args = parser.parse_args()
for executable in (args.luau, args.compiler):
    if not shutil.which(executable):
        raise SystemExit(f'Missing {executable}; install the official Luau CLI or pass --luau/--compiler.')
build(check=True)
sources = sorted((ROOT/'Aurelis').rglob('*.lua')) + sorted((ROOT/'examples').glob('*.lua')) + sorted((ROOT/'dist').glob('*.lua'))
for path in sources:
    result = subprocess.run([args.compiler, str(path)], capture_output=True, text=True)
    if result.returncode:
        raise SystemExit(result.stderr)
print(f'Compiled {len(sources)} Luau source and distribution files', flush=True)
harness = (ROOT/'tests/RobloxMock.luau').read_text() + '\n' + bundle_loader() + '\n' + (ROOT/'tests/Spec.luau').read_text()
with tempfile.TemporaryDirectory(prefix='aurelis-test-') as directory:
    path = Path(directory)/'run.luau'
    path.write_text(harness)
    subprocess.run([args.luau, str(path)], check=True)
