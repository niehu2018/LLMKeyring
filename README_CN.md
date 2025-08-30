# LLMKeyring

一款轻量的 macOS SwiftUI 菜单栏应用，用于管理多家大模型（LLM）提供商与 API Key。支持将密钥安全存入 macOS Keychain，快速切换默认提供商，并通过内置健康检查验证连通性。

- 平台：macOS 13+
- 技术栈：SwiftUI、Keychain、Xcode 工程
- 提供商：OpenAI 兼容（Kimi/Moonshot、SiliconFlow、OpenRouter、Together、Mistral、Groq、Fireworks）、Ollama、阿里云（原生 + 兼容模式）、Anthropic、Google Gemini、Azure OpenAI、智谱 GLM（原生）、百度千帆（原生）、Vertex AI Gemini

## 快速开始
- Xcode：打开 `LLMKeyring/LLMKeyring.xcodeproj`，运行 `LLMKeyring` scheme。
- 命令行：
  - `cd LLMKeyring`
  - 无签名构建并运行：`bash scripts/build_and_run.sh`
  - 自动签名构建：`TEAM_ID=YOURTEAMID bash scripts/build_and_run.sh`
- Gatekeeper：若被阻止，请在 系统设置 > 隐私与安全 中“仍要打开”。

## 使用说明
- 通过“+”菜单新增提供商（已内置常见模板）。
- 输入 Base URL 与 API Key 后点击保存。密钥仅存入 Keychain。
- 在 Base URL 下方使用 Normalize / Detect / Switch Mode：
  - Normalize：按推荐规范修正地址（如 Aliyun、Kimi、Groq 等）。
  - Detect：根据域名自动识别类型与推荐 Base。
  - Switch Mode：一键切换阿里云原生/兼容模式。
- 点击“测试”运行健康检查（如 `/v1/models` 或原生模型列表）。

## 安全
- API Key 仅存于 Keychain（`service: LLMKeyring`，`account: prov_<uuid>`），不导出、不写日志。
- Ollama 推荐 IPv4 `http://127.0.0.1:11434` 以避免 `::1` 问题。

## 贡献
- 请阅读 `AGENTS.md` 获取贡献规范、命令与 PR 要求。
- 本项目要求：任何 UI 变更需同时更新 `en.lproj/Localizable.strings` 与 `zh-Hans.lproj/Localizable.strings`。

## 许可证
- 发布前请选择并添加开源许可证（建议 MIT 或 Apache‑2.0）。

English README: `README.md`
