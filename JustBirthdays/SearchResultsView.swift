import SwiftUI
import SwiftData

struct SearchResultsView: View {
    let searchText: String
    @EnvironmentObject private var appState: AppState
    
    @Query var people: [Person]
    
    // Add state to track the person being edited.
    @State private var personToEdit: Person?
    
    init(searchText: String) {
        self.searchText = searchText
        let predicate = #Predicate<Person> { person in
            person.name.localizedStandardContains(searchText)
        }
        _people = Query(filter: predicate, sort: \Person.name)
    }
    
    private var sortedPeople: [Person] {
        switch appState.sortOrder {
        case .chronological:
            return people.sorted { $0.birthMonthDay < $1.birthMonthDay }
        case .alphabetical:
            return people
        }
    }
    
    var body: some View {
        if sortedPeople.isEmpty {
            ContentUnavailableView.search(text: searchText)
        } else {
            List(sortedPeople) { person in
                PersonRowView(person: person)
                    // Add the tap gesture to each row.
                    .onTapGesture {
                        personToEdit = person
                    }
            }
            .listStyle(.plain)
            // Add the sheet modifier to the view.
            .sheet(item: $personToEdit) { person in
                AddEditPersonView(person: person, isNew: false)
            }
        }
    }
}

#Preview {
    NavigationStack {
        SearchResultsView(searchText: "Sample")
    }
    .modelContainer(for: Person.self, inMemory: true)
    .environmentObject(AppState())
}
