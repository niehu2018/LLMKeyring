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
            // Prioritize non-settings windows (main window)
            for window in sender.windows {
                if !window.isVisible {
                    // Check if this is not a settings window by looking at the title
                    if window.title != NSLocalizedString("Settings", comment: "") && 
                       !window.title.contains("Settings") &&
                       !window.title.contains("设置") {
                        window.makeKeyAndOrderFront(nil)
                        return true
                    }
                }
            }
            
            // If we have any non-settings window, try to bring it to front
            for window in sender.windows {
                if window.title != NSLocalizedString("Settings", comment: "") && 
                   !window.title.contains("Settings") &&
                   !window.title.contains("设置") {
                    window.makeKeyAndOrderFront(nil)
                    return true
                }
            }
            
            // No main windows exist - let SwiftUI create only the main window
            // We return false to let SwiftUI handle window creation, but we'll
            // make sure to close any unwanted settings windows that might open
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                // Close any settings windows that might have opened accidentally
                for window in NSApp.windows {
                    if window.title == NSLocalizedString("Settings", comment: "") || 
                       window.title.contains("Settings") ||
                       window.title.contains("设置") {
                        window.close()
                    }
                }
            }
            return false
        } else {
            // Windows exist and are visible - bring the main window to front (not settings)
            for window in sender.windows {
                if window.isVisible && 
                   window.title != NSLocalizedString("Settings", comment: "") && 
                   !window.title.contains("Settings") &&
                   !window.title.contains("设置") {
                    window.makeKeyAndOrderFront(nil)
                    break
                }
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
