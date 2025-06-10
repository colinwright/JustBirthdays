import SwiftUI

// This extension provides a clean way to reference our shared user defaults.
extension UserDefaults {
    static let appGroup = UserDefaults(suiteName: "group.com.colinismyname.JustBirthdaysApp")!
}

class AppSettings: ObservableObject {
    @AppStorage("upcomingDaysLimit", store: .appGroup) var upcomingDaysLimit = 30
    @AppStorage("showYearInList", store: .appGroup) var showYearInList = false
}
