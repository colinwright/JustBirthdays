// MARK: - ContentView.swift
// Main view with refined text-based tabs and sort toggle.

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var store: BirthdayStore
    @State private var entryToEdit: BirthdayEntry? = nil
    @State private var showingAddNewSheet = false
    
    enum DisplayMode: String, CaseIterable, Identifiable {
        case today = "Today"
        case upcoming = "Upcoming"
        case all = "All"
        var id: String { self.rawValue }
    }
    @State private var selectedDisplayMode: DisplayMode = .today

    @State private var searchText = ""
    enum SortOrder: String, CaseIterable, Identifiable {
        case chronological = "Date"
        case alphabetical = "Name"
        var id: String { self.rawValue }
        
        var iconName: String {
            switch self {
            case .chronological: return "calendar"
            case .alphabetical: return "a.circle.fill"
            }
        }
    }
    @State private var currentSortOrder: SortOrder = .chronological

    private var birthdaysToDisplay: [BirthdayEntry] {
        var listToProcess: [BirthdayEntry]
        switch selectedDisplayMode {
        case .today: listToProcess = store.todaysBirthdays
        case .upcoming: listToProcess = store.upcomingBirthdays
        case .all: listToProcess = store.allSortedBirthdays
        }

        if !searchText.isEmpty {
            listToProcess = listToProcess.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }

        if currentSortOrder == .alphabetical {
            listToProcess.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        } else {
            if selectedDisplayMode == .today {
                 listToProcess.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
            }
        }
        return listToProcess
    }

    @ViewBuilder
    private var listHeaderControls: some View {
        HStack(alignment: .center) {
            // Text-based Tab Buttons
            HStack(spacing: 18) {
                ForEach(DisplayMode.allCases) { mode in
                    Button {
                        if selectedDisplayMode != mode {
                           selectedDisplayMode = mode
                        }
                    } label: {
                        Text(mode.rawValue)
                            .font(.system(size: 15))
                            .fontWeight(selectedDisplayMode == mode ? .semibold : .regular)
                            // Refined color for better differentiation:
                            // Selected tab is darker (but not full black like names), unselected is standard secondary.
                            .foregroundColor(selectedDisplayMode == mode ? Color(NSColor.labelColor).opacity(0.85) : Color.secondary)
                            .padding(.vertical, 4)
                            .background(Color.clear) // Ensure no unintended background on the text itself
                    }
                    .buttonStyle(PlainButtonStyle())
                    .contentShape(Rectangle())
                    .disabled(selectedDisplayMode == mode)
                }
            }

            Spacer()

            Button {
                currentSortOrder = (currentSortOrder == .chronological) ? .alphabetical : .chronological
            } label: {
                Image(systemName: currentSortOrder.iconName)
                    .font(.system(size: 17))
                    .foregroundColor(.secondary)
                    .id(currentSortOrder.iconName)
            }
            .buttonStyle(PlainButtonStyle())
            .frame(width: 28, height: 28, alignment: .center)
            .help(currentSortOrder == .chronological ? "Sort Alphabetically (A-Z)" : "Sort by Date (Upcoming Soonest)")
        }
        .padding(.horizontal)
        .padding(.top, 10)
        .padding(.bottom, 12)
    }
    
    @ViewBuilder
    private var listContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            if birthdaysToDisplay.isEmpty {
                Text(searchText.isEmpty ? "No birthdays in \"\(selectedDisplayMode.rawValue)\"." : "No results for \"\(searchText)\".")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 30)
            } else {
                ForEach(birthdaysToDisplay) { entry in
                    Group {
                        if selectedDisplayMode == .today {
                            TodaysBirthdayRow(entry: entry, onNameTap: { self.entryToEdit = entry })
                        } else {
                            BirthdayRow(entry: entry, store: store, onNameTap: { self.entryToEdit = entry })
                        }
                    }
                    .padding(.vertical, 8)
                    .contextMenu {
                        Button { self.entryToEdit = entry } label: { Label("Edit", systemImage: "pencil") }
                        Button(role: .destructive) { store.deleteEntry(entry) } label: { Label("Delete", systemImage: "trash") }
                    }
                    
                    if entry.id != birthdaysToDisplay.last?.id {
                        Divider().padding(.leading, 5)
                    }
                }
            }
            Spacer(minLength: 0)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            listHeaderControls

            ScrollView(.vertical, showsIndicators: true) {
                listContent
            }
             .searchable(text: $searchText, placement: .toolbar, prompt: "Search by Name")
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    self.entryToEdit = nil
                    self.showingAddNewSheet = true
                } label: {
                    Image(systemName: "plus")
                        .foregroundColor(.secondary)
                }
                .help("Add new birthday")
            }
        }
        .sheet(isPresented: $showingAddNewSheet) {
            AddBirthdayView(store: store, entryToEdit: nil).id(UUID())
        }
        .sheet(item: $entryToEdit) { currentEntryToEdit in
            AddBirthdayView(store: store, entryToEdit: currentEntryToEdit).id(currentEntryToEdit.id)
        }
        .frame(minWidth: 320, idealWidth: 380, maxWidth: 500, minHeight: 350, idealHeight: 550)
        .background(Color(NSColor.windowBackgroundColor).ignoresSafeArea())
    }
}

// MARK: - Row Views (Updated for subtle styling)

struct TodaysBirthdayRow: View {
    let entry: BirthdayEntry
    var onNameTap: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(entry.name)
                .font(.title3)
                .fontWeight(.medium)
                .foregroundColor(.primary)
                .onTapGesture { onNameTap() }
            
            if let phoneNumber = entry.phoneNumber, !phoneNumber.isEmpty {
                ContactInfoRow(iconName: "phone", detail: phoneNumber, type: .phone)
            }
            if let emailAddress = entry.emailAddress, !emailAddress.isEmpty {
                ContactInfoRow(iconName: "envelope", detail: emailAddress, type: .email)
            }
            if let socialMediaHandle = entry.socialMediaHandle, !socialMediaHandle.isEmpty {
                ContactInfoRow(iconName: "link", detail: socialMediaHandle, type: .social)
            }
            if !entry.hasAnyContactInfo {
                Text("No contact info")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct ContactInfoRow: View {
    let iconName: String
    let detail: String
    let type: ContactTypeForOpening

    enum ContactTypeForOpening { case phone, email, social }

    var body: some View {
        Button(action: { openContactDetail(detail: detail, type: type) }) {
            HStack(spacing: 5) {
                Image(systemName: iconName)
                    .font(.caption)
                    .frame(width: 16, alignment: .center)
                Text(detail)
                    .font(.caption)
            }
        }
        .buttonStyle(PlainButtonStyle())
        .foregroundColor(.secondary)
    }

    private func openContactDetail(detail: String, type: ContactTypeForOpening) {
        var urlString: String? = nil
        let trimmedDetail = detail.trimmingCharacters(in: .whitespacesAndNewlines)
        switch type {
        case .phone: urlString = "tel:\(trimmedDetail.filter("0123456789".contains))"
        case .email: urlString = "mailto:\(trimmedDetail)"
        case .social:
            if trimmedDetail.lowercased().starts(with: "http://") || trimmedDetail.lowercased().starts(with: "https://") { urlString = trimmedDetail }
            else if trimmedDetail.contains(".") && !trimmedDetail.contains(" ") { urlString = "https://\(trimmedDetail)" }
            else if trimmedDetail.starts(with: "@") { urlString = "https://twitter.com/\(trimmedDetail.dropFirst())" }
            else { print("Cannot directly open social handle: \(trimmedDetail)."); return }
        }
        if let safeUrlString = urlString, let url = URL(string: safeUrlString) { #if os(macOS)
            NSWorkspace.shared.open(url)
            #endif
        } else { print("Could not create a valid URL for contact detail: \(trimmedDetail)") }
    }
}

struct BirthdayRow: View {
    let entry: BirthdayEntry
    @ObservedObject var store: BirthdayStore
    var onNameTap: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(entry.name)
                    .font(.headline)
                    .fontWeight(.regular)
                    .foregroundColor(.primary)
                    .onTapGesture { onNameTap() }
                Text(entry.formattedBirthday)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            Spacer()
            Text("\(entry.daysUntilNextBirthday) day\(entry.daysUntilNextBirthday == 1 ? "" : "s")")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - ContentView_Previews
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        let previewStore = BirthdayStore()
        let calendar = Calendar.current
        let todayComponents = calendar.dateComponents([.year, .month, .day], from: Date())
        let todayBirthday = calendar.date(from: todayComponents)!
        
        previewStore.addEntry(name: "Alex (Today)", birthday: todayBirthday, phoneNumber: "555-0100", emailAddress: "alex@example.com", socialMediaHandle: "@alex")
        let upcomingDay1 = calendar.date(byAdding: .day, value: 3, to: Date())!
        previewStore.addEntry(name: "Bob (Upcoming)", birthday: upcomingDay1, phoneNumber: nil, emailAddress: "bob@example.com", socialMediaHandle: nil)
        
        return ContentView().environmentObject(previewStore).frame(width: 380, height: 550)
    }
}
