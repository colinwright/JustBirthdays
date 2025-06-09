import SwiftUI
import SwiftData

struct UpcomingView: View {
    @Query var people: [Person]
    @State private var personToEdit: Person?
    
    // Read the setting from AppStorage.
    @AppStorage("upcomingDaysLimit") private var upcomingDaysLimit = 30
    
    private var upcomingBirthdays: [Person] {
        people.filter {
            !$0.isBirthdayToday && $0.daysUntilNextBirthday <= upcomingDaysLimit
        }
        .sorted { $0.daysUntilNextBirthday < $1.daysUntilNextBirthday }
    }
    
    var body: some View {
        if upcomingBirthdays.isEmpty {
            ContentUnavailableView(
                "No Upcoming Birthdays",
                systemImage: "calendar.badge.exclamationmark",
                description: Text("No birthdays in the next \(upcomingDaysLimit) days.")
            )
        } else {
            // ... (rest of the body is unchanged)
            List(upcomingBirthdays) { person in
                PersonRowView(person: person)
                    .onTapGesture {
                        personToEdit = person
                    }
            }
            .listStyle(.plain)
            .sheet(item: $personToEdit) { person in
                AddEditPersonView(person: person, isNew: false)
            }
        }
    }
}
