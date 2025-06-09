import SwiftUI

struct PersonRowView: View {
    let person: Person
    
    @AppStorage("showYearInList", store: .appGroup) private var showYearInList = false
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(person.name)
                    .font(.headline)
                
                Text(person.birthday, format: birthdayFormat)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()
            
            Text(daysUntilText)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .monospacedDigit()
        }
        .padding(.vertical, 4)
    }
    
    private var daysUntilText: String {
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
        if showYearInList && person.hasRealYear {
            return .init().month(.wide).day().year()
        } else {
            return .init().month(.wide).day()
        }
    }
}
