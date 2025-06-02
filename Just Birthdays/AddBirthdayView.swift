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
    @State private var socialMediaURL: String
    @State private var notes: String

    @State private var monthInput: String
    @State private var dayInput: String
    @State private var yearInput: String

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
        let initialYearIsKnown = entryToEdit?.yearIsKnown ?? true

        _birthday = State(initialValue: initialDate)
        _name = State(initialValue: entryToEdit?.name ?? "")
        _phoneNumber = State(initialValue: entryToEdit?.phoneNumber ?? "")
        _emailAddress = State(initialValue: entryToEdit?.emailAddress ?? "")
        _socialMediaURL = State(initialValue: entryToEdit?.socialMediaURL ?? "")
        _notes = State(initialValue: entryToEdit?.notes ?? "")

        let components = Calendar.current.dateComponents([.month, .day, .year], from: initialDate)
        _monthInput = State(initialValue: String(format: "%02d", components.month ?? 1))
        _dayInput = State(initialValue: String(format: "%02d", components.day ?? 1))
        
        if initialYearIsKnown {
            _yearInput = State(initialValue: String(format: "%04d", components.year ?? Calendar.current.component(.year, from: Date())))
        } else {
            _yearInput = State(initialValue: "")
        }
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
    
    private var birthdayInputField: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Birthday").font(.caption).foregroundColor(.secondary)
            HStack(spacing: 4) {
                TextField("MM", text: $monthInput)
                    .textFieldStyle(PlainTextFieldStyle())
                    .frame(width: 35)
                    .multilineTextAlignment(.center)
                    .focused($focusedField, equals: .month)
                    .onChange(of: monthInput) { handleMonthChange($1) }
                    .onReceive(Just(monthInput)) { newValue in
                        let filtered = newValue.filter { "0123456789".contains($0) }
                        if filtered.count > 2 {
                            monthInput = String(filtered.prefix(2))
                        }
                    }

                Text("/").foregroundColor(.secondary)

                TextField("DD", text: $dayInput)
                    .textFieldStyle(PlainTextFieldStyle())
                    .frame(width: 35)
                    .multilineTextAlignment(.center)
                    .focused($focusedField, equals: .day)
                    .onChange(of: dayInput) { handleDayChange($1) }
                    .onReceive(Just(dayInput)) { newValue in
                        let filtered = newValue.filter { "0123456789".contains($0) }
                        if filtered.count > 2 {
                           dayInput = String(filtered.prefix(2))
                        }
                    }

                Text("/").foregroundColor(.secondary)

                TextField("YYYY", text: $yearInput)
                    .textFieldStyle(PlainTextFieldStyle())
                    .frame(width: 50)
                    .multilineTextAlignment(.center)
                    .focused($focusedField, equals: .year)
                    .onChange(of: yearInput) { handleYearChange($1) }
                     .onReceive(Just(yearInput)) { newValue in
                        let filtered = newValue.filter { "0123456789".contains($0) }
                        if filtered.count > 4 {
                           yearInput = String(filtered.prefix(4))
                        }
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
            
            Text("Year is optional.")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.leading, 2)
        }
    }

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
                Text("Social Media URL").font(.caption).foregroundColor(.secondary)
                styledTextField(placeholder: "Optional (e.g., https://...)", text: $socialMediaURL, disableAutocorrection: true)
            }
        }
        .padding(.horizontal)
    }
    
    private var moreInformationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(title: "More Information")
            VStack(alignment: .leading, spacing: 4) {
                Text("Notes").font(.caption).foregroundColor(.secondary)
                TextEditor(text: $notes)
                    .frame(height: 60)
                    .padding(EdgeInsets(top: 5, leading: 5, bottom: 5, trailing: 5))
                    .background(Color(NSColor.textBackgroundColor))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.4), lineWidth: 1)
                    )
            }
        }
        .padding(.horizontal)
    }

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
                .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || !isDateInputValid())
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
                    moreInformationSection
                }
                .padding(.vertical)
            }
            bottomButtonBar
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(NSColor.windowBackgroundColor).ignoresSafeArea(.all))
        .navigationTitle(entryToEdit == nil ? "New Birthday" : "Edit Birthday")
        .task {
             if entryToEdit == nil && self.name.isEmpty {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    focusedField = .name
                }
            }
        }
        .onChange(of: focusedField) { oldValue, newValue in
            if oldValue == .month {
                formatSingleDigitInput(for: $monthInput)
            }
            if oldValue == .day {
                formatSingleDigitInput(for: $dayInput)
            }
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
                updateDateInputs(from: self.birthday)
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
        yearInput = String(format: "%04d", components.year ?? 1)
    }
    
    private func formatSingleDigitInput(for binding: Binding<String>) {
        let text = binding.wrappedValue
        if let number = Int(text), number >= 1 && number <= 9 && text.count == 1 {
            binding.wrappedValue = "0\(number)"
        }
    }

    private func handleMonthChange(_ newValue: String) {
        if newValue.count == 2 {
            focusedField = .day
        }
    }

    private func handleDayChange(_ newValue: String) {
        if newValue.count == 2 {
            focusedField = .year
        } else if newValue.isEmpty && focusedField == .day {
            focusedField = .month
        }
    }

    private func handleYearChange(_ newValue: String) {
        if newValue.count == 4 {
            focusedField = nil
        }
    }
    
    private func isDateInputValid() -> Bool {
        guard let month = Int(monthInput), let day = Int(dayInput) else { return false }
        
        let year = Int(yearInput) ?? 1
        
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        
        guard let date = Calendar.current.date(from: components) else { return false }
        
        let createdComponents = Calendar.current.dateComponents([.year, .month, .day], from: date)
        return createdComponents.year == year && createdComponents.month == month && createdComponents.day == day
    }

    private func performDelete() {
        if let entry = entryToEdit {
            store.deleteEntry(entry)
            dismiss()
        }
    }

    private func saveEntry() {
        guard isDateInputValid() else { return }

        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedName.isEmpty { return }

        let phoneToSave = phoneNumber.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : phoneNumber
        let emailToSave = emailAddress.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : emailAddress
        let socialToSave = socialMediaURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : socialMediaURL
        let notesToSave = notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : notes
        let finalYearIsKnown = !yearInput.isEmpty
        
        let year = Int(yearInput) ?? 1
        let month = Int(monthInput)!
        let day = Int(dayInput)!
        
        let components = DateComponents(year: year, month: month, day: day)
        let finalBirthday = Calendar.current.date(from: components)!

        if var updatedEntry = entryToEdit {
            updatedEntry.name = trimmedName
            updatedEntry.birthday = finalBirthday
            updatedEntry.phoneNumber = phoneToSave
            updatedEntry.emailAddress = emailToSave
            updatedEntry.socialMediaURL = socialToSave
            updatedEntry.notes = notesToSave
            updatedEntry.yearIsKnown = finalYearIsKnown
            store.updateEntry(updatedEntry)
        } else {
            store.addEntry(
                name: trimmedName,
                birthday: finalBirthday,
                phoneNumber: phoneToSave,
                emailAddress: emailToSave,
                socialMediaURL: socialToSave,
                notes: notesToSave,
                yearIsKnown: finalYearIsKnown
            )
        }
        dismiss()
    }
}

// Custom ViewModifier for conditional focus
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
        let sampleEntryWithYear = BirthdayEntry(name: "Jane Doe", birthday: Calendar.current.date(byAdding: .year, value: -30, to: Date())!, phoneNumber: "555-1234",
                                        emailAddress: "jane@example.com", socialMediaURL: "https://example.com/janedoe", notes: "Loves chocolate cake.", yearIsKnown: true)
        let sampleEntryWithoutYear = BirthdayEntry(name: "John Smith", birthday: Date(), phoneNumber: nil, emailAddress: nil, socialMediaURL: nil, notes: "No year known.", yearIsKnown: false)

        Group {
            NavigationView {
                AddBirthdayView(store: previewStore, entryToEdit: nil)
            }
            .previewDisplayName("New Birthday")
            .frame(width: 480, height: 500)

            NavigationView {
                AddBirthdayView(store: previewStore, entryToEdit: sampleEntryWithYear)
            }
            .previewDisplayName("Edit Birthday (Year Known)")
            .frame(width: 480, height: 500)
            
            NavigationView {
                AddBirthdayView(store: previewStore, entryToEdit: sampleEntryWithoutYear)
            }
            .previewDisplayName("Edit Birthday (No Year)")
            .frame(width: 480, height: 500)
        }
    }
}
