import SwiftUI
import SwiftData
import UniformTypeIdentifiers

// A simple, reusable view for the confirmation message.
struct ConfirmationMessageView: View {
    let message: String
    
    var body: some View {
        Text(message)
            .font(.headline)
            .padding()
            .background(.ultraThickMaterial)
            .cornerRadius(12)
            .shadow(radius: 5)
    }
}

struct SettingsView: View {
    @StateObject private var settings = AppSettings()
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @Query var allPeople: [Person]
    
    @State private var documentToExport: CSVDocument?
    @State private var isShowingImporter = false
    @State private var importError: Error?
    @State private var confirmationMessage: String?

    var body: some View {
        ZStack(alignment: .top) {
            NavigationStack {
                Form {
                    Section("Display Preferences") {
                        Stepper("Show upcoming birthdays for the next \(settings.upcomingDaysLimit) days", value: $settings.upcomingDaysLimit, in: 1...365)
                        Toggle("Show year in birthday lists", isOn: $settings.showYearInList)
                    }
                    
                    Section("Data Management") {
                        Button("Export Birthdays...", action: exportData)
                            .disabled(allPeople.isEmpty)
                        Button("Import Birthdays...", action: { isShowingImporter = true })
                    }
                }
                .navigationTitle("Settings")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done") { dismiss() }
                    }
                }
                .fileExporter(
                    isPresented: Binding(
                        get: { documentToExport != nil },
                        set: { if !$0 { documentToExport = nil } }
                    ),
                    document: documentToExport,
                    contentType: .commaSeparatedText,
                    defaultFilename: "JustBirthdays_Export.csv"
                ) { result in
                    if case .success = result {
                        showConfirmationMessage("Successfully exported birthdays.")
                    }
                }
                .fileImporter(
                    isPresented: $isShowingImporter,
                    allowedContentTypes: [.commaSeparatedText],
                    onCompletion: handleImport
                )
                .alert(
                    "Import Failed",
                    isPresented: Binding(
                        get: { importError != nil },
                        set: { if !$0 { importError = nil } }
                    )
                ) {
                    Button("OK") {}
                } message: {
                    Text(importError?.localizedDescription ?? "An unknown error occurred.")
                }
            }
            
            // Display the confirmation message when it's set.
            if let message = confirmationMessage {
                ConfirmationMessageView(message: message)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .padding(.top)
            }
        }
        .animation(.spring(), value: confirmationMessage)
    }
    
    private func exportData() {
        let csvString = CSVManager.generateCSV(from: allPeople)
        documentToExport = CSVDocument(csvString: csvString)
    }
    
    private func handleImport(result: Result<URL, Error>) {
        switch result {
        case .success(let url):
            guard url.startAccessingSecurityScopedResource() else {
                self.importError = CSVParseError.fileReadError
                return
            }
            
            defer {
                url.stopAccessingSecurityScopedResource()
            }

            do {
                let people = try CSVManager.parseCSV(from: url)
                for person in people {
                    modelContext.insert(person)
                }
                showConfirmationMessage("Imported \(people.count) birthdays.")
            } catch {
                self.importError = error
            }
        case .failure(let error):
            self.importError = error
        }
    }
    
    private func showConfirmationMessage(_ message: String) {
        confirmationMessage = message
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            confirmationMessage = nil
        }
    }
}

private struct CSVDocument: FileDocument {
    static var readableContentTypes: [UTType] = [.commaSeparatedText]
    var csvString: String

    init(csvString: String) {
        self.csvString = csvString
    }

    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents else {
            throw CocoaError(.fileReadCorruptFile)
        }
        self.csvString = String(decoding: data, as: UTF8.self)
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let data = csvString.data(using: .utf8)!
        return FileWrapper(regularFileWithContents: data)
    }
}
