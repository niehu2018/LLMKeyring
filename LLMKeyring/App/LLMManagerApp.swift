import SwiftUI
import AppKit

@main
struct LLMKeyringApp: App {
    @StateObject private var store = ProviderStore()
    @AppStorage("appLanguage") private var appLanguage: String = "system"

    private var appLocale: Locale {
        switch appLanguage {
        case "en": return Locale(identifier: "en")
        case "zh-Hans": return Locale(identifier: "zh-Hans")
        default: return Locale.current
        }
    }

    init() {
        // Generate a simple runtime app icon with letter "A"
        let icon = AppIconGenerator.makeLetterIcon(letter: "A")
        NSApplication.shared.applicationIconImage = icon
    }

    var body: some Scene {
        WindowGroup(NSLocalizedString("ManagerTitle", comment: "Window title"), id: "manager") {
            ContentView()
                .environmentObject(store)
                .environment(\.locale, appLocale)
        }
        .defaultSize(width: 980, height: 640)

        MenuBarExtra(NSLocalizedString("LLMTitle", comment: "Menu bar title"), systemImage: "bolt.circle") {
            MenuBarView()
                .environmentObject(store)
                .environment(\.locale, appLocale)
        }

        Settings {
            AppSettingsView()
                .environmentObject(store)
                .environment(\.locale, appLocale)
        }
    }
}
