import SwiftUI

class AppSettings: ObservableObject {
    @AppStorage("upcomingDaysLimit") var upcomingDaysLimit = 30
    @AppStorage("showYearInList") var showYearInList = false
}
