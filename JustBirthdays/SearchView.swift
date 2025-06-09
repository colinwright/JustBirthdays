import SwiftUI

struct SearchView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    @State private var isSearchActive = false

    var body: some View {
        NavigationStack {
            SearchResultsView(searchText: searchText)
                .navigationTitle("Search Birthdays")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done") {
                            dismiss()
                        }
                    }
                }
                .searchable(text: $searchText, isPresented: $isSearchActive, prompt: "Search by name")
                .onAppear {
                    isSearchActive = true
                }
        }
    }
}
