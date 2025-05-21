// MARK: - JustBirthdaysApp.swift
// The main entry point for the macOS application.

import SwiftUI

@main
struct JustBirthdaysApp: App {
    @StateObject var birthdayStore = BirthdayStore()
    // Delegate to handle app lifecycle events, specifically window closing.
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(birthdayStore)
        }
        // Add the Settings scene to create a "Settings..." menu item
        // and open the SettingsView when selected.
        // The keyboard shortcut Command-Comma (⌘,) is standard for settings.
        Settings {
            SettingsView()
                .environmentObject(birthdayStore) // Pass the store if settings need to interact with it
        }
    }
}

// MARK: - AppDelegate
// This class handles application-level events.
class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        // This delegate method tells the application to terminate when its last window is closed.
        return true
    }
}
