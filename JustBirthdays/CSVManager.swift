import Foundation
import SwiftData

struct CSVManager {
    private static let headers = ["name", "birthday", "phoneNumber", "email", "socialMediaURL", "notes"]
    
    // Corrected the typo from O to 0.
    private static let dateFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate]
        return formatter
    }()

    static func generateCSV(from people: [Person]) -> String {
        var csvString = headers.joined(separator: ",") + "\n"

        for person in people {
            let birthdayString = dateFormatter.string(from: person.birthday)
            
            let row = [
                "\"\(person.name)\"",
                "\"\(birthdayString)\"",
                "\"\(person.phoneNumber ?? "")\"",
                "\"\(person.email ?? "")\"",
                "\"\(person.socialMediaURL ?? "")\"",
                "\"\(person.notes ?? "")\""
            ].joined(separator: ",")
            
            csvString += row + "\n"
        }
        return csvString
    }

    static func parseCSV(from url: URL) -> [Person] {
        var people: [Person] = []
        guard let csvString = try? String(contentsOf: url, encoding: .utf8) else { return people }

        let lines = csvString.split(separator: "\n").map(String.init)
        guard lines.count > 1 else { return people }

        for line in lines.dropFirst() {
            let columns = line.components(separatedBy: ",")
            if columns.count == headers.count {
                let name = columns[0].trimmingQuotes()
                let birthdayString = columns[1].trimmingQuotes()
                let phone = columns[2].trimmingQuotes()
                let email = columns[3].trimmingQuotes()
                let url = columns[4].trimmingQuotes()
                let notes = columns[5].trimmingQuotes()
                
                if let birthday = dateFormatter.date(from: birthdayString) {
                    let person = Person(
                        name: name,
                        birthday: birthday,
                        phoneNumber: phone.isEmpty ? nil : phone,
                        email: email.isEmpty ? nil : email,
                        socialMediaURL: url.isEmpty ? nil : url,
                        notes: notes.isEmpty ? nil : notes
                    )
                    people.append(person)
                }
            }
        }
        return people
    }
}

private extension String {
    func trimmingQuotes() -> String {
        self.trimmingCharacters(in: .whitespaces).trimmingCharacters(in: CharacterSet(charactersIn: "\""))
    }
}
