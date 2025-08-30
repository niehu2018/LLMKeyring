import Foundation
import Combine

final class ProviderStore: ObservableObject {
    @Published var providers: [Provider] = [] {
        didSet { persist() }
    }
    @Published var defaultProviderID: UUID? {
        didSet { persist() }
    }

    private let providersKey = "providers"
    private let defaultKey = "defaultProviderID"

    init() {
        load()
        if providers.isEmpty {
            bootstrapDefaults()
        }
    }

    func add(_ provider: Provider) {
        providers.append(provider)
    }

    func update(_ provider: Provider) {
        if let idx = providers.firstIndex(where: { $0.id == provider.id }) {
            providers[idx] = provider
        }
    }

    func delete(_ provider: Provider) {
        providers.removeAll { $0.id == provider.id }
        if defaultProviderID == provider.id { defaultProviderID = nil }
        // Optionally remove key from Keychain
        if case let .bearer(keyRef) = provider.auth {
            try? KeychainService.shared.delete(account: keyRef)
        }
    }
    
    func moveProviders(from source: IndexSet, to destination: Int) {
        providers.move(fromOffsets: source, toOffset: destination)
    }

    func setDefault(_ provider: Provider?) {
        defaultProviderID = provider?.id
    }

    func test(provider: Provider) async {
        let adapter = AdapterFactory.make(for: provider)
        let result = await adapter.testHealth(provider: provider)
        let last = LastTest(status: result.status, at: Date(), message: result.message)
        await MainActor.run {
            if let idx = self.providers.firstIndex(where: { $0.id == provider.id }) {
                var p = self.providers[idx]
                p.lastTest = last
                self.providers[idx] = p
            }
        }
    }

    func saveAPIKey(_ key: String, for provider: Provider) throws -> Provider {
        var updated = provider
        let keyRef: String
        switch provider.auth {
        case .bearer(let ref): keyRef = ref
        case .none:
            keyRef = "prov_\(provider.id.uuidString)"
        }
        try KeychainService.shared.save(secret: key, account: keyRef)
        updated.auth = .bearer(keyRef: keyRef)
        update(updated)
        return updated
    }

    func removeAPIKey(for provider: Provider) throws -> Provider {
        var updated = provider
        if case let .bearer(keyRef) = provider.auth {
            try KeychainService.shared.delete(account: keyRef)
        }
        updated.auth = .none
        update(updated)
        return updated
    }
    
    func clearAllAPIKeys() throws {
        // Delete all keys from keychain
        try KeychainService.shared.deleteAll()
        
        // Update all providers to remove auth references
        for i in providers.indices {
            providers[i].auth = .none
            providers[i].lastTest = .unknown
        }
    }

    // MARK: - Persistence
    private func persist() {
        do {
            let data = try JSONEncoder().encode(providers)
            UserDefaults.standard.set(data, forKey: providersKey)
        } catch {
            // Best effort; do not crash
        }
        if let id = defaultProviderID {
            UserDefaults.standard.set(id.uuidString, forKey: defaultKey)
        } else {
            UserDefaults.standard.removeObject(forKey: defaultKey)
        }
    }

    private func load() {
        if let data = UserDefaults.standard.data(forKey: providersKey) {
            if let decoded = try? JSONDecoder().decode([Provider].self, from: data) {
                self.providers = decoded
            }
        }
        if let raw = UserDefaults.standard.string(forKey: defaultKey), let id = UUID(uuidString: raw) {
            self.defaultProviderID = id
        }
    }

    private func bootstrapDefaults() {
        var defaults: [Provider] = []

        // DeepSeek (OpenAI-compatible)
        defaults.append(Provider(
            name: NSLocalizedString("ProviderNameDeepSeek", comment: "DeepSeek"),
            kind: .openAICompatible,
            baseURL: "https://api.deepseek.com",
            defaultModel: nil,
            enabled: true,
            auth: .none,
            extraHeaders: [:]
        ))

        // Kimi (Moonshot)
        defaults.append(Provider(
            name: NSLocalizedString("ProviderNameKimi", comment: "Kimi"),
            kind: .openAICompatible,
            baseURL: "https://api.moonshot.cn",
            defaultModel: nil,
            enabled: true,
            auth: .none,
            extraHeaders: [:]
        ))

        // Aliyun DashScope (native)
        defaults.append(Provider(
            name: NSLocalizedString("ProviderNameAliyunNative", comment: "Aliyun native"),
            kind: .aliyunNative,
            baseURL: "https://dashscope.aliyuncs.com/api/v1",
            defaultModel: nil,
            enabled: true,
            auth: .bearer(keyRef: "prov_\(UUID().uuidString)"),
            extraHeaders: [:]
        ))

        // 硅基流动 (SiliconFlow)
        defaults.append(Provider(
            name: NSLocalizedString("ProviderNameSiliconFlow", comment: "SiliconFlow"),
            kind: .openAICompatible,
            baseURL: "https://api.siliconflow.cn",
            defaultModel: nil,
            enabled: true,
            auth: .none,
            extraHeaders: [:]
        ))

        // Anthropic (Claude)
        defaults.append(Provider(
            name: NSLocalizedString("ProviderNameAnthropic", comment: "Anthropic"),
            kind: .anthropic,
            baseURL: "https://api.anthropic.com",
            defaultModel: nil,
            enabled: true,
            auth: .none,
            extraHeaders: [:]
        ))

        // Google Gemini
        defaults.append(Provider(
            name: NSLocalizedString("ProviderNameGoogleGemini", comment: "Google Gemini"),
            kind: .googleGemini,
            baseURL: "https://generativelanguage.googleapis.com",
            defaultModel: nil,
            enabled: true,
            auth: .none,
            extraHeaders: [:]
        ))

        // Ollama local
        defaults.append(Provider(
            name: NSLocalizedString("ProviderNameOllama", comment: "Ollama"),
            kind: .ollama,
            baseURL: "http://127.0.0.1:11434",
            defaultModel: nil,
            enabled: true,
            auth: .none,
            extraHeaders: [:]
        ))

        self.providers = defaults
        self.defaultProviderID = defaults.first?.id
    }
}
