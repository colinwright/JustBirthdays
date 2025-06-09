import SwiftUI
import SwiftData

struct TodayView: View {
    @Query var people: [Person]
    
    @State private var personToEdit: Person?
    
    private var todaysBirthdays: [Person] {
        people
            .filter { $0.isBirthdayToday }
            .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
    }
    
    var body: some View {
        if todaysBirthdays.isEmpty {
            ContentUnavailableView(
                "No Birthdays Today",
                systemImage: "gift",
                description: Text("Check back tomorrow!")
            )
        } else {
            List(todaysBirthdays) { person in
                TodayPersonRowView(person: person)
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
