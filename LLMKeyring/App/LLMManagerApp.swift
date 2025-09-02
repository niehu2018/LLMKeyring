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
            // No visible windows - try to restore or create a main window
            // First try to deminiaturize any minimized windows
            for window in sender.windows {
                if window.isMiniaturized {
                    window.deminiaturize(nil)
                    window.makeKeyAndOrderFront(nil)
                    return true
                }
            }
            
            // If we have any existing window (even if not visible), try to bring it to front
            if let window = sender.windows.first {
                window.makeKeyAndOrderFront(nil)
                return true
            }
            
            // No windows exist at all - let SwiftUI create a new window
            // Returning false tells SwiftUI to create a new window for the WindowGroup
            return false
        } else {
            // Windows exist and are visible - bring the first window to front
            if let mainWindow = sender.windows.first {
                mainWindow.makeKeyAndOrderFront(nil)
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
