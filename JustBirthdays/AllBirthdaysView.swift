import SwiftUI
import SwiftData

struct AllBirthdaysView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.modelContext) private var modelContext
    @Query var people: [Person]
    
    @State private var personToEdit: Person?
    
    private var sortedPeople: [Person] {
        switch appState.sortOrder {
        case .chronological:
            return people.sorted { $0.birthMonthDay < $1.birthMonthDay }
        case .alphabetical:
            return people.sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
        }
    }

    var body: some View {
        if sortedPeople.isEmpty {
            ContentUnavailableView(
                "No Birthdays Yet",
                systemImage: "person.3",
                description: Text("Tap the + button to add your first birthday.")
            )
        } else {
            List {
                ForEach(sortedPeople) { person in
                    PersonRowView(person: person)
                        .onTapGesture {
                            personToEdit = person
                        }
                        // This ensures consistent separator lines.
                        .listRowSeparator(.visible)
                }
                .onDelete(perform: deletePeople)
            }
            .listStyle(.plain)
            .sheet(item: $personToEdit) { person in
                AddEditPersonView(person: person, isNew: false)
            }
        }
    }
    
    private func deletePeople(at offsets: IndexSet) {
        let peopleToDelete = offsets.map { sortedPeople[$0] }
        for person in peopleToDelete {
            modelContext.delete(person)
        }
    }
}

#Preview {
    NavigationStack {
        AllBirthdaysView()
            .environmentObject(AppState())
            .modelContainer(for: Person.self, inMemory: true)
    }
}
