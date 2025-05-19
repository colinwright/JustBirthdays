// MARK: - BirthdayWidget.swift
// This file defines the structure and content of the "Birthdays At a Glance" widget.
// This code should be in the file associated with your 'MyBirthdaysWidget' target.

import WidgetKit
import SwiftUI

// MARK: 1. Timeline Provider
struct BirthdayTimelineProvider: TimelineProvider {
    typealias Entry = BirthdayWidgetEntry

    // Ensure this matches your actual App Group ID from BirthdayStore.swift and project settings.
    private let appGroupIdForWidget = "group.com.colinismyname.JustBirthdays"

    // Helper to check App Group configuration status.
    private func checkAppGroupConfiguration() -> (isError: Bool, errorMessage: String?) {
        if appGroupIdForWidget.isEmpty || appGroupIdForWidget == "group.com.yourdomain.JustBirthdays" { // Check against old placeholder
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

    func placeholder(in context: Context) -> BirthdayWidgetEntry {
        print("Birthdays At a Glance Widget: placeholder called")
        let sampleToday = BirthdayEntry(name: "Alex (Today)", birthday: Date(), phoneNumber: "555-0101", emailAddress: nil, socialMediaHandle: nil)
        return BirthdayWidgetEntry(date: Date(), todaysBirthdays: [sampleToday], upcomingBirthdays: [], isError: false, errorMessage: "Placeholder")
    }

    func getSnapshot(in context: Context, completion: @escaping (BirthdayWidgetEntry) -> ()) {
        print("Birthdays At a Glance Widget: getSnapshot called")
        let configStatus = checkAppGroupConfiguration()
        var todays: [BirthdayEntry] = []
        var upcoming: [BirthdayEntry] = []

        if !configStatus.isError {
            let store = BirthdayStore()
            todays = Array(store.todaysBirthdays.prefix(3))
            upcoming = Array(store.upcomingBirthdays.prefix(3))
        }
        
        let entry = BirthdayWidgetEntry(date: Date(),
                                        todaysBirthdays: todays,
                                        upcomingBirthdays: upcoming,
                                        isError: configStatus.isError,
                                        errorMessage: configStatus.errorMessage ?? "Snapshot Data")
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        print("Birthdays At a Glance Widget: getTimeline called")
        let configStatus = checkAppGroupConfiguration()
        var todays: [BirthdayEntry] = []
        var upcoming: [BirthdayEntry] = []

        if !configStatus.isError {
            let store = BirthdayStore()
            todays = Array(store.todaysBirthdays.prefix(3))
            upcoming = Array(store.upcomingBirthdays.prefix(3))
            print("Birthdays At a Glance Widget: Timeline - Store loaded \(store.entries.count) total entries. Today: \(todays.count), Upcoming: \(upcoming.count)")
        } else {
            print("Birthdays At a Glance Widget: Timeline - App Group configuration error.")
        }
        
        let currentDate = Date()
        let entry = BirthdayWidgetEntry(
            date: currentDate,
            todaysBirthdays: todays,
            upcomingBirthdays: upcoming,
            isError: configStatus.isError,
            errorMessage: configStatus.errorMessage ?? "Timeline Data"
        )

        let startOfTomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Calendar.current.startOfDay(for: currentDate))!
        let timeline = Timeline(entries: [entry], policy: .after(startOfTomorrow))
        print("Birthdays At a Glance Widget: Timeline created. Next update after: \(startOfTomorrow)")
        completion(timeline)
    }
}

// MARK: 2. Widget Entry (Uses BirthdayEntry from DataModel.swift)
struct BirthdayWidgetEntry: TimelineEntry {
    let date: Date
    let todaysBirthdays: [BirthdayEntry]
    let upcomingBirthdays: [BirthdayEntry]
    let isError: Bool
    let errorMessage: String?
}

// MARK: 3. Widget View (This is the UI for your "Birthdays At a Glance" widget)
struct BirthdayWidgetView : View {
    var entry: BirthdayTimelineProvider.Entry
    @Environment(\.widgetFamily) var family

    var body: some View {
        // The content of the widget
        VStack(alignment: .leading, spacing: 6) {
            Text("Birthdays At a Glance")
                .font(family == .systemSmall ? .caption.bold() : .headline)
                .foregroundColor(.pink)

            if entry.isError {
                VStack(alignment: .center) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange).font(.title)
                    Text(entry.errorMessage ?? "Configuration error.")
                        .font(.caption).foregroundColor(.orange).multilineTextAlignment(.center).padding(.top, 2)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if entry.todaysBirthdays.isEmpty && entry.upcomingBirthdays.isEmpty {
                Text("No birthdays today or upcoming soon.")
                    .font(.caption).foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            } else {
                // Today's Birthdays
                if !entry.todaysBirthdays.isEmpty {
                    VStack(alignment: .leading, spacing: 3) {
                        if family != .systemSmall {
                             Text("Today:")
                                .font(family == .systemSmall ? .footnote.bold() : .caption.bold())
                        }
                        let maxToday = (family == .systemSmall ? 2 : (family == .systemMedium ? 2 : 3))
                        ForEach(entry.todaysBirthdays.prefix(maxToday)) { bd in
                            Text("• \(bd.name)")
                                .font(family == .systemSmall ? .caption2 : .footnote)
                                .lineLimit(1)
                        }
                    }
                } else if family != .systemSmall && !entry.upcomingBirthdays.isEmpty {
                    Text("No birthdays today.")
                        .font(family == .systemSmall ? .caption2 : .footnote)
                        .foregroundColor(.secondary)
                }

                // Upcoming Birthdays
                if !entry.upcomingBirthdays.isEmpty && family != .systemSmall {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Upcoming:")
                            .font(family == .systemSmall ? .footnote.bold() : .caption.bold())
                            .padding(.top, entry.todaysBirthdays.isEmpty ? 0 : (family == .systemMedium ? 4 : 6))
                        
                        let maxUpcoming = (family == .systemMedium ? (entry.todaysBirthdays.isEmpty ? 3 : 2) : (family == .systemLarge ? (entry.todaysBirthdays.isEmpty ? 5 : 4) : 0))
                        ForEach(entry.upcomingBirthdays.prefix(maxUpcoming)) { bd in
                            HStack {
                                Text("• \(bd.name)")
                                    .font(family == .systemSmall ? .caption2 : .footnote)
                                    .lineLimit(1)
                                Spacer()
                                Text("\(bd.daysUntilNextBirthday)d")
                                    .font(family == .systemSmall ? .caption2 : .footnote)
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                }
            }
            // Special layout for small widget if only upcoming is available
            if family == .systemSmall && entry.todaysBirthdays.isEmpty && !entry.upcomingBirthdays.isEmpty {
                 VStack(alignment: .leading, spacing: 3) {
                    Text("Next Up:")
                        .font(.footnote.bold())
                    if let upcomingEntry = entry.upcomingBirthdays.first {
                        HStack {
                            Text("• \(upcomingEntry.name)")
                                .font(.caption2).lineLimit(1)
                            Spacer()
                            Text("\(upcomingEntry.daysUntilNextBirthday)d")
                                .font(.caption2).foregroundColor(.gray)
                        }
                    }
                }
            }
            Spacer()
        }
        .padding()
        .widgetURL(URL(string: "justbirthdays://open"))
        // Apply the containerBackground modifier here
        .containerBackground(for: .widget) {
            // You can place a Color, a Material, or any other View here
            // For a simple default, Color.clear will allow wallpaper tinting
            // Or use a specific color if you prefer.
            // For a standard system background look:
            // Color(NSColor.windowBackgroundColor) // Or system background material
            Color.clear // This allows the widget to pick up wallpaper tinting
        }
    }
}

// MARK: 4. Widget Definition
struct BirthdayWidget: Widget {
    private let kind: String = "BirthdayWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: BirthdayTimelineProvider()) { entry in
            BirthdayWidgetView(entry: entry)
        }
        .configurationDisplayName("Birthdays At a Glance")
        .description("See today's and upcoming birthdays.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

// MARK: 5. Widget Bundle
@main
struct JustBirthdaysWidgetBundle: WidgetBundle {
   @WidgetBundleBuilder
   var body: some Widget {
       BirthdayWidget()
   }
}

// MARK: - Preview Provider for Widget
struct BirthdayWidget_Previews: PreviewProvider {
    static var previews: some View {
        let sampleEntryWithData = BirthdayWidgetEntry(
            date: Date(),
            todaysBirthdays: [
                BirthdayEntry(name: "Alice Wonderland", birthday: Date(), phoneNumber: "555-1111", emailAddress: "alice@example.com", socialMediaHandle: nil)
            ],
            upcomingBirthdays: [
                BirthdayEntry(name: "Bob The Builder", birthday: Calendar.current.date(byAdding: .day, value: 3, to: Date())!, phoneNumber: "555-2222", emailAddress: nil, socialMediaHandle: nil)
            ],
            isError: false,
            errorMessage: nil
        )
        
        BirthdayWidgetView(entry: sampleEntryWithData)
            .previewContext(WidgetPreviewContext(family: .systemMedium))
    }
}
