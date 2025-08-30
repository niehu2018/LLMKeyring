# LLMKeyring

Simple, convenient, free, and open‑source key manager for LLM APIs on macOS. Add your favorite providers once, keep keys safe in Keychain, and switch or test with a single click — no fuss.

Why you’ll like it
- Simple: clean menu bar app — add, save, test, done.
- Convenient: one place for all LLM provider keys and base URLs.
- Free & open‑source: no subscriptions, no telemetry.
- Private by design: keys stay in your local macOS Keychain.

Key features
- Multi‑provider support: OpenAI‑compatible services (Kimi/Moonshot, SiliconFlow, OpenRouter, Together, Mistral, Groq, Fireworks), Aliyun (native/compatible), Anthropic, Google Gemini, Azure OpenAI, Zhipu GLM (native), Baidu Qianfan (native), Vertex AI Gemini.
- One‑click health check: quickly validate connectivity per provider.
- Smart helpers: Normalize / Detect / Switch Mode fix common base‑URL issues (e.g., Aliyun native ↔ compatible, Kimi .cn).
- Bilingual UI: English and Simplified Chinese.

Get started (2 minutes)
- Download: grab the latest release on GitHub (Releases tab). If macOS blocks it, allow from System Settings > Privacy & Security.
- Add a provider: click “+”, pick a template, paste Base URL & API key, Save.
- Test & switch: click “Test” to verify; set default provider from the menu.

Privacy & security
- Keys are stored only in macOS Keychain (`service: LLMKeyring`, `account: prov_<uuid>`). No export, no logs, no background network calls.

Contribute
- Issues and PRs welcome. See `AGENTS.md` for quick guidelines. UI changes should update both English and Chinese strings.

License
- MIT — see `LICENSE` for details.

中文说明见：`README_CN.md`
