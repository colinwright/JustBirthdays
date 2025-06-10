import SwiftUI
import SwiftData
import UniformTypeIdentifiers

// A wrapper for UIActivityViewController to be used in SwiftUI.
private struct ShareSheet: UIViewControllerRepresentable {
    let url: URL
    var onComplete: (Result<Void, Error>) -> Void

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: [url],
            applicationActivities: nil
        )
        controller.completionWithItemsHandler = { _, completed, _, error in
            if let error = error {
                onComplete(.failure(error))
            } else if completed {
                onComplete(.success(()))
            }
        }
        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// A helper struct to make the URL identifiable for the .sheet modifier.
private struct ShareableURL: Identifiable {
    let id = UUID()
    let url: URL
}

struct SettingsView: View {
    @StateObject private var settings = AppSettings()
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @Query var allPeople: [Person]
    
    @State private var isShowingImporter = false
    @State private var importError: Error?
    @State private var confirmationMessage: String?
    @State private var shareableURL: ShareableURL?

    var body: some View {
        ZStack(alignment: .top) {
            NavigationStack {
                Form {
                    Section("Display Preferences") {
                        Stepper("Show upcoming birthdays for the next \(settings.upcomingDaysLimit) days", value: $settings.upcomingDaysLimit, in: 1...365)
                        Toggle("Show year in birthday lists", isOn: $settings.showYearInList)
                    }
                    
                    Section {
                        Button("Export Birthdays...", action: exportData)
                            .disabled(allPeople.isEmpty)
                        Button("Import Birthdays...", action: { isShowingImporter = true })
                    } header: {
                        Text("Data Management")
                    } footer: {
                        Text("After tapping Export, choose 'Save to Files' to save the CSV to your device.")
                    }
                }
                .navigationTitle("Settings")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done") { dismiss() }
                    }
                }
                .fileImporter(
                    isPresented: $isShowingImporter,
                    allowedContentTypes: [.commaSeparatedText],
                    onCompletion: handleImport
                )
                .sheet(item: $shareableURL) { item in
                    ShareSheet(url: item.url) { result in
                        if case .success = result {
                            showConfirmationMessage("Successfully exported birthdays.")
                        }
                        try? FileManager.default.removeItem(at: item.url)
                    }
                }
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
        
        let tempDir = FileManager.default.temporaryDirectory
        let fileName = "JustBirthdays_Export.csv"
        let fileURL = tempDir.appendingPathComponent(fileName)

        do {
            try csvString.write(to: fileURL, atomically: true, encoding: .utf8)
            self.shareableURL = ShareableURL(url: fileURL)
        } catch {
            print("Failed to write CSV to temp file: \(error)")
        }
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
