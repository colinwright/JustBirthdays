// MARK: - AddBirthdayView.swift
// SwiftUI View for adding or editing a birthday entry, with custom date input.

import SwiftUI
import Combine // For .onReceive with Just for keyboard focus

struct AddBirthdayView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var store: BirthdayStore
    var entryToEdit: BirthdayEntry?

    // MARK: - State Variables
    @State private var name: String
    @State private var birthday: Date // Main date source of truth
    @State private var phoneNumber: String
    @State private var emailAddress: String
    // Renamed to socialMediaURL for clarity
    @State private var socialMediaURL: String

    @State private var monthInput: String = ""
    @State private var dayInput: String = ""
    @State private var yearInput: String = ""

    // Updated FocusState enum to include the name field
    enum FocusableField: Hashable {
        case name, month, day, year
    }
    @FocusState private var focusedField: FocusableField?
    
    @State private var showingDatePickerPopover = false
    @State private var showingDeleteConfirmation = false
    
    // Initializer
    init(store: BirthdayStore, entryToEdit: BirthdayEntry?) {
        self.store = store
        self.entryToEdit = entryToEdit
        
        let initialDate = entryToEdit?.birthday ?? Date()
        _birthday = State(initialValue: initialDate)
        _name = State(initialValue: entryToEdit?.name ?? "")
        _phoneNumber = State(initialValue: entryToEdit?.phoneNumber ?? "")
        _emailAddress = State(initialValue: entryToEdit?.emailAddress ?? "")
        // Updated to initialize socialMediaURL
        _socialMediaURL = State(initialValue: entryToEdit?.socialMediaURL ?? "")

        let components = Calendar.current.dateComponents([.month, .day, .year], from: initialDate)
        _monthInput = State(initialValue: String(format: "%02d", components.month ?? 1))
        _dayInput = State(initialValue: String(format: "%02d", components.day ?? 1))
        _yearInput = State(initialValue: String(format: "%04d", components.year ?? Calendar.current.component(.year, from: Date())))
    }

    // MARK: - UI Helper Functions & Computed Properties

    private func sectionHeader(title: String) -> some View {
        Text(title)
            .font(.system(size: 12, weight: .semibold))
            .foregroundColor(.secondary)
            .textCase(.uppercase)
            .padding(.bottom, 10)
            .padding(.top, 25)
    }

    @ViewBuilder
    private func styledTextField(placeholder: String, text: Binding<String>, focusField: FocusableField? = nil, disableAutocorrection: Bool = false) -> some View {
        TextField(placeholder, text: text)
            .textFieldStyle(PlainTextFieldStyle())
            .padding(EdgeInsets(top: 8, leading: 10, bottom: 8, trailing: 10))
            .background(Color(NSColor.textBackgroundColor))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.gray.opacity(0.4), lineWidth: 1)
            )
            .disableAutocorrection(disableAutocorrection)
            .if(focusField != nil) { view in
                view.focused($focusedField, equals: focusField)
            }
    }

    // Computed property for Person Details section
    private var personDetailsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(title: "Person Details")

            VStack(alignment: .leading, spacing: 4) {
                Text("Name").font(.caption).foregroundColor(.secondary)
                styledTextField(placeholder: "Full Name", text: $name, focusField: .name)
            }
            birthdayInputField
        }
        .padding(.horizontal)
    }
    
    // Computed property for the custom Birthday Input Field
    private var birthdayInputField: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Birthday").font(.caption).foregroundColor(.secondary)
            HStack(spacing: 0) {
                TextField("MM", text: $monthInput)
                    .textFieldStyle(PlainTextFieldStyle())
                    .frame(width: 30)
                    .multilineTextAlignment(.center)
                    .focused($focusedField, equals: .month)
                    .onChange(of: monthInput) { oldValue, newValue in handleMonthChange(newValue) }
                    .onReceive(Just(monthInput)) { newValue in
                        let filtered = newValue.filter { "0123456789".contains($0) }
                        monthInput = String(filtered.prefix(2))
                    }

                Text("/").foregroundColor(.secondary).padding(.horizontal, 2)

                TextField("DD", text: $dayInput)
                    .textFieldStyle(PlainTextFieldStyle())
                    .frame(width: 30)
                    .multilineTextAlignment(.center)
                    .focused($focusedField, equals: .day)
                    .onChange(of: dayInput) { oldValue, newValue in handleDayChange(newValue) }
                    .onReceive(Just(dayInput)) { newValue in
                        let filtered = newValue.filter { "0123456789".contains($0) }
                        dayInput = String(filtered.prefix(2))
                    }

                Text("/").foregroundColor(.secondary).padding(.horizontal, 2)

                TextField("YYYY", text: $yearInput)
                    .textFieldStyle(PlainTextFieldStyle())
                    .frame(width: 45)
                    .multilineTextAlignment(.center)
                    .focused($focusedField, equals: .year)
                    .onChange(of: yearInput) { oldValue, newValue in handleYearChange(newValue) }
                     .onReceive(Just(yearInput)) { newValue in
                        let filtered = newValue.filter { "0123456789".contains($0) }
                        yearInput = String(filtered.prefix(4))
                    }
                
                Spacer()

                Button {
                    showingDatePickerPopover = true
                } label: {
                    Image(systemName: "calendar")
                        .font(.system(size: 16))
                        .foregroundColor(.blue)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(EdgeInsets(top: 8, leading: 10, bottom: 8, trailing: 10))
            .background(Color(NSColor.textBackgroundColor))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.gray.opacity(0.4), lineWidth: 1)
            )
            .onTapGesture {
                if monthInput.isEmpty { focusedField = .month }
                else if dayInput.isEmpty { focusedField = .day }
                else if yearInput.isEmpty { focusedField = .year }
                else { focusedField = .month }
            }
            .popover(isPresented: $showingDatePickerPopover, arrowEdge: .bottom) {
                datePickerPopoverContent
            }
        }
    }

    // Computed property for Contact Information section
    private var contactInformationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(title: "Contact Information")
            VStack(alignment: .leading, spacing: 4) {
                Text("Phone Number").font(.caption).foregroundColor(.secondary)
                styledTextField(placeholder: "Optional", text: $phoneNumber)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text("Email Address").font(.caption).foregroundColor(.secondary)
                styledTextField(placeholder: "Optional", text: $emailAddress, disableAutocorrection: true)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text("Social Media URL").font(.caption).foregroundColor(.secondary) // Updated label
                // Updated placeholder and binding
                styledTextField(placeholder: "Optional (e.g., https://...)", text: $socialMediaURL, disableAutocorrection: true)
            }
        }
        .padding(.horizontal)
    }

    // Computed property for the bottom button bar
    private var bottomButtonBar: some View {
        VStack(spacing: 0) {
            Divider().padding(.bottom, 8)
            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)

                if entryToEdit != nil {
                    Button("Delete") {
                        showingDeleteConfirmation = true
                    }
                    .foregroundColor(.red)
                    .padding(.leading, 5)
                }

                Spacer()

                Button(entryToEdit == nil ? "Add" : "Save") {
                    saveEntry()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding([.horizontal, .bottom]).padding(.top, 8)
        }
    }
    
    // MARK: - Body
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    personDetailsSection
                    contactInformationSection
                }
                .padding(.vertical)
            }
            bottomButtonBar
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(NSColor.windowBackgroundColor).ignoresSafeArea(.all))
        .navigationTitle(entryToEdit == nil ? "New Birthday" : "Edit Birthday")
        .task(id: entryToEdit) {
            let dateToUse = entryToEdit?.birthday ?? Date()
            self.birthday = dateToUse
            self.name = entryToEdit?.name ?? ""
            self.phoneNumber = entryToEdit?.phoneNumber ?? ""
            self.emailAddress = entryToEdit?.emailAddress ?? ""
            // Updated to initialize socialMediaURL
            self.socialMediaURL = entryToEdit?.socialMediaURL ?? ""
            
            updateDateInputs(from: dateToUse)

            if entryToEdit == nil && self.name.isEmpty {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    focusedField = .name
                }
            } else if entryToEdit != nil && !self.name.isEmpty {
                 focusedField = nil
            }
        }
        .onChange(of: birthday) { oldValue, newValue in
            updateDateInputs(from: newValue)
        }
        .alert("Delete Birthday", isPresented: $showingDeleteConfirmation) {
            Button("Delete", role: .destructive) {
                performDelete()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Are you sure you want to delete \"\(name)\"? This action cannot be undone.")
        }
    }

    // MARK: - Popover and Date Logic
    private var datePickerPopoverContent: some View {
        VStack(spacing: 10) {
            Text("Select Birthday")
                .font(.headline)
            DatePicker(
                "",
                selection: $birthday,
                displayedComponents: .date
            )
            .datePickerStyle(.graphical)
            .labelsHidden()

            Button("Done") {
                showingDatePickerPopover = false
            }
            .padding(.top, 5)
            .keyboardShortcut(.defaultAction)
        }
        .padding()
        .frame(minWidth: 280)
    }
    
    private func updateDateInputs(from date: Date) {
        let components = Calendar.current.dateComponents([.month, .day, .year], from: date)
        monthInput = String(format: "%02d", components.month ?? 1)
        dayInput = String(format: "%02d", components.day ?? 1)
        yearInput = String(format: "%04d", components.year ?? Calendar.current.component(.year, from: Date()))
    }

    private func handleMonthChange(_ newValue: String) {
        if monthInput.count == 2 {
            if let monthVal = Int(monthInput), monthVal >= 1 && monthVal <= 12 {
                focusedField = .day
            }
        }
        attemptDateConstruction()
    }

    private func handleDayChange(_ newValue: String) {
        if dayInput.count == 2 {
             if let dayVal = Int(dayInput), dayVal >= 1 && dayVal <= 31 {
                focusedField = .year
            }
        } else if dayInput.isEmpty && focusedField == .day {
            focusedField = .month
        }
        attemptDateConstruction()
    }

    private func handleYearChange(_ newValue: String) {
        if yearInput.count == 4 {
            if let yearVal = Int(yearInput), yearVal > 1900 && yearVal < 2100 {
                 focusedField = nil
            }
        } else if yearInput.isEmpty && focusedField == .year {
            focusedField = .day
        }
        attemptDateConstruction()
    }
    
    private func attemptDateConstruction() {
        guard monthInput.count == 2, dayInput.count == 2, yearInput.count == 4,
              let month = Int(monthInput),
              let day = Int(dayInput),
              let year = Int(yearInput) else {
            return
        }

        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        
        if let date = Calendar.current.date(from: components) {
            let validComponents = Calendar.current.dateComponents([.year, .month, .day], from: date)
            if validComponents.year == year && validComponents.month == month && validComponents.day == day {
                if self.birthday != date {
                     self.birthday = date
                }
            } else {
                print("Invalid date constructed from components: \(month)/\(day)/\(year)")
            }
        } else {
             print("Could not construct date from components: \(month)/\(day)/\(year)")
        }
    }

    private func performDelete() {
        if let entry = entryToEdit {
            store.deleteEntry(entry)
            dismiss()
        }
    }

    private func saveEntry() {
        attemptDateConstruction()
        
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedName.isEmpty {
            print("Name cannot be empty.")
            return
        }

        let finalBirthday = self.birthday

        let phoneToSave = phoneNumber.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : phoneNumber.trimmingCharacters(in: .whitespacesAndNewlines)
        let emailToSave = emailAddress.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : emailAddress.trimmingCharacters(in: .whitespacesAndNewlines)
        // Updated to save socialMediaURL
        let socialToSave = socialMediaURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : socialMediaURL.trimmingCharacters(in: .whitespacesAndNewlines)

        if var updatedEntry = entryToEdit {
            updatedEntry.name = trimmedName
            updatedEntry.birthday = finalBirthday
            updatedEntry.phoneNumber = phoneToSave
            updatedEntry.emailAddress = emailToSave
            // Updated to save socialMediaURL
            updatedEntry.socialMediaURL = socialToSave
            store.updateEntry(updatedEntry)
        } else {
            // Ensure addEntry in BirthdayStore is updated to accept socialMediaURL
            // For now, assuming the parameter name in addEntry is still socialMediaHandle
            // but you'll pass the socialMediaURL value to it.
            store.addEntry(name: trimmedName,
                           birthday: finalBirthday,
                           phoneNumber: phoneToSave,
                           emailAddress: emailToSave,
                           socialMediaURL: socialToSave) // This might need to be socialMediaURL if you change addEntry
        }
        dismiss()
    }
}

// Custom ViewModifier for conditional focus (optional, but can make styledTextField cleaner)
extension View {
    @ViewBuilder func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}


// Preview
struct AddBirthdayView_Previews: PreviewProvider {
    static var previews: some View {
        let previewStore = BirthdayStore()
        let sampleEntry = BirthdayEntry(name: "Jane Doe", birthday: Calendar.current.date(byAdding: .year, value: -30, to: Date())!, phoneNumber: "555-1234",
                                        emailAddress: "jane@example.com", socialMediaURL: "https://example.com/janedoe") // Updated preview
        Group {
            NavigationView {
                AddBirthdayView(store: previewStore, entryToEdit: nil)
            }
            .previewDisplayName("New Birthday (Sheet)")
            .frame(width: 480, height: 400)

            NavigationView {
                AddBirthdayView(store: previewStore, entryToEdit: sampleEntry)
            }
            .previewDisplayName("Edit Birthday (Sheet)")
            .frame(width: 480, height: 400)
        }
    }
}
