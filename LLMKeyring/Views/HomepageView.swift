import SwiftUI
import AppKit

struct HomepageView: View {
    @EnvironmentObject var store: ProviderStore
    @State private var revealed: [UUID: String] = [:]
    @State private var message: String?
    var onOpenProvider: ((UUID) -> Void)? = nil
    @State private var models: [UUID: [String]] = [:]
    @State private var loading: Set<UUID> = []
    @State private var modelErrors: [UUID: String] = [:]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(NSLocalizedString("HomepageTitle", comment: "Homepage title"))
                .font(.title2)
                .bold()
            if let msg = message { Text(msg).font(.caption).foregroundColor(.secondary) }
            List {
                ForEach(store.providers) { p in
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text(p.name).font(.headline)
                            Spacer()
                            if hasKey(p) {
                                Label(NSLocalizedString("KeySaved", comment: "Key saved"), systemImage: "lock.fill").foregroundColor(.green)
                            } else {
                                Label(NSLocalizedString("KeyMissing", comment: "Key missing"), systemImage: "lock.slash").foregroundColor(.orange)
                            }
                        }
                        if case let .bearer(keyRef) = p.auth {
                            Text(String(format: NSLocalizedString("KeyRefFmt", comment: "Key ref"), keyRef))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        HStack(spacing: 12) {
                            if let text = revealed[p.id] {
                                Text(text).font(.system(.body, design: .monospaced))
                                Button("Copy Key") { copy(text) }
                                Button(NSLocalizedString("Hide", comment: "Hide")) { revealed[p.id] = nil }
                            } else {
                                Text(maskedKey(for: p)).font(.system(.body, design: .monospaced))
                                Button(NSLocalizedString("Reveal", comment: "Reveal")) { reveal(p) }
                                Menu("Copy") {
                                    Button("Copy API Key") { copyFromKeychain(p) }
                                    Button("Copy Base URL") { copyBaseURL(p) }
                                    Button("Copy Full URL") { copyFullURL(p) }
                                }
                                Button(NSLocalizedString("Open", comment: "Open")) { onOpenProvider?(p.id) }
                            }
                        }

                        // Models section per provider
                        HStack(spacing: 12) {
                            if loading.contains(p.id) {
                                ProgressView()
                            } else {
                                Button(NSLocalizedString("FetchModels", comment: "Fetch models")) { fetchModels(for: p) }
                            }
                            if let list = models[p.id], !list.isEmpty {
                                Text(String(format: NSLocalizedString("ModelsCountFmt", comment: "Models count"), list.count))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            if let err = modelErrors[p.id] {
                                Text(err).font(.caption).foregroundColor(.secondary)
                            }
                        }
                        if let list = models[p.id], !list.isEmpty {
                            // Show up to first 6 models inline
                            let prefix = Array(list.prefix(6))
                            Text(prefix.joined(separator: ", "))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
        .padding()
    }

    private func hasKey(_ p: Provider) -> Bool { if case .bearer = p.auth { return true } else { return false } }

    private func maskedKey(for p: Provider) -> String {
        guard case let .bearer(keyRef) = p.auth else { return "••••" }
        do {
            guard let key = try KeychainService.shared.read(account: keyRef) else { return "••••" }
            if key.count <= 8 { return String(repeating: "•", count: key.count) }
            let start = key.prefix(4)
            let end = key.suffix(4)
            return "\(start)•••\(end)"
        } catch {
            return "••••"
        }
    }

    private func reveal(_ p: Provider) {
        guard case let .bearer(keyRef) = p.auth else { return }
        do {
            if let k = try KeychainService.shared.read(account: keyRef) { revealed[p.id] = k }
        } catch {
            message = error.localizedDescription
        }
    }

    private func copyFromKeychain(_ p: Provider) {
        guard case let .bearer(keyRef) = p.auth else { return }
        do {
            if let k = try KeychainService.shared.read(account: keyRef) { 
                copy(k, message: "API Key Copied")
            }
        } catch {
            message = error.localizedDescription
        }
    }
    
    private func copyBaseURL(_ p: Provider) {
        copy(p.baseURL, message: "Base URL Copied")
    }
    
    private func copyFullURL(_ p: Provider) {
        let base = URL(string: p.baseURL)
        let path = (base?.path.trimmingCharacters(in: CharacterSet(charactersIn: "/")) ?? "")
        let fullURL: String
        
        switch p.kind {
        case .openAICompatible:
            if path.hasSuffix("v1") {
                fullURL = p.baseURL
            } else {
                fullURL = (base?.appendingPathComponent("v1").absoluteString ?? p.baseURL)
            }
        case .aliyunNative:
            fullURL = (base?.appendingPathComponent("api/v1").absoluteString ?? p.baseURL)
        case .ollama:
            fullURL = p.baseURL
        }
        
        copy(fullURL, message: "Full URL Copied")
    }

    private func copy(_ text: String, message: String = "Copied") {
        let pb = NSPasteboard.general
        pb.clearContents()
        pb.setString(text, forType: .string)
        self.message = message
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { self.message = nil }
    }

    private func fetchModels(for p: Provider) {
        loading.insert(p.id)
        modelErrors[p.id] = nil
        let provider = p
        Task {
            let adapter = AdapterFactory.make(for: provider)
            let (list, err) = await adapter.listModels(provider: provider)
            await MainActor.run {
                self.models[p.id] = list
                if let err = err, !err.isEmpty { self.modelErrors[p.id] = err } else { self.modelErrors[p.id] = nil }
                self.loading.remove(p.id)
            }
        }
    }
}
