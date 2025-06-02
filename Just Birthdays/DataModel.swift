// MARK: - DataModel.swift
// This file defines the structure for a birthday entry.

import Foundation

struct BirthdayEntry: Codable, Identifiable, Equatable {
    var id = UUID()
    var name: String
    var birthday: Date
    
    var phoneNumber: String?
    var emailAddress: String?
    var socialMediaURL: String?
    var notes: String?
    var yearIsKnown: Bool

    var isToday: Bool {
        let calendar = Calendar.current
        let todayComponents = calendar.dateComponents([.month, .day], from: Date())
        let birthdayComponents = calendar.dateComponents([.month, .day], from: birthday)
        
        return todayComponents.month == birthdayComponents.month &&
               todayComponents.day == birthdayComponents.day
    }

    var nextBirthdayDate: Date {
        let calendar = Calendar.current
        let today = Date()
        let currentYear = calendar.component(.year, from: today)

        var components = calendar.dateComponents([.month, .day], from: birthday)
        components.year = currentYear
        
        guard let nextBirthdayThisYear = calendar.date(from: components) else {
            var nextYearComponents = calendar.dateComponents([.month, .day, .year], from: birthday)
            nextYearComponents.year = (nextYearComponents.year ?? currentYear) + 1
            return calendar.date(from: nextYearComponents) ?? calendar.date(byAdding: .year, value: 1, to: birthday)!
        }
        
        if self.isToday {
             return nextBirthdayThisYear
        } else if nextBirthdayThisYear < today {
            components.year = currentYear + 1
            return calendar.date(from: components) ?? calendar.date(byAdding: .year, value: 1, to: nextBirthdayThisYear)!
        } else {
            return nextBirthdayThisYear
        }
    }
    
    // Formatted birthday string (e.g., "May 19")
    var formattedBirthday: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM d"
        return formatter.string(from: birthday)
    }

    // Formatted birthday string including year (e.g., "May 19, 1990")
    var formattedBirthdayWithYear: String {
        guard yearIsKnown else {
            return formattedBirthday
        }
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM d, yyyy"
        return formatter.string(from: birthday)
    }

    var daysUntilNextBirthday: Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let nextBday = calendar.startOfDay(for: nextBirthdayDate)
        
        if self.isToday {
            return 0
        }
        
        let components = calendar.dateComponents([.day], from: today, to: nextBday)
        return components.day ?? 0
    }

    var hasAnyContactInfo: Bool {
        return !(phoneNumber?.isEmpty ?? true) ||
               !(emailAddress?.isEmpty ?? true) ||
               !(socialMediaURL?.isEmpty ?? true)
    }
}
