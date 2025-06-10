import Foundation
import WidgetKit

struct WidgetManager {
    static func reloadTimelines() {
        // The 'kind' must match the string you defined in your Widget struct.
        WidgetCenter.shared.reloadTimelines(ofKind: "JustBirthdaysWidget")
    }
}
