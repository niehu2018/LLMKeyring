# LLMKeyring

A lightweight macOS SwiftUI menu bar app to manage multiple LLM providers and API keys. Store secrets securely in macOS Keychain, switch providers quickly, and verify connectivity with built‑in health checks.

- Platforms: macOS 13+
- Tech: SwiftUI, Keychain, Xcode project
 - Providers: OpenAI‑compatible (Kimi/Moonshot, SiliconFlow, OpenRouter, Together, Mistral, Groq, Fireworks), Aliyun (native + compatible), Anthropic, Google Gemini, Azure OpenAI, Zhipu GLM (native), Baidu Qianfan (native), Vertex AI Gemini

## Quick Start
- Xcode: open `LLMKeyring/LLMKeyring.xcodeproj` and run the `LLMKeyring` scheme.
- CLI:
  - `cd LLMKeyring`
  - Build/run without signing: `bash scripts/build_and_run.sh`
  - With automatic signing: `TEAM_ID=YOURTEAMID bash scripts/build_and_run.sh`
- Gatekeeper: if blocked, allow from System Settings > Privacy & Security > Open Anyway.

## Using The App
- Add a provider via the “+” menu (templates included for major vendors).
- Enter Base URL and API Key, then click Save. Keys are stored in Keychain only.
- Use Normalize/Detect/Switch Mode under Base URL to fix paths, auto‑detect type, or toggle Aliyun native/compatible.
- Click “Test” to run a health check (e.g., `/v1/models` or native model list).

## Security
- Keys are stored in macOS Keychain (`service: LLMKeyring`, `account: prov_<uuid>`). No export, no logs.


## Contributing
- See `AGENTS.md` for guidelines, commands, and PR requirements.
- Localization: every UI change must update both `en.lproj/Localizable.strings` and `zh-Hans.lproj/Localizable.strings`.

## License
- Choose and add a license (e.g., MIT/Apache‑2.0) before publishing releases.

中文说明见：`README_CN.md`
