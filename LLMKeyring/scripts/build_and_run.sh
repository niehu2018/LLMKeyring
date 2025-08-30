#!/usr/bin/env bash
set -euo pipefail

# One‑shot build & run for LLMKeyring (macOS app).
# Usage:
#   bash scripts/build_and_run.sh              # build without signing, then ad‑hoc sign and run
#   TEAM_ID=YOURTEAMID bash scripts/build_and_run.sh  # build with your dev team signing and run

ROOT_DIR=$(cd "$(dirname "$0")/.." && pwd)
# Prefer new folder name if present, fallback to old
PROJ_DIR="$ROOT_DIR/LLMKeyring"
PROJECT_FILE="LLMKeyring.xcodeproj"
DERIVED="$PROJ_DIR/build"
APP_PATH="$DERIVED/Build/Products/Debug/LLMKeyring.app"

echo "[i] Using project: $PROJ_DIR"

if ! command -v xcodebuild >/dev/null 2>&1; then
  echo "[!] xcodebuild not found. Install full Xcode and run: sudo xcode-select -s /Applications/Xcode.app/Contents/Developer" >&2
  exit 1
fi

if ! xcodebuild -version >/dev/null 2>&1; then
  echo "[!] xcodebuild is not available. Ensure Xcode is installed and license accepted: sudo xcodebuild -license" >&2
  exit 1
fi

cd "$PROJ_DIR"
echo "[i] Cleaning previous build..."
rm -rf "$DERIVED"

if [[ -n "${TEAM_ID:-}" ]]; then
  echo "[i] Building with DEVELOPMENT_TEAM=$TEAM_ID (automatic signing)..."
  xcodebuild \
    -project "$PROJECT_FILE" \
    -scheme LLMKeyring \
    -configuration Debug \
    -derivedDataPath "$DERIVED" \
    -destination 'platform=macOS' \
    -allowProvisioningUpdates \
    DEVELOPMENT_TEAM="$TEAM_ID" \
    clean build
else
  echo "[i] Building without signing (CODE_SIGNING_ALLOWED=NO)..."
  xcodebuild \
    -project "$PROJECT_FILE" \
    -scheme LLMKeyring \
    -configuration Debug \
    -derivedDataPath "$DERIVED" \
    -destination 'platform=macOS' \
    CODE_SIGNING_ALLOWED=NO \
    clean build
fi

if [[ ! -d "$APP_PATH" ]]; then
  echo "[!] Build output not found: $APP_PATH" >&2
  exit 1
fi

if [[ -z "${TEAM_ID:-}" ]]; then
  echo "[i] Ad‑hoc signing the app (for local run)..."
  codesign --force --deep -s - "$APP_PATH"
fi

echo "[i] Launching app: $APP_PATH"
open "$APP_PATH"

echo "[✓] Done. If Gatekeeper blocks, allow it in System Settings > Privacy & Security or click 'Open Anyway'."
