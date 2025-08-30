import Foundation

enum BaseURLHelper {
    static func normalizedBase(for kind: ProviderKind, base: String) -> String {
        let trimmed = base.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let url = URL(string: trimmed) else { return trimmed }
        let host = url.host ?? ""
        switch kind {
        case .openAICompatible:
            // Aliyun compatible-mode
            if host.contains("aliyuncs.com") { return "https://dashscope.aliyuncs.com/compatible-mode" }
            // OpenRouter
            if host.contains("openrouter.ai") { return "https://openrouter.ai/api" }
            // Together
            if host.contains("together.xyz") { return "https://api.together.xyz" }
            // Mistral
            if host.contains("mistral.ai") { return "https://api.mistral.ai" }
            // Groq
            if host.contains("groq.com") { return "https://api.groq.com/openai" }
            // Fireworks
            if host.contains("fireworks.ai") { return "https://api.fireworks.ai/inference" }
            // Kimi/Moonshot
            if host.contains("moonshot") { return "https://api.moonshot.cn" }
            // SiliconFlow
            if host.contains("siliconflow") { return "https://api.siliconflow.cn" }
            // DeepSeek
            if host.contains("deepseek.com") { return "https://api.deepseek.com" }
            return trimmed
        case .aliyunNative:
            return "https://dashscope.aliyuncs.com/api/v1"
        case .ollama:
            return "http://127.0.0.1:11434"
        case .anthropic:
            return "https://api.anthropic.com"
        case .googleGemini:
            return "https://generativelanguage.googleapis.com"
        case .azureOpenAI:
            // Replace to template if host matches azure domain but missing scheme
            if host.contains("openai.azure.com") { return "https://\(host)" }
            return "https://YOUR_RESOURCE_NAME.openai.azure.com"
        case .zhipuGLMNative:
            return "https://open.bigmodel.cn/api/paas/v4"
        case .baiduQianfan:
            return "https://aip.baidubce.com"
        case .vertexGemini:
            return "https://us-central1-aiplatform.googleapis.com/v1/projects/YOUR_PROJECT/locations/us-central1"
        }
    }

    static func alternateKindAndBase(for provider: Provider) -> (ProviderKind, String)? {
        let base = provider.baseURL
        guard let url = URL(string: base) else { return nil }
        let host = url.host ?? ""
        // Aliyun: toggle between native and compatible
        if host.contains("aliyuncs.com") {
            if url.path.contains("compatible-mode") {
                return (.aliyunNative, normalizedBase(for: .aliyunNative, base: base))
            } else {
                return (.openAICompatible, normalizedBase(for: .openAICompatible, base: "https://dashscope.aliyuncs.com/compatible-mode"))
            }
        }
        // Other vendors can be expanded later
        return nil
    }

    static func detectionSuggestion(for raw: String) -> (ProviderKind, String)? {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let url = URL(string: trimmed) else { return nil }
        let host = url.host ?? ""
        if host.contains("aliyuncs.com") {
            // Default to compatible to maximize compatibility
            return (.openAICompatible, normalizedBase(for: .openAICompatible, base: "https://dashscope.aliyuncs.com/compatible-mode"))
        }
        if host.contains("moonshot") { return (.openAICompatible, normalizedBase(for: .openAICompatible, base: trimmed)) }
        if host.contains("siliconflow") { return (.openAICompatible, normalizedBase(for: .openAICompatible, base: trimmed)) }
        if host.contains("openrouter.ai") { return (.openAICompatible, normalizedBase(for: .openAICompatible, base: trimmed)) }
        if host.contains("together.xyz") { return (.openAICompatible, normalizedBase(for: .openAICompatible, base: trimmed)) }
        if host.contains("mistral.ai") { return (.openAICompatible, normalizedBase(for: .openAICompatible, base: trimmed)) }
        if host.contains("groq.com") { return (.openAICompatible, normalizedBase(for: .openAICompatible, base: trimmed)) }
        if host.contains("fireworks.ai") { return (.openAICompatible, normalizedBase(for: .openAICompatible, base: trimmed)) }
        if host.contains("anthropic.com") { return (.anthropic, normalizedBase(for: .anthropic, base: trimmed)) }
        if host.contains("generativelanguage.googleapis.com") { return (.googleGemini, normalizedBase(for: .googleGemini, base: trimmed)) }
        if host.contains("openai.azure.com") { return (.azureOpenAI, normalizedBase(for: .azureOpenAI, base: trimmed)) }
        if host.contains("bigmodel.cn") { return (.zhipuGLMNative, normalizedBase(for: .zhipuGLMNative, base: trimmed)) }
        if host.contains("baidubce.com") { return (.baiduQianfan, normalizedBase(for: .baiduQianfan, base: trimmed)) }
        if host.contains("aiplatform.googleapis.com") { return (.vertexGemini, normalizedBase(for: .vertexGemini, base: trimmed)) }
        return nil
    }
}

