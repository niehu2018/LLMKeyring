import Foundation

struct TestResult: Equatable {
    var status: TestStatus
    var message: String?
}

protocol ProviderAdapter {
    func testHealth(provider: Provider) async -> TestResult
    func listModels(provider: Provider) async -> ([String], String?)
}

enum AdapterFactory {
    static func make(for provider: Provider) -> ProviderAdapter {
        switch provider.kind {
        case .openAICompatible:
            return OpenAICompatibleAdapter()
        case .ollama:
            return OllamaAdapter()
        case .aliyunNative:
            return AliyunDashScopeAdapter()
        case .anthropic:
            return AnthropicAdapter()
        case .googleGemini:
            return GoogleGeminiAdapter()
        case .azureOpenAI:
            return AzureOpenAIAdapter()
        case .zhipuGLMNative:
            return ZhipuGLMNativeAdapter()
        case .baiduQianfan:
            return BaiduQianfanAdapter()
        case .vertexGemini:
            return VertexGeminiAdapter()
        }
    }
}

extension ProviderAdapter {
    func listModels(provider: Provider) async -> ([String], String?) {
        return ([], NSLocalizedString("ERR_LIST_MODELS_UNSUPPORTED", comment: "List models not supported"))
    }
}
