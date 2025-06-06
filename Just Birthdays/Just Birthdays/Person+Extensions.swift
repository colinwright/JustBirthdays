import Foundation
import CoreData

extension Person {
    // MARK: - Safe Wrappers for Optional Properties
    
    public var wrappedId: UUID {
        return id ?? UUID()
    }

    public var wrappedName: String {
        return name ?? "No Name"
    }

    public var wrappedBirthday: Date {
        return birthday ?? Date()
    }

    // MARK: - Computed Properties for UI Logic

    var isToday: Bool {
        guard let birthday else { return false }
        // Re-introduce the calendar constant here.
        let calendar = Calendar.current
        let todayComponents = calendar.dateComponents([.month, .day], from: Date())
        let birthdayComponents = calendar.dateComponents([.month, .day], from: birthday)
        return todayComponents.month == birthdayComponents.month && todayComponents.day == birthdayComponents.day
    }

    var nextBirthdayDate: Date {
        guard let birthday else { return Date() }
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        if self.isToday {
            return today
        }
        
        let components = calendar.dateComponents([.month, .day], from: birthday)
        
        guard let nextBirthdayThisOrNextYear = calendar.nextDate(after: today, matching: components, matchingPolicy: .nextTime, direction: .forward) else {
            return today
        }
        
        return nextBirthdayThisOrNextYear
    }
    
    var daysUntilNextBirthday: Int {
        if isToday { return 0 }
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let nextBday = calendar.startOfDay(for: nextBirthdayDate)
        return calendar.dateComponents([.day], from: today, to: nextBday).day ?? 0
    }
    
    var formattedBirthday: String {
        guard let birthday else { return "" }
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM d"
        return formatter.string(from: birthday)
    }

    var formattedBirthdayWithYear: String {
        guard let birthday, yearIsKnown else { return formattedBirthday }
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        return formatter.string(from: birthday)
    }
    
    var hasAnyContactInfo: Bool {
        // Corrected syntax for checking optional strings.
        !(self.phoneNumber?.trimmingCharacters(in: .whitespaces).isEmpty ?? true) ||
        !(self.emailAddress?.trimmingCharacters(in: .whitespaces).isEmpty ?? true) ||
        !(self.socialMediaURL?.trimmingCharacters(in: .whitespaces).isEmpty ?? true)
    }
}
