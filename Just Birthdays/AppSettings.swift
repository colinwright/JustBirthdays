// AppSettings.swift
import Foundation

struct AppSettings {
    // Display Preferences
    static let upcomingDaysKey = "upcomingBirthdayLeadTime"
    static let defaultUpcomingDays = 7
    
    static let showYearInListKey = "showYearInBirthdayList"
    static let defaultShowYearInList = false

    // Interaction Preferences
    static let isPhoneNumberClickableKey = "isPhoneNumberClickable"
    static let defaultIsPhoneNumberClickable = false // Default to not clickable
    
    static let isEmailClickableKey = "isEmailClickable"
    static let defaultIsEmailClickable = false // Default to not clickable
    
    // Changed to reflect URL focus
    static let isSocialMediaURLClickableKey = "isSocialMediaURLClickable"
    static let defaultIsSocialMediaURLClickable = false // Default to not clickable
}
