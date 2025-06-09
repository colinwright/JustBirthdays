import SwiftUI
import SwiftData

struct UpcomingView: View {
    @EnvironmentObject private var appState: AppState
    @Query var people: [Person]
    @State private var personToEdit: Person?
    
    @AppStorage("upcomingDaysLimit") private var upcomingDaysLimit = 30
    
    private var upcomingBirthdays: [Person] {
        let filtered = people.filter {
            !$0.isBirthdayToday && $0.daysUntilNextBirthday > 0 && $0.daysUntilNextBirthday <= upcomingDaysLimit
        }
        
        switch appState.sortOrder {
        case .chronological:
            return filtered.sorted { $0.daysUntilNextBirthday < $1.daysUntilNextBirthday }
        case .alphabetical:
            return filtered.sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
        }
    }
    
    var body: some View {
        if upcomingBirthdays.isEmpty {
            ContentUnavailableView(
                "No Upcoming Birthdays",
                systemImage: "calendar.badge.exclamationmark",
                description: Text("No birthdays in the next \(upcomingDaysLimit) days.")
            )
        } else {
            List(upcomingBirthdays) { person in
                PersonRowView(person: person)
                    .onTapGesture {
                        personToEdit = person
                    }
                    .alignmentGuide(.listRowSeparatorLeading) { _ in
                        return 0
                    }
            }
            .listStyle(.plain)
            .sheet(item: $personToEdit) { person in
                AddEditPersonView(person: person, isNew: false)
            }
        }
    }
}
