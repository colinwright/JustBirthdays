// MARK: - BirthdayStore.swift
// This class manages the storage and retrieval of birthday entries.

import SwiftUI
import Combine // For ObservableObject
import WidgetKit // For reloading widget timelines

class BirthdayStore: ObservableObject {
    @Published var entries: [BirthdayEntry] = [] {
        didSet {
            saveEntries()
        }
    }

    private let userDefaultsKey = "birthdayEntries"
    // MARK: - APP GROUP ID HAS BEEN UPDATED
    // This now reflects the App Group ID from your screenshot.
    private let appGroupId = "group.com.colinismyname.JustBirthdays"

    init() {
        loadEntries()
        sortEntries()
    }

    private func getAppGroupUserDefaults() -> UserDefaults? {
        // Check if the appGroupId is empty (it shouldn't be if configured correctly)
        if appGroupId.isEmpty || appGroupId == "group.com.yourdomain.JustBirthdays" /* Safety check for old placeholder */ {
            print("Warning: App Group ID is empty or still the original placeholder ('\(appGroupId)'). UserDefaults will use standard. Please ensure App Groups are configured in Xcode and the appGroupId string in BirthdayStore.swift (and BirthdayWidget.swift) is correctly set to your actual App Group ID.")
            return UserDefaults.standard
        }
        return UserDefaults(suiteName: appGroupId)
    }

    private func saveEntries() {
        guard let userDefaults = getAppGroupUserDefaults() else {
            print("Critical Error: getAppGroupUserDefaults() returned nil. This should not happen.")
            return
        }

        let targetDescription = (userDefaults == UserDefaults.standard) ? "standard UserDefaults (App Group not properly configured)" : "App Group UserDefaults ('\(appGroupId)')"

        if let encoded = try? JSONEncoder().encode(entries) {
            userDefaults.set(encoded, forKey: userDefaultsKey)
            if userDefaults != UserDefaults.standard {
                WidgetCenter.shared.reloadTimelines(ofKind: "BirthdayWidget")
            }
            print("Entries saved to \(targetDescription).")
        } else {
            print("Error: Failed to encode entries for saving to \(targetDescription).")
        }
    }

    private func loadEntries() {
        guard let userDefaults = getAppGroupUserDefaults() else {
            print("Critical Error: getAppGroupUserDefaults() returned nil during load.")
            self.entries = []
            return
        }
        
        let sourceDescription = (userDefaults == UserDefaults.standard) ? "standard UserDefaults (App Group not properly configured)" : "App Group UserDefaults ('\(appGroupId)')"

        if let savedEntries = userDefaults.data(forKey: userDefaultsKey) {
            if let decodedEntries = try? JSONDecoder().decode([BirthdayEntry].self, from: savedEntries) {
                self.entries = decodedEntries
                print("Entries loaded from \(sourceDescription). Count: \(entries.count)")
                return
            } else {
                print("Error: Failed to decode entries from \(sourceDescription). Data might be corrupt or in old format.")
            }
        }
        self.entries = []
        print("No entries found in \(sourceDescription) or decoding failed.")
    }

    func addEntry(name: String,
                  birthday: Date,
                  phoneNumber: String?,
                  emailAddress: String?,
                  socialMediaHandle: String?) {
        let newEntry = BirthdayEntry(
            name: name,
            birthday: birthday,
            phoneNumber: phoneNumber,
            emailAddress: emailAddress,
            socialMediaHandle: socialMediaHandle
        )
        entries.append(newEntry)
        sortEntries()
    }

    func updateEntry(_ entry: BirthdayEntry) {
        if let index = entries.firstIndex(where: { $0.id == entry.id }) {
            entries[index] = entry
            sortEntries()
        }
    }

    func deleteEntry(at offsets: IndexSet) {
        entries.remove(atOffsets: offsets)
    }
    
    func deleteEntry(_ entry: BirthdayEntry) {
        entries.removeAll { $0.id == entry.id }
    }

    private func sortEntries() {
        entries.sort {
            if $0.nextBirthdayDate != $1.nextBirthdayDate {
                return $0.nextBirthdayDate < $1.nextBirthdayDate
            }
            return $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
        }
    }

    var todaysBirthdays: [BirthdayEntry] {
        entries.filter { $0.isToday }
    }

    var upcomingBirthdays: [BirthdayEntry] {
        let calendar = Calendar.current
        let todayStart = calendar.startOfDay(for: Date())
        guard let tomorrowStart = calendar.date(byAdding: .day, value: 1, to: todayStart),
              let thirtyDaysFromTomorrowStart = calendar.date(byAdding: .day, value: 30, to: tomorrowStart) else {
            return []
        }

        return entries.filter { entry in
            !entry.isToday &&
            entry.nextBirthdayDate >= tomorrowStart &&
            entry.nextBirthdayDate < thirtyDaysFromTomorrowStart
        }
    }
    
    var allSortedBirthdays: [BirthdayEntry] {
        return entries
    }
}
