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
            
            // If no minimized windows, try to bring any existing but hidden window to front
            for window in sender.windows {
                if !window.isVisible {
                    window.makeKeyAndOrderFront(nil)
                    return true
                }
            }
            
            // If we have any window (even if not visible), try to bring it to front
            if let window = sender.windows.first {
                window.makeKeyAndOrderFront(nil)
                return true
            }
            
            // No windows exist at all - tell SwiftUI to create a new window
            // For SwiftUI WindowGroup, we need to explicitly open a new window
            if #available(macOS 13.0, *) {
                // Use the new window opening approach for macOS 13+
                NSApp.sendAction(#selector(NSResponder.newDocument(_:)), to: nil, from: nil)
            } else {
                // Fallback for older versions - let SwiftUI handle it
                return false
            }
            
            return true
        } else {
            // Windows exist and are visible - bring the main window to front
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
