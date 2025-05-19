// MARK: - BirthdayWidget.swift (MINIMAL ENTRY TEST)
import WidgetKit
import SwiftUI

// 1. Define an extremely simple TimelineEntry directly in this file
struct MinimalTestEntry: TimelineEntry {
    let date: Date
    let message: String
}

// 2. Timeline Provider using the MinimalTestEntry
struct MinimalTestTimelineProvider: TimelineProvider {
    typealias Entry = MinimalTestEntry

    func placeholder(in context: Context) -> MinimalTestEntry {
        print("MinimalWidget: placeholder called")
        return MinimalTestEntry(date: Date(), message: "Placeholder")
    }

    func getSnapshot(in context: Context, completion: @escaping (MinimalTestEntry) -> ()) {
        print("MinimalWidget: getSnapshot called")
        let entry = MinimalTestEntry(date: Date(), message: "Snapshot Data")
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<MinimalTestEntry>) -> ()) {
        print("MinimalWidget: getTimeline called")
        var entries: [MinimalTestEntry] = []
        let currentDate = Date()
        let entry = MinimalTestEntry(date: currentDate, message: "Timeline Data @ \(currentDate.formatted(date: .omitted, time: .shortened))")
        entries.append(entry)

        let nextUpdateDate = Calendar.current.date(byAdding: .minute, value: 15, to: currentDate)! // Update every 15 mins for test
        let timeline = Timeline(entries: entries, policy: .after(nextUpdateDate))
        print("MinimalWidget: Timeline created with 1 static entry.")
        completion(timeline)
    }
}

// 3. Widget View using the MinimalTestEntry
struct MinimalTestWidgetView : View {
    var entry: MinimalTestTimelineProvider.Entry

    var body: some View {
        VStack {
            Text("Minimal Test Widget")
                .font(.headline)
            Text(entry.message)
                .font(.subheadline)
            Text("Date: \(entry.date, style: .time)")
        }
        .padding()
        // You'll need to define this URL scheme in your main app's Info.plist if you want it to work
        .widgetURL(URL(string: "justbirthdays://widgettap"))
    }
}

// 4. Widget Definition
struct MinimalBirthdayTestWidget: Widget {
    // Using a clearly unique kind string for this test
    private let kind: String = "com.colinismyname.JustBirthdays.MinimalTestWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: MinimalTestTimelineProvider()) { entry in
            MinimalTestWidgetView(entry: entry)
        }
        .configurationDisplayName("Minimal Birthday Test")
        .description("A very simple test widget.")
        .supportedFamilies([.systemSmall, .systemMedium]) // Keep it simple
    }
}

// 5. Widget Bundle (This is the @main entry point for your widget extension)
// Ensure NSExtensionPrincipalClass in Info.plist is $(PRODUCT_MODULE_NAME).JustBirthdaysWidgetBundle
@main
struct JustBirthdaysWidgetBundle: WidgetBundle {
   @WidgetBundleBuilder
   var body: some Widget {
       MinimalBirthdayTestWidget() // Only include this minimal test widget
   }
}

// 6. Preview Provider
struct MinimalBirthdayTestWidget_Previews: PreviewProvider {
    static var previews: some View {
        MinimalTestWidgetView(entry: MinimalTestEntry(date: Date(), message: "Preview Message"))
            .previewContext(WidgetPreviewContext(family: .systemMedium))
    }
}
