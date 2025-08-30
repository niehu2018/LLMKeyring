# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

LLMKeyring is a macOS SwiftUI menu bar application for managing multiple LLM provider configurations. It provides secure API key storage using macOS Keychain and supports various providers including Ollama, OpenAI-compatible services (DeepSeek, Kimi, Aliyun), and native Aliyun DashScope.

## Build Commands

### Build and run with CLI:
```bash
# Build without signing (ad-hoc sign) and run:
bash scripts/build_and_run.sh

# Build with Apple Developer Team ID (automatic signing) and run:
TEAM_ID=YOURTEAMID bash scripts/build_and_run.sh
```

### Generate app icons:
```bash
# Generate all icon sizes from base 1024px icon
bash scripts/make_app_icon.sh
```

Output app location: `build/Build/Products/Debug/LLMKeyring.app`

## Architecture

### Core Components

**App Entry (`App/LLMManagerApp.swift`)**
- Main app entry with `@main` struct
- Manages three scenes: main window (ContentView), menu bar extra, and settings
- Uses `ProviderStore` as the central state management
- Handles localization with en/zh-Hans support

**Provider System (`Models/Provider.swift`)**
- `Provider`: Core model with id, name, kind, baseURL, auth method, and test status
- `ProviderKind`: Enum for provider types (openAICompatible, ollama, aliyunNative)
- `AuthMethod`: Handles authentication (none or bearer token with keychain reference)
- `TestStatus`/`LastTest`: Tracks health check results

**Storage Layer**
- `Storage/ProviderStore.swift`: UserDefaults for provider configs (excluding secrets)
- `Keychain/KeychainService.swift`: Secure storage for API keys (service: "LLMKeyring", account: "prov_<uuid>")

**Provider Adapters (`Providers/`)**
- `ProviderAdapter` protocol: Defines health testing and model listing interface
- `OpenAICompatibleAdapter`: For DeepSeek, Kimi, Aliyun compatible mode (tests via `/v1/models`)
- `OllamaAdapter`: For local Ollama instances (tests via `/api/tags`)
- `AliyunDashScopeAdapter`: Native Aliyun DashScope implementation
- `AdapterFactory`: Creates appropriate adapter based on provider kind

**Networking (`Networking/HTTPClient.swift`)**
- Centralized HTTP client for all API calls
- Handles authentication headers and request configuration

**Views (`Views/`)**
- `ContentView`: Main window with provider list and detail panes
- `MenuBarView`: Quick access menu bar interface
- `ProviderDetailView`: Provider configuration and testing
- `SettingsView`: App preferences
- `HomepageView`: Landing page when no provider selected

## Key Implementation Details

### API Key Security
- Keys stored only in macOS Keychain, never in UserDefaults or files
- Keys referenced by UUID in provider config
- Keys not exported or logged

### Provider Health Testing
- OpenAI-compatible: GET `{baseURL}/v1/models` with Bearer token
- Ollama: GET `{baseURL}/api/tags`
- URL normalization: Adapter auto-appends `/v1` if missing for OpenAI-compatible

### Localization
- Supports English and Simplified Chinese
- Files: `en.lproj/Localizable.strings`, `zh-Hans.lproj/Localizable.strings`
- Uses NSLocalizedString throughout views

### Default Provider URLs
- DeepSeek: `https://api.deepseek.com`
- Kimi: `https://api.moonshot.cn`
- Aliyun DashScope: `https://dashscope.aliyuncs.com/compatible-mode`
- SiliconFlow: `https://api.siliconflow.cn`
- Ollama: `http://127.0.0.1:11434`

## Development Requirements

- macOS 13.0+
- Xcode with SwiftUI support
- Full Xcode installation (not just Command Line Tools)
- Accepted Xcode license: `sudo xcodebuild -license`
- Correct Xcode path: `sudo xcode-select -s /Applications/Xcode.app/Contents/Developer`