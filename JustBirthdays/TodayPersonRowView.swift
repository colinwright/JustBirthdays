import SwiftUI

struct TodayPersonRowView: View {
    let person: Person
    
    // The onEdit closure is no longer needed, as we'll go back to tapping the row.
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(person.name)
                .font(.headline)

            if let phone = person.phoneNumber, !phone.isEmpty {
                CopyableRow(systemImage: "phone.fill", text: phone)
            }
            
            if let email = person.email, !email.isEmpty {
                CopyableRow(systemImage: "envelope.fill", text: email)
            }
            
            if let urlString = person.socialMediaURL, !urlString.isEmpty {
                CopyableRow(systemImage: "link", text: urlString)
            }
            
            if (person.phoneNumber?.isEmpty ?? true) &&
               (person.email?.isEmpty ?? true) &&
               (person.socialMediaURL?.isEmpty ?? true) {
                Text("No contact info")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .font(.subheadline)
        .padding(.vertical, 8)
    }
}

// A new, reusable subview for a row with a copy button.
private struct CopyableRow: View {
    let systemImage: String
    let text: String
    @State private var justCopied = false

    var body: some View {
        HStack {
            Label(text, systemImage: systemImage)
            Spacer()
            Button(action: copyToClipboard) {
                // The button changes to a checkmark briefly after copying.
                Image(systemName: justCopied ? "checkmark" : "doc.on.doc")
            }
            .buttonStyle(.plain)
        }
    }

    private func copyToClipboard() {
        UIPasteboard.general.string = text
        withAnimation {
            justCopied = true
        }
        // Revert the checkmark back to the copy icon after 2 seconds.
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation {
                justCopied = false
            }
        }
    }
}
