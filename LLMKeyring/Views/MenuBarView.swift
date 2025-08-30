import SwiftUI

struct MenuBarView: View {
    @EnvironmentObject var store: ProviderStore
    @Environment(\.openWindow) private var openWindow
    @State private var isTesting = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let current = store.providers.first(where: { $0.id == store.defaultProviderID }) {
                HStack {
                    StatusDot(status: current.lastTest.status)
                    Text(current.name).font(.headline)
                }
                Text(current.baseURL).font(.caption).foregroundColor(.secondary)
            } else {
                Text(NSLocalizedString("NoDefaultProvider", comment: "No default provider")).foregroundColor(.secondary)
            }

            Divider()

            Menu(NSLocalizedString("SwitchDefaultProvider", comment: "Switch Default Provider")) {
                ForEach(store.providers) { p in
                    Button(action: { store.setDefault(p) }) {
                        if store.defaultProviderID == p.id { Image(systemName: "checkmark") }
                        Text(p.name)
                    }
                }
            }

            Button {
                openWindow(id: "manager")
            } label: {
                Label(NSLocalizedString("OpenManager", comment: "Open Manager"), systemImage: "gearshape")
            }

            Button {
                Task { await testDefault() }
            } label: {
                if isTesting { ProgressView() } else { Label(NSLocalizedString("TestDefaultProvider", comment: "Test Default Provider"), systemImage: "bolt") }
            }.disabled(store.defaultProviderID == nil || isTesting)
        }
        .padding(12)
        .frame(minWidth: 260)
    }

    private func testDefault() async {
        guard let id = store.defaultProviderID, let p = store.providers.first(where: { $0.id == id }) else { return }
        await MainActor.run { isTesting = true }
        defer { Task { await MainActor.run { isTesting = false } } }
        await store.test(provider: p)
    }
}
