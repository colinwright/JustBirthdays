import WidgetKit
import SwiftUI
import SwiftData
import AppIntents

struct Provider: AppIntentTimelineProvider {
    let modelContainer: ModelContainer?
    
    init() {
        let appGroupID = "group.com.colinismyname.JustBirthdaysApp"
        let schema = Schema([Person.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false, groupContainer: .identifier(appGroupID))
        
        do {
            modelContainer = try ModelContainer(for: schema, configurations: [config])
        } catch {
            print("Failed to create container for widget: \(error)")
            modelContainer = nil
        }
    }

    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), people: [
            PersonInfo(id: UUID(), name: "John Appleseed", daysUntilNextBirthday: 0, ageTurningToday: 30),
            PersonInfo(id: UUID(), name: "Jane Doe", daysUntilNextBirthday: 5, ageTurningToday: nil)
        ], widgetKind: .today, upcomingDaysLimit: 30)
    }

    func snapshot(for configuration: ConfigurationAppIntent, in context: Context) async -> SimpleEntry {
        guard let container = modelContainer else {
            return SimpleEntry(date: .now, people: [], widgetKind: configuration.widgetKind, upcomingDaysLimit: 30)
        }
        
        let limit = fetchUpcomingDaysLimit()
        let people = await fetchPeople(from: container, for: configuration.widgetKind, upcomingDaysLimit: limit)
        return SimpleEntry(date: Date(), people: people, widgetKind: configuration.widgetKind, upcomingDaysLimit: limit)
    }
    
    func timeline(for configuration: ConfigurationAppIntent, in context: Context) async -> Timeline<SimpleEntry> {
        guard let container = modelContainer else {
            let entry = SimpleEntry(date: .now, people: [], widgetKind: configuration.widgetKind, upcomingDaysLimit: 30)
            let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: .now)!
            return Timeline(entries: [entry], policy: .after(nextUpdate))
        }

        let limit = fetchUpcomingDaysLimit()
        let people = await fetchPeople(from: container, for: configuration.widgetKind, upcomingDaysLimit: limit)
        let entry = SimpleEntry(date: Date(), people: people, widgetKind: configuration.widgetKind, upcomingDaysLimit: limit)
        
        let nextUpdateDate = Calendar.current.startOfDay(for: Date()).addingTimeInterval(60*60*24)
        return Timeline(entries: [entry], policy: .after(nextUpdateDate))
    }
    
    private func fetchUpcomingDaysLimit() -> Int {
        let appGroupID = "group.com.colinismyname.JustBirthdaysApp"
        guard let userDefaults = UserDefaults(suiteName: appGroupID) else {
            return 30
        }
        let savedLimit = userDefaults.integer(forKey: "upcomingDaysLimit")
        return savedLimit > 0 ? savedLimit : 30
    }
    
    @MainActor
    private func fetchPeople(from container: ModelContainer, for kind: WidgetKind, upcomingDaysLimit: Int) -> [PersonInfo] {
        let descriptor = FetchDescriptor<Person>()
        guard let allPeople = try? container.mainContext.fetch(descriptor) else { return [] }

        let filteredPeople: [Person]
        switch kind {
        case .today:
            filteredPeople = allPeople
                .filter { $0.isBirthdayToday }
                .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
        case .upcoming:
            filteredPeople = allPeople
                .filter { !$0.isBirthdayToday && $0.daysUntilNextBirthday > 0 && $0.daysUntilNextBirthday <= upcomingDaysLimit }
                .sorted { $0.daysUntilNextBirthday < $1.daysUntilNextBirthday }
        }
        
        return filteredPeople.map { PersonInfo(id: $0.id, name: $0.name, daysUntilNextBirthday: $0.daysUntilNextBirthday, ageTurningToday: $0.ageTurningToday) }
    }
}

struct PersonInfo: Identifiable, Hashable {
    let id: UUID
    let name: String
    let daysUntilNextBirthday: Int?
    let ageTurningToday: Int?
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let people: [PersonInfo]
    let widgetKind: WidgetKind
    let upcomingDaysLimit: Int
}

struct JustBirthdaysWidgetEntryView : View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) var family

    var body: some View {
        if family == .systemSmall {
            smallWidgetBody
        } else {
            mediumAndLargeWidgetBody
        }
    }

    @ViewBuilder
    private var smallWidgetBody: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(widgetTitle)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
            
            Spacer(minLength: 0)

            if let firstPerson = entry.people.first {
                Text(firstPerson.name)
                    .font(.headline)
                    .fontWeight(.bold)
                    .fixedSize(horizontal: false, vertical: true)

                if entry.people.count > 1 {
                    Text("and \(entry.people.count - 1) more")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            } else {
                Text(emptyStateText)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            Spacer(minLength: 0)
        }
        .padding()
    }
    
    @ViewBuilder
    private var mediumAndLargeWidgetBody: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(widgetTitle)
                .font(.headline)
                .foregroundStyle(.secondary)
                .padding(.bottom, 12)

            if entry.people.isEmpty {
                emptyStateView
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(entry.people.prefix(peopleToShow)) { personInfo in
                        HStack(alignment: .firstTextBaseline) {
                            Text(personInfo.name)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                            Spacer()
                            Text(contextualInfo(for: personInfo))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .monospacedDigit()
                        }
                    }
                }
                
                if entry.people.count > peopleToShow {
                    Text("and \(entry.people.count - peopleToShow) more")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.top, 8)
                }
                
                Spacer(minLength: 0)
            }
        }
        .padding()
    }
    
    private var emptyStateView: some View {
        VStack {
            Spacer()
            Image(systemName: entry.widgetKind == .today ? "gift" : "calendar")
                .font(.largeTitle)
                .foregroundStyle(.tertiary)
            Text(emptyStateText)
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
    
    private var widgetTitle: String {
        switch family {
        case .systemSmall:
            return entry.widgetKind == .today ? "Today" : "Upcoming"
        default:
            return entry.widgetKind == .today ? "Today's Birthdays" : "Upcoming Birthdays"
        }
    }
    
    private var emptyStateText: String {
        entry.widgetKind == .today ? "No birthdays today." : "No upcoming birthdays."
    }
    
    private var peopleToShow: Int {
        switch family {
        case .systemMedium: return 2
        case .systemLarge: return 9
        default: return 5
        }
    }
    
    private func contextualInfo(for person: PersonInfo) -> String {
        if entry.widgetKind == .upcoming {
            guard let days = person.daysUntilNextBirthday else { return "" }
            return days == 1 ? "in 1 day" : "in \(days) days"
        }
        
        if let age = person.ageTurningToday, age > 0 {
            return "turning \(age)"
        }
        
        return ""
    }
}

enum WidgetKind: String, AppEnum {
    case today, upcoming
    
    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Widget Type"
    static var caseDisplayRepresentations: [WidgetKind : DisplayRepresentation] = [
        .today: "Today's Birthdays",
        .upcoming: "Upcoming Birthdays"
    ]
}

struct ConfigurationAppIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Birthday Widget"
    static var description = IntentDescription("Choose which birthdays to display.")

    @Parameter(title: "Widget Type", default: .today)
    var widgetKind: WidgetKind
}

struct JustBirthdaysWidget: Widget {
    let kind: String = "JustBirthdaysWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: ConfigurationAppIntent.self, provider: Provider()) { entry in
            JustBirthdaysWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Birthdays")
        .description("See today's or upcoming birthdays.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

@main
struct JustBirthdaysWidgets: WidgetBundle {
    var body: some Widget {
        JustBirthdaysWidget()
    }
}
