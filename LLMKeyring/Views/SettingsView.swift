import SwiftUI

struct AppSettingsView: View {
    @StateObject private var localizationHelper = LocalizationHelper.shared
    
    var body: some View {
        Form {
            Section(header: Text(LocalizedString("LanguageSection", comment: "Language Section"))) {
                Picker("", selection: $localizationHelper.currentLanguage) {
                    Text(LocalizedString("FollowSystem", comment: "Follow System")).tag("system")
                    Text("English").tag("en")
                    Text("简体中文").tag("zh-Hans")
                }
                .pickerStyle(.segmented)
                Text(LocalizedString("LanguageChangeHint", comment: "Language change hint"))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(20)
        .frame(width: 420)
        .id(localizationHelper.currentLanguage)
    }
}
