import SwiftUI
import AppKit

@main
struct LLMKeyringApp: App {
    @StateObject private var store = ProviderStore()
    @StateObject private var localizationHelper = LocalizationHelper.shared

    init() {
        // Generate a simple runtime app icon with letter "A"
        let icon = AppIconGenerator.makeLetterIcon(letter: "A")
        NSApplication.shared.applicationIconImage = icon
    }

    var body: some Scene {
        WindowGroup(LocalizationHelper.shared.localizedString(for: "ManagerTitle", comment: "Window title"), id: "manager") {
            ContentView()
                .environmentObject(store)
                .environmentObject(localizationHelper)
        }
        .defaultSize(width: 980, height: 640)

        MenuBarExtra(LocalizationHelper.shared.localizedString(for: "LLMTitle", comment: "Menu bar title"), systemImage: "bolt.circle") {
            MenuBarView()
                .environmentObject(store)
                .environmentObject(localizationHelper)
        }

        Settings {
            AppSettingsView()
                .environmentObject(store)
        }
    }
}
