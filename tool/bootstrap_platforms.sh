#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

if [[ -z "${CI:-}" ]]; then
  cat >&2 <<'EOF'
This recovery script regenerates platform wrappers and reapplies the tracked native bridges.
Review the resulting diff before committing when it is run in a developer checkout.
EOF
fi

if ! command -v flutter >/dev/null 2>&1; then
  echo "flutter is required" >&2
  exit 1
fi

BRIDGE_DIR="$(mktemp -d)"
trap 'rm -rf "$BRIDGE_DIR"' EXIT
cp android/app/src/main/kotlin/com/eiranotes/reality_diorama/MainActivity.kt "$BRIDGE_DIR/MainActivity.kt"
cp ios/Runner/AppDelegate.swift "$BRIDGE_DIR/AppDelegate.swift"
cp ios/Runner/SceneDelegate.swift "$BRIDGE_DIR/SceneDelegate.swift"

flutter create \
  --platforms=android,ios \
  --org com.eiranotes \
  --project-name reality_diorama \
  --android-language kotlin \
  --ios-language swift \
  .

mkdir -p android/app/src/main/kotlin/com/eiranotes/reality_diorama ios/Runner
cp "$BRIDGE_DIR/MainActivity.kt" android/app/src/main/kotlin/com/eiranotes/reality_diorama/MainActivity.kt
cp "$BRIDGE_DIR/AppDelegate.swift" ios/Runner/AppDelegate.swift
cp "$BRIDGE_DIR/SceneDelegate.swift" ios/Runner/SceneDelegate.swift

python3 tool/patch_platform_manifests.py

echo "Platform wrappers generated and sensor bridges reapplied."
