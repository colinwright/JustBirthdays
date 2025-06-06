import Foundation

struct AppSettings {
    // Display Preferences
    static let upcomingDaysKey = "upcomingBirthdayLeadTime"
    static let defaultUpcomingDays = 7
    
    static let showYearInListKey = "showYearInBirthdayList"
    static let defaultShowYearInList = false

    // Interaction Preferences
    static let isPhoneNumberClickableKey = "isPhoneNumberClickable"
    static let defaultIsPhoneNumberClickable = false
    
    static let isEmailClickableKey = "isEmailClickable"
    static let defaultIsEmailClickable = false
    
    static let isSocialMediaURLClickableKey = "isSocialMediaURLClickable"
    static let defaultIsSocialMediaURLClickable = false
}
