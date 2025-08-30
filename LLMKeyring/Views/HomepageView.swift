import SwiftUI
import AppKit

struct HomepageView: View {
    @EnvironmentObject var store: ProviderStore
    @State private var revealed: [UUID: String] = [:]
    @State private var message: String?
    @Environment(\.locale) private var locale
    var onOpenProvider: ((UUID) -> Void)? = nil

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
                        // First row: API key display with Reveal and Open buttons
                        HStack(spacing: 12) {
                            if let text = revealed[p.id] {
                                Text(text).font(.system(.body, design: .monospaced))
                                Button(NSLocalizedString("Hide", comment: "Hide")) { revealed[p.id] = nil }
                            } else {
                                Text(maskedKey(for: p)).font(.system(.body, design: .monospaced))
                                Button(NSLocalizedString("Reveal", comment: "Reveal")) { reveal(p) }
                            }
                            Spacer()
                            Button(NSLocalizedString("Open", comment: "Open")) { onOpenProvider?(p.id) }
                        }
                        
                        // Second row: Copy buttons
                        HStack(spacing: 8) {
                            Button(NSLocalizedString("CopyAPIKey", comment: "Copy API Key")) { 
                                if revealed[p.id] != nil {
                                    copy(revealed[p.id]!, message: NSLocalizedString("APIKeyCopied", comment: "API Key Copied"))
                                } else {
                                    copyFromKeychain(p)
                                }
                            }
                            .buttonStyle(.bordered)
                            
                            Button(NSLocalizedString("CopyBaseURL", comment: "Copy Base URL")) { copyBaseURL(p) }
                                .buttonStyle(.bordered)
                            
                            Spacer()
                        }
                    }
                }
                .onMove(perform: moveProviders)
            }
        }
        .padding()
        .id(locale)
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
                copy(k, message: NSLocalizedString("APIKeyCopied", comment: "API Key Copied"))
            }
        } catch {
            message = error.localizedDescription
        }
    }
    
    private func copyBaseURL(_ p: Provider) {
        copy(p.baseURL, message: NSLocalizedString("BaseURLCopied", comment: "Base URL Copied"))
    }

    private func copy(_ text: String, message: String = "Copied") {
        let pb = NSPasteboard.general
        pb.clearContents()
        pb.setString(text, forType: .string)
        self.message = message
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { self.message = nil }
    }
    
    private func moveProviders(from source: IndexSet, to destination: Int) {
        store.moveProviders(from: source, to: destination)
    }
}
