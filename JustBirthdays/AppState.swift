import Foundation

enum SortOrder {
    case chronological, alphabetical
}

final class AppState: ObservableObject {
    @Published var sortOrder: SortOrder = .chronological
}
