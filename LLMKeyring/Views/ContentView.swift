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
                    Button(NSLocalizedString("TemplateAnthropic", comment: "Anthropic")) { addTemplate(.anthropic) }
                    Button(NSLocalizedString("TemplateGoogleGemini", comment: "Google Gemini")) { addTemplate(.googleGemini) }
                    Button(NSLocalizedString("TemplateVertexGemini", comment: "Vertex AI Gemini")) { addTemplate(.vertexGemini) }
                    Button(NSLocalizedString("TemplateAzureOpenAI", comment: "Azure OpenAI")) { addTemplate(.azureOpenAI) }
                    Button(NSLocalizedString("TemplateOpenRouter", comment: "OpenRouter")) { addTemplate(.openRouter) }
                    Button(NSLocalizedString("TemplateTogether", comment: "Together AI")) { addTemplate(.together) }
                    Button(NSLocalizedString("TemplateMistral", comment: "Mistral")) { addTemplate(.mistral) }
                    Button(NSLocalizedString("TemplateGroq", comment: "Groq")) { addTemplate(.groq) }
                    Button(NSLocalizedString("TemplateFireworks", comment: "Fireworks AI")) { addTemplate(.fireworks) }
                    Divider()
                    Button(NSLocalizedString("BlankProvider", comment: "Blank")) { addTemplate(.blank) }
                } label: {
                    Label(NSLocalizedString("New", comment: "New"), systemImage: "plus")
                }
                Button(action: deleteSelected) { Label(NSLocalizedString("Delete", comment: "Delete"), systemImage: "trash") }
                    .disabled(!isProviderSelected)
            }
        }
        .navigationTitle(NSLocalizedString("ProviderManagement", comment: "Provider Management"))
    }

    private enum Template { case deepseek, kimi, aliyunNative, siliconflow, anthropic, googleGemini, vertexGemini, azureOpenAI, openRouter, together, mistral, groq, fireworks, zhipuGLM, baiduQianfan, blank }

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
        case .anthropic:
            p = Provider(name: NSLocalizedString("ProviderNameAnthropic", comment: "Anthropic"), kind: .anthropic, baseURL: "https://api.anthropic.com", defaultModel: nil, enabled: true, auth: .none)
        case .googleGemini:
            p = Provider(name: NSLocalizedString("ProviderNameGoogleGemini", comment: "Google Gemini"), kind: .googleGemini, baseURL: "https://generativelanguage.googleapis.com", defaultModel: nil, enabled: true, auth: .none)
        case .vertexGemini:
            p = Provider(name: NSLocalizedString("KindVertexGemini", comment: "Vertex AI Gemini"), kind: .vertexGemini, baseURL: "https://us-central1-aiplatform.googleapis.com/v1/projects/YOUR_PROJECT/locations/us-central1", defaultModel: nil, enabled: true, auth: .bearer(keyRef: "prov_\(UUID().uuidString)"))
        case .azureOpenAI:
            p = Provider(name: NSLocalizedString("ProviderNameAzureOpenAI", comment: "Azure OpenAI"), kind: .azureOpenAI, baseURL: "https://YOUR_RESOURCE_NAME.openai.azure.com", defaultModel: nil, enabled: true, auth: .bearer(keyRef: "prov_\(UUID().uuidString)"))
        case .openRouter:
            p = Provider(name: NSLocalizedString("ProviderNameOpenRouter", comment: "OpenRouter"), kind: .openAICompatible, baseURL: "https://openrouter.ai/api", defaultModel: nil, enabled: true, auth: .none)
        case .together:
            p = Provider(name: NSLocalizedString("ProviderNameTogether", comment: "Together AI"), kind: .openAICompatible, baseURL: "https://api.together.xyz", defaultModel: nil, enabled: true, auth: .none)
        case .mistral:
            p = Provider(name: NSLocalizedString("ProviderNameMistral", comment: "Mistral"), kind: .openAICompatible, baseURL: "https://api.mistral.ai", defaultModel: nil, enabled: true, auth: .none)
        case .groq:
            p = Provider(name: NSLocalizedString("ProviderNameGroq", comment: "Groq"), kind: .openAICompatible, baseURL: "https://api.groq.com/openai", defaultModel: nil, enabled: true, auth: .none)
        case .fireworks:
            p = Provider(name: NSLocalizedString("ProviderNameFireworks", comment: "Fireworks AI"), kind: .openAICompatible, baseURL: "https://api.fireworks.ai/inference", defaultModel: nil, enabled: true, auth: .none)
        case .zhipuGLM:
            p = Provider(name: NSLocalizedString("KindZhipuGLM", comment: "Zhipu GLM"), kind: .zhipuGLMNative, baseURL: "https://open.bigmodel.cn/api/paas/v4", defaultModel: nil, enabled: true, auth: .none)
        case .baiduQianfan:
            p = Provider(name: NSLocalizedString("KindBaiduQianfan", comment: "Baidu Qianfan"), kind: .baiduQianfan, baseURL: "https://aip.baidubce.com", defaultModel: nil, enabled: true, auth: .none)
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
                .onMove(perform: moveProviders)
            }
        }
    }
    
    private func moveProviders(from source: IndexSet, to destination: Int) {
        store.moveProviders(from: source, to: destination)
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
