import SwiftUI

struct ProviderDetailView: View {
    @EnvironmentObject var store: ProviderStore
    @State var provider: Provider
    @State private var apiKeyInput: String = ""
    @State private var showingKeySaved = false
    @State private var testing = false
    @FocusState private var keyFieldFocused: Bool

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header Section
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(provider.name)
                                .font(.title2)
                                .fontWeight(.semibold)
                            Text(provider.kind.displayName)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Toggle("", isOn: $provider.enabled)
                    }
                    
                    HStack(spacing: 8) {
                        Image(systemName: provider.enabled ? "checkmark.circle.fill" : "xmark.circle")
                            .foregroundColor(provider.enabled ? .green : .secondary)
                        Text(provider.enabled ? "已启用" : "已禁用")
                            .font(.caption)
                            .foregroundColor(provider.enabled ? .green : .secondary)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                
                Divider()
                    .padding(.horizontal, 20)
                
                // Basic Configuration
                VStack(alignment: .leading, spacing: 16) {
                    Text("基本配置")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .padding(.horizontal, 20)
                    
                    VStack(spacing: 16) {
                        // Name
                        VStack(alignment: .leading, spacing: 6) {
                            Text("名称")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            TextField("Provider Name", text: $provider.name)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                        .padding(.horizontal, 20)
                        
                        // Type
                        VStack(alignment: .leading, spacing: 6) {
                            Text("类型")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            Picker("类型", selection: $provider.kind) {
                                ForEach(ProviderKind.allCases) { kind in
                                    Text(kind.displayName).tag(kind)
                                }
                            }
                            .pickerStyle(MenuPickerStyle())
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .padding(.horizontal, 20)
                        
                        // Base URL
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Base URL")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            TextField("https://api.example.com", text: $provider.baseURL)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .font(.system(.body, design: .monospaced))
                            if provider.kind == .openAICompatible && provider.baseURL.contains("aliyuncs.com") {
                                Text(NSLocalizedString("HintAliyunBaseURL", comment: "Aliyun base URL hint"))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                }
                
                Divider()
                    .padding(.horizontal, 20)
                
                // Authentication Section
                VStack(alignment: .leading, spacing: 16) {
                    Text("API 密钥")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .padding(.horizontal, 20)
                    
                    VStack(alignment: .leading, spacing: 16) {
                        // Status
                        HStack(spacing: 10) {
                            if case let .bearer(keyRef) = provider.auth {
                                Image(systemName: "lock.fill")
                                    .foregroundColor(.green)
                                    .font(.title3)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("已安全保存")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                    Text("Keychain: \(keyRef)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            } else {
                                Image(systemName: "lock.slash")
                                    .foregroundColor(.orange)
                                    .font(.title3)
                                Text("未保存 API Key")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.orange)
                            }
                            Spacer()
                        }
                        .padding(.horizontal, 20)
                        
                        // Input and buttons
                        VStack(spacing: 12) {
                            SecureField("输入 API Key", text: $apiKeyInput)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .focused($keyFieldFocused)
                                .font(.system(.body, design: .monospaced))
                            
                            HStack(spacing: 12) {
                                Button(action: saveKey) {
                                    HStack {
                                        Image(systemName: "square.and.arrow.down")
                                        Text("保存")
                                    }
                                    .frame(maxWidth: .infinity)
                                }
                                .buttonStyle(.borderedProminent)
                                .disabled(apiKeyInput.isEmpty)
                                
                                Button(action: removeKey) {
                                    HStack {
                                        Image(systemName: "trash")
                                        Text("移除")
                                    }
                                    .frame(maxWidth: .infinity)
                                }
                                .buttonStyle(.bordered)
                                .foregroundColor(.red)
                                .disabled(!hasKey)
                            }
                        }
                        .padding(.horizontal, 20)
                        
                        if showingKeySaved {
                            HStack(spacing: 8) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                Text("保存成功")
                                    .font(.subheadline)
                                    .foregroundColor(.green)
                            }
                            .padding(.horizontal, 20)
                        }
                    }
                }
                
                Divider()
                    .padding(.horizontal, 20)
                
                // Connection Test
                VStack(alignment: .leading, spacing: 16) {
                    Text("连接测试")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .padding(.horizontal, 20)
                    
                    VStack(spacing: 16) {
                        Button(action: test) {
                            HStack {
                                if testing {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                    Text("测试中...")
                                } else {
                                    Image(systemName: "bolt.fill")
                                    Text("开始测试")
                                }
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                        .disabled(testing)
                        .padding(.horizontal, 20)
                        
                        // Test result
                        HStack(spacing: 10) {
                            StatusDot(status: provider.lastTest.status)
                            Text(provider.lastTest.message ?? "点击上方按钮开始测试连接")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Spacer()
                        }
                        .padding(.horizontal, 20)
                    }
                }
                
                Spacer(minLength: 32)
            }
        }
        .background(Color(NSColor.controlBackgroundColor))
        .onDisappear { store.update(provider) }
        .onReceive(store.$providers) { _ in
            if let fresh = store.providers.first(where: { $0.id == provider.id }) {
                self.provider = fresh
            }
        }
        .navigationTitle("")
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
}



extension Binding where Value == String {
    static func fromOptional(_ source: Binding<String?>, replacingNilWith nilReplacement: String = "") -> Binding<String> {
        Binding<String>(
            get: { source.wrappedValue ?? nilReplacement },
            set: { newValue in source.wrappedValue = newValue.isEmpty ? nil : newValue }
        )
    }
}
