import SwiftUI

struct SearchView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    
    @FocusState private var isSearchFieldFocused: Bool

    var body: some View {
        NavigationStack {
            SearchResultsView(searchText: searchText)
                .navigationTitle("Search Birthdays")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Done") {
                            dismiss()
                        }
                    }
                }
                .searchable(text: $searchText, prompt: "Search by name")
                .focused($isSearchFieldFocused)
                .onAppear {
                    // This delay gives the UI time to settle before we request focus.
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        isSearchFieldFocused = true
                    }
                }
        }
    }
}

#Preview {
    SearchView()
        .modelContainer(for: Person.self, inMemory: true)
        .environmentObject(AppState())
}
