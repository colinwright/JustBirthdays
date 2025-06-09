import Foundation
import SwiftData

@Model
final class Person {
    @Attribute(.unique) var id: UUID
    var name: String
    var birthday: Date
    
    var phoneNumber: String?
    var email: String?
    var socialMediaURL: String?
    
    @Attribute(.externalStorage)
    var notes: String?
    
    static let defaultYear = 1
    
    init(
        name: String,
        birthday: Date,
        phoneNumber: String? = nil,
        email: String? = nil,
        socialMediaURL: String? = nil,
        notes: String? = nil
    ) {
        self.id = UUID()
        self.name = name
        self.birthday = birthday
        self.phoneNumber = phoneNumber
        self.email = email
        self.socialMediaURL = socialMediaURL
        self.notes = notes
    }
}

extension Person {
    var hasRealYear: Bool {
        let year = Calendar.current.component(.year, from: birthday)
        return year != Person.defaultYear
    }

    // This is the corrected implementation. It now properly ignores the year.
    var isBirthdayToday: Bool {
        let calendar = Calendar.current
        let todayComponents = calendar.dateComponents([.month, .day], from: Date())
        let birthdayComponents = calendar.dateComponents([.month, .day], from: birthday)
        
        return todayComponents.month == birthdayComponents.month &&
               todayComponents.day == birthdayComponents.day
    }

    var birthMonthDay: Int {
        let components = Calendar.current.dateComponents([.month, .day], from: birthday)
        guard let month = components.month, let day = components.day else { return 0 }
        return month * 100 + day
    }

    var nextBirthday: Date? {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        let birthdayComponents = calendar.dateComponents([.month, .day], from: birthday)
        let currentYear = calendar.component(.year, from: today)

        var nextBirthdayComponents = DateComponents()
        nextBirthdayComponents.month = birthdayComponents.month
        nextBirthdayComponents.day = birthdayComponents.day
        nextBirthdayComponents.year = currentYear
        
        guard var nextBirthdayDate = calendar.date(from: nextBirthdayComponents) else {
            return nil
        }
        
        // If this year's birthday has already passed, check for next year's.
        if nextBirthdayDate < today {
            nextBirthdayComponents.year = currentYear + 1
            if let nextYearBirthday = calendar.date(from: nextBirthdayComponents) {
                nextBirthdayDate = nextYearBirthday
            }
        }
        
        return nextBirthdayDate
    }
    
    var daysUntilNextBirthday: Int {
        guard let nextBirthdayDate = nextBirthday else { return 0 }
        
        // If it's their birthday today, the countdown is 0.
        if self.isBirthdayToday {
            return 0
        }
        
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        let components = calendar.dateComponents([.day], from: today, to: nextBirthdayDate)
        return components.day ?? 0
    }
}
