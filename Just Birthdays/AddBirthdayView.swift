// MARK: - AddBirthdayView.swift
// SwiftUI View for adding or editing a birthday entry, with refined minimalist styling.

import SwiftUI

struct AddBirthdayView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var store: BirthdayStore
    
    @State private var name: String
    @State private var birthday: Date
    @State private var phoneNumber: String
    @State private var emailAddress: String
    @State private var socialMediaHandle: String
    
    var entryToEdit: BirthdayEntry?

    // Custom initializer to set initial state based on entryToEdit
    init(store: BirthdayStore, entryToEdit: BirthdayEntry?) {
        self.store = store
        self.entryToEdit = entryToEdit
        
        if let entry = entryToEdit {
            _name = State(initialValue: entry.name)
            _birthday = State(initialValue: entry.birthday)
            _phoneNumber = State(initialValue: entry.phoneNumber ?? "")
            _emailAddress = State(initialValue: entry.emailAddress ?? "")
            _socialMediaHandle = State(initialValue: entry.socialMediaHandle ?? "")
        } else {
            _name = State(initialValue: "")
            _birthday = State(initialValue: Date())
            _phoneNumber = State(initialValue: "")
            _emailAddress = State(initialValue: "")
            _socialMediaHandle = State(initialValue: "")
        }
    }

    var body: some View {
        // Form provides good structure and adapts to system styling for sheets.
        Form {
            Section(header:
                Text("Person Details")
                    .font(.system(size: 11, weight: .medium)) // Small, medium weight for subtlety
                    .foregroundColor(.secondary.opacity(0.7))    // Muted color
                    .textCase(.uppercase)                       // Subtle design touch
                    .padding(.top, 15)                          // Space above first section
                    .padding(.bottom, 3)                        // Little space below header before fields
            ) {
                // The labels "Name" and "Birthday" are part of the TextField/DatePicker by default in a Form
                // and will adopt standard Form label styling (typically aligned leading).
                TextField("Name", text: $name)
                    .textFieldStyle(.roundedBorder) // Standard bordered field

                DatePicker("Birthday", selection: $birthday, displayedComponents: .date)
                    .datePickerStyle(.field)
            }
            .padding(.bottom, 15) // Space after the first section

            Section(header:
                Text("Contact Information") // Removed "(Optional)" for cleaner look
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.secondary.opacity(0.7))
                    .textCase(.uppercase)
                    .padding(.bottom, 3)
            ) {
                TextField("Phone Number", text: $phoneNumber)
                    .textFieldStyle(.roundedBorder) // Standard bordered field
                
                TextField("Email Address", text: $emailAddress)
                    .textFieldStyle(.roundedBorder) // Standard bordered field
                    .disableAutocorrection(true)
                
                TextField("Social Media (URL or @handle)", text: $socialMediaHandle)
                    .textFieldStyle(.roundedBorder) // Standard bordered field
                    .disableAutocorrection(true)
            }
        }
        .padding(.horizontal) // Apply horizontal padding to the Form itself for side margins
        .padding(.top, 5)     // Reduce top padding as section header has its own
        .padding(.bottom)     // Standard bottom padding for the Form
        .frame(minWidth: 380, idealWidth: 420, maxWidth: 500, minHeight: 360, idealHeight: 400, maxHeight: 480)
        .navigationTitle(entryToEdit == nil ? "New Birthday" : "Edit Birthday")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    dismiss()
                }
            }
            ToolbarItem(placement: .confirmationAction) {
                 Button(entryToEdit == nil ? "Add" : "Save", action: saveEntry)
                    .disabled(name.isEmpty)
            }
        }
        .task(id: entryToEdit) {
            if let entry = entryToEdit {
                name = entry.name; birthday = entry.birthday
                phoneNumber = entry.phoneNumber ?? ""; emailAddress = entry.emailAddress ?? ""
                socialMediaHandle = entry.socialMediaHandle ?? ""
            } else {
                name = ""; birthday = Date(); phoneNumber = ""; emailAddress = ""; socialMediaHandle = ""
            }
        }
        // The sheet background will be the system default material.
    }

    private func saveEntry() {
        let phoneToSave = phoneNumber.isEmpty ? nil : phoneNumber
        let emailToSave = emailAddress.isEmpty ? nil : emailAddress
        let socialToSave = socialMediaHandle.isEmpty ? nil : socialMediaHandle

        if let entry = entryToEdit {
            var updatedEntry = entry
            updatedEntry.name = name; updatedEntry.birthday = birthday
            updatedEntry.phoneNumber = phoneToSave; updatedEntry.emailAddress = emailToSave
            updatedEntry.socialMediaHandle = socialToSave
            store.updateEntry(updatedEntry)
        } else {
            store.addEntry(name: name, birthday: birthday, phoneNumber: phoneToSave,
                           emailAddress: emailToSave, socialMediaHandle: socialToSave)
        }
        dismiss()
    }
}

struct AddBirthdayView_Previews: PreviewProvider {
    static var previews: some View {
        let previewStore = BirthdayStore()
        let sampleEntry = BirthdayEntry(name: "Jane Doe", birthday: Date(), phoneNumber: "555-1234",
                                        emailAddress: "jane@example.com", socialMediaHandle: "@janedoe")
        Group {
            NavigationView { AddBirthdayView(store: previewStore, entryToEdit: nil) }
                .previewDisplayName("New Birthday")
            NavigationView { AddBirthdayView(store: previewStore, entryToEdit: sampleEntry) }
                .previewDisplayName("Edit Birthday")
        }
        .frame(width: 420, height: 450)
    }
}
