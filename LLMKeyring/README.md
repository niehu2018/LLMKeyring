# LLM Keyring (MVP)

A lightweight macOS SwiftUI menu bar app to manage multiple LLM providers (Ollama, Aliyun/OpenAI-compatible, DeepSeek, Kimi): add/edit/delete providers, securely store API keys in Keychain, and test health/connectivity.

This MVP includes:
- Menu bar extra + management window (list + detail).
- Provider models and storage (UserDefaults, Keychain for secrets).
- Provider adapters: OpenAI-compatible (DeepSeek, Kimi, Aliyun compatible) and Ollama, with health test.

## Getting Started (Xcode)

1) Open Xcode, create a new project: App > macOS > App.
   - Product Name: `LLMKeyring`
   - Interface: SwiftUI
   - Language: Swift
   - Minimum macOS: 13.0 or later
2) Close Xcode. Copy the `LLMKeyring` folder contents from this repo into your Xcode project's source folder (replace the auto-generated files with these):
   - App files in `App/`
   - Models in `Models/`
   - Storage in `Storage/`
   - Keychain in `Keychain/`
   - Networking in `Networking/`
   - Providers in `Providers/`
   - Views in `Views/`
3) Reopen the project in Xcode, ensure the files are added to the target (select the target `LLMKeyring` > Build Phases > Compile Sources).
4) Build & Run. The app will appear as a menu bar item. Click it to open the management window.

## Build & Run (CLI)

Prereqs:
- Install full Xcode (not just CLT), accept license: `sudo xcodebuild -license`
- Select Xcode path: `sudo xcode-select -s /Applications/Xcode.app/Contents/Developer`

Commands:
- Build without signing (then ad‑hoc sign) and run:
  - `cd LLMKeyring`
  - `bash scripts/build_and_run.sh`
- Build with your Apple Developer Team ID (automatic signing) and run:
  - `cd LLMKeyring`
  - `TEAM_ID=YOURTEAMID bash scripts/build_and_run.sh`

Output app path: `LLMKeyring/build/Build/Products/Debug/LLMKeyring.app`

### Note on rename
This repo now uses folder and project name "LLMKeyring".
If you pulled an older revision with name "LLMManager", run `bash LLMManager/scripts/rename_project.sh` once to migrate.

## App Icon
- Asset Catalog: `Assets.xcassets/AppIcon.appiconset` (uses filenames like `icon_16.png`, `icon_32.png`, ..., `icon_1024.png`).
- Generate/update all sizes from a 1024 base:
  - `cd LLMKeyring`
  - `bash scripts/make_app_icon.sh`
- Note: The app also sets a runtime Dock icon programmatically. For Finder to show it, build with the Asset Catalog present (run the script once to create PNGs).

## Notes
- API keys are stored only in macOS Keychain (`service: LLMKeyring`, `account: prov_<uuid>`). They are not exported or logged.
- Health test for OpenAI-compatible providers calls `{baseURL}/v1/models` with `Authorization: Bearer <key>`.
- Health test for Ollama calls `{baseURL}/api/tags`.

## Default Provider Base URLs
- DeepSeek: `https://api.deepseek.com`
- Kimi (Moonshot): `https://api.moonshot.cn`
- Aliyun (DashScope compatible mode, China): `https://dashscope.aliyuncs.com/compatible-mode`
 - SiliconFlow (CN): `https://api.siliconflow.cn`
 - Ollama (local): `http://127.0.0.1:11434` (use IPv4 to avoid ::1 issues)
 - Anthropic (Claude): `https://api.anthropic.com`
 - Google Gemini: `https://generativelanguage.googleapis.com`
 - Azure OpenAI: `https://<resource>.openai.azure.com`
 - OpenRouter: `https://openrouter.ai/api`
 - Together AI: `https://api.together.xyz`

OpenAI-compatible adapter auto-normalizes the path:
- If you include `/v1`, it requests `/v1/models`.
- If not, it appends `/v1/models` automatically.

Anthropic adapter expects headers:
- `x-api-key: <key>` and `anthropic-version: 2023-06-01`.

Google Gemini adapter appends API key as query parameter:
- `GET /v1/models?key=<key>`.

Azure OpenAI adapter lists deployments:
- `GET /openai/deployments?api-version=2023-05-15` with header `api-key: <key>`.

## Roadmap (next)
- Model listing and capability tagging (tools/vision/etc.)
- Batch tests and better error categorization
- Optional migrations to Core Data
