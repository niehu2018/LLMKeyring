#!/usr/bin/env bash
set -euo pipefail

# Rename project folder and .xcodeproj from LLMManager -> LLMKeyring.
# Usage: bash scripts/rename_project.sh

ROOT_DIR=$(cd "$(dirname "$0")/.." && pwd)

if [[ ! -d "$ROOT_DIR/LLMManager" ]]; then
  echo "[!] LLMManager folder not found at $ROOT_DIR" >&2
  exit 1
fi

if [[ -d "$ROOT_DIR/LLMKeyring" ]]; then
  echo "[!] Target folder LLMKeyring already exists. Abort to avoid overwrite." >&2
  exit 1
fi

echo "[i] Renaming folder: LLMManager -> LLMKeyring"
mv "$ROOT_DIR/LLMManager" "$ROOT_DIR/LLMKeyring"

if [[ -d "$ROOT_DIR/LLMKeyring/LLMManager.xcodeproj" ]]; then
  echo "[i] Renaming .xcodeproj: LLMManager.xcodeproj -> LLMKeyring.xcodeproj"
  mv "$ROOT_DIR/LLMKeyring/LLMManager.xcodeproj" "$ROOT_DIR/LLMKeyring/LLMKeyring.xcodeproj"
fi

echo "[✓] Done. Open: $ROOT_DIR/LLMKeyring/LLMKeyring.xcodeproj"

