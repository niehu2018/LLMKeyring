import SwiftUI

enum SidebarItem: Hashable {
    case homepage
    case provider(UUID)
}

struct ContentView: View {
    @EnvironmentObject var store: ProviderStore
    @State private var selection: SidebarItem? = .homepage
    @StateObject private var localizationHelper = LocalizationHelper.shared

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
                    Button(LocalizedString("TemplateDeepSeek", comment: "DeepSeek")) { addTemplate(.deepseek) }
                    Button(LocalizedString("TemplateKimi", comment: "Kimi")) { addTemplate(.kimi) }
                    Button(LocalizedString("TemplateAliyunNative", comment: "Aliyun native")) { addTemplate(.aliyunNative) }
                    Button(LocalizedString("TemplateSiliconFlow", comment: "SiliconFlow")) { addTemplate(.siliconflow) }
                    Button(LocalizedString("TemplateAnthropic", comment: "Anthropic")) { addTemplate(.anthropic) }
                    Button(LocalizedString("TemplateGoogleGemini", comment: "Google Gemini")) { addTemplate(.googleGemini) }
                    Button(LocalizedString("TemplateVertexGemini", comment: "Vertex AI Gemini")) { addTemplate(.vertexGemini) }
                    Button(LocalizedString("TemplateAzureOpenAI", comment: "Azure OpenAI")) { addTemplate(.azureOpenAI) }
                    Button(LocalizedString("TemplateOpenRouter", comment: "OpenRouter")) { addTemplate(.openRouter) }
                    Button(LocalizedString("TemplateTogether", comment: "Together AI")) { addTemplate(.together) }
                    Button(LocalizedString("TemplateMistral", comment: "Mistral")) { addTemplate(.mistral) }
                    Button(LocalizedString("TemplateGroq", comment: "Groq")) { addTemplate(.groq) }
                    Button(LocalizedString("TemplateFireworks", comment: "Fireworks AI")) { addTemplate(.fireworks) }
                    Divider()
                    Button(LocalizedString("BlankProvider", comment: "Blank")) { addTemplate(.blank) }
                } label: {
                    Label(LocalizedString("New", comment: "New"), systemImage: "plus")
                }
                Button(action: deleteSelected) { Label(LocalizedString("Delete", comment: "Delete"), systemImage: "trash") }
                    .disabled(!isProviderSelected)
            }
        }
        .navigationTitle(LocalizedString("ProviderManagement", comment: "Provider Management"))
        .id(localizationHelper.currentLanguage)
    }

    private enum Template { case deepseek, kimi, aliyunNative, siliconflow, anthropic, googleGemini, vertexGemini, azureOpenAI, openRouter, together, mistral, groq, fireworks, zhipuGLM, baiduQianfan, blank }

    private func addTemplate(_ t: Template) {
        let p: Provider
        switch t {
        case .deepseek:
            p = Provider(name: LocalizedString("ProviderNameDeepSeek", comment: "DeepSeek"), kind: .openAICompatible, baseURL: "https://api.deepseek.com", defaultModel: nil, enabled: true, auth: .none)
        case .kimi:
            p = Provider(name: LocalizedString("ProviderNameKimi", comment: "Kimi"), kind: .openAICompatible, baseURL: "https://api.moonshot.cn", defaultModel: nil, enabled: true, auth: .none)
        case .aliyunNative:
            p = Provider(name: LocalizedString("ProviderNameAliyunNative", comment: "Aliyun native"), kind: .aliyunNative, baseURL: "https://dashscope.aliyuncs.com/api/v1", defaultModel: nil, enabled: true, auth: .bearer(keyRef: "prov_\(UUID().uuidString)"))
        case .siliconflow:
            p = Provider(name: LocalizedString("ProviderNameSiliconFlow", comment: "SiliconFlow"), kind: .openAICompatible, baseURL: "https://api.siliconflow.cn", defaultModel: nil, enabled: true, auth: .none)
        case .anthropic:
            p = Provider(name: LocalizedString("ProviderNameAnthropic", comment: "Anthropic"), kind: .anthropic, baseURL: "https://api.anthropic.com", defaultModel: nil, enabled: true, auth: .none)
        case .googleGemini:
            p = Provider(name: LocalizedString("ProviderNameGoogleGemini", comment: "Google Gemini"), kind: .googleGemini, baseURL: "https://generativelanguage.googleapis.com", defaultModel: nil, enabled: true, auth: .bearer(keyRef: "prov_\(UUID().uuidString)"))
        case .vertexGemini:
            p = Provider(name: LocalizedString("KindVertexGemini", comment: "Vertex AI Gemini"), kind: .vertexGemini, baseURL: "https://us-central1-aiplatform.googleapis.com/v1/projects/YOUR_PROJECT/locations/us-central1", defaultModel: nil, enabled: true, auth: .bearer(keyRef: "prov_\(UUID().uuidString)"))
        case .azureOpenAI:
            p = Provider(name: LocalizedString("ProviderNameAzureOpenAI", comment: "Azure OpenAI"), kind: .azureOpenAI, baseURL: "https://YOUR_RESOURCE_NAME.openai.azure.com", defaultModel: nil, enabled: true, auth: .bearer(keyRef: "prov_\(UUID().uuidString)"))
        case .openRouter:
            p = Provider(name: LocalizedString("ProviderNameOpenRouter", comment: "OpenRouter"), kind: .openAICompatible, baseURL: "https://openrouter.ai/api", defaultModel: nil, enabled: true, auth: .none)
        case .together:
            p = Provider(name: LocalizedString("ProviderNameTogether", comment: "Together AI"), kind: .openAICompatible, baseURL: "https://api.together.xyz", defaultModel: nil, enabled: true, auth: .none)
        case .mistral:
            p = Provider(name: LocalizedString("ProviderNameMistral", comment: "Mistral"), kind: .openAICompatible, baseURL: "https://api.mistral.ai", defaultModel: nil, enabled: true, auth: .none)
        case .groq:
            p = Provider(name: LocalizedString("ProviderNameGroq", comment: "Groq"), kind: .openAICompatible, baseURL: "https://api.groq.com/openai", defaultModel: nil, enabled: true, auth: .none)
        case .fireworks:
            p = Provider(name: LocalizedString("ProviderNameFireworks", comment: "Fireworks AI"), kind: .openAICompatible, baseURL: "https://api.fireworks.ai/inference", defaultModel: nil, enabled: true, auth: .none)
        case .zhipuGLM:
            p = Provider(name: LocalizedString("KindZhipuGLM", comment: "Zhipu GLM"), kind: .zhipuGLMNative, baseURL: "https://open.bigmodel.cn/api/paas/v4", defaultModel: nil, enabled: true, auth: .none)
        case .baiduQianfan:
            p = Provider(name: LocalizedString("KindBaiduQianfan", comment: "Baidu Qianfan"), kind: .baiduQianfan, baseURL: "https://aip.baidubce.com", defaultModel: nil, enabled: true, auth: .none)
        case .blank:
            p = Provider(name: LocalizedString("BlankProvider", comment: "Blank"), kind: .openAICompatible, baseURL: "https://", defaultModel: nil, enabled: true, auth: .none)
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
    @StateObject private var localizationHelper = LocalizationHelper.shared

    var body: some View {
        List(selection: $selection) {
            Label(LocalizedString("Homepage", comment: "Homepage"), systemImage: "house")
                .tag(SidebarItem.homepage)
            Section(LocalizedString("ProvidersSection", comment: "Providers")) {
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
        .id(localizationHelper.currentLanguage)
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
