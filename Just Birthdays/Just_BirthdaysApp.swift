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
        // Remove the settings scene if you don't have one, or it can cause issues
        // if not fully implemented. For a simple app, it's often not needed initially.
        // Settings {
        //     SettingsView()
        // }
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

// (Optional) If you were to create a SettingsView:
// struct SettingsView: View {
//     var body: some View {
//         Form {
//             Text("App Settings")
//                 .font(.title)
//             Text("Configure your Just Birthdays app preferences here.")
//         }
//         .padding()
//         .frame(width: 400, height: 300)
//     }
// }
