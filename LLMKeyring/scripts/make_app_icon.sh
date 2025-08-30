#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR=$(cd "$(dirname "$0")/.." && pwd)
ASSET_DIR="$ROOT_DIR/Assets.xcassets/AppIcon.appiconset"
BASE_PNG="$ASSET_DIR/icon_1024.png"

mkdir -p "$ASSET_DIR"

# Ensure Contents.json exists with macOS entries
CONTENTS_JSON="$ASSET_DIR/Contents.json"
if [[ ! -f "$CONTENTS_JSON" ]]; then
  cat > "$CONTENTS_JSON" <<'JSON'
{
  "images": [
    {"idiom":"mac","size":"16x16","scale":"1x","filename":"icon_16.png"},
    {"idiom":"mac","size":"16x16","scale":"2x","filename":"icon_32.png"},
    {"idiom":"mac","size":"32x32","scale":"1x","filename":"icon_32.png"},
    {"idiom":"mac","size":"32x32","scale":"2x","filename":"icon_64.png"},
    {"idiom":"mac","size":"128x128","scale":"1x","filename":"icon_128.png"},
    {"idiom":"mac","size":"128x128","scale":"2x","filename":"icon_256.png"},
    {"idiom":"mac","size":"256x256","scale":"1x","filename":"icon_256.png"},
    {"idiom":"mac","size":"256x256","scale":"2x","filename":"icon_512.png"},
    {"idiom":"mac","size":"512x512","scale":"1x","filename":"icon_512.png"},
    {"idiom":"mac","size":"512x512","scale":"2x","filename":"icon_1024.png"}
  ],
  "info": {"version": 1, "author": "xcode"}
}
JSON
fi

if [[ ! -f "$BASE_PNG" ]]; then
  echo "[i] Base icon missing; creating minimal placeholder..."
  TMP="$ASSET_DIR/icon_1x1.png"
  # Transparent 1x1 PNG (base64)
  BASE64="iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR4nGMAAQAABQABDQottAAAAABJRU5ErkJggg=="
  echo "$BASE64" | base64 --decode > "$TMP"
  sips -Z 1024 "$TMP" --out "$BASE_PNG" >/dev/null
  rm -f "$TMP"
fi

echo "[i] Generating resized variants..."
sizes=(16 32 64 128 256 512)
for s in "${sizes[@]}"; do
  out="$ASSET_DIR/icon_${s}.png"
  sips -Z "$s" "$BASE_PNG" --out "$out" >/dev/null
  echo " - $out"
done

echo "[✓] AppIcon images updated in $ASSET_DIR"
