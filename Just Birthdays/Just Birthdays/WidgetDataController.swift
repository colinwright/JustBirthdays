import Foundation
import CoreData
import WidgetKit

// A simple, thread-safe struct to hold widget data.
// This must be Codable to be saved as JSON.
struct PersonInfo: Codable, Identifiable, Hashable {
    let id: UUID
    let name: String
    let formattedBirthday: String
    let daysUntil: Int
}

// The top-level structure for our JSON file.
struct WidgetData: Codable {
    let todaysBirthdays: [PersonInfo]
    let upcomingBirthdays: [PersonInfo]
}

final class WidgetDataController {
    static let shared = WidgetDataController()
    
    private var widgetDataURL: URL? {
        // Read the App Group ID dynamically from the bundle's Info.plist.
        guard let appGroup = Bundle.main.object(forInfoDictionaryKey: "AppGroupIdentifier") as? String else {
            fatalError("AppGroupIdentifier not found in Info.plist. Make sure it's set for the current target.")
        }
        return FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroup)?.appendingPathComponent("widget-data.json")
    }
    
    // This is called from the main app whenever data changes.
    @MainActor
    func updateWidgetData(using context: NSManagedObjectContext) {
        let request: NSFetchRequest<Person> = Person.fetchRequest()
        
        do {
            let allPeople = try context.fetch(request)
            
            // Generate today's birthdays list.
            let todays = allPeople
                .filter { $0.isToday }
                .sorted { $0.wrappedName.localizedCaseInsensitiveCompare($1.wrappedName) == .orderedAscending }
                .map { PersonInfo(id: $0.wrappedId, name: $0.wrappedName, formattedBirthday: $0.formattedBirthday, daysUntil: 0) }

            // Generate upcoming birthdays list (next 7 days).
            let calendar = Calendar.current
            let todayStart = calendar.startOfDay(for: Date())
            guard let endDate = calendar.date(byAdding: .day, value: 7, to: todayStart) else { return }

            let upcoming = allPeople
                .filter { person in
                    !person.isToday && person.nextBirthdayDate >= todayStart && person.nextBirthdayDate < endDate
                }
                .sorted { $0.nextBirthdayDate < $1.nextBirthdayDate }
                .map { PersonInfo(id: $0.wrappedId, name: $0.wrappedName, formattedBirthday: $0.formattedBirthday, daysUntil: $0.daysUntilNextBirthday) }

            // Combine into a single data object.
            let widgetData = WidgetData(todaysBirthdays: todays, upcomingBirthdays: upcoming)
            
            // Write the data to the shared JSON file.
            if let url = widgetDataURL {
                let encoder = JSONEncoder()
                let data = try encoder.encode(widgetData)
                try data.write(to: url)
                
                // After successfully writing the data, tell all widgets to reload their timelines.
                WidgetCenter.shared.reloadAllTimelines()
            }
            
        } catch {
            print("Failed to update widget data: \(error)")
        }
    }
    
    // This is called from the widget extension to read the data.
    func readWidgetData() -> WidgetData {
        guard let url = widgetDataURL, let data = try? Data(contentsOf: url) else {
            // If the file doesn't exist or can't be read, return empty data.
            return WidgetData(todaysBirthdays: [], upcomingBirthdays: [])
        }
        
        let decoder = JSONDecoder()
        if let widgetData = try? decoder.decode(WidgetData.self, from: data) {
            return widgetData
        }
        
        // If decoding fails, return empty data.
        return WidgetData(todaysBirthdays: [], upcomingBirthdays: [])
    }
}
