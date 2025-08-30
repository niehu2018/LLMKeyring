# Repository Guidelines

## Project Structure & Module Organization
- Root app: `LLMKeyring/` (macOS SwiftUI).
- Key folders: `App/` (entry, app lifecycle), `Views/` (SwiftUI screens, Menu Bar), `Models/` (domain types), `Providers/` (adapters: OpenAI‑compatible, Ollama, Aliyun), `Networking/`, `Storage/` (UserDefaults), `Keychain/` (secure secrets), `Utilities/`, `Assets.xcassets/`, `scripts/`.
- Localization: `en.lproj/`, `zh-Hans.lproj/`.

## Build, Test, and Development Commands
- Xcode: open `LLMKeyring/LLMKeyring.xcodeproj`, select scheme `LLMKeyring`, run.
- CLI build + run (no signing):
  - `cd LLMKeyring && bash scripts/build_and_run.sh`
- CLI build + run (automatic signing):
  - `cd LLMKeyring && TEAM_ID=YOURTEAMID bash scripts/build_and_run.sh`
- App icon assets:
  - `cd LLMKeyring && bash scripts/make_app_icon.sh`
- Notes: Requires full Xcode. If Gatekeeper blocks, allow in System Settings.

## Coding Style & Naming Conventions
- Language: Swift 5+, SwiftUI. Indent 4 spaces, avoid trailing whitespace.
- Follow Swift API Design Guidelines; keep files focused (one top‑level type per file).
- Naming: Types `UpperCamelCase` (e.g., `ProviderStore`), methods/vars `lowerCamelCase` (e.g., `defaultProviderID`). Views end with `View` (e.g., `SettingsView.swift`). Asset icons: `icon_<size>.png`.
- Access control: default to `internal`; use `private` for helpers.
- Lint/format: Use Xcode’s formatter; wrap at ~120 cols when reasonable.

## Testing Guidelines
- Current repo has no test target. When adding tests, use XCTest in `LLMKeyringTests/`.
- File naming: `<Feature>Tests.swift`; test funcs start with `test...`.
- Run in Xcode (Product > Test) or CLI:
  - `xcodebuild -project LLMKeyring/LLMKeyring.xcodeproj -scheme LLMKeyring -destination 'platform=macOS' test`
- Aim for coverage on models, providers/adapters, and networking error paths.

## Commit & Pull Request Guidelines
- Commits: Use Conventional Commits (e.g., `feat: add Aliyun native provider`, `fix: handle IPv4 for Ollama`). Keep changes scoped and message bodies specific.
- PRs: Use `.github/pull_request_template.md`. Include concise description, linked issues, screenshots for UI changes, and clear manual test steps (build/run method, macOS version, Xcode version). Note any signing/config needs (`TEAM_ID`, Keychain access).
- CI not configured; keep PRs small and buildable from a clean checkout.

## Security & Configuration Tips
- Never hardcode or log API keys. Keys live in macOS Keychain (`service: LLMKeyring`, `account: prov_<uuid>`).
- Validate base URLs; OpenAI‑compatible adapter normalizes `/v1/models`. Prefer IPv4 `http://127.0.0.1:11434` for Ollama.
