import SwiftUI
import Combine

struct AddEditPersonView: View {
    @Bindable var person: Person
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    let isNew: Bool
    
    @State private var showingDeleteConfirmation = false
    @State private var birthdayInputMode: BirthdayInputMode = .input
    
    @FocusState private var focusedField: FocusableField?
    
    enum FocusableField: Hashable {
        case name, month, day, year, phone, email, social, notes
    }
    
    private enum BirthdayInputMode: String, CaseIterable, Identifiable {
        case input = "Input"
        case calendar = "Calendar"
        var id: Self { self }
    }
    
    private var isFormValid: Bool {
        !person.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Person") {
                    TextField("Full Name", text: $person.name)
                        .focused($focusedField, equals: .name)
                        .onSubmit { focusedField = .month }
                }
                
                Section {
                    VStack(spacing: 12) {
                        Picker("Input Style", selection: $birthdayInputMode) {
                            ForEach(BirthdayInputMode.allCases) { mode in
                                Text(mode.rawValue).tag(mode)
                            }
                        }
                        .pickerStyle(.segmented)
                        .onChange(of: birthdayInputMode) {
                            focusedField = nil
                        }
                        
                        if birthdayInputMode == .calendar {
                            DatePicker("Date", selection: $person.birthday, displayedComponents: .date)
                                .datePickerStyle(.graphical)
                        } else {
                            BirthdayTextFieldsView(birthday: $person.birthday, focusedField: $focusedField)
                        }
                    }
                    .padding(.vertical, 8)
                } header: {
                    Text("Birthday")
                } footer: {
                    if birthdayInputMode == .input {
                        Text("The fields are ordered month, day, year (and the year is optional).")
                    }
                }

                Section("Contact Information") {
                    LabeledContent {
                        TextField("Optional", text: Binding(
                            get: { person.phoneNumber ?? "" },
                            set: { person.phoneNumber = $0.isEmpty ? nil : $0 }
                        ))
                        .keyboardType(.phonePad)
                        .multilineTextAlignment(.trailing)
                        .focused($focusedField, equals: .phone)
                        .onSubmit { focusedField = .email }
                    } label: { Label("Phone", systemImage: "phone.fill") }
                    
                    LabeledContent {
                        TextField("Optional", text: Binding(
                            get: { person.email ?? "" },
                            set: { person.email = $0.isEmpty ? nil : $0 }
                        ))
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .multilineTextAlignment(.trailing)
                        .focused($focusedField, equals: .email)
                        .onSubmit { focusedField = .social }
                    } label: { Label("Email", systemImage: "envelope.fill") }

                    LabeledContent {
                        TextField("Optional", text: Binding(
                            get: { person.socialMediaURL ?? "" },
                            set: { person.socialMediaURL = $0.isEmpty ? nil : $0 }
                        ))
                        .keyboardType(.URL)
                        .textInputAutocapitalization(.never)
                        .multilineTextAlignment(.trailing)
                        .focused($focusedField, equals: .social)
                        .onSubmit { focusedField = .notes }
                    } label: { Label("Social", systemImage: "link") }
                }

                Section("Notes") {
                    TextField("Add any relevant notes...", text: Binding(
                        get: { person.notes ?? "" },
                        set: { person.notes = $0.isEmpty ? nil : $0 }
                    ), axis: .vertical)
                    .lineLimit(5...)
                    .focused($focusedField, equals: .notes)
                }
                
                if !isNew {
                    Section {
                        Button("Delete Person", role: .destructive) {
                            showingDeleteConfirmation = true
                        }
                    }
                }
            }
            .navigationTitle(isNew ? "New Birthday" : "Edit Birthday")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel", role: .cancel) { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button("Save", action: save).disabled(!isFormValid) }
            }
            .alert("Delete Birthday?", isPresented: $showingDeleteConfirmation) {
                Button("Delete", role: .destructive, action: deletePerson)
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("Are you sure you want to delete this birthday? This action cannot be undone.")
            }
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    if isNew {
                        focusedField = .name
                    } else {
                        focusedField = nil
                    }
                }
            }
        }
    }
    
    private func save() {
        if isNew {
            modelContext.insert(person)
        }
        dismiss()
    }
    
    private func deletePerson() {
        modelContext.delete(person)
        dismiss()
    }
}

fileprivate struct BirthdayTextFieldsView: View {
    @Binding var birthday: Date
    @FocusState.Binding var focusedField: AddEditPersonView.FocusableField?
    
    @State private var monthString: String = ""
    @State private var dayString: String = ""
    @State private var yearString: String = ""
    
    var body: some View {
        HStack {
            SelectAllTextField(text: $monthString, placeholder: "MM")
                .frame(width: 50)
                .focused($focusedField, equals: .month)
                .onChange(of: monthString) { _, newValue in
                    let newString = String(newValue.filter { "0123456789".contains($0) }.prefix(2))
                    monthString = newString
                    if focusedField == .month && newString.count == 2 {
                        focusedField = .day
                    }
                }

            SelectAllTextField(text: $dayString, placeholder: "DD")
                .frame(width: 50)
                .focused($focusedField, equals: .day)
                .onChange(of: dayString) { _, newValue in
                    let newString = String(newValue.filter { "0123456789".contains($0) }.prefix(2))
                    dayString = newString
                    if focusedField == .day && newString.count == 2 {
                        focusedField = .year
                    }
                }

            SelectAllTextField(text: $yearString, placeholder: "YYYY")
                .frame(minWidth: 70)
                .focused($focusedField, equals: .year)
                .onChange(of: yearString) { _, newValue in
                    let newString = String(newValue.filter { "0123456789".contains($0) }.prefix(4))
                    yearString = newString
                    if focusedField == .year && newString.count == 4 {
                        focusedField = .phone
                    }
                }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .onAppear(perform: setFieldsFromDate)
        .onChange(of: focusedField) { _, newFocus in
            if newFocus != .month && newFocus != .day && newFocus != .year {
                updateDateFromFields()
            }
        }
        .onChange(of: birthday) {
            if focusedField == nil {
                setFieldsFromDate()
            }
        }
    }
    
    private func setFieldsFromDate() {
        let components = Calendar.current.dateComponents([.month, .day, .year], from: birthday)
        monthString = String(format: "%02d", components.month ?? 1)
        dayString = String(format: "%02d", components.day ?? 1)
        
        if let year = components.year, year != Person.defaultYear {
            yearString = String(format: "%04d", year)
        } else {
            yearString = ""
        }
    }
    
    private func updateDateFromFields() {
        if let month = Int(monthString) { monthString = String(format: "%02d", month) }
        if let day = Int(dayString) { dayString = String(format: "%02d", day) }
        
        var components = DateComponents()
        let month = Int(monthString) ?? 1
        components.month = min(max(month, 1), 12)
        components.year = Int(yearString) ?? Person.defaultYear
        let day = Int(dayString) ?? 1
        let maxDay = maxDays(forMonth: components.month!, year: components.year!)
        components.day = min(max(day, 1), maxDay)
        
        if let newDate = Calendar.current.date(from: components) {
            birthday = newDate
        }
    }
    
    private func maxDays(forMonth month: Int, year: Int) -> Int {
        var components = DateComponents()
        components.year = year
        components.month = month + 1
        components.day = 0
        
        if let date = Calendar.current.date(from: components) {
            return Calendar.current.component(.day, from: date)
        }
        return 31
    }
}

fileprivate struct SelectAllTextField: UIViewRepresentable {
    @Binding var text: String
    let placeholder: String

    func makeUIView(context: Context) -> UITextField {
        let textField = UITextField()
        textField.placeholder = placeholder
        textField.keyboardType = .numberPad
        textField.borderStyle = .roundedRect
        textField.textAlignment = .center
        textField.delegate = context.coordinator
        
        textField.addTarget(context.coordinator, action: #selector(Coordinator.textFieldDidChange(_:)), for: .editingChanged)
        
        return textField
    }

    func updateUIView(_ uiView: UITextField, context: Context) {
        uiView.text = text
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UITextFieldDelegate {
        var parent: SelectAllTextField

        init(_ textField: SelectAllTextField) {
            self.parent = textField
        }
        
        @objc func textFieldDidChange(_ textField: UITextField) {
            parent.text = textField.text ?? ""
        }

        func textFieldDidBeginEditing(_ textField: UITextField) {
            DispatchQueue.main.async {
                textField.selectAll(nil)
            }
        }
    }
}
