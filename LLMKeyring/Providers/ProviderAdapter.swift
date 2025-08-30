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
        }
    }
}

extension ProviderAdapter {
    func listModels(provider: Provider) async -> ([String], String?) {
        return ([], NSLocalizedString("ERR_LIST_MODELS_UNSUPPORTED", comment: "List models not supported"))
    }
}
