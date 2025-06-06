import WidgetKit
import SwiftUI

struct Provider: TimelineProvider {
    let widgetType: WidgetType

    enum WidgetType {
        case today, upcoming
    }

    struct SimpleEntry: TimelineEntry {
        let date: Date
        let people: [PersonInfo]
        let widgetType: Provider.WidgetType
    }
    
    func placeholder(in context: Context) -> SimpleEntry {
        let samplePeople: [PersonInfo]
        if widgetType == .today {
            samplePeople = [PersonInfo(id: UUID(), name: "Alex Applebaum", formattedBirthday: "Oct 26", daysUntil: 0)]
        } else {
            samplePeople = [
                PersonInfo(id: UUID(), name: "Brenda Blueberry", formattedBirthday: "Nov 1", daysUntil: 3),
                PersonInfo(id: UUID(), name: "Charles Cherry", formattedBirthday: "Nov 5", daysUntil: 7)
            ]
        }
        return SimpleEntry(date: Date(), people: samplePeople, widgetType: widgetType)
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        // When running in a preview, just return the placeholder data immediately.
        if context.isPreview {
            completion(placeholder(in: context))
            return
        }
        
        let entry = getEntry()
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SimpleEntry>) -> ()) {
        let entry = getEntry()
        let startOfTomorrow = Calendar.current.startOfDay(for: Date().addingTimeInterval(86400))
        let timeline = Timeline(entries: [entry], policy: .after(startOfTomorrow))
        completion(timeline)
    }
    
    private func getEntry() -> SimpleEntry {
        let widgetData = WidgetDataController.shared.readWidgetData()
        let people: [PersonInfo]
        switch widgetType {
            case .today: people = widgetData.todaysBirthdays
            case .upcoming: people = widgetData.upcomingBirthdays
        }
        return SimpleEntry(date: Date(), people: people, widgetType: widgetType)
    }
}

struct BirthdayWidgetEntryView: View {
    var entry: Provider.SimpleEntry
    
    var body: some View {
        switch entry.widgetType {
        case .today:
            TodaysBirthdaysWidgetView(entry: entry)
        case .upcoming:
            UpcomingBirthdaysWidgetView(entry: entry)
        }
    }
}

struct TodaysBirthdaysWidgetView : View {
    var entry: Provider.SimpleEntry
    @Environment(\.widgetFamily) var family

    private func getMaxItems() -> Int {
        switch family {
        case .systemSmall: return 2
        case .systemMedium: return 4
        case .systemLarge: return 7
        default: return 4
        }
    }

    @ViewBuilder
    private var content: some View {
        if entry.people.isEmpty {
            emptyStateView(message: "No birthdays today.")
        } else {
            birthdayListView(maxItems: getMaxItems())
        }
    }
    
    private func birthdayListView(maxItems: Int) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            ForEach(entry.people.prefix(maxItems)) { person in
                Text("• \(person.name)")
                    .font(family == .systemSmall ? .caption2 : .footnote)
                    .foregroundColor(.secondary)
            }
            Spacer()
            if entry.people.count > maxItems {
                clickForMoreView()
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func emptyStateView(message: String) -> some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                Text(message).font(.caption).foregroundColor(.secondary)
                Spacer()
            }
            Spacer()
        }
    }
    
    private func clickForMoreView() -> some View {
        HStack {
            Spacer()
            Text("Click for More")
                .font(family == .systemSmall ? .caption2.bold() : .footnote.bold())
                .foregroundColor(.accentColor)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Today's Birthdays")
                .font(family == .systemSmall ? .caption.bold() : .headline)
                .foregroundColor(.primary)
            content
        }
        .padding(EdgeInsets(top: 12, leading: 8, bottom: 12, trailing: 12))
        .widgetURL(URL(string: "justbirthdays://openToday"))
        .containerBackground(for: .widget) {
            Color(NSColor.windowBackgroundColor)
        }
    }
}

struct UpcomingBirthdaysWidgetView : View {
    var entry: Provider.SimpleEntry
    @Environment(\.widgetFamily) var family

    private func getMaxItems() -> Int {
        switch family {
        case .systemSmall: return 2
        case .systemMedium: return 3
        case .systemLarge: return 6
        default: return 3
        }
    }

    @ViewBuilder
    private var content: some View {
        if entry.people.isEmpty {
            emptyStateView(message: "No upcoming birthdays.")
        } else {
            upcomingBirthdayListView(maxItems: getMaxItems())
        }
    }

    private func upcomingBirthdayListView(maxItems: Int) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            ForEach(entry.people.prefix(maxItems)) { person in
                HStack {
                    Text("• \(person.name)")
                        .font(family == .systemSmall ? .caption2 : .footnote)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(person.daysUntil)d")
                        .font(family == .systemSmall ? .caption2 : .footnote)
                        .foregroundColor(.gray)
                }
            }
            Spacer()
            if entry.people.count > maxItems {
                clickForMoreView()
            }
        }
    }
    
    private func emptyStateView(message: String) -> some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                Text(message).font(.caption).foregroundColor(.secondary)
                Spacer()
            }
            Spacer()
        }
    }

    private func clickForMoreView() -> some View {
        HStack {
            Spacer()
            Text("Click for More")
                .font(family == .systemSmall ? .caption2.bold() : .footnote.bold())
                .foregroundColor(.accentColor)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Upcoming Birthdays")
                .font(family == .systemSmall ? .caption.bold() : .headline)
                .foregroundColor(.primary)
            content
        }
        .padding(EdgeInsets(top: 12, leading: 8, bottom: 12, trailing: 12))
        .widgetURL(URL(string: "justbirthdays://openUpcoming"))
        .containerBackground(for: .widget) {
            Color(NSColor.windowBackgroundColor)
        }
    }
}

struct TodaysBirthdaysWidget: Widget {
    let kind: String = "TodaysBirthdaysWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider(widgetType: .today)) { entry in
            BirthdayWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Today's Birthdays")
        .description("See who has a birthday today.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

struct UpcomingBirthdaysWidget: Widget {
    let kind: String = "UpcomingBirthdaysWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider(widgetType: .upcoming)) { entry in
            BirthdayWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Upcoming Birthdays")
        .description("See birthdays coming up soon.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

@main
struct JustBirthdaysWidgetBundle: WidgetBundle {
   @WidgetBundleBuilder
   var body: some Widget {
       TodaysBirthdaysWidget()
       UpcomingBirthdaysWidget()
   }
}
