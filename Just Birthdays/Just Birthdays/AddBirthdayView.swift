import SwiftUI
import Combine
import CoreData
import WidgetKit

struct AddBirthdayView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.managedObjectContext) private var viewContext

    var personToEdit: Person?

    @State private var name: String
    @State private var birthday: Date
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
    
    init(personToEdit: Person?) {
        self.personToEdit = personToEdit
        
        let initialDate = personToEdit?.wrappedBirthday ?? Date()
        let initialYearIsKnown = personToEdit?.yearIsKnown ?? true

        _birthday = State(initialValue: initialDate)
        _name = State(initialValue: personToEdit?.wrappedName ?? "")
        _phoneNumber = State(initialValue: personToEdit?.phoneNumber ?? "")
        _emailAddress = State(initialValue: personToEdit?.emailAddress ?? "")
        _socialMediaURL = State(initialValue: personToEdit?.socialMediaURL ?? "")
        _notes = State(initialValue: personToEdit?.notes ?? "")

        let components = Calendar.current.dateComponents([.month, .day, .year], from: initialDate)
        _monthInput = State(initialValue: String(format: "%02d", components.month ?? 1))
        _dayInput = State(initialValue: String(format: "%02d", components.day ?? 1))
        
        if initialYearIsKnown, let year = components.year {
            _yearInput = State(initialValue: String(format: "%04d", year))
        } else {
            _yearInput = State(initialValue: "")
        }
    }

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
        .frame(minWidth: 480, idealWidth: 480, maxWidth: 480, minHeight: 500)
        .background(Color(NSColor.windowBackgroundColor).ignoresSafeArea(.all))
        .navigationTitle(personToEdit == nil ? "New Birthday" : "Edit Birthday")
        .task {
            if personToEdit == nil && self.name.isEmpty {
                focusedField = .name
            }
        }
        .onChange(of: focusedField) { oldValue, newValue in
            if oldValue == .month { formatSingleDigitInput(for: $monthInput) }
            if oldValue == .day { formatSingleDigitInput(for: $dayInput) }
        }
        .alert("Delete Birthday", isPresented: $showingDeleteConfirmation) {
            Button("Delete", role: .destructive) { performDelete() }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Are you sure you want to delete \"\(name)\"? This action cannot be undone.")
        }
    }
    
    private func saveEntry() {
        guard isDateInputValid() else { return }

        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedName.isEmpty { return }

        let person = personToEdit ?? Person(context: viewContext)
        
        person.name = trimmedName
        person.phoneNumber = phoneNumber.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty()
        person.emailAddress = emailAddress.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty()
        person.socialMediaURL = socialMediaURL.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty()
        person.notes = notes.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty()
        person.yearIsKnown = !yearInput.isEmpty
        
        let month = Int(monthInput)!
        let day = Int(dayInput)!
        let year = yearInput.isEmpty ? nil : Int(yearInput)
        
        let components = DateComponents(year: year, month: month, day: day)
        person.birthday = Calendar.current.date(from: components)!

        do {
            try viewContext.save()
            WidgetDataController.shared.updateWidgetData(using: viewContext)
            dismiss()
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
    }
    
    private func performDelete() {
        guard let person = personToEdit else { return }
        viewContext.delete(person)
        do {
            try viewContext.save()
            WidgetDataController.shared.updateWidgetData(using: viewContext)
            dismiss()
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
    }
    
    // MARK: - UI Helpers
    
    private func sectionHeader(title: String) -> some View {
        Text(title)
            .font(.system(size: 12, weight: .semibold))
            .foregroundColor(.secondary)
            .textCase(.uppercase)
            .padding(.bottom, 10)
            .padding(.top, 25)
    }

    private func styledTextField(placeholder: String, text: Binding<String>, focusField: FocusableField? = nil, disableAutocorrection: Bool = false) -> some View {
        TextField(placeholder, text: text)
            .textFieldStyle(PlainTextFieldStyle())
            .padding(EdgeInsets(top: 8, leading: 10, bottom: 8, trailing: 10))
            .background(Color(NSColor.textBackgroundColor))
            .cornerRadius(8)
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.4), lineWidth: 1))
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
                    .textFieldStyle(PlainTextFieldStyle()).frame(width: 35).multilineTextAlignment(.center)
                    .focused($focusedField, equals: .month)
                    .onChange(of: monthInput) { handleMonthChange($1) }
                    .onReceive(Just(monthInput)) { monthInput = String($0.filter { "0123456789".contains($0) }.prefix(2)) }

                Text("/").foregroundColor(.secondary)

                TextField("DD", text: $dayInput)
                    .textFieldStyle(PlainTextFieldStyle()).frame(width: 35).multilineTextAlignment(.center)
                    .focused($focusedField, equals: .day)
                    .onChange(of: dayInput) { handleDayChange($1) }
                    .onReceive(Just(dayInput)) { dayInput = String($0.filter { "0123456789".contains($0) }.prefix(2)) }

                Text("/").foregroundColor(.secondary)

                TextField("YYYY", text: $yearInput)
                    .textFieldStyle(PlainTextFieldStyle()).frame(width: 50).multilineTextAlignment(.center)
                    .focused($focusedField, equals: .year)
                    .onChange(of: yearInput) { handleYearChange($1) }
                    .onReceive(Just(yearInput)) { yearInput = String($0.filter { "0123456789".contains($0) }.prefix(4)) }
                                
                Spacer()

                Button { showingDatePickerPopover = true } label: { Image(systemName: "calendar").font(.system(size: 16)) }
                    .buttonStyle(PlainButtonStyle()).foregroundColor(.accentColor)
            }
            .padding(EdgeInsets(top: 8, leading: 10, bottom: 8, trailing: 10))
            .background(Color(NSColor.textBackgroundColor))
            .cornerRadius(8)
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.4), lineWidth: 1))
            .popover(isPresented: $showingDatePickerPopover, arrowEdge: .bottom) { datePickerPopoverContent }
            
            Text("Year is optional.").font(.caption).foregroundColor(.secondary).padding(.leading, 2)
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
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.4), lineWidth: 1))
            }
        }
        .padding(.horizontal)
    }

    private var bottomButtonBar: some View {
        VStack(spacing: 0) {
            Divider().padding(.bottom, 8)
            HStack {
                Button("Cancel") { dismiss() }.keyboardShortcut(.cancelAction)

                if personToEdit != nil {
                    Button("Delete") { showingDeleteConfirmation = true }.foregroundColor(.red).padding(.leading, 5)
                }
                Spacer()
                Button(personToEdit == nil ? "Add" : "Save") { saveEntry() }
                    .keyboardShortcut(.defaultAction)
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || !isDateInputValid())
            }
            .padding([.horizontal, .bottom]).padding(.top, 8)
        }
    }
    
    private var datePickerPopoverContent: some View {
        VStack(spacing: 10) {
             Text("Select Birthday")
                .font(.headline)
            DatePicker("", selection: $birthday, displayedComponents: .date)
                .datePickerStyle(.graphical).labelsHidden()
            Button("Done") {
                updateDateInputs(from: self.birthday)
                showingDatePickerPopover = false
            }
            .padding(.top, 5).keyboardShortcut(.defaultAction)
        }
        .padding().frame(minWidth: 280)
    }
    
    private func updateDateInputs(from date: Date) {
        let components = Calendar.current.dateComponents([.month, .day, .year], from: date)
        monthInput = String(format: "%02d", components.month ?? 1)
        dayInput = String(format: "%02d", components.day ?? 1)
        if !yearInput.isEmpty, let year = components.year {
             yearInput = String(format: "%04d", year)
        }
    }
    
    private func formatSingleDigitInput(for binding: Binding<String>) {
        let text = binding.wrappedValue
        if let number = Int(text), number >= 1 && number <= 9 && text.count == 1 {
            binding.wrappedValue = "0\(number)"
        }
    }

    private func handleMonthChange(_ newValue: String) { if newValue.count == 2 { focusedField = .day } }
    private func handleDayChange(_ newValue: String) { if newValue.count == 2 { focusedField = .year } else if newValue.isEmpty { focusedField = .month } }
    private func handleYearChange(_ newValue: String) { if newValue.count == 4 { focusedField = nil } }
    
    private func isDateInputValid() -> Bool {
        guard let month = Int(monthInput), let day = Int(dayInput) else { return false }
        
        let year: Int
        if let y = Int(yearInput), !yearInput.isEmpty {
            year = y
        } else {
            year = 2024
        }
        
        var components = DateComponents()
        components.year = year; components.month = month; components.day = day
        
        guard let date = Calendar.current.date(from: components) else { return false }
        
        let createdComponents = Calendar.current.dateComponents([.year, .month, .day], from: date)
        return createdComponents.year == year && createdComponents.month == month && createdComponents.day == day
    }
}

fileprivate extension View {
    @ViewBuilder func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition { transform(self) } else { self }
    }
}

fileprivate extension String {
    func nilIfEmpty() -> String? {
        self.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : self
    }
}
