import SwiftUI

struct AppSettingsView: View {
    @AppStorage("appLanguage") private var appLanguage: String = "system"

    var body: some View {
        Form {
            Section(header: Text("语言 / Language")) {
                Picker("语言 / Language", selection: $appLanguage) {
                    Text("跟随系统 / System").tag("system")
                    Text("English").tag("en")
                    Text("简体中文").tag("zh-Hans")
                }
                .pickerStyle(.segmented)
                Text("更改语言后，界面将即时更新。")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(20)
        .frame(width: 420)
    }
}
