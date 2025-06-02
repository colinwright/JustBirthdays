// MARK: - MyBirthdaysWidget/BirthdayWidget.swift
// This file defines the "Today's Birthdays" and "Upcoming Birthdays" widgets.

import WidgetKit
import SwiftUI

// MARK: 1. Timeline Entry
// Common entry for both widget types, data will be filtered by the provider.
struct SimpleBirthdayEntry: TimelineEntry {
    let date: Date
    let birthdays: [BirthdayEntry] // Holds either today's or upcoming birthdays
    let widgetType: WidgetType // To inform the view which type it is
    let isError: Bool
    let errorMessage: String?

    enum WidgetType {
        case today, upcoming
    }
}

// MARK: 2. Timeline Provider
struct BirthdayTimelineProvider: TimelineProvider {
    typealias Entry = SimpleBirthdayEntry

    private let appGroupIdForWidget = "group.com.colinismyname.JustBirthdays" // Ensure this matches your app
    let widgetType: SimpleBirthdayEntry.WidgetType // Added property

    // Initializer to specify the widget type
    init(widgetType: SimpleBirthdayEntry.WidgetType) {
        self.widgetType = widgetType
    }

    private func checkAppGroupConfiguration() -> (isError: Bool, errorMessage: String?) {
        if appGroupIdForWidget.isEmpty || appGroupIdForWidget == "group.com.yourdomain.JustBirthdays" {
            let msg = "Widget Error: App Group ID is placeholder or empty. Please configure."
            print(msg)
            return (isError: true, errorMessage: msg)
        }
        if UserDefaults(suiteName: appGroupIdForWidget) == nil {
            let msg = "Widget Error: Failed to init UserDefaults with App Group ID: \(appGroupIdForWidget). Check capabilities."
            print(msg)
            return (isError: true, errorMessage: msg)
        }
        return (isError: false, errorMessage: nil)
    }

    func placeholder(in context: Context) -> SimpleBirthdayEntry {
        // Use the provider's widgetType for the placeholder
        let sampleBirthday = BirthdayEntry(name: "Alex Applebaum-Smithington", birthday: Date(), phoneNumber: nil, emailAddress: nil, socialMediaURL: "https://example.com/alex", notes: nil, yearIsKnown: true)
        return SimpleBirthdayEntry(date: Date(), birthdays: [sampleBirthday], widgetType: self.widgetType, isError: false, errorMessage: "Placeholder")
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleBirthdayEntry) -> ()) {
        let configStatus = checkAppGroupConfiguration()
        var relevantBirthdays: [BirthdayEntry] = []
        let store = BirthdayStore()

        // Use the provider's widgetType for the snapshot
        if !configStatus.isError {
            if self.widgetType == .today {
                relevantBirthdays = Array(store.todaysBirthdays.prefix(3))
            } else {
                relevantBirthdays = Array(store.upcomingBirthdays.prefix(3))
            }
        }
        
        let entry = SimpleBirthdayEntry(date: Date(),
                                        birthdays: relevantBirthdays,
                                        widgetType: self.widgetType, // Use provider's type
                                        isError: configStatus.isError,
                                        errorMessage: configStatus.errorMessage ?? "Snapshot Data")
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        let configStatus = checkAppGroupConfiguration()
        var relevantBirthdays: [BirthdayEntry] = []
        let store = BirthdayStore()
        
        // Use the provider's widgetType, no need to inspect context.configuration.kind
        if !configStatus.isError {
            if self.widgetType == .today {
                relevantBirthdays = store.todaysBirthdays
            } else {
                relevantBirthdays = store.upcomingBirthdays
            }
            print("Widget Timeline (\(self.widgetType)): Store loaded \(store.entries.count) total. Displaying: \(relevantBirthdays.count)")
        } else {
            print("Widget Timeline (\(self.widgetType)): App Group configuration error.")
        }
        
        let currentDate = Date()
        let entry = SimpleBirthdayEntry(
            date: currentDate,
            birthdays: relevantBirthdays,
            widgetType: self.widgetType, // Use provider's type
            isError: configStatus.isError,
            errorMessage: configStatus.errorMessage ?? "Timeline Data"
        )

        let startOfTomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Calendar.current.startOfDay(for: currentDate))!
        let timeline = Timeline(entries: [entry], policy: .after(startOfTomorrow))
        print("Widget Timeline (\(self.widgetType)) created. Next update after: \(startOfTomorrow)")
        completion(timeline)
    }
}

// MARK: 3. Widget Views

struct ErrorView: View {
    let errorMessage: String
    var body: some View {
        VStack(alignment: .leading) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.orange)
                .font(.title2)
            Text(errorMessage)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.leading)
                .padding(.horizontal)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .containerBackground(for: .widget){
            Color(NSColor.windowBackgroundColor)
        }
    }
}

struct TodaysBirthdaysWidgetView : View {
    var entry: SimpleBirthdayEntry
    @Environment(\.widgetFamily) var family

    // Helper function to determine max items
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
        if entry.isError {
            ErrorView(errorMessage: entry.errorMessage ?? "Configuration Error.")
        } else if entry.birthdays.isEmpty {
            emptyStateView(message: "No birthdays today.")
        } else {
            birthdayListView(maxItems: getMaxItems())
        }
    }

    private func birthdayListView(maxItems: Int) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            ForEach(entry.birthdays.prefix(maxItems)) { bd in
                Text("• \(bd.name)")
                    .font(family == .systemSmall ? .caption2 : .footnote)
                    .foregroundColor(.secondary)
            }
            Spacer()
            if entry.birthdays.count > maxItems {
                clickForMoreView()
            } else {
                EmptyView()
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func emptyStateView(message: String) -> some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                Text(message)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
            }
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private func clickForMoreView() -> some View {
        HStack {
            Spacer()
            Text("Click for More")
                .font(family == .systemSmall ? .caption2.bold() : .footnote.bold())
                .foregroundColor(.accentColor)
        }
        .frame(maxWidth: .infinity, alignment: .trailing)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Today's Birthdays")
                .font(family == .systemSmall ? .caption.bold() : .headline)
                .foregroundColor(.primary)
            content
        }
        .padding(EdgeInsets(top: 12, leading: 8, bottom: 12, trailing: 12))
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .widgetURL(URL(string: "justbirthdays://openToday"))
        .containerBackground(for: .widget) {
            Color(NSColor.windowBackgroundColor)
        }
    }
}

struct UpcomingBirthdaysWidgetView : View {
    var entry: SimpleBirthdayEntry
    @Environment(\.widgetFamily) var family

    // Helper function to determine max items
    private func getMaxItems() -> Int {
        switch family {
        case .systemSmall: return 2 // Changed from 1 to 2
        case .systemMedium: return 3
        case .systemLarge: return 6
        default: return 3
        }
    }

    @ViewBuilder
    private var content: some View {
        if entry.isError {
            ErrorView(errorMessage: entry.errorMessage ?? "Configuration Error.")
        } else if entry.birthdays.isEmpty {
            emptyStateView(message: "No upcoming birthdays.")
        } else {
            upcomingBirthdayListView(maxItems: getMaxItems())
        }
    }

    private func upcomingBirthdayListView(maxItems: Int) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            ForEach(entry.birthdays.prefix(maxItems)) { bd in
                HStack {
                    Text("• \(bd.name)")
                        .font(family == .systemSmall ? .caption2 : .footnote)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(bd.daysUntilNextBirthday)d")
                        .font(family == .systemSmall ? .caption2 : .footnote)
                        .foregroundColor(.gray)
                }
            }
            Spacer()
            if entry.birthdays.count > maxItems {
                clickForMoreView()
            } else {
                EmptyView()
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private func emptyStateView(message: String) -> some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                Text(message)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
            }
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func clickForMoreView() -> some View {
        HStack {
            Spacer()
            Text("Click for More")
                .font(family == .systemSmall ? .caption2.bold() : .footnote.bold())
                .foregroundColor(.accentColor)
        }
        .frame(maxWidth: .infinity, alignment: .trailing)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Upcoming Birthdays")
                .font(family == .systemSmall ? .caption.bold() : .headline)
                .foregroundColor(.primary)
            content
        }
        .padding(EdgeInsets(top: 12, leading: 8, bottom: 12, trailing: 12))
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .widgetURL(URL(string: "justbirthdays://openUpcoming"))
        .containerBackground(for: .widget) {
            Color(NSColor.windowBackgroundColor)
        }
    }
}


// MARK: 4. Widget Definitions
struct TodaysBirthdaysWidget: Widget {
    static let kind: String = "TodaysBirthdaysWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: TodaysBirthdaysWidget.kind, provider: BirthdayTimelineProvider(widgetType: .today)) { entry in
            TodaysBirthdaysWidgetView(entry: entry)
        }
        .configurationDisplayName("Today's Birthdays")
        .description("See who has a birthday today.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

struct UpcomingBirthdaysWidget: Widget {
    static let kind: String = "UpcomingBirthdaysWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: UpcomingBirthdaysWidget.kind, provider: BirthdayTimelineProvider(widgetType: .upcoming)) { entry in
            UpcomingBirthdaysWidgetView(entry: entry)
        }
        .configurationDisplayName("Upcoming Birthdays")
        .description("See birthdays coming up soon.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}


// MARK: 5. Widget Bundle
@main
struct JustBirthdaysWidgetBundle: WidgetBundle {
   @WidgetBundleBuilder
   var body: some Widget {
       TodaysBirthdaysWidget()
       UpcomingBirthdaysWidget()
   }
}

// MARK: - Preview Providers
struct TodaysBirthdaysWidget_Previews: PreviewProvider {
    static var previews: some View {
        let sampleBirthdays = [
            BirthdayEntry(name: "Alice Wonderland Smith", birthday: Date(), phoneNumber: nil, emailAddress: nil, socialMediaURL: "https://example.com/alice", notes: nil, yearIsKnown: true),
            BirthdayEntry(name: "Robert 'Bob' The Builder Jr.", birthday: Date(), phoneNumber: nil, emailAddress: nil, socialMediaURL: nil, notes: nil, yearIsKnown: true),
            BirthdayEntry(name: "Another Person With A Birthday", birthday: Date(), phoneNumber: nil, emailAddress: nil, socialMediaURL: "https://example.com/another", notes: nil, yearIsKnown: false)
        ]
        let entry = SimpleBirthdayEntry(date: Date(), birthdays: sampleBirthdays, widgetType: .today, isError: false, errorMessage: nil)
        
        Group {
            TodaysBirthdaysWidgetView(entry: entry)
                .previewContext(WidgetPreviewContext(family: .systemSmall))
                .previewDisplayName("Today - Small")
            TodaysBirthdaysWidgetView(entry: entry)
                .previewContext(WidgetPreviewContext(family: .systemMedium))
                .previewDisplayName("Today - Medium")
            TodaysBirthdaysWidgetView(entry: entry)
                .previewContext(WidgetPreviewContext(family: .systemLarge))
                .previewDisplayName("Today - Large")
        }
    }
}

struct UpcomingBirthdaysWidget_Previews: PreviewProvider {
    static var previews: some View {
        let sampleBirthdays = [
            BirthdayEntry(name: "Charles Xavier Brownstone III", birthday: Calendar.current.date(byAdding: .day, value: 3, to: Date())!, phoneNumber: nil, emailAddress: nil, socialMediaURL: nil, notes: nil, yearIsKnown: true),
            BirthdayEntry(name: "Diana Prince of Themyscira", birthday: Calendar.current.date(byAdding: .day, value: 7, to: Date())!, phoneNumber: nil, emailAddress: nil, socialMediaURL: "https://example.com/diana", notes: nil, yearIsKnown: false),
            BirthdayEntry(name: "Yet Another Upcoming Birthday Person", birthday: Calendar.current.date(byAdding: .day, value: 10, to: Date())!, phoneNumber: nil, emailAddress: nil, socialMediaURL: nil, notes: nil, yearIsKnown: true)
        ]
        let entry = SimpleBirthdayEntry(date: Date(), birthdays: sampleBirthdays, widgetType: .upcoming, isError: false, errorMessage: nil)
        
        Group {
            UpcomingBirthdaysWidgetView(entry: entry)
                .previewContext(WidgetPreviewContext(family: .systemSmall))
                .previewDisplayName("Upcoming - Small")
            UpcomingBirthdaysWidgetView(entry: entry)
                .previewContext(WidgetPreviewContext(family: .systemMedium))
                .previewDisplayName("Upcoming - Medium")
            UpcomingBirthdaysWidgetView(entry: entry)
                .previewContext(WidgetPreviewContext(family: .systemLarge))
                .previewDisplayName("Upcoming - Large")
        }
    }
}
