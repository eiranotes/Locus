#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DESTINATION="${1:-$ROOT/../reality-diorama-flutter-source.zip}"
cd "$ROOT"

python3 - "$ROOT" "$DESTINATION" <<'PY'
from __future__ import annotations

import sys
import zipfile
from pathlib import Path

root = Path(sys.argv[1]).resolve()
destination = Path(sys.argv[2]).resolve()
archive_root = Path('reality-diorama-flutter')
excluded_parts = {'.git', '.dart_tool', 'build', '.idea', '.gradle', 'DerivedData'}
excluded_names = {'local.properties', '.DS_Store'}

with zipfile.ZipFile(destination, 'w', compression=zipfile.ZIP_DEFLATED) as archive:
    for path in sorted(root.rglob('*')):
        relative = path.relative_to(root)
        if path.is_dir():
            continue
        if any(part in excluded_parts for part in relative.parts):
            continue
        if path.name in excluded_names:
            continue
        archive.write(path, archive_root / relative)
print(destination)
PY
