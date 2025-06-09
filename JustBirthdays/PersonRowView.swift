import SwiftUI

struct PersonRowView: View {
    let person: Person
    
    // Read the setting from AppStorage.
    @AppStorage("showYearInList") private var showYearInList = false
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(person.name)
                    .font(.headline)
                
                // Now uses our setting to format the date.
                Text(person.birthday, format: birthdayFormat)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            // ... (rest of the body is unchanged)
            Spacer()
            
            Text(daysUntilText)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .monospacedDigit()
        }
        .padding(.vertical, 4)
    }
    
    private var daysUntilText: String {
        // ...
        let days = person.daysUntilNextBirthday
        if days == 0 {
            return "Today"
        } else if days == 1 {
            return "1 day"
        } else {
            return "\(days) days"
        }
    }
    
    private var birthdayFormat: Date.FormatStyle {
        if showYearInList {
            return .init().month(.wide).day().year()
        } else {
            return .init().month(.wide).day()
        }
    }
}
