import SwiftUI

struct NewSheet: View {
    let title: String

    @Environment(\.dismiss) private var dismiss

    init(title: String = "Create new") {
        self.title = title
    }

    var body: some View {
        NavigationStack {
            Group {
                if title == "Add person authorization" {
                    PersonAuthorizationForm()
                } else {
                    genericCreateList
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if title == "Add person authorization" {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            dismiss()
                        }
                    }

                    ToolbarItem(placement: .confirmationAction) {
                        Button("Save") {
                            dismiss()
                        }
                    }
                } else {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "xmark")
                        }
                        .accessibilityLabel("Close")
                    }
                }
            }
        }
        .presentationDetents([.large])
    }

    private var genericCreateList: some View {
        List {
            Section("Create new") {
                Button {
                    dismiss()
                } label: {
                    Label("Person authorization", systemImage: "person.badge.plus")
                }

                Button {
                    dismiss()
                } label: {
                    Label("Organization", systemImage: "building.2")
                }

                Button {
                    dismiss()
                } label: {
                    Label("Equipment", systemImage: "truck.box")
                }

                Button {
                    dismiss()
                } label: {
                    Label("Appointment", systemImage: "calendar.badge.plus")
                }

                Button {
                    dismiss()
                } label: {
                    Label("Access record", systemImage: "door.left.hand.open")
                }
            }
        }
    }
}

private struct PersonAuthorizationForm: View {
    @State private var personName = ""
    @State private var organizationName = ""
    @State private var cdlNumber = ""

    @State private var title = "Driver"
    @State private var phoneNumber = ""
    @State private var emailAddress = ""
    @State private var dateOfBirth = Date()
    @State private var idCountry = ""
    @State private var dlNumber = ""
    @State private var companyCardNumber = ""
    @State private var showingMoreDetails = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Button {
                } label: {
                    Label {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Quick scan to fill in the data")
                                .font(.headline)
                                .foregroundStyle(.blue)

                            Text("Scan the driver's license.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    } icon: {
                        Image(systemName: "viewfinder.circle")
                            .font(.title2)
                            .foregroundStyle(.blue)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 14)
                    .background(.blue.opacity(0.12), in: RoundedRectangle(cornerRadius: 28))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Quick scan to fill in the data")

                PersonFormField(title: "Full name", isRequired: true) {
                    SearchableInput(
                        placeholder: "Select or enter a person",
                        text: $personName,
                        suggestions: [
                            "David Okafor",
                            "Olivia Martin",
                            "Elias Petrov"
                        ]
                    )
                }

                PersonFormField(title: "Organization name", isRequired: true) {
                    SearchableInput(
                        placeholder: "Select or enter an organization",
                        text: $organizationName,
                        suggestions: [
                            "Northstar Logistics",
                            "SafeGate Services",
                            "CargoTrucks"
                        ]
                    )
                }

                PersonFormField(title: "CDL number") {
                    TextField("Enter CDL number", text: $cdlNumber)
                        .textFieldStyle(.roundedBorder)
                }

                DisclosureGroup(isExpanded: $showingMoreDetails) {
                    VStack(alignment: .leading, spacing: 18) {
                        PersonFormField(title: "Title") {
                            Picker("Title", selection: $title) {
                                Text("Driver").tag("Driver")
                                Text("Employee").tag("Employee")
                                Text("Site Manager").tag("Site Manager")
                                Text("Contractor").tag("Contractor")
                            }
                            .pickerStyle(.menu)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 9)
                            .background(
                                .background,
                                in: RoundedRectangle(cornerRadius: 10)
                            )
                            .overlay {
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(.quaternary, lineWidth: 1)
                            }
                        }

                        PersonFormField(title: "Phone number") {
                            TextField("Enter phone number", text: $phoneNumber)
                                .keyboardType(.phonePad)
                                .textFieldStyle(.roundedBorder)
                        }

                        PersonFormField(title: "Email address") {
                            TextField("Enter email address", text: $emailAddress)
                                .keyboardType(.emailAddress)
                                .textInputAutocapitalization(.never)
                                .textFieldStyle(.roundedBorder)
                        }

                        PersonFormField(title: "Date of birth") {
                            DatePicker(
                                "Date of birth",
                                selection: $dateOfBirth,
                                displayedComponents: .date
                            )
                            .datePickerStyle(.compact)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(
                                .background,
                                in: RoundedRectangle(cornerRadius: 10)
                            )
                            .overlay {
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(.quaternary, lineWidth: 1)
                            }
                        }

                        PersonFormField(title: "ID country") {
                            Picker("ID country", selection: $idCountry) {
                                Text("Select ID country").tag("")
                                Text("United States").tag("United States")
                                Text("Canada").tag("Canada")
                            }
                            .pickerStyle(.menu)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 9)
                            .background(
                                .background,
                                in: RoundedRectangle(cornerRadius: 10)
                            )
                            .overlay {
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(.quaternary, lineWidth: 1)
                            }
                        }

                        PersonFormField(title: "DL number") {
                            TextField("Enter DL number", text: $dlNumber)
                                .textFieldStyle(.roundedBorder)
                        }

                        PersonFormField(title: "Company card number") {
                            TextField("Enter company card number", text: $companyCardNumber)
                                .textFieldStyle(.roundedBorder)
                        }
                    }
                    .padding(.top, 16)
                } label: {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("More details")
                            .font(.headline)
                            .foregroundStyle(.secondary)

                        filledDetailChips
                    }
                }
                .tint(.secondary)
            }
            .padding(20)
        }
        .scrollDismissesKeyboard(.interactively)
    }

    @ViewBuilder
    private var filledDetailChips: some View {
        HStack(spacing: 8) {
            DetailChip(title: "Title", value: title)

            if !phoneNumber.isEmpty {
                DetailChip(title: "Phone", value: phoneNumber)
            }

            if !emailAddress.isEmpty {
                DetailChip(title: "Email", value: emailAddress)
            }

            if !idCountry.isEmpty {
                DetailChip(title: "ID country", value: idCountry)
            }
        }
    }
}

private struct SearchableInput: View {
    let placeholder: String
    @Binding var text: String
    let suggestions: [String]

    @State private var showingSuggestions = false
    @FocusState private var isFocused: Bool

    private var matchingSuggestions: [String] {
        let query = text.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !query.isEmpty else {
            return suggestions
        }

        return suggestions.filter {
            $0.localizedCaseInsensitiveContains(query)
        }
    }

    var body: some View {
        TextField(placeholder, text: $text)
            .textFieldStyle(.roundedBorder)
            .focused($isFocused)
            .onChange(of: text) { _, newValue in
                showingSuggestions = isFocused && !newValue.isEmpty && !matchingSuggestions.isEmpty
            }
            .onChange(of: isFocused) { _, newValue in
                if !newValue {
                    showingSuggestions = false
                }
            }
            .popover(isPresented: $showingSuggestions) {
                List(matchingSuggestions, id: \.self) { suggestion in
                    Button(suggestion) {
                        text = suggestion
                        showingSuggestions = false
                        isFocused = false
                    }
                    .foregroundStyle(.primary)
                }
                .frame(minWidth: 280, maxHeight: 220)
            }
    }
}

private struct PersonFormField<Content: View>: View {
    let title: LocalizedStringKey
    let isRequired: Bool
    let content: () -> Content

    init(
        title: LocalizedStringKey,
        isRequired: Bool = false,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.title = title
        self.isRequired = isRequired
        self.content = content
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 3) {
                Text(title)
                    .font(.headline)

                if isRequired {
                    Text("*")
                        .font(.headline)
                        .foregroundStyle(.red)
                }
            }

            content()
        }
    }
}

private struct DetailChip: View {
    let title: String
    let value: String

    var body: some View {
        Text("\(title) \(value)")
            .font(.subheadline)
            .foregroundStyle(.primary)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(.secondary.opacity(0.1), in: Capsule())
    }
}

#Preview {
    NewSheet(title: "Add person authorization")
}
