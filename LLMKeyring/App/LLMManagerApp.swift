import SwiftUI
import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApplication.shared.activate(ignoringOtherApps: true)
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        // When the Dock icon is clicked, bring app windows to front or reopen if closed
        sender.activate(ignoringOtherApps: true)
        if !flag {
            for window in sender.windows {
                if window.isMiniaturized { window.deminiaturize(nil) }
                window.makeKeyAndOrderFront(nil)
            }
        }
        return true
    }
}

@main
struct LLMKeyringApp: App {
    @StateObject private var store = ProviderStore()
    @StateObject private var localizationHelper = LocalizationHelper.shared
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

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

        Settings {
            AppSettingsView()
                .environmentObject(store)
        }
    }
}
