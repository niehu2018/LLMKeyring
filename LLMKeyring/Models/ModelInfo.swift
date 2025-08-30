import Foundation

struct CapabilitySet: OptionSet, Codable {
    let rawValue: Int
    init(rawValue: Int) { self.rawValue = rawValue }

    static let textInput = CapabilitySet(rawValue: 1 << 0)
    static let imageInput = CapabilitySet(rawValue: 1 << 1)
    static let tools      = CapabilitySet(rawValue: 1 << 2)
    static let jsonOutput = CapabilitySet(rawValue: 1 << 3)
    static let webAccess  = CapabilitySet(rawValue: 1 << 4)

    // Codable helpers
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let raw = try container.decode(Int.self)
        self.init(rawValue: raw)
    }
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }
}

enum CapabilitySource: String, Codable { case inferred, verified, userOverride }

struct ModelInfo: Identifiable, Codable, Equatable {
    var id: String
    var displayName: String?
    var capabilities: CapabilitySet
    var source: CapabilitySource
    var verifiedAt: Date?
    var lastError: String?
}

