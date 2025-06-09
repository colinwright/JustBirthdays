import Foundation

enum Tab: Identifiable, CaseIterable {
    case today, upcoming, all
    
    var id: Self { self }
    
    var title: String {
        switch self {
        case .today:
            return "Today"
        case .upcoming:
            return "Upcoming"
        case .all:
            return "All Birthdays"
        }
    }
}
