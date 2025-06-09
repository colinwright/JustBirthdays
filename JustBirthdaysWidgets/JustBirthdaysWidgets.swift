import WidgetKit
import SwiftUI
import SwiftData
import AppIntents

struct PersonInfo: Identifiable, Hashable {
    let id: UUID
    let name: String
}

// --- The Provider struct is unchanged ---
struct Provider: AppIntentTimelineProvider {
    let modelContainer: ModelContainer
    
    init() {
        let appGroupID = "group.com.colinismyname.JustBirthdays"
        let schema = Schema([Person.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false, groupContainer: .identifier(appGroupID))
        
        do {
            modelContainer = try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Failed to create container for widget: \(error)")
        }
    }

    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), people: [
            PersonInfo(id: UUID(), name: "John Appleseed"),
            PersonInfo(id: UUID(), name: "Jane Doe")
        ], widgetKind: .today)
    }

    func snapshot(for configuration: ConfigurationAppIntent, in context: Context) async -> SimpleEntry {
        let people = await fetchPeople(for: configuration.widgetKind)
        return SimpleEntry(date: Date(), people: people, widgetKind: configuration.widgetKind)
    }
    
    func timeline(for configuration: ConfigurationAppIntent, in context: Context) async -> Timeline<SimpleEntry> {
        let people = await fetchPeople(for: configuration.widgetKind)
        let entry = SimpleEntry(date: Date(), people: people, widgetKind: configuration.widgetKind)
        
        let nextUpdateDate = Calendar.current.startOfDay(for: Date()).addingTimeInterval(60*60*24)
        return Timeline(entries: [entry], policy: .after(nextUpdateDate))
    }
    
    @MainActor
    private func fetchPeople(for kind: WidgetKind) -> [PersonInfo] {
        let descriptor = FetchDescriptor<Person>()
        guard let allPeople = try? modelContainer.mainContext.fetch(descriptor) else { return [] }

        let filteredPeople: [Person]
        switch kind {
        case .today:
            filteredPeople = allPeople.filter { $0.isBirthdayToday }.sorted { $0.name < $1.name }
        case .upcoming:
            filteredPeople = allPeople
                .filter { !$0.isBirthdayToday && $0.daysUntilNextBirthday <= 30 }
                .sorted { $0.daysUntilNextBirthday < $1.daysUntilNextBirthday }
        }
        
        return filteredPeople.map { PersonInfo(id: $0.id, name: $0.name) }
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let people: [PersonInfo]
    let widgetKind: WidgetKind
}

// --- All changes are in this view ---
struct JustBirthdaysWidgetEntryView : View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) var family

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            if family != .systemSmall {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.secondary)
                Divider()
            }
            
            if entry.people.isEmpty {
                Text("None")
                    .font(nameFont).bold()
            } else {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(entry.people.prefix(peopleToShow)) { personInfo in
                        if family == .systemSmall {
                            HStack(alignment: .top, spacing: 5) {
                                Text("•")
                                    .font(nameFont)
                                
                                Text(personInfo.name)
                                    .font(nameFont)
                                    .bold()
                                    .lineLimit(2)
                                    .fixedSize(horizontal: false, vertical: true)
                                
                                Spacer() // This pushes the bullet and name to the left.
                            }
                        } else {
                            Text(personInfo.name)
                                .font(nameFont)
                                .bold()
                                .lineLimit(2)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
                
                if entry.people.count > peopleToShow {
                    Text("and \(entry.people.count - peopleToShow) more...")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.top, 2)
                }
            }
            
            // By putting the Spacer only here, it pushes all content up.
            // This ensures the small widget's content starts at the top.
            // The medium widget will naturally center itself due to the VStack's behavior.
            if family == .systemSmall {
                Spacer()
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
    }
    
    private var title: String {
        switch entry.widgetKind {
        case .today:
            return "Today's Birthdays"
        case .upcoming:
            return "Upcoming Birthdays"
        }
    }
    
    private var nameFont: Font {
        switch family {
        case .systemSmall:
            return .caption
        default:
            return .subheadline
        }
    }
    
    private var peopleToShow: Int {
        switch family {
        case .systemSmall: return 3
        case .systemMedium: return 4
        default: return 8
        }
    }
}

// --- The rest of the file is unchanged ---

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
    
    init() {}
    
    init(widgetKind: WidgetKind) {
        self.widgetKind = widgetKind
    }
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
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

@main
struct JustBirthdaysWidgets: WidgetBundle {
    var body: some Widget {
        JustBirthdaysWidget()
    }
}
