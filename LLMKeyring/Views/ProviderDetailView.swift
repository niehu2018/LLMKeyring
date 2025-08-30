import SwiftUI

struct ProviderDetailView: View {
    @EnvironmentObject var store: ProviderStore
    @State var provider: Provider
    @State private var apiKeyInput: String = ""
    @State private var showingKeySaved = false
    @State private var testing = false
    @State private var loadingModels = false
    @State private var models: [String] = []
    @State private var modelsMessage: String?
    @FocusState private var keyFieldFocused: Bool

    var body: some View {
        Form {
            Section(header: Text("基本信息")) {
                TextField("名称", text: $provider.name)
                Picker("类型", selection: $provider.kind) {
                    ForEach(ProviderKind.allCases) { kind in
                        Text(kind.displayName).tag(kind)
                    }
                }
                TextField("Base URL", text: $provider.baseURL)
                if provider.kind == .openAICompatible && provider.baseURL.contains("aliyuncs.com") {
                    Text(NSLocalizedString("HintAliyunBaseURL", comment: "Aliyun base URL hint"))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                TextField("默认模型（可选）", text: Binding.fromOptional($provider.defaultModel, replacingNilWith: ""))
                Toggle("启用", isOn: $provider.enabled)
            }

            Section(header: Text(NSLocalizedString("ModelsSection", comment: "Models"))) {
                HStack(spacing: 12) {
                    Button(action: fetchModels) {
                        if loadingModels { ProgressView() } else { Label(NSLocalizedString("FetchModels", comment: "Fetch models"), systemImage: "arrow.clockwise") }
                    }
                    if !models.isEmpty {
                        Text(String(format: NSLocalizedString("ModelsCountFmt", comment: "Models count"), models.count))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                if let msg = modelsMessage, !msg.isEmpty {
                    Text(msg).font(.caption).foregroundColor(.secondary)
                }
                if !models.isEmpty {
                    Picker(NSLocalizedString("PickDefaultModel", comment: "Pick default model"), selection: Binding.fromOptional($provider.defaultModel, replacingNilWith: "")) {
                        ForEach(models, id: \.self) { m in Text(m).tag(m) }
                    }
                }
            }

            Section(header: Text("鉴权")) {
                HStack {
                    if case let .bearer(keyRef) = provider.auth {
                        Image(systemName: "lock.fill").foregroundColor(.green)
                        Text("已保存到 Keychain: \(keyRef)").font(.caption).foregroundColor(.secondary)
                    } else {
                        Image(systemName: "lock.slash").foregroundColor(.orange)
                        Text("未保存 API Key").font(.caption).foregroundColor(.secondary)
                    }
                }
                HStack {
                    SecureField("API Key", text: $apiKeyInput)
                        .textFieldStyle(.roundedBorder)
                        .focused($keyFieldFocused)
                    Button("保存") { saveKey() }
                    Button("移除") { removeKey() }
                        .disabled(!hasKey)
                }
                if showingKeySaved { Text("已保存").font(.caption).foregroundColor(.green) }
            }

            Section(header: Text("额外 Header（可选）")) {
                KeyValueEditorView(dict: $provider.extraHeaders)
            }

            Section(header: Text("连通性测试")) {
                HStack {
                    Button(action: test) {
                        if testing { ProgressView() } else { Label("测试", systemImage: "bolt") }
                    }
                    StatusDot(status: provider.lastTest.status)
                    Text(provider.lastTest.message ?? "未测试")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Button(action: copyCurl) {
                        Label(NSLocalizedString("CopyCurl", comment: "Copy curl"), systemImage: "doc.on.doc")
                    }
                }
            }
        }
        .onDisappear { store.update(provider) }
        .onReceive(store.$providers) { _ in
            if let fresh = store.providers.first(where: { $0.id == provider.id }) {
                self.provider = fresh
            }
        }
        .navigationTitle(provider.name)
        .padding()
    }

    private var hasKey: Bool {
        if case .bearer = provider.auth { return true }
        return false
    }

    private func saveKey() {
        guard !apiKeyInput.isEmpty else { return }
        do {
            let updated = try store.saveAPIKey(apiKeyInput, for: provider)
            provider = updated
            apiKeyInput = ""
            keyFieldFocused = false
            showingKeySaved = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { showingKeySaved = false }
        } catch {
            // TODO: surface error nicely
        }
    }

    private func removeKey() {
        do {
            let updated = try store.removeAPIKey(for: provider)
            provider = updated
        } catch {
            // TODO: surface error nicely
        }
    }

    private func test() {
        testing = true
        Task { await store.test(provider: provider); await MainActor.run { testing = false } }
    }

    private func fetchModels() {
        loadingModels = true
        modelsMessage = nil
        let current = provider
        Task {
            let adapter = AdapterFactory.make(for: current)
            let (list, msg) = await adapter.listModels(provider: current)
            await MainActor.run {
                self.models = list
                self.modelsMessage = msg
                self.loadingModels = false
            }
        }
    }
}

extension ProviderDetailView {
    private func copyCurl() {
        let curl: String
        switch provider.kind {
        case .ollama:
            let url = URL(string: provider.baseURL)?.appendingPathComponent("api/tags").absoluteString ?? "<base>/api/tags"
            curl = "curl -s \"\(url)\""
        case .openAICompatible:
            let base = URL(string: provider.baseURL)
            let path = (base?.path.trimmingCharacters(in: CharacterSet(charactersIn: "/")) ?? "")
            let url = (path.hasSuffix("v1") ? base?.appendingPathComponent("models") : base?.appendingPathComponent("v1/models"))?.absoluteString ?? "<base>/v1/models"
            var header = ""
            if case let .bearer(keyRef) = provider.auth, let k = try? KeychainService.shared.read(account: keyRef) ?? nil {
                header = " -H \"Authorization: Bearer \(k)\""
            }
            let extras = provider.extraHeaders.map { " -H \"\($0.key): \($0.value)\"" }.joined()
            curl = "curl -s\(header)\(extras) \"\(url)\""
        case .aliyunNative:
            let url = URL(string: provider.baseURL)?.appendingPathComponent("api/v1/models").absoluteString ?? "<base>/api/v1/models"
            var header = ""
            if case let .bearer(keyRef) = provider.auth, let k = try? KeychainService.shared.read(account: keyRef) ?? nil {
                header = " -H \"Authorization: Bearer \(k)\""
            }
            let extras = provider.extraHeaders.map { " -H \"\($0.key): \($0.value)\"" }.joined()
            curl = "curl -s\(header)\(extras) \"\(url)\""
        }
        let pb = NSPasteboard.general
        pb.clearContents()
        pb.setString(curl, forType: .string)
    }
}

struct KeyValueEditorView: View {
    @Binding var dict: [String: String]

    var body: some View {
        VStack(alignment: .leading) {
            if dict.isEmpty {
                Text("无额外 Header")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else {
                ForEach(Array(dict.keys).sorted(), id: \.self) { k in
                    let v = dict[k] ?? ""
                    HStack {
                        TextField("Key", text: .constant(k))
                            .disabled(true)
                        TextField("Value", text: Binding(get: { v }, set: { dict[k] = $0 }))
                        Button(role: .destructive) { dict.removeValue(forKey: k) } label: { Image(systemName: "trash") }
                    }
                }
            }
        }
    }
}

extension Binding where Value == String {
    static func fromOptional(_ source: Binding<String?>, replacingNilWith nilReplacement: String = "") -> Binding<String> {
        Binding<String>(
            get: { source.wrappedValue ?? nilReplacement },
            set: { newValue in source.wrappedValue = newValue.isEmpty ? nil : newValue }
        )
    }
}
