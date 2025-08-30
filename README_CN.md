# LLMKeyring

[![下载最新版本](https://img.shields.io/github/v/release/niehu2018/LLMKeyring?label=%E4%B8%8B%E8%BD%BD%E6%9C%80%E6%96%B0%E7%89%88%E6%9C%AC)](https://github.com/niehu2018/LLMKeyring/releases/latest)

简单、方便、免费、开源的 macOS 大模型（LLM）密钥管理工具。把常用提供商与密钥集中放在一处，安全保存在 Keychain，一键测试与切换，开箱即用。

为什么好用
- 简单：菜单栏小工具，添加、保存、测试，几步到位。
- 方便：所有提供商的 Base URL 与 API Key 统一管理。
- 免费开源：无订阅、无遥测，随时自建自用。
- 注重隐私：密钥只存本机 Keychain，不上传、不记录日志。

主要功能
- 多家提供商：OpenAI 兼容（Kimi/Moonshot、SiliconFlow、OpenRouter、Together、Mistral、Groq、Fireworks）、阿里云（原生/兼容）、Anthropic、Google Gemini、Azure OpenAI、智谱 GLM（原生）、百度千帆（原生）、Vertex AI Gemini。
- 一键健康检查：快速验证连通性与可用性。
- 智能助手：Normalize / Detect / Switch Mode 自动修正常见 Base URL 问题（如阿里云原生↔兼容、Kimi .cn）。
- 双语界面：简体中文与英文切换。

开始使用（约 2 分钟）
- 下载：在 GitHub Releases 下载最新版本（提供 DMG 安装包）。若被系统拦截，请在“系统设置 > 隐私与安全”允许打开。
- 新增提供商：点击“+”，选择模板，粘贴 Base URL 与 API Key 并保存。
- 测试与切换：点击“测试”验证，菜单中可设为默认提供商。

隐私与安全
- API Key 仅存于本机 Keychain（`service: LLMKeyring`，`account: prov_<uuid>`），不导出、不记录、不做额外网络请求。

首次运行（未签名版本）
- 在 Finder 中右键应用选择“打开”，或
- 前往“系统设置 > 隐私与安全”，在“安全性”中点击“仍要打开”。
开源应用的未签名构建属正常情况，首次放行后即可直接使用。

参与贡献
- 欢迎提 Issue/PR。规范见 `AGENTS.md`。更新 UI 时请同步维护中英文文案。

许可证
- MIT — 详见 `LICENSE`。

English README: `README.md`
