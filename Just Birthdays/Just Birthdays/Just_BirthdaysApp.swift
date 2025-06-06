import SwiftUI

@main
struct Just_BirthdaysApp: App {
    let persistenceController = PersistenceController.shared
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    @State private var activeDisplayMode: ContentView.DisplayMode = .today

    var body: some Scene {
        WindowGroup(id: "main") {
            ContentView(initialDisplayMode: activeDisplayMode)
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .onAppear {
                    // On first launch or when the view appears, ensure widget data is up to date.
                    WidgetDataController.shared.updateWidgetData(using: persistenceController.container.viewContext)
                }
                .onOpenURL { url in
                    guard url.scheme == "justbirthdays" else { return }
                    
                    switch url.host {
                    case "openToday":
                        activeDisplayMode = .today
                    case "openUpcoming":
                        activeDisplayMode = .upcoming
                    default:
                        activeDisplayMode = .today
                    }
                }
        }
        .defaultSize(width: 550, height: 430) // Sets the initial window size.

        Settings {
            SettingsView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
    
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if flag {
            for window in sender.windows {
                window.makeKeyAndOrderFront(self)
            }
            return false
        } else {
            return true
        }
    }
}
