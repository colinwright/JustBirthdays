import SwiftUI
import SwiftData

struct ContentView: View {
    @EnvironmentObject private var appState: AppState
    
    @State private var showingAddSheet = false
    @State private var showingSearchSheet = false
    @State private var showingSettingsSheet = false
    
    @State private var selectedTab: Tab = .today

    var body: some View {
        NavigationStack {
            VStack {
                Picker("View", selection: $selectedTab) {
                    ForEach(Tab.allCases) { tab in
                        Text(tab.title).tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                
                TabView(selection: $selectedTab) {
                    TodayView()
                        .tag(Tab.today)

                    UpcomingView()
                        .tag(Tab.upcoming)

                    AllBirthdaysView()
                        .tag(Tab.all)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
            }
            .navigationTitle(selectedTab.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button(action: { showingAddSheet.toggle() }) {
                        Image(systemName: "plus")
                    }
                    
                    Button(action: { showingSearchSheet.toggle() }) {
                        Image(systemName: "magnifyingglass")
                    }

                    Menu {
                        Button(action: { showingSettingsSheet.toggle() }) {
                            Label("Settings", systemImage: "gearshape.fill")
                        }
                        
                        Button(action: toggleSortOrder) {
                            Label(
                                "Sort by \(appState.sortOrder == .chronological ? "Name" : "Date")",
                                systemImage: appState.sortOrder == .chronological ? "a.circle.fill" : "calendar"
                            )
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
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
