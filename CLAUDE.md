# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Structure

This repository contains the LLMKeyring macOS application in the `LLMKeyring/` subdirectory. The project is a SwiftUI menu bar application for managing multiple LLM provider configurations with secure API key storage.

## Development Commands

All commands should be run from within the `LLMKeyring/` directory:

```bash
cd LLMKeyring

# Build and run without signing (ad-hoc sign):
bash scripts/build_and_run.sh

# Build with Apple Developer Team ID and run:
TEAM_ID=YOURTEAMID bash scripts/build_and_run.sh

# Generate app icons from base 1024px icon:
bash scripts/make_app_icon.sh
```

## Architecture Overview

The LLMKeyring app follows a SwiftUI + MVVM pattern with secure keychain integration:

**State Management Flow:**
1. `ProviderStore` acts as the central ObservableObject managing all provider configurations
2. Provider configs (excluding secrets) persist in UserDefaults
3. API keys store securely in macOS Keychain with UUID references
4. Views observe ProviderStore changes via @StateObject/@ObservedObject

**Provider Adapter Pattern:**
- `ProviderAdapter` protocol defines the interface for all provider integrations
- Concrete adapters handle provider-specific API differences (OpenAI, Ollama, Aliyun)
- `AdapterFactory` creates the appropriate adapter based on provider kind
- Adapters handle URL normalization, authentication, and health testing

**Security Architecture:**
- API keys never stored in UserDefaults or logged
- Keychain service: "LLMKeyring", account pattern: "prov_<uuid>"
- Authentication headers built dynamically from keychain on each request
- No export functionality for sensitive data

## Key Implementation Patterns

### Adding New Provider Types
1. Add case to `ProviderKind` enum in `Models/Provider.swift`
2. Create adapter in `Providers/` implementing `ProviderAdapter` protocol
3. Update `AdapterFactory.makeAdapter()` to return new adapter
4. Add UI support in `Views/ProviderDetailView.swift`

### Provider Health Testing
- OpenAI-compatible: GET `{baseURL}/v1/models` with Bearer token
- Ollama: GET `{baseURL}/api/tags`
- Custom providers should implement appropriate health endpoints

### Localization
- Add strings to both `en.lproj/Localizable.strings` and `zh-Hans.lproj/Localizable.strings`
- Use `NSLocalizedString("key", comment: "")` in SwiftUI views

## Build Requirements

- macOS 13.0+ deployment target
- Full Xcode installation (not just Command Line Tools)
- Accepted Xcode license: `sudo xcodebuild -license`
- Correct Xcode path: `sudo xcode-select -s /Applications/Xcode.app/Contents/Developer`

## Testing Approach

Currently no automated tests. Manual testing focuses on:
- Provider CRUD operations
- Keychain integration (add/update/delete keys)
- Health check functionality for each provider type
- Menu bar interaction and window management

## Important Files

- `LLMKeyring/App/LLMManagerApp.swift`: Main app entry point
- `LLMKeyring/Models/Provider.swift`: Core data model
- `LLMKeyring/Storage/ProviderStore.swift`: State management
- `LLMKeyring/Keychain/KeychainService.swift`: Secure storage
- `LLMKeyring/Providers/AdapterFactory.swift`: Provider adapter creation