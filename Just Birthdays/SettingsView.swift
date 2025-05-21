// MARK: - SettingsView.swift
// This view will contain the settings for the Just Birthdays app.

import SwiftUI

struct SettingsView: View {
    @AppStorage(AppSettings.upcomingDaysKey) var upcomingBirthdayLeadTime: Int = AppSettings.defaultUpcomingDays
    @AppStorage(AppSettings.showYearInListKey) var showYearInList: Bool = AppSettings.defaultShowYearInList
    
    @AppStorage(AppSettings.isPhoneNumberClickableKey) var isPhoneNumberClickable: Bool = AppSettings.defaultIsPhoneNumberClickable
    @AppStorage(AppSettings.isEmailClickableKey) var isEmailClickable: Bool = AppSettings.defaultIsEmailClickable
    // Updated to use the new key for social media URL
    @AppStorage(AppSettings.isSocialMediaURLClickableKey) var isSocialMediaURLClickable: Bool = AppSettings.defaultIsSocialMediaURLClickable

    @EnvironmentObject var birthdayStore: BirthdayStore

    let dayOptions = [3, 7, 14, 30]

    private var csvDateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }

    // Consistent spacing value for items within a section, below the header
    private let sectionContentTopPadding: CGFloat = 5
    // Consistent spacing value for descriptive text below a control
    private let descriptionTextTopPadding: CGFloat = 0 // Reduced to bring text closer to toggle

    var body: some View {
        Form {
            // Section for Display Preferences
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
                Text("If enabled, the year of birth will be displayed in the main birthday lists.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, descriptionTextTopPadding)
            } header: {
                Text("Display Preferences").font(.headline)
            }
            .padding(.top, sectionContentTopPadding) // Space below header

            Divider()

            // Section for Interaction Preferences
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
            .padding(.top, sectionContentTopPadding) // Space below header
            
            Divider()

            // Section for Data Management
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
            .padding(.top, sectionContentTopPadding) // Space below header
            
        }
        .padding(EdgeInsets(top: 15, leading: 20, bottom: 20, trailing: 20))
        .frame(width: 480, height: 420)
    }

    // MARK: - Import/Export Logic (Assumed unchanged and correct from previous version)

    func exportBirthdays() {
        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [.commaSeparatedText]
        savePanel.canCreateDirectories = true
        savePanel.nameFieldStringValue = "JustBirthdays_Export.csv"

        savePanel.begin { response in
            if response == .OK, let url = savePanel.url {
                var csvString = "id,name,birthday,phoneNumber,emailAddress,socialMediaURL\n"
                for entry in birthdayStore.entries {
                    let id = entry.id.uuidString
                    let name = escapeCSVField(entry.name)
                    let birthday = csvDateFormatter.string(from: entry.birthday)
                    let phone = escapeCSVField(entry.phoneNumber ?? "")
                    let email = escapeCSVField(entry.emailAddress ?? "")
                    let social = escapeCSVField(entry.socialMediaURL ?? "")
                    csvString.append("\(id),\(name),\(birthday),\(phone),\(email),\(social)\n")
                }

                do {
                    try csvString.write(to: url, atomically: true, encoding: .utf8)
                    print("Successfully exported birthdays to: \(url.path)")
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
                do {
                    let csvString = try String(contentsOf: url, encoding: .utf8)
                    let lines = csvString.components(separatedBy: .newlines).filter { !$0.isEmpty }
                    
                    guard lines.count > 1 else {
                        print("CSV file is empty or has no data rows.")
                        return
                    }

                    var importedCount = 0
                    for i in 1..<lines.count {
                        let line = lines[i]
                        let fields = parseCSVLine(line)

                        guard fields.count == 6 else {
                            print("Skipping malformed CSV line (expected 6 fields): \(line)")
                            continue
                        }
                        
                        let name = unescapeCSVField(fields[1])
                        guard let birthday = csvDateFormatter.date(from: fields[2]) else {
                            print("Skipping line due to invalid date format: \(fields[2])")
                            continue
                        }
                        let phoneNumber = fields[3].isEmpty ? nil : unescapeCSVField(fields[3])
                        let emailAddress = fields[4].isEmpty ? nil : unescapeCSVField(fields[4])
                        let socialMediaURLValue = fields[5].isEmpty ? nil : unescapeCSVField(fields[5])

                        birthdayStore.addEntry(
                            name: name,
                            birthday: birthday,
                            phoneNumber: phoneNumber,
                            emailAddress: emailAddress,
                            socialMediaURL: socialMediaURLValue
                        )
                        importedCount += 1
                    }
                    print("Successfully imported \(importedCount) birthdays from: \(url.path)")
                } catch {
                    print("Error importing birthdays: \(error.localizedDescription)")
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
        for char in line {
            if char == "\"" {
                inQuotes.toggle()
            } else if char == "," && !inQuotes {
                fields.append(currentField)
                currentField = ""
            } else {
                currentField.append(char)
            }
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

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
            .environmentObject(BirthdayStore())
            .frame(width: 480, height: 390)
    }
}
