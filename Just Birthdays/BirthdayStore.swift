// MARK: - BirthdayStore.swift
// This class manages the storage and retrieval of birthday entries.

import SwiftUI
import Combine
import WidgetKit

class BirthdayStore: ObservableObject {
    @Published var entries: [BirthdayEntry] = [] {
        didSet {
            saveEntries()
            reloadWidgets()
        }
    }

    @AppStorage(AppSettings.upcomingDaysKey) var upcomingBirthdayLeadTimeSetting: Int = AppSettings.defaultUpcomingDays {
        didSet {
            objectWillChange.send()
            reloadWidgets()
        }
    }
    
    private let userDefaultsKey = "birthdayEntries"
    private let appGroupId = "group.com.colinismyname.JustBirthdays"

    private static let todaysWidgetKind = "TodaysBirthdaysWidget"
    private static let upcomingWidgetKind = "UpcomingBirthdaysWidget"

    init() {
        loadEntries()
    }

    private func reloadWidgets() {
        WidgetCenter.shared.reloadTimelines(ofKind: BirthdayStore.todaysWidgetKind)
        WidgetCenter.shared.reloadTimelines(ofKind: BirthdayStore.upcomingWidgetKind)
    }

    private func getAppGroupUserDefaults() -> UserDefaults? {
        if appGroupId.isEmpty || appGroupId == "group.com.yourdomain.JustBirthdays" {
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
        do {
            let encoder = JSONEncoder()
            let encoded = try encoder.encode(entries)
            userDefaults.set(encoded, forKey: userDefaultsKey)
            print("Entries saved to \(targetDescription).")
        } catch {
            print("Error: Failed to encode entries for saving to \(targetDescription): \(error.localizedDescription)")
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
            do {
                let decoder = JSONDecoder()
                let decodedEntries = try decoder.decode([BirthdayEntry].self, from: savedEntries)
                self.entries = decodedEntries
                sortEntries()
                print("Entries loaded from \(sourceDescription). Count: \(entries.count)")
                return
            } catch {
                print("Error: Failed to decode entries from \(sourceDescription). Data might be corrupt or in old format: \(error.localizedDescription)")
            }
        }
        self.entries = []
        print("No entries found in \(sourceDescription) or decoding failed.")
    }

    func addEntry(name: String,
                  birthday: Date,
                  phoneNumber: String?,
                  emailAddress: String?,
                  socialMediaURL: String?,
                  notes: String?,
                  yearIsKnown: Bool) {
        let newEntry = BirthdayEntry(
            name: name,
            birthday: birthday,
            phoneNumber: phoneNumber,
            emailAddress: emailAddress,
            socialMediaURL: socialMediaURL,
            notes: notes,
            yearIsKnown: yearIsKnown
        )
        var mutableEntries = entries
        mutableEntries.append(newEntry)
        mutableEntries.sort {
            if $0.nextBirthdayDate != $1.nextBirthdayDate {
                return $0.nextBirthdayDate < $1.nextBirthdayDate
            }
            return $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
        }
        entries = mutableEntries
    }

    func updateEntry(_ entry: BirthdayEntry) {
        if let index = entries.firstIndex(where: { $0.id == entry.id }) {
            var mutableEntries = entries
            mutableEntries[index] = entry
            mutableEntries.sort {
                if $0.nextBirthdayDate != $1.nextBirthdayDate {
                    return $0.nextBirthdayDate < $1.nextBirthdayDate
                }
                return $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
            }
            entries = mutableEntries
        }
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
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    var upcomingBirthdays: [BirthdayEntry] {
        let calendar = Calendar.current
        let todayStart = calendar.startOfDay(for: Date())
        
        guard let tomorrowStart = calendar.date(byAdding: .day, value: 1, to: todayStart),
              let endDate = calendar.date(byAdding: .day, value: upcomingBirthdayLeadTimeSetting, to: tomorrowStart) else {
            return []
        }

        return entries.filter { entry in
            !entry.isToday &&
            entry.nextBirthdayDate >= tomorrowStart &&
            entry.nextBirthdayDate < endDate
        }
    }
    
    var allSortedBirthdays: [BirthdayEntry] {
        return entries
    }
}
