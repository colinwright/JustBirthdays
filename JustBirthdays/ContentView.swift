import SwiftUI
import SwiftData

struct ContentView: View {
    @EnvironmentObject private var appState: AppState
    
    @State private var showingAddSheet = false
    @State private var showingSearchSheet = false
    @State private var showingSettingsSheet = false // State for settings

    @State private var selectedTab: Tab = .today

    var body: some View {
        NavigationStack {
            TabView(selection: $selectedTab) {
                TodayView()
                    .tabItem { Label("Today", systemImage: "gift.fill") }
                    .tag(Tab.today)

                UpcomingView()
                    .tabItem { Label("Upcoming", systemImage: "calendar") }
                    .tag(Tab.upcoming)

                AllBirthdaysView()
                    .tabItem { Label("All", systemImage: "person.3.fill") }
                    .tag(Tab.all)
            }
            .navigationTitle("Just Birthdays")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    HStack(spacing: 12) {
                        Button(action: { showingAddSheet.toggle() }) {
                            Image(systemName: "plus")
                        }
                        
                        Button(action: { showingSearchSheet.toggle() }) {
                            Image(systemName: "magnifyingglass")
                        }

                        // New button for Settings
                        Button(action: { showingSettingsSheet.toggle() }) {
                            Image(systemName: "gearshape.fill")
                        }

                        Button(action: toggleSortOrder) {
                            Label("Sort", systemImage: appState.sortOrder == .chronological ? "calendar" : "a.circle.fill")
                        }
                    }
                }
            }
            .sheet(isPresented: $showingAddSheet) {
                AddEditPersonView(person: Person(name: "", birthday: .now), isNew: true)
            }
            .sheet(isPresented: $showingSearchSheet) {
                SearchView()
            }
            .sheet(isPresented: $showingSettingsSheet) {
                SettingsView()
            }
        }
    }

    private func toggleSortOrder() {
        withAnimation {
            appState.sortOrder = (appState.sortOrder == .chronological) ? .alphabetical : .chronological
        }
    }
}
