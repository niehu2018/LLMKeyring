import Foundation

enum ProviderKind: String, Codable, CaseIterable, Identifiable {
    case openAICompatible
    case ollama
    case aliyunNative
    case anthropic
    case googleGemini

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .openAICompatible: return NSLocalizedString("KindOpenAICompatible", comment: "Kind: OpenAI compatible")
        case .ollama: return NSLocalizedString("KindOllama", comment: "Kind: Ollama")
        case .aliyunNative: return NSLocalizedString("KindAliyunNative", comment: "Kind: Aliyun DashScope native")
        case .anthropic: return NSLocalizedString("KindAnthropic", comment: "Kind: Anthropic")
        case .googleGemini: return NSLocalizedString("KindGoogleGemini", comment: "Kind: Google Gemini")
        }
    }
}

enum AuthMethod: Codable, Equatable {
    case none
    case bearer(keyRef: String)

    enum CodingKeys: String, CodingKey { case type, keyRef }

    enum Kind: String, Codable { case none, bearer }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(Kind.self, forKey: .type)
        switch type {
        case .none:
            self = .none
        case .bearer:
            let ref = try container.decode(String.self, forKey: .keyRef)
            self = .bearer(keyRef: ref)
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .none:
            try container.encode(Kind.none, forKey: .type)
        case .bearer(let keyRef):
            try container.encode(Kind.bearer, forKey: .type)
            try container.encode(keyRef, forKey: .keyRef)
        }
    }
}

enum TestStatus: String, Codable { case unknown, success, failure }

struct LastTest: Codable, Equatable {
    var status: TestStatus
    var at: Date?
    var message: String?

    static let unknown = LastTest(status: .unknown, at: nil, message: nil)
}

struct Provider: Identifiable, Codable, Equatable {
    var id: UUID
    var name: String
    var kind: ProviderKind
    var baseURL: String
    var defaultModel: String?
    var enabled: Bool
    var auth: AuthMethod
    var extraHeaders: [String: String]
    var lastTest: LastTest

    init(id: UUID = UUID(), name: String, kind: ProviderKind, baseURL: String, defaultModel: String? = nil, enabled: Bool = true, auth: AuthMethod = .none, extraHeaders: [String: String] = [:], lastTest: LastTest = .unknown) {
        self.id = id
        self.name = name
        self.kind = kind
        self.baseURL = baseURL
        self.defaultModel = defaultModel
        self.enabled = enabled
        self.auth = auth
        self.extraHeaders = extraHeaders
        self.lastTest = lastTest
    }
}
