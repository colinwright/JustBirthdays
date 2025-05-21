// MARK: - ContentView.swift
// Main view with refined text-based tabs and sort toggle, integrating settings.

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var store: BirthdayStore
    @State private var entryToEdit: BirthdayEntry? = nil
    @State private var showingAddNewSheet = false
    
    @AppStorage(AppSettings.showYearInListKey) var showYearInList: Bool = AppSettings.defaultShowYearInList
    @AppStorage(AppSettings.isPhoneNumberClickableKey) var isPhoneNumberClickable: Bool = AppSettings.defaultIsPhoneNumberClickable
    @AppStorage(AppSettings.isEmailClickableKey) var isEmailClickable: Bool = AppSettings.defaultIsEmailClickable
    // Updated to use the new key for social media URL clickability
    @AppStorage(AppSettings.isSocialMediaURLClickableKey) var isSocialMediaURLClickable: Bool = AppSettings.defaultIsSocialMediaURLClickable
    
    @AppStorage(AppSettings.upcomingDaysKey) var upcomingBirthdayLeadTimeForViewID: Int = AppSettings.defaultUpcomingDays

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
                            .foregroundColor(selectedDisplayMode == mode ? Color(NSColor.labelColor).opacity(0.85) : Color.secondary)
                            .padding(.vertical, 4)
                            .background(Color.clear)
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
                            TodaysBirthdayRow(
                                entry: entry,
                                onNameTap: { self.entryToEdit = entry },
                                isPhoneNumberClickable: isPhoneNumberClickable,
                                isEmailClickable: isEmailClickable,
                                // Updated to pass the correct setting for social media URL
                                isSocialMediaClickable: isSocialMediaURLClickable
                            )
                        } else {
                            BirthdayRow(entry: entry, store: store, showYear: showYearInList, onNameTap: { self.entryToEdit = entry })
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
        .id(upcomingBirthdayLeadTimeForViewID)
    }
}

// MARK: - Row Views (Updated for settings)

struct TodaysBirthdayRow: View {
    let entry: BirthdayEntry
    var onNameTap: () -> Void
    let isPhoneNumberClickable: Bool
    let isEmailClickable: Bool
    let isSocialMediaClickable: Bool // Name remains the same, its value comes from isSocialMediaURLClickable

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(entry.name)
                .font(.title3)
                .fontWeight(.medium)
                .foregroundColor(.primary)
                .onTapGesture { onNameTap() }
            
            if let phoneNumber = entry.phoneNumber, !phoneNumber.isEmpty {
                ContactInfoRow(iconName: "phone", detail: phoneNumber, type: .phone, isClickable: isPhoneNumberClickable)
            }
            if let emailAddress = entry.emailAddress, !emailAddress.isEmpty {
                ContactInfoRow(iconName: "envelope", detail: emailAddress, type: .email, isClickable: isEmailClickable)
            }
            // Updated to use socialMediaURL from entry
            if let socialMediaURL = entry.socialMediaURL, !socialMediaURL.isEmpty {
                ContactInfoRow(iconName: "link", detail: socialMediaURL, type: .social, isClickable: isSocialMediaClickable)
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
    let isClickable: Bool

    enum ContactTypeForOpening { case phone, email, social }

    var body: some View {
        if isClickable {
            Button(action: { openContactDetail(detail: detail, type: type) }) {
                HStack(spacing: 5) {
                    Image(systemName: iconName)
                        .font(.caption)
                        .frame(width: 16, alignment: .center)
                    Text(detail)
                        .font(.caption)
                        .underline()
                }
            }
            .buttonStyle(PlainButtonStyle())
            .foregroundColor(.accentColor)
        } else {
            HStack(spacing: 5) {
                Image(systemName: iconName)
                    .font(.caption)
                    .frame(width: 16, alignment: .center)
                Text(detail)
                    .font(.caption)
            }
            .foregroundColor(.secondary)
        }
    }

    private func openContactDetail(detail: String, type: ContactTypeForOpening) {
        var urlString: String? = nil
        let trimmedDetail = detail.trimmingCharacters(in: .whitespacesAndNewlines)
        switch type {
        case .phone: urlString = "tel:\(trimmedDetail.filter("0123456789".contains))"
        case .email: urlString = "mailto:\(trimmedDetail)"
        case .social: // Assumes detail is a valid URL for social media
            if trimmedDetail.lowercased().starts(with: "http://") || trimmedDetail.lowercased().starts(with: "https://") {
                urlString = trimmedDetail
            } else if trimmedDetail.contains(".") && !trimmedDetail.contains(" ") { // Try to make it a URL if it looks like one
                urlString = "https://\(trimmedDetail)"
            } else {
                print("Social media link is not a full URL: \(trimmedDetail). Cannot open directly.")
                return
            }
        }
        if let safeUrlString = urlString, let url = URL(string: safeUrlString) {
            #if os(macOS)
            NSWorkspace.shared.open(url)
            #elseif os(iOS)
            // UIApplication.shared.open(url)
            #endif
        } else { print("Could not create a valid URL for contact detail: \(trimmedDetail)") }
    }
}

struct BirthdayRow: View {
    let entry: BirthdayEntry
    @ObservedObject var store: BirthdayStore
    let showYear: Bool
    var onNameTap: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(entry.name)
                    .font(.headline)
                    .fontWeight(.regular)
                    .foregroundColor(.primary)
                    .onTapGesture { onNameTap() }
                Text(showYear ? entry.formattedBirthdayWithYear : entry.formattedBirthday)
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
        let todayBirthdayDate = calendar.date(from: DateComponents(year: 1990, month: todayComponents.month, day: todayComponents.day))!
        // CORRECTED: Use socialMediaURL as the argument label
        previewStore.addEntry(name: "Alex (Today)", birthday: todayBirthdayDate, phoneNumber: "555-0100", emailAddress: "alex@example.com", socialMediaURL: "https://twitter.com/alex_social")
        
        let upcomingDay1 = calendar.date(byAdding: .day, value: 3, to: Date())!
        let upcomingBirthdayDate1 = calendar.date(from: DateComponents(year: 1985, month: calendar.component(.month, from: upcomingDay1), day: calendar.component(.day, from: upcomingDay1)))!
        // CORRECTED: Use socialMediaURL as the argument label
        previewStore.addEntry(name: "Bob (Upcoming)", birthday: upcomingBirthdayDate1, phoneNumber: nil, emailAddress: "bob@example.com", socialMediaURL: nil)
        
        let farOutDay = calendar.date(byAdding: .day, value: 45, to: Date())!
        let farOutBirthdayDate = calendar.date(from: DateComponents(year: 2000, month: calendar.component(.month, from: farOutDay), day: calendar.component(.day, from: farOutDay)))!
        // CORRECTED: Use socialMediaURL as the argument label
        previewStore.addEntry(name: "Charlie (All)", birthday: farOutBirthdayDate, phoneNumber: "555-0102", emailAddress: nil, socialMediaURL: "https://charlie.blog.com")

        return ContentView().environmentObject(previewStore).frame(width: 380, height: 550)
    }
}
