import SwiftUI

struct AddEditPersonView: View {
    @Bindable var person: Person
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    let isNew: Bool
    
    private var isFormValid: Bool {
        !person.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Full Name", text: $person.name)
                }
                
                Section("Birthday") {
                    // The standard, compact date picker.
                    // It shows the graphical calendar when tapped.
                    DatePicker(
                        "Date",
                        selection: $person.birthday,
                        displayedComponents: .date
                    )
                }
                
                Section("Contact Information") {
                    TextField("Phone Number", text: Binding(get: { person.phoneNumber ?? "" }, set: { person.phoneNumber = $0.isEmpty ? nil : $0 })).keyboardType(.phonePad)
                    TextField("Email Address", text: Binding(get: { person.email ?? "" }, set: { person.email = $0.isEmpty ? nil : $0 })).keyboardType(.emailAddress).textInputAutocapitalization(.never)
                    TextField("Social Media URL", text: Binding(get: { person.socialMediaURL ?? "" }, set: { person.socialMediaURL = $0.isEmpty ? nil : $0 })).keyboardType(.URL).textInputAutocapitalization(.never)
                }

                Section("More Information") {
                    TextField("Notes", text: Binding(get: { person.notes ?? "" }, set: { person.notes = $0.isEmpty ? nil : $0 }), axis: .vertical).lineLimit(5...)
                }
            }
            .navigationTitle(isNew ? "New Birthday" : "Edit Birthday")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { Button("Cancel", role: .cancel) { dismiss() } }
                ToolbarItem(placement: .topBarTrailing) { Button("Save", action: save).disabled(!isFormValid) }
            }
        }
    }
    
    private func save() {
        if isNew {
            modelContext.insert(person)
        }
        dismiss()
    }
}

#Preview {
    AddEditPersonView(person: Person(name: "", birthday: .now), isNew: true)
}
