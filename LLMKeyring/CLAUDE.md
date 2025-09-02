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

## Git Workflow

**CRITICAL: Always commit changes after making code modifications.** This repository follows a commit-after-changes policy.

### Standard Workflow:
1. Make code changes
2. Test changes (build/run if possible)
3. Commit immediately with descriptive message
4. Do NOT leave uncommitted changes

### Commit Message Format:
```
type(scope): brief description

- Detailed explanation of changes
- Why the changes were made
- Any breaking changes or important notes

🤖 Generated with [Claude Code](https://claude.ai/code)

Co-Authored-By: Claude <noreply@anthropic.com>
```

### Common Git Commands:
```bash
# Check status and see changes
git status
git diff

# Add and commit all changes
git add .
git commit -m "your message"

# Add specific files
git add path/to/file.swift
git commit -m "your message"
```

## Architecture

### Core Components

**Window Management (`App/LLMManagerApp.swift`)**
- Uses `AppDelegate` with `applicationShouldHandleReopen` to handle dock icon clicks
- Manages WindowGroup with proper window restoration and focus handling
- Ensures main window appears when dock icon is clicked, even if previously closed

**App Entry (`App/LLMManagerApp.swift`)**
- Main app entry with `@main` struct
- Manages WindowGroup for main interface and Settings scene
- Uses `ProviderStore` as the central state management
- Handles localization with en/zh-Hans support
- Generates runtime app icon with letter "A"

**Provider System (`Models/Provider.swift`)**
- `Provider`: Core model with id, name, kind, baseURL, auth method, and test status
- `ProviderKind`: Enum for provider types (openAICompatible, aliyunNative, anthropic, googleGemini, azureOpenAI, zhipuGLMNative, baiduQianfan, vertexGemini)
- `AuthMethod`: Handles authentication (none or bearer token with keychain reference)
- `TestStatus`/`LastTest`: Tracks health check results

**Storage Layer**
- `Storage/ProviderStore.swift`: UserDefaults for provider configs (excluding secrets)
- `Keychain/KeychainService.swift`: Secure storage for API keys (service: "LLMKeyring", account: "prov_<uuid>")

**Provider Adapters (`Providers/`)**
- `ProviderAdapter` protocol: Defines health testing and model listing interface
- `OpenAICompatibleAdapter`: For most providers (DeepSeek, Anthropic, Google Gemini, Azure OpenAI, etc.) - tests via `/v1/models`
- `AliyunDashScopeAdapter`: Native Aliyun DashScope implementation
- `AdapterFactory`: Creates appropriate adapter based on provider kind (most kinds use OpenAICompatibleAdapter)

**Networking (`Networking/HTTPClient.swift`)**
- Centralized HTTP client for all API calls
- Handles authentication headers and request configuration

**Views (`Views/`)**
- `ContentView`: Main window with provider list and detail panes
- `ProviderDetailView`: Provider configuration and testing
- `AppSettingsView`: App preferences and language switching
- `HomepageView`: Landing page when no provider selected

## Key Implementation Details

### API Key Security
- Keys stored only in macOS Keychain, never in UserDefaults or files
- Keys referenced by UUID in provider config
- Keys not exported or logged

### Provider Health Testing
- Most providers (OpenAI-compatible): GET `{baseURL}/v1/models` with Bearer token
- Google Gemini: GET `{baseURL}/v1beta/models?key=API_KEY` (uses query parameter for auth)
- Aliyun DashScope: Native API endpoint with specific headers
- URL normalization: Adapters auto-append appropriate version paths

### Localization System
- **Dual-language support**: English and Simplified Chinese (124 localization keys each)
- **Files**: `en.lproj/Localizable.strings`, `zh-Hans.lproj/Localizable.strings`
- **Implementation**: Custom `LocalizationHelper` class with `@Published currentLanguage` property
- **Usage**: Use `LocalizedString("Key", comment: "Comment")` instead of `NSLocalizedString`

**CRITICAL: When updating UI, ALWAYS maintain dual-language support:**

1. **For every new user-facing text, add localization keys to BOTH files:**
   ```swift
   // ❌ WRONG: Hard-coded text
   Text("New Feature")
   
   // ✅ CORRECT: Localized text
   Text(LocalizedString("NewFeature", comment: "New Feature"))
   ```

2. **Add corresponding entries in both localization files:**
   ```
   // en.lproj/Localizable.strings
   "NewFeature" = "New Feature";
   
   // zh-Hans.lproj/Localizable.strings  
   "NewFeature" = "新功能";
   ```

3. **Views must use LocalizationHelper for reactivity:**
   ```swift
   struct MyView: View {
       @StateObject private var localizationHelper = LocalizationHelper.shared
       
       var body: some View {
           // Your UI content
           .id(localizationHelper.currentLanguage) // Force re-render on language change
       }
   }
   ```

4. **Verification commands:**
   ```bash
   # Check key count matches between languages
   grep -c '^".*" = ' en.lproj/Localizable.strings
   grep -c '^".*" = ' zh-Hans.lproj/Localizable.strings
   
   # Find any hard-coded text (should return empty)
   grep -r 'Text("' Views/ --include="*.swift" | grep -v 'LocalizedString\|NSLocalizedString'
   ```

### Default Provider URLs
- DeepSeek: `https://api.deepseek.com`
- Kimi: `https://api.moonshot.cn`
- Aliyun DashScope: `https://dashscope.aliyuncs.com/api/v1`
- SiliconFlow: `https://api.siliconflow.cn`
- Anthropic: `https://api.anthropic.com`
- Google Gemini: `https://generativelanguage.googleapis.com`
- Azure OpenAI: `https://YOUR_RESOURCE_NAME.openai.azure.com`

## Development Requirements

- macOS 13.0+
- Xcode with SwiftUI support
- Full Xcode installation (not just Command Line Tools)
- Accepted Xcode license: `sudo xcodebuild -license`
- Correct Xcode path: `sudo xcode-select -s /Applications/Xcode.app/Contents/Developer`

## UI Development Guidelines

### Mandatory Dual-Language Support
**Every UI change must include complete localization support. This is non-negotiable.**

#### When Adding New UI Elements:
1. **Buttons, Labels, Text**: Use `LocalizedString()` for all user-facing text
2. **Error Messages**: Add to adapter error message keys (ERR_* pattern)  
3. **Placeholder Text**: TextFields and SecureFields must have localized placeholders
4. **Menu Items**: All menu entries must be localized
5. **Accessibility Labels**: Include localized accessibility text

#### Localization Key Naming Conventions:
- **UI Elements**: `ButtonName`, `SectionTitle`, `FieldLabel`
- **Templates**: `TemplateProviderName` (e.g., `TemplateDeepSeek`)
- **Provider Names**: `ProviderNameService` (e.g., `ProviderNameAnthropic`)
- **Kinds**: `KindType` (e.g., `KindOpenAICompatible`)
- **Errors**: `ERR_SPECIFIC_ERROR` (e.g., `ERR_AUTH_FAILED_HINT`)
- **Help Text**: `HintFeatureName` (e.g., `HintAliyunBaseURL`)

#### Common Mistakes to Avoid:
```swift
// ❌ WRONG: Direct string literals
Text("Save")
Button("Delete") { ... }
.navigationTitle("Settings")

// ❌ WRONG: English-only comments in code  
Text("保存") // Chinese hardcoded

// ❌ WRONG: Missing reactive binding
struct MyView: View {
    var body: some View {
        Text(LocalizedString("Title", comment: "Title"))
        // Missing .id(localizationHelper.currentLanguage)
    }
}

// ✅ CORRECT: Properly localized
struct MyView: View {
    @StateObject private var localizationHelper = LocalizationHelper.shared
    
    var body: some View {
        VStack {
            Text(LocalizedString("Title", comment: "Title"))
            Button(LocalizedString("Save", comment: "Save")) { ... }
        }
        .navigationTitle(LocalizedString("Settings", comment: "Settings"))
        .id(localizationHelper.currentLanguage)
    }
}
```

#### Testing Checklist:
- [ ] All new text uses `LocalizedString()`
- [ ] Keys added to both `en.lproj/Localizable.strings` and `zh-Hans.lproj/Localizable.strings`
- [ ] Key counts match between language files
- [ ] Language switching updates all new UI elements immediately
- [ ] No hardcoded strings remain in Views directory
- [ ] Chinese translations are accurate and contextually appropriate