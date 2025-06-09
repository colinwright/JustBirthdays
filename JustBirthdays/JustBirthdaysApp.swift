import SwiftUI
import SwiftData

@main
struct JustBirthdaysApp: App {
    @StateObject private var appState = AppState()

    var sharedModelContainer: ModelContainer = {
        let appGroupID = "group.com.colinismyname.JustBirthdays"

        let schema = Schema([
            Person.self,
        ])
        
        // This configuration tells SwiftData to store its database in the shared App Group.
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false, groupContainer: .identifier(appGroupID))

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
        .environmentObject(appState)
    }
}
