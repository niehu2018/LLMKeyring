import SwiftUI

struct AppSettingsView: View {
    @AppStorage("appLanguage") private var appLanguage: String = "system"
    @Environment(\.locale) private var locale

    var body: some View {
        Form {
            Section(header: Text(NSLocalizedString("LanguageSection", comment: "Language Section"))) {
                Picker("", selection: $appLanguage) {
                    Text(NSLocalizedString("FollowSystem", comment: "Follow System")).tag("system")
                    Text("English").tag("en")
                    Text("简体中文").tag("zh-Hans")
                }
                .pickerStyle(.segmented)
                Text(NSLocalizedString("LanguageChangeHint", comment: "Language change hint"))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(20)
        .frame(width: 420)
        .id(locale)
    }
}
