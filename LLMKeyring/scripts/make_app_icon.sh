#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR=$(cd "$(dirname "$0")/.." && pwd)
ASSET_DIR="$ROOT_DIR/Assets.xcassets/AppIcon.appiconset"
BASE_PNG="$ASSET_DIR/icon_1024.png"

echo "[i] Generating 1024x1024 base icon..."
xcrun swift "$ROOT_DIR/scripts/gen_app_icon.swift" "$BASE_PNG"

echo "[i] Generating resized variants..."
sizes=(16 32 64 128 256 512)
for s in "${sizes[@]}"; do
  out="$ASSET_DIR/icon_${s}.png"
  sips -Z "$s" "$BASE_PNG" --out "$out" >/dev/null
  echo " - $out"
done

echo "[✓] AppIcon images updated in $ASSET_DIR"

