import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct SettingsView: View {
    @StateObject private var settings = AppSettings()
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @Query var allPeople: [Person]
    
    @State private var documentToExport: CSVDocument?
    @State private var isShowingImporter = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Display Preferences") {
                    Stepper("Show upcoming birthdays for the next \(settings.upcomingDaysLimit) days", value: $settings.upcomingDaysLimit, in: 1...365)
                    Toggle("Show year in birthday lists", isOn: $settings.showYearInList)
                }
                
                Section("Data Management") {
                    Button("Export Birthdays...") {
                        exportData()
                    }
                    
                    Button("Import Birthdays...") {
                        isShowingImporter = true
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .fileExporter(
                isPresented: .constant(documentToExport != nil),
                document: documentToExport,
                contentType: .commaSeparatedText,
                defaultFilename: "JustBirthdays_Export.csv"
            ) { result in
                // Handle export result if necessary
                documentToExport = nil
            }
            .fileImporter(
                isPresented: $isShowingImporter,
                allowedContentTypes: [.commaSeparatedText]
            ) { result in
                handleImport(result: result)
            }
        }
    }
    
    private func exportData() {
        let csvString = CSVManager.generateCSV(from: allPeople)
        documentToExport = CSVDocument(csvString: csvString)
    }
    
    private func handleImport(result: Result<URL, Error>) {
        switch result {
        case .success(let url):
            let people = CSVManager.parseCSV(from: url)
            for person in people {
                // To avoid duplicates, we could check if a person with the same name/birthday exists.
                // For simplicity now, we just insert them all.
                modelContext.insert(person)
            }
        case .failure(let error):
            // Handle import error, e.g., show an alert
            print("Error importing file: \(error.localizedDescription)")
        }
    }
}

// A helper struct conforming to FileDocument to work with .fileExporter.
struct CSVDocument: FileDocument {
    static var readableContentTypes: [UTType] = [.commaSeparatedText]
    var csvString: String

    init(csvString: String) {
        self.csvString = csvString
    }

    init(configuration: ReadConfiguration) throws {
        if let data = configuration.file.regularFileContents {
            self.csvString = String(decoding: data, as: UTF8.self)
        } else {
            self.csvString = ""
        }
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let data = csvString.data(using: .utf8)!
        return FileWrapper(regularFileWithContents: data)
    }
}

#Preview {
    SettingsView()
        .modelContainer(for: Person.self, inMemory: true)
}
