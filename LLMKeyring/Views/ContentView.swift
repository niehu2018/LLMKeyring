import SwiftUI

enum SidebarItem: Hashable {
    case homepage
    case provider(UUID)
}

struct ContentView: View {
    @EnvironmentObject var store: ProviderStore
    @State private var selection: SidebarItem? = .homepage

    var body: some View {
        NavigationSplitView {
            ProviderListView(selection: $selection)
        } detail: {
            switch selection {
            case .homepage, .none:
                HomepageView(onOpenProvider: { id in selection = .provider(id) })
            case .provider(let id):
                if let provider = store.providers.first(where: { $0.id == id }) {
                    ProviderDetailView(provider: provider)
                        .id(provider.id)
                } else {
                    HomepageView()
                }
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Menu {
                    Button(NSLocalizedString("TemplateDeepSeek", comment: "DeepSeek")) { addTemplate(.deepseek) }
                    Button(NSLocalizedString("TemplateKimi", comment: "Kimi")) { addTemplate(.kimi) }
                    Button(NSLocalizedString("TemplateAliyunNative", comment: "Aliyun native")) { addTemplate(.aliyunNative) }
                    Button(NSLocalizedString("TemplateSiliconFlow", comment: "SiliconFlow")) { addTemplate(.siliconflow) }
                    Divider()
                    Button(NSLocalizedString("BlankProvider", comment: "Blank")) { addTemplate(.blank) }
                } label: {
                    Label("新增", systemImage: "plus")
                }
                Button(action: deleteSelected) { Label("删除", systemImage: "trash") }
                    .disabled(!isProviderSelected)
            }
        }
        .navigationTitle("提供商管理")
    }

    private enum Template { case deepseek, kimi, aliyunNative, siliconflow, blank }

    private func addTemplate(_ t: Template) {
        let p: Provider
        switch t {
        case .deepseek:
            p = Provider(name: NSLocalizedString("ProviderNameDeepSeek", comment: "DeepSeek"), kind: .openAICompatible, baseURL: "https://api.deepseek.com", defaultModel: nil, enabled: true, auth: .none)
        case .kimi:
            p = Provider(name: NSLocalizedString("ProviderNameKimi", comment: "Kimi"), kind: .openAICompatible, baseURL: "https://api.moonshot.cn", defaultModel: nil, enabled: true, auth: .none)
        case .aliyunNative:
            p = Provider(name: NSLocalizedString("ProviderNameAliyunNative", comment: "Aliyun native"), kind: .aliyunNative, baseURL: "https://dashscope.aliyuncs.com/api/v1", defaultModel: nil, enabled: true, auth: .bearer(keyRef: "prov_\(UUID().uuidString)"))
        case .siliconflow:
            p = Provider(name: NSLocalizedString("ProviderNameSiliconFlow", comment: "SiliconFlow"), kind: .openAICompatible, baseURL: "https://api.siliconflow.cn", defaultModel: nil, enabled: true, auth: .none)
        case .blank:
            p = Provider(name: NSLocalizedString("BlankProvider", comment: "Blank"), kind: .openAICompatible, baseURL: "https://", defaultModel: nil, enabled: true, auth: .none)
        }
        store.add(p)
        selection = .provider(p.id)
    }

    private var selectedProvider: Provider? {
        if case let .provider(id) = selection { return store.providers.first(where: { $0.id == id }) }
        return nil
    }
    private var isProviderSelected: Bool { selectedProvider != nil }

    private func deleteSelected() {
        guard let p = selectedProvider else { return }
        store.delete(p)
        if let first = store.providers.first { selection = .provider(first.id) } else { selection = .homepage }
    }
}

struct ProviderListView: View {
    @EnvironmentObject var store: ProviderStore
    @Binding var selection: SidebarItem?

    var body: some View {
        List(selection: $selection) {
            Label(NSLocalizedString("Homepage", comment: "Homepage"), systemImage: "house")
                .tag(SidebarItem.homepage)
            Section(NSLocalizedString("ProvidersSection", comment: "Providers")) {
            ForEach(store.providers) { p in
                HStack {
                    VStack(alignment: .leading) {
                        Text(p.name)
                        Text(p.kind.displayName)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    StatusDot(status: p.lastTest.status)
                }
                .tag(SidebarItem.provider(p.id))
            }
        }
    }
}
}

struct StatusDot: View {
    let status: TestStatus
    var color: Color {
        switch status {
        case .unknown: return .gray
        case .success: return .green
        case .failure: return .red
        }
    }
    var body: some View {
        Circle().fill(color).frame(width: 10, height: 10)
            .accessibilityLabel(Text("status: \(status.rawValue)"))
    }
}
