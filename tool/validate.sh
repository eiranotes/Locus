#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

python3 tool/check_repo.py
python3 - <<'PY'
import json
from pathlib import Path
import xml.etree.ElementTree as ET

root = Path('.')
for path in root.glob('assets/content/*.json'):
    json.loads(path.read_text(encoding='utf-8'))
for path in (
    root / 'android/app/src/main/AndroidManifest.xml',
    root / 'android/app/src/debug/AndroidManifest.xml',
    root / 'android/app/src/profile/AndroidManifest.xml',
    root / 'ios/Runner/Info.plist',
    root / 'ios/Runner/Runner.entitlements',
):
    ET.parse(path)
print('content and manifest checks passed')
PY

if command -v swiftc >/dev/null 2>&1; then
  swiftc -parse ios/Runner/AppDelegate.swift ios/Runner/SceneDelegate.swift
  echo "Swift parse passed"
fi

if command -v kotlinc >/dev/null 2>&1; then
  kotlin_log="$(mktemp)"
  kotlin_out="$(mktemp -u).jar"
  if ! kotlinc android/app/src/main/kotlin/com/eiranotes/reality_diorama/MainActivity.kt \
      -d "$kotlin_out" >"$kotlin_log" 2>&1; then
    if grep -Eiq "expecting|unexpected tokens|unclosed comment|syntax error" "$kotlin_log"; then
      cat "$kotlin_log" >&2
      rm -f "$kotlin_log" "$kotlin_out"
      exit 1
    fi
  fi
  rm -f "$kotlin_log" "$kotlin_out"
  echo "Kotlin syntax-level check passed (Android/Flutter classpath resolution deferred to Gradle CI)"
fi

if command -v flutter >/dev/null 2>&1; then
  flutter pub get
  dart format --output=none lib test
  flutter analyze
  flutter test
else
  echo "Flutter SDK not found: skipped pub resolution, analyzer, and Flutter tests." >&2
fi
