import SwiftUI
import CoreData
import WidgetKit

struct SettingsView: View {
    @AppStorage(AppSettings.upcomingDaysKey) var upcomingBirthdayLeadTime: Int = AppSettings.defaultUpcomingDays
    @AppStorage(AppSettings.showYearInListKey) var showYearInList: Bool = AppSettings.defaultShowYearInList
    
    @AppStorage(AppSettings.isPhoneNumberClickableKey) var isPhoneNumberClickable: Bool = AppSettings.defaultIsPhoneNumberClickable
    @AppStorage(AppSettings.isEmailClickableKey) var isEmailClickable: Bool = AppSettings.defaultIsEmailClickable
    @AppStorage(AppSettings.isSocialMediaURLClickableKey) var isSocialMediaURLClickable: Bool = AppSettings.defaultIsSocialMediaURLClickable

    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \Person.name, ascending: true)])
    private var people: FetchedResults<Person>

    let dayOptions = [3, 7, 14, 30]

    private var csvDateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }

    private let sectionContentTopPadding: CGFloat = 5
    private let descriptionTextTopPadding: CGFloat = 0

    var body: some View {
        Form {
            Section {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Show upcoming birthdays for the next:")
                    Picker("", selection: $upcomingBirthdayLeadTime) {
                        ForEach(dayOptions, id: \.self) { days in
                            Text("\(days) days").tag(days)
                        }
                    }
                    .pickerStyle(.menu)
                    .labelsHidden()
                    .frame(maxWidth: 150)
                }
                .padding(.bottom, 8)

                Toggle("Show year in birthday lists", isOn: $showYearInList)
                Text("If enabled, the year of birth will be displayed for entries where it is known.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, descriptionTextTopPadding)
            } header: {
                Text("Display Preferences").font(.headline)
            }
            .padding(.top, sectionContentTopPadding)

            Divider()

            Section {
                VStack(alignment: .leading, spacing: 10) {
                    Toggle("Make phone numbers clickable", isOn: $isPhoneNumberClickable)
                    Toggle("Make email addresses clickable", isOn: $isEmailClickable)
                    Toggle("Make social media URLs clickable", isOn: $isSocialMediaURLClickable)
                }
                Text("If enabled, tapping contact info in the 'Today' view will attempt to open the relevant app (Phone, Mail, Browser).")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, descriptionTextTopPadding)
            } header: {
                Text("Interaction Preferences").font(.headline)
            }
            .padding(.top, sectionContentTopPadding)
            
            Divider()

            Section {
                HStack {
                    Button("Export Birthdays...") {
                        exportBirthdays()
                    }
                    Button("Import Birthdays...") {
                        importBirthdays()
                    }
                }
            } header: {
                Text("Data Management").font(.headline)
            }
            .padding(.top, sectionContentTopPadding)
            
        }
        .padding(EdgeInsets(top: 15, leading: 20, bottom: 20, trailing: 20))
        .frame(width: 480, height: 420)
    }

    func exportBirthdays() {
        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [.commaSeparatedText]
        savePanel.canCreateDirectories = true
        savePanel.nameFieldStringValue = "JustBirthdays_Export.csv"

        savePanel.begin { response in
            if response == .OK, let url = savePanel.url {
                var csvString = "id,name,birthday,phoneNumber,emailAddress,socialMediaURL,notes,yearIsKnown\n"
                for person in people {
                    let id = person.wrappedId.uuidString
                    let name = escapeCSVField(person.wrappedName)
                    let birthday = csvDateFormatter.string(from: person.wrappedBirthday)
                    let phone = escapeCSVField(person.phoneNumber ?? "")
                    let email = escapeCSVField(person.emailAddress ?? "")
                    let social = escapeCSVField(person.socialMediaURL ?? "")
                    let notes = escapeCSVField(person.notes ?? "")
                    let yearKnown = person.yearIsKnown ? "true" : "false"
                    csvString.append("\(id),\(name),\(birthday),\(phone),\(email),\(social),\(notes),\(yearKnown)\n")
                }

                do {
                    try csvString.write(to: url, atomically: true, encoding: .utf8)
                } catch {
                    print("Error exporting birthdays: \(error.localizedDescription)")
                }
            }
        }
    }

    func importBirthdays() {
        let openPanel = NSOpenPanel()
        openPanel.allowedContentTypes = [.commaSeparatedText]
        openPanel.allowsMultipleSelection = false
        openPanel.canChooseDirectories = false
        openPanel.canChooseFiles = true

        openPanel.begin { response in
            if response == .OK, let url = openPanel.url {
                Task {
                    do {
                        let csvString = try String(contentsOf: url, encoding: .utf8)
                        let lines = csvString.components(separatedBy: .newlines).filter { !$0.isEmpty }
                        
                        guard lines.count > 1 else { return }

                        var importedCount = 0
                        for i in 1..<lines.count {
                            let line = lines[i]
                            let fields = parseCSVLine(line)

                            guard fields.count >= 8 else {
                                print("Skipping malformed CSV line: \(line)")
                                continue
                            }
                            
                            let newPerson = Person(context: viewContext)
                            newPerson.id = UUID(uuidString: fields[0])
                            newPerson.name = unescapeCSVField(fields[1])
                            
                            guard let birthday = csvDateFormatter.date(from: fields[2]) else {
                                print("Skipping line due to invalid date format: \(fields[2])")
                                viewContext.delete(newPerson)
                                continue
                            }
                            newPerson.birthday = birthday
                            newPerson.phoneNumber = fields[3].isEmpty ? nil : unescapeCSVField(fields[3])
                            newPerson.emailAddress = fields[4].isEmpty ? nil : unescapeCSVField(fields[4])
                            newPerson.socialMediaURL = fields[5].isEmpty ? nil : unescapeCSVField(fields[5])
                            newPerson.notes = fields[6].isEmpty ? nil : unescapeCSVField(fields[6])
                            newPerson.yearIsKnown = (fields[7].lowercased() == "true")
                            
                            importedCount += 1
                        }
                        
                        if viewContext.hasChanges {
                            try viewContext.save()
                            WidgetDataController.shared.updateWidgetData(using: viewContext)
                            print("Successfully imported \(importedCount) birthdays from: \(url.path)")
                        }
                    } catch {
                        print("Error importing birthdays: \(error.localizedDescription)")
                    }
                }
            }
        }
    }

    private func escapeCSVField(_ field: String) -> String {
        if field.contains(",") || field.contains("\"") || field.contains("\n") {
            return "\"\(field.replacingOccurrences(of: "\"", with: "\"\""))\""
        }
        return field
    }
    
    private func parseCSVLine(_ line: String) -> [String] {
        var fields: [String] = []
        var currentField = ""
        var inQuotes = false
        var i = line.startIndex
        while i < line.endIndex {
            let char = line[i]
            if char == "\"" {
                if inQuotes, i < line.index(before: line.endIndex), line[line.index(after: i)] == "\"" {
                    currentField.append("\"")
                    i = line.index(after: i)
                } else {
                    inQuotes.toggle()
                }
            } else if char == "," && !inQuotes {
                fields.append(currentField)
                currentField = ""
            } else {
                currentField.append(char)
            }
            i = line.index(after: i)
        }
        fields.append(currentField)
        return fields
    }

    private func unescapeCSVField(_ field: String) -> String {
        var mutableField = field
        if mutableField.hasPrefix("\"") && mutableField.hasSuffix("\"") {
            mutableField.removeFirst()
            mutableField.removeLast()
        }
        return mutableField.replacingOccurrences(of: "\"\"", with: "\"")
    }
}
