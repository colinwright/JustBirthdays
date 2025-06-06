import SwiftUI
import CoreData

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    @FetchRequest(sortDescriptors: [], animation: .default)
    private var people: FetchedResults<Person>
    
    @State private var personToEdit: Person? = nil
    @State private var showingAddNewSheet = false
    
    @AppStorage(AppSettings.showYearInListKey) var showYearInList: Bool = AppSettings.defaultShowYearInList
    @AppStorage(AppSettings.isPhoneNumberClickableKey) var isPhoneNumberClickable: Bool = AppSettings.defaultIsPhoneNumberClickable
    @AppStorage(AppSettings.isEmailClickableKey) var isEmailClickable: Bool = AppSettings.defaultIsEmailClickable
    @AppStorage(AppSettings.isSocialMediaURLClickableKey) var isSocialMediaURLClickable: Bool = AppSettings.defaultIsSocialMediaURLClickable
    @AppStorage(AppSettings.upcomingDaysKey) var upcomingBirthdayLeadTime: Int = AppSettings.defaultUpcomingDays

    enum DisplayMode: String, CaseIterable, Identifiable {
        case today = "Today"
        case upcoming = "Upcoming"
        case all = "All"
        var id: String { self.rawValue }
    }
    @State private var selectedDisplayMode: DisplayMode

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

    init(initialDisplayMode: DisplayMode) {
        _selectedDisplayMode = State(initialValue: initialDisplayMode)
    }

    private var peopleToDisplay: [Person] {
        var listToProcess: [Person]

        if searchText.isEmpty {
            // Browsing mode: Filter by the selected tab.
            let calendar = Calendar.current
            let todayStart = calendar.startOfDay(for: Date())
            
            switch selectedDisplayMode {
            case .today:
                listToProcess = Array(people.filter { $0.isToday })
            case .upcoming:
                guard let tomorrowStart = calendar.date(byAdding: .day, value: 1, to: todayStart),
                      let endDate = calendar.date(byAdding: .day, value: upcomingBirthdayLeadTime, to: tomorrowStart) else {
                    return []
                }
                listToProcess = people.filter { person in
                    !person.isToday && person.nextBirthdayDate >= tomorrowStart && person.nextBirthdayDate < endDate
                }
            case .all:
                listToProcess = Array(people)
            }
        } else {
            // Search mode: Filter all people by the search text.
            listToProcess = people.filter { $0.wrappedName.localizedCaseInsensitiveContains(searchText) }
        }
        
        // Sort the resulting list (either tab-filtered or search-filtered).
        if currentSortOrder == .alphabetical {
            listToProcess.sort { $0.wrappedName.localizedCaseInsensitiveCompare($1.wrappedName) == .orderedAscending }
        } else {
            listToProcess.sort {
                if $0.nextBirthdayDate != $1.nextBirthdayDate {
                    return $0.nextBirthdayDate < $1.nextBirthdayDate
                }
                return $0.wrappedName.localizedCaseInsensitiveCompare($1.wrappedName) == .orderedAscending
            }
        }
        
        return listToProcess
    }
    
    private func deletePerson(_ person: Person) {
        viewContext.delete(person)
        do {
            try viewContext.save()
            WidgetDataController.shared.updateWidgetData(using: viewContext)
        } catch {
            print("Failed to delete person: \(error.localizedDescription)")
        }
    }
    
    @ViewBuilder
    private var listHeaderControls: some View {
        HStack(alignment: .center) {
            HStack(spacing: 18) {
                ForEach(DisplayMode.allCases) { mode in
                    Button {
                        selectedDisplayMode = mode
                    } label: {
                        Text(mode.rawValue)
                            .font(.system(size: 15))
                            .fontWeight(selectedDisplayMode == mode ? .semibold : .regular)
                            .foregroundColor(selectedDisplayMode == mode ? Color(NSColor.labelColor).opacity(0.85) : Color.secondary)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .contentShape(Rectangle())
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
            .help(currentSortOrder == .chronological ? "Sort by Date" : "Sort Alphabetically (A-Z)")
        }
        .padding(.horizontal)
        .padding(.top, 10)
        .padding(.bottom, 12)
    }
    
    @ViewBuilder
    private var listContent: some View {
        if peopleToDisplay.isEmpty {
            VStack {
                Spacer()
                Text(searchText.isEmpty ? "No birthdays in this category." : "No results for \"\(searchText)\".")
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding()
                Spacer()
            }
            .frame(maxWidth: .infinity)
        } else {
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(peopleToDisplay) { person in
                        Group {
                             if selectedDisplayMode == .today && searchText.isEmpty {
                                TodaysBirthdayRow(
                                    person: person,
                                    onNameTap: { self.personToEdit = person },
                                    isPhoneNumberClickable: isPhoneNumberClickable,
                                    isEmailClickable: isEmailClickable,
                                    isSocialMediaClickable: isSocialMediaURLClickable
                                )
                            } else {
                                BirthdayRow(person: person, showYear: showYearInList, onNameTap: { self.personToEdit = person })
                            }
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            self.personToEdit = person
                        }
                        .contextMenu {
                            Button { self.personToEdit = person } label: { Label("Edit", systemImage: "pencil") }
                            Button(role: .destructive) { deletePerson(person) } label: { Label("Delete", systemImage: "trash") }
                        }
                        
                        if person.id != peopleToDisplay.last?.id {
                            Divider().padding(.leading)
                        }
                    }
                }
                .padding(.vertical)
            }
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            listHeaderControls
            Divider()
            listContent
        }
        .searchable(text: $searchText, placement: .toolbar, prompt: "Search All Birthdays")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    self.personToEdit = nil
                    self.showingAddNewSheet = true
                } label: {
                    Image(systemName: "plus")
                }
                .help("Add new birthday")
            }
        }
        .sheet(isPresented: $showingAddNewSheet) {
            AddBirthdayView(personToEdit: nil)
        }
        .sheet(item: $personToEdit) { person in
            AddBirthdayView(personToEdit: person)
        }
        .frame(minWidth: 320, idealWidth: 380, maxWidth: 500, minHeight: 350, idealHeight: 550)
        .background(Color(NSColor.windowBackgroundColor).ignoresSafeArea())
        .id(upcomingBirthdayLeadTime)
    }
}


// MARK: - Row Views

struct TodaysBirthdayRow: View {
    let person: Person
    var onNameTap: () -> Void
    let isPhoneNumberClickable: Bool
    let isEmailClickable: Bool
    let isSocialMediaClickable: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(person.wrappedName)
                .font(.title3)
                .fontWeight(.medium)
                .foregroundColor(.primary)
            
            if let phoneNumber = person.phoneNumber, !phoneNumber.isEmpty {
                ContactInfoRow(iconName: "phone", detail: phoneNumber, type: .phone, isClickable: isPhoneNumberClickable)
            }
            if let emailAddress = person.emailAddress, !emailAddress.isEmpty {
                ContactInfoRow(iconName: "envelope", detail: emailAddress, type: .email, isClickable: isEmailClickable)
            }
            if let socialMediaURL = person.socialMediaURL, !socialMediaURL.isEmpty {
                ContactInfoRow(iconName: "link", detail: socialMediaURL, type: .social, isClickable: isSocialMediaClickable)
            }
            if !person.hasAnyContactInfo {
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
        case .social:
            if trimmedDetail.lowercased().starts(with: "http://") || trimmedDetail.lowercased().starts(with: "https://") {
                urlString = trimmedDetail
            } else if trimmedDetail.contains(".") && !trimmedDetail.contains(" ") {
                urlString = "https://\(trimmedDetail)"
            }
        }
        if let safeUrlString = urlString, let url = URL(string: safeUrlString) {
            NSWorkspace.shared.open(url)
        }
    }
}

struct BirthdayRow: View {
    let person: Person
    let showYear: Bool
    var onNameTap: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(person.wrappedName)
                    .font(.headline)
                    .fontWeight(.regular)
                    .foregroundColor(.primary)
                Text(showYear ? person.formattedBirthdayWithYear : person.formattedBirthday)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            Spacer()
            Text("\(person.daysUntilNextBirthday) day\(person.daysUntilNextBirthday == 1 ? "" : "s")")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
