// MARK: - DataModel.swift
// This file defines the structure for a birthday entry.

import Foundation

// ContactType enum is no longer needed as we'll have distinct fields.

// Struct to hold individual birthday information
// Codable: Allows saving/loading from storage (e.g., UserDefaults)
// Identifiable: Useful for SwiftUI lists
// Equatable: To compare instances, especially for finding and deleting
struct BirthdayEntry: Codable, Identifiable, Equatable {
    var id = UUID() // Unique identifier for each entry
    var name: String
    var birthday: Date
    
    // Optional fields for different contact methods
    var phoneNumber: String?
    var emailAddress: String?
    var socialMediaHandle: String? // Could be a URL or a username like @handle

    // Computed property to check if the birthday is today
    var isToday: Bool {
        Calendar.current.isDateInToday(birthday)
    }

    // Computed property to get the next occurrence of the birthday
    var nextBirthdayDate: Date {
        let calendar = Calendar.current
        let today = Date()
        let currentYear = calendar.component(.year, from: today)

        var components = calendar.dateComponents([.month, .day], from: birthday)
        components.year = currentYear

        // If the birthday this year has already passed or is today (and we want next year's for "upcoming"),
        // advance to next year.
        guard let nextBirthdayThisYear = calendar.date(from: components) else {
            // Should not happen with valid month/day
            return calendar.date(byAdding: .year, value: 1, to: birthday)!
        }
        
        if calendar.isDateInToday(nextBirthdayThisYear) { // If it's today, nextBirthdayDate is today.
             return nextBirthdayThisYear
        } else if nextBirthdayThisYear < today { // If it has passed this year
            components.year = currentYear + 1
            return calendar.date(from: components)!
        } else { // If it's upcoming this year
            return nextBirthdayThisYear
        }
    }
    
    // Formatted birthday string (e.g., "May 19")
    var formattedBirthday: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM d" // Changed from "MMM d" for full month name
        return formatter.string(from: birthday)
    }

    // Days until next birthday
    var daysUntilNextBirthday: Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date()) // Compare start of day to start of day
        let nextBday = calendar.startOfDay(for: nextBirthdayDate)
        
        // If the birthday is today, daysUntil should be 0.
        if calendar.isDateInToday(nextBirthdayDate) {
            return 0
        }
        
        let components = calendar.dateComponents([.day], from: today, to: nextBday)
        return components.day ?? 0 // Should always return a value
    }

    // Helper to check if any contact info is available
    var hasAnyContactInfo: Bool {
        return !(phoneNumber?.isEmpty ?? true) ||
               !(emailAddress?.isEmpty ?? true) ||
               !(socialMediaHandle?.isEmpty ?? true)
    }
}
