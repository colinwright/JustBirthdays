import Foundation
import SwiftData

enum CSVParseError: Error, LocalizedError {
    case fileReadError
    case invalidColumnCount(expected: Int, actual: Int, onLine: Int)
    case invalidDateFormat(value: String, onLine: Int)
    case malformedRow(onLine: Int)

    var errorDescription: String? {
        switch self {
        case .fileReadError:
            return "Could not read the selected file."
        case .invalidColumnCount(let expected, let actual, let onLine):
            return "Invalid data format on line \(onLine). Expected \(expected) columns, but found \(actual)."
        case .invalidDateFormat(let value, let onLine):
            return "Invalid date format '\(value)' on line \(onLine). Please use YYYY-MM-DD format."
        case .malformedRow(let onLine):
            return "The data on line \(onLine) is malformed and could not be read."
        }
    }
}

struct CSVManager {
    private static let headers = ["name", "birthday", "phoneNumber", "email", "socialMediaURL", "notes"]

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
                escape(person.name),
                escape(birthdayString),
                escape(person.phoneNumber ?? ""),
                escape(person.email ?? ""),
                escape(person.socialMediaURL ?? ""),
                escape(person.notes ?? "")
            ].joined(separator: ",")
            
            csvString += row + "\n"
        }
        return csvString
    }

    static func parseCSV(from url: URL) throws -> [Person] {
        let csvString: String
        do {
            csvString = try String(contentsOf: url, encoding: .utf8)
        } catch {
            throw CSVParseError.fileReadError
        }

        let lines = csvString.components(separatedBy: .newlines).filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        
        guard lines.count > 1 else { return [] }

        var people: [Person] = []
        for (index, line) in lines.dropFirst().enumerated() {
            let lineNumber = index + 2
            
            let columns = try parse(csvLine: line)
            
            guard columns.count == headers.count else {
                throw CSVParseError.invalidColumnCount(expected: headers.count, actual: columns.count, onLine: lineNumber)
            }
                
            let name = columns[0]
            let birthdayString = columns[1]
            let phone = columns[2]
            let email = columns[3]
            let urlString = columns[4]
            let notes = columns[5]
            
            guard let birthday = dateFormatter.date(from: birthdayString) else {
                throw CSVParseError.invalidDateFormat(value: birthdayString, onLine: lineNumber)
            }
            
            let person = Person(
                name: name,
                birthday: birthday,
                phoneNumber: phone.isEmpty ? nil : phone,
                email: email.isEmpty ? nil : email,
                socialMediaURL: urlString.isEmpty ? nil : urlString,
                notes: notes.isEmpty ? nil : notes
            )
            people.append(person)
        }
        return people
    }

    private static func escape(_ value: String) -> String {
        let escapedValue = value.replacingOccurrences(of: "\"", with: "\"\"")
        return "\"\(escapedValue)\""
    }

    private static func parse(csvLine: String) throws -> [String] {
        var fields: [String] = []
        var currentField = ""
        var i = csvLine.startIndex
        var inQuotedField = false

        while i < csvLine.endIndex {
            let char = csvLine[i]

            if inQuotedField {
                if char == "\"" {
                    let nextIndex = csvLine.index(after: i)
                    if nextIndex < csvLine.endIndex && csvLine[nextIndex] == "\"" {
                        // Escaped quote (""). Append one quote and advance past the second one.
                        currentField.append("\"")
                        i = nextIndex
                    } else {
                        // End of quoted field.
                        inQuotedField = false
                    }
                } else {
                    currentField.append(char)
                }
            } else {
                switch char {
                case "\"":
                    inQuotedField = true
                case ",":
                    fields.append(currentField)
                    currentField = ""
                default:
                    currentField.append(char)
                }
            }
            i = csvLine.index(after: i)
        }

        fields.append(currentField)
        return fields
    }
}
