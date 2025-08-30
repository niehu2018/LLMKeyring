import SwiftUI

struct ProviderDetailView: View {
    @EnvironmentObject var store: ProviderStore
    @State var provider: Provider
    @State private var apiKeyInput: String = ""
    @State private var showingKeySaved = false
    @State private var testing = false
    @FocusState private var keyFieldFocused: Bool
    @Environment(\.locale) private var locale

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
                        Text(provider.enabled ? NSLocalizedString("Enabled", comment: "Enabled") : NSLocalizedString("Disabled", comment: "Disabled"))
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
                    Text(NSLocalizedString("BasicConfiguration", comment: "Basic Configuration"))
                        .font(.headline)
                        .fontWeight(.semibold)
                        .padding(.horizontal, 20)
                    
                    VStack(spacing: 16) {
                        // Name
                        VStack(alignment: .leading, spacing: 6) {
                            Text(NSLocalizedString("Name", comment: "Name"))
                                .font(.subheadline)
                                .fontWeight(.medium)
                            TextField(NSLocalizedString("ProviderNamePlaceholder", comment: "Provider Name"), text: $provider.name)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                        .padding(.horizontal, 20)
                        
                        // Base URL
                        VStack(alignment: .leading, spacing: 6) {
                            Text(NSLocalizedString("BaseURL", comment: "Base URL"))
                                .font(.subheadline)
                                .fontWeight(.medium)
                            TextField("https://api.example.com", text: $provider.baseURL)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .font(.system(.body, design: .monospaced))
                            HStack(spacing: 8) {
                                Button {
                                    let newBase = BaseURLHelper.normalizedBase(for: provider.kind, base: provider.baseURL)
                                    if newBase != provider.baseURL {
                                        provider.baseURL = newBase
                                        store.update(provider)
                                    }
                                } label: {
                                    Label(NSLocalizedString("Normalize", comment: "Normalize"), systemImage: "wand.and.stars")
                                }
                                if let alt = BaseURLHelper.alternateKindAndBase(for: provider) {
                                    Button {
                                        var p = provider
                                        p.kind = alt.0
                                        p.baseURL = alt.1
                                        provider = p
                                        store.update(p)
                                    } label: {
                                        Label(NSLocalizedString("SwitchMode", comment: "Switch Mode"), systemImage: "arrow.triangle.2.circlepath")
                                    }.help(alt.0.displayName)
                                }
                                Button {
                                    if let suggestion = BaseURLHelper.detectionSuggestion(for: provider.baseURL) {
                                        var p = provider
                                        p.kind = suggestion.0
                                        p.baseURL = suggestion.1
                                        provider = p
                                        store.update(p)
                                    }
                                } label: {
                                    Label(NSLocalizedString("Detect", comment: "Detect"), systemImage: "scope")
                                }
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                            Text(NSLocalizedString("NormalizeExplain", comment: "Explain normalize"))
                                .font(.caption)
                                .foregroundColor(.secondary)
                            if provider.kind == .openAICompatible && provider.baseURL.contains("aliyuncs.com") {
                                Text(NSLocalizedString("HintAliyunBaseURL", comment: "Aliyun base URL hint"))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            if provider.baseURL.contains("moonshot.ai") {
                                Text(NSLocalizedString("KimiURLTip", comment: "Kimi URL tip"))
                                    .font(.caption)
                                    .foregroundColor(.orange)
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                }
                
                Divider()
                    .padding(.horizontal, 20)
                
                // Authentication Section
                VStack(alignment: .leading, spacing: 16) {
                    Text(NSLocalizedString("APIKey", comment: "API Key"))
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
                                    Text(NSLocalizedString("SafelySaved", comment: "Safely Saved"))
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
                                Text(NSLocalizedString("NoAPIKeySaved", comment: "No API Key Saved"))
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.orange)
                            }
                            Spacer()
                        }
                        .padding(.horizontal, 20)
                        
                        // Input and buttons
                        VStack(spacing: 12) {
                            SecureField(NSLocalizedString("EnterAPIKey", comment: "Enter API Key"), text: $apiKeyInput)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .focused($keyFieldFocused)
                                .font(.system(.body, design: .monospaced))
                            
                            HStack(spacing: 12) {
                                Button(action: saveKey) {
                                    HStack {
                                        Image(systemName: "square.and.arrow.down")
                                        Text(NSLocalizedString("Save", comment: "Save"))
                                    }
                                    .frame(maxWidth: .infinity)
                                }
                                .buttonStyle(.borderedProminent)
                                .disabled(apiKeyInput.isEmpty)
                                
                                Button(action: removeKey) {
                                    HStack {
                                        Image(systemName: "trash")
                                        Text(NSLocalizedString("Remove", comment: "Remove"))
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
                                Text(NSLocalizedString("SaveSuccess", comment: "Save Successful"))
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
                    Text(NSLocalizedString("ConnectionTest", comment: "Connection Test"))
                        .font(.headline)
                        .fontWeight(.semibold)
                        .padding(.horizontal, 20)
                    
                    VStack(spacing: 16) {
                        Button(action: test) {
                            HStack {
                                if testing {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                    Text(NSLocalizedString("Testing", comment: "Testing..."))
                                } else {
                                    Image(systemName: "bolt.fill")
                                    Text(NSLocalizedString("StartTest", comment: "Start Test"))
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
                            Text(provider.lastTest.message ?? NSLocalizedString("ClickToStartTest", comment: "Click the button above to start connection test"))
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
        .id(locale)
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
