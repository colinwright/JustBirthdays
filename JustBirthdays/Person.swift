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
    // This is the corrected logic. It now ignores the year for the comparison.
    var isBirthdayToday: Bool {
        let calendar = Calendar.current
        let todayComponents = calendar.dateComponents([.month, .day], from: Date())
        let birthdayComponents = calendar.dateComponents([.month, .day], from: birthday)
        
        return todayComponents.month == birthdayComponents.month && todayComponents.day == birthdayComponents.day
    }

    var birthMonthDay: Int {
        let components = Calendar.current.dateComponents([.month, .day], from: birthday)
        guard let month = components.month, let day = components.day else { return 0 }
        return month * 100 + day
    }

    var nextBirthday: Date? {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        let components = calendar.dateComponents([.month, .day], from: birthday)
        var nextBirthdayComponents = DateComponents()
        nextBirthdayComponents.month = components.month
        nextBirthdayComponents.day = components.day
        
        let currentYear = calendar.component(.year, from: today)
        nextBirthdayComponents.year = currentYear
        
        guard let nextBirthdayDate = calendar.date(from: nextBirthdayComponents) else {
            return nil
        }
        
        if nextBirthdayDate < today && !self.isBirthdayToday {
            nextBirthdayComponents.year! += 1
            return calendar.date(from: nextBirthdayComponents)
        }
        
        return nextBirthdayDate
    }
    
    var daysUntilNextBirthday: Int {
        guard let nextBirthdayDate = nextBirthday else { return 0 }
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let components = calendar.dateComponents([.day], from: today, to: nextBirthdayDate)
        return components.day ?? 0
    }
}
