import SwiftUI
import PhotosUI
import UniformTypeIdentifiers
import UIKit

struct AddPersonAuthorizationView: View {

    private enum QuickScanState {
        case empty
        case scanning
        case success
    }

    @Environment(\.dismiss)

    private var dismiss

    @State private var fullName = ""

    @State private var organization = ""

    @State private var cdlNumber = ""

    @State private var title = "Driver"

    @State private var phoneNumber = ""

    @State private var emailAddress = ""

    @State private var dateOfBirth: Date?

    @State private var idCountry = "Canada"

    @State private var dlNumber = ""

    @State private var companyCardNumber = ""

    @State private var accessPolicy = AccessPolicy()

    @State private var moreDetailsExpanded = false

    @State private var showingDatePicker = false

    @State private var showingAccessPolicy = false

    @State private var selectedExistingPerson: ExistingPerson?

    @State private var quickScanState: QuickScanState = .empty
    @State private var scannedImage: UIImage?
    @State private var showingScanOptions = false
    @State private var showingCamera = false
    @State private var showingPhotos = false
    @State private var showingFiles = false
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var showingCDLConfirmation = false

    @FocusState

    private var focusedField: Field?

    private enum Field {

        case fullName

        case organization

        case cdl

        case phone

        case email

        case dlNumber

        case companyCardNumber

    }



    // MARK: Existing People

    private let existingPeople: [ExistingPerson] = [

        ExistingPerson(

            fullName: "David Okafor",

            organization: "Northstar Logistics",

            title: "Driver",

            cdlNumber: "CDL-483920",

            phoneNumber: "+1 416 555 0182",

            emailAddress: "david.okafor@northstar.com",

            dateOfBirth: nil,

            idCountry: "Canada",

            dlNumber: "ON-829104",

            companyCardNumber: "NS-2841"

        ),

        ExistingPerson(

            fullName: "Olivia Martin",

            organization: "CargoTrucks",

            title: "Site supervisor",

            cdlNumber: "",

            phoneNumber: "+1 647 555 0197",

            emailAddress: "olivia@cargotrucks.com",

            dateOfBirth: nil,

            idCountry: "Canada",

            dlNumber: "",

            companyCardNumber: "CT-1108"

        ),

        ExistingPerson(

            fullName: "Elias Petrov",

            organization: "SafeGate Services",

            title: "Contractor",

            cdlNumber: "",

            phoneNumber: "+1 905 555 0144",

            emailAddress: "elias@safegate.com",

            dateOfBirth: nil,

            idCountry: "Canada",

            dlNumber: "",

            companyCardNumber: "SG-0292"

        ),

        ExistingPerson(

            fullName: "Milan Jović",

            organization: "Bison Transport",

            title: "Driver",

            cdlNumber: "CDL-882013",

            phoneNumber: "+1 204 555 0124",

            emailAddress: "milan.jovic@bisontransport.com",

            dateOfBirth: nil,

            idCountry: "Canada",

            dlNumber: "MB-420931",

            companyCardNumber: ""

        ),

        ExistingPerson(

            fullName: "Gurpreet Singh",

            organization: "Honda Dealership",

            title: "Driver",

            cdlNumber: "CDL-109274",

            phoneNumber: "+1 416 555 0168",

            emailAddress: "gurpreet@honda.com",

            dateOfBirth: nil,

            idCountry: "Canada",

            dlNumber: "ON-520184",

            companyCardNumber: "HD-4412"

        )

    ]

    private let titles = [

        "Driver",

        "Employee",

        "Contractor",

        "Visitor",

        "Supervisor"

    ]

    private let countries = [

        "Canada",

        "United States",

        "Mexico",

        "United Kingdom",

        "France",

        "Germany"

    ]



    // MARK: Search

    private var cleanFullName: String {

        fullName.trimmingCharacters(

            in: .whitespacesAndNewlines

        )

    }

    private var filteredPeople: [ExistingPerson] {

        guard !cleanFullName.isEmpty else {

            return []

        }

        return existingPeople

            .filter { person in

                person.fullName

                    .localizedCaseInsensitiveContains(

                        cleanFullName

                    )

                ||

                person.organization

                    .localizedCaseInsensitiveContains(

                        cleanFullName

                    )

            }

            .prefix(3)

            .map { $0 }

    }

    private var shouldShowPeopleSuggestions: Bool {

        focusedField == .fullName &&

        !cleanFullName.isEmpty &&

        selectedExistingPerson == nil

    }



    // MARK: Validation

    private var canSave: Bool {

        !cleanFullName.isEmpty &&

        !organization

            .trimmingCharacters(

                in: .whitespacesAndNewlines

            )

            .isEmpty

    }



    // MARK: Body

    var body: some View {

        NavigationStack {

            Form {

                quickScanSection

                VStack(

                    alignment: .leading,

                    spacing: 14

                ) {

                    fullNameField

                    organizationField

                    cdlField

                    moreDetailsArea

                    accessPolicyArea

                }

                .listRowInsets(

                    EdgeInsets(

                        top: 4,

                        leading: 0,

                        bottom: 4,

                        trailing: 0

                    )

                )

                .listRowSeparator(.hidden)

                .listRowBackground(Color.clear)

            }

            .contentMargins(

                .top,

                8,

                for: .scrollContent

            )

            .scrollDismissesKeyboard(

                .interactively

            )

            .navigationTitle(

                "Add person"

            )

            .navigationBarTitleDisplayMode(

                .inline

            )

            .toolbar {

                ToolbarItem(

                    placement: .cancellationAction

                ) {

                    Button("Cancel") {

                        focusedField = nil

                        dismiss()

                    }

                }

                ToolbarItem(

                    placement: .confirmationAction

                ) {

                    Button("Save") {

                        save()

                    }

                    .buttonStyle(.glassProminent)

                    .tint(.blue)

                    .disabled(!canSave)

                }

            }
            .alert(
                "CDL number improves security",
                isPresented: $showingCDLConfirmation
            ) {
                Button("Continue without CDL number") {
                    savePerson()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Adding a CDL number helps us verify the driver's identity.\nAre you sure you want to continue without one?")
            }
            .photosPicker(
                isPresented: $showingPhotos,
                selection: $selectedPhotoItem,
                matching: .images,
                photoLibrary: .shared()
            )
            .onChange(of: selectedPhotoItem) { _, newItem in
                guard let newItem else { return }
                Task {
                    guard let data = try? await newItem.loadTransferable(type: Data.self),
                          let image = UIImage(data: data) else { return }
                    await MainActor.run {
                        handleScannedImage(image)
                        selectedPhotoItem = nil
                    }
                }
            }
            .fileImporter(
                isPresented: $showingFiles,
                allowedContentTypes: [.image],
                allowsMultipleSelection: false
            ) { result in
                guard case .success(let urls) = result, let url = urls.first else { return }
                let hasAccess = url.startAccessingSecurityScopedResource()
                defer { if hasAccess { url.stopAccessingSecurityScopedResource() } }
                guard let data = try? Data(contentsOf: url),
                      let image = UIImage(data: data) else { return }
                handleScannedImage(image)
            }
            .sheet(isPresented: $showingCamera) {
                CameraPicker { image in
                    showingCamera = false
                    handleScannedImage(image)
                }
                .ignoresSafeArea()
            }

            .sheet(

                isPresented: $showingDatePicker

            ) {

                datePickerSheet

            }

            .sheet(

                item: $selectedExistingPerson

            ) { person in

                EditPersonAuthorizationView(

                    person: person

                )

            }

            .sheet(

                isPresented: $showingAccessPolicy

            ) {

                AccessPolicyEditorView(

                    policy: accessPolicy

                ) { updatedPolicy in

                    accessPolicy = updatedPolicy

                }

            }

        }

    }



    // MARK: Quick Scan

    private var quickScanSection: some View {
        Section {
            Button {
                focusedField = nil
                showingScanOptions = true
            } label: {
                HStack(spacing: 12) {
                    Group {
                        if let scannedImage {
                            Image(uiImage: scannedImage)
                                .resizable()
                                .scaledToFill()
                        } else {
                            Image(systemName: "text.viewfinder")
                                .font(.title3.weight(.semibold))
                                .foregroundStyle(.blue)
                        }
                    }
                    .frame(width: 44, height: 44)
                    .background(
                        scannedImage == nil ? Color.blue.opacity(0.08) : Color.clear,
                        in: RoundedRectangle(cornerRadius: 10, style: .continuous)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

                    VStack(alignment: .leading, spacing: 3) {
                        switch quickScanState {
                        case .empty:
                            Text("Quick scan")
                                .font(.body.weight(.semibold))
                                .foregroundStyle(.blue)
                            Text("Scan the driver's license to fill in the data.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)

                        case .scanning:
                            Text("Scanning license...")
                                .font(.body.weight(.semibold))
                            HStack(spacing: 7) {
                                ProgressView().controlSize(.small)
                                Text("Reading driver information")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }

                        case .success:
                            HStack(spacing: 6) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                                Text("License scanned")
                                    .font(.body.weight(.semibold))
                            }
                            Text("Driver information was filled in.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }

                    
                }
                .padding(.vertical, 2)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .disabled(quickScanState == .scanning)
            .confirmationDialog(
                "Quick scan",
                isPresented: $showingScanOptions,
                titleVisibility: .visible
            ) {
                Button("Camera", systemImage: "camera") { showingCamera = true }
                Button("Photos", systemImage: "photo") { showingPhotos = true }
                Button("Files", systemImage: "folder") { showingFiles = true }
                Button("Cancel", role: .cancel) {}
            }
        }
    }

    // MARK: Full Name

    private var fullNameField: some View {

        VStack(

            alignment: .leading,

            spacing: 6

        ) {

            fieldLabel(

                "Full name",

                required: true

            )

            VStack(spacing: 0) {

                TextField(

                    "Enter full name",

                    text: $fullName

                )

                .focused(

                    $focusedField,

                    equals: .fullName

                )

                .textContentType(.name)

                .textInputAutocapitalization(

                    .words

                )

                .submitLabel(.next)

                .padding(.horizontal, 16)

                .frame(

                    maxWidth: .infinity,

                    minHeight: 52,

                    alignment: .leading

                )

                .onSubmit {

                    focusedField = .organization

                }

                if shouldShowPeopleSuggestions {

                    Divider()

                        .padding(.leading, 16)

                    existingPeopleSuggestions

                }

            }

            .background(

                Color(

                    .secondarySystemGroupedBackground

                ),

                in: RoundedRectangle(

                    cornerRadius: 20,

                    style: .continuous

                )

            )

            .clipShape(

                RoundedRectangle(

                    cornerRadius: 20,

                    style: .continuous

                )

            )

        }

    }



    // MARK: Organization

    private var organizationField: some View {

        formField(

            title: "Organization name",

            required: true

        ) {

            TextField(

                "Enter organization name",

                text: $organization

            )

            .focused(

                $focusedField,

                equals: .organization

            )

            .textContentType(

                .organizationName

            )

            .textInputAutocapitalization(

                .words

            )

            .submitLabel(.next)

            .onSubmit {

                focusedField = .cdl

            }

        }

    }



    // MARK: CDL

    private var cdlField: some View {

        formField(

            title: "CDL number"

        ) {

            TextField(

                "Optional",

                text: $cdlNumber

            )

            .focused(

                $focusedField,

                equals: .cdl

            )

            .textInputAutocapitalization(

                .characters

            )

            .autocorrectionDisabled()

            .submitLabel(.done)

            .onSubmit {

                focusedField = nil

            }

        }

    }



    // MARK: Existing People

    @ViewBuilder

    private var existingPeopleSuggestions: some View {

        if filteredPeople.isEmpty {

            HStack(spacing: 10) {

                Image(

                    systemName: "magnifyingglass"

                )

                .foregroundStyle(.secondary)

                Text("No existing people found")

                    .font(.subheadline)

                    .foregroundStyle(.secondary)

                Spacer()

            }

            .padding(.horizontal, 16)

            .frame(minHeight: 52)

        } else {

            VStack(spacing: 0) {

                ForEach(

                    Array(

                        filteredPeople.enumerated()

                    ),

                    id: \.element.id

                ) { index, person in

                    Button {

                        focusedField = nil

                        DispatchQueue.main.async {

                            selectedExistingPerson = person

                        }

                    } label: {

                        HStack(spacing: 12) {

                            Image(

                                systemName:

                                    "person.crop.circle.fill"

                            )

                            .font(.title2)

                            .foregroundStyle(.blue)

                            .frame(

                                width: 32,

                                height: 32

                            )

                            VStack(

                                alignment: .leading,

                                spacing: 2

                            ) {

                                Text(person.fullName)

                                    .font(

                                        .body.weight(.medium)

                                    )

                                    .foregroundStyle(.primary)

                                Text(person.subtitle)

                                    .font(.subheadline)

                                    .foregroundStyle(.secondary)

                            }

                            Spacer()

                            Image(

                                systemName: "chevron.right"

                            )

                            .font(

                                .caption.weight(.semibold)

                            )

                            .foregroundStyle(.tertiary)

                        }

                        .padding(.horizontal, 16)

                        .frame(minHeight: 58)

                        .contentShape(Rectangle())

                    }

                    .buttonStyle(.plain)

                    if index < filteredPeople.count - 1 {

                        Divider()

                            .padding(.leading, 60)

                    }

                }

            }

        }

    }



    // MARK: More Details

    private var moreDetailsArea: some View {

        VStack(

            alignment: .leading,

            spacing: 10

        ) {

            moreDetailsDisclosure

            if moreDetailsExpanded {

                moreDetailsFields

                    .transition(.opacity)

            }

        }

    }



    private var moreDetailsDisclosure: some View {

        Button {

            focusedField = nil

            moreDetailsExpanded.toggle()

        } label: {

            VStack(

                alignment: .leading,

                spacing: 8

            ) {

                HStack {

                    Text("More details")

                        .font(

                            .subheadline.weight(.semibold)

                        )

                        .foregroundStyle(.secondary)

                    Spacer()

                    Image(

                        systemName:

                            moreDetailsExpanded

                            ? "chevron.up"

                            : "chevron.down"

                    )

                    .font(

                        .caption.weight(.semibold)

                    )

                    .foregroundStyle(.secondary)

                }

                if !moreDetailsExpanded {

                    MoreDetailsChips(

                        title: title,

                        phoneNumber: phoneNumber,

                        emailAddress: emailAddress,

                        dateOfBirth: dateOfBirth,

                        idCountry: idCountry,

                        dlNumber: dlNumber,

                        companyCardNumber: companyCardNumber

                    )

                    .transition(.opacity)

                }

            }

            .padding(.horizontal, 16)

            .contentShape(Rectangle())

        }

        .buttonStyle(.plain)

    }

    private var moreDetailsFields: some View {

        VStack(spacing: 0) {

            titleMenu

            rowDivider

            detailsRow(

                title: "Phone number"

            ) {

                TextField(

                    "Optional",

                    text: $phoneNumber

                )

                .focused(

                    $focusedField,

                    equals: .phone

                )

                .keyboardType(.phonePad)

                .multilineTextAlignment(

                    .trailing

                )

            }

            rowDivider

            detailsRow(

                title: "Email"

            ) {

                TextField(

                    "Optional",

                    text: $emailAddress

                )

                .focused(

                    $focusedField,

                    equals: .email

                )

                .keyboardType(.emailAddress)

                .textInputAutocapitalization(

                    .never

                )

                .autocorrectionDisabled()

                .multilineTextAlignment(

                    .trailing

                )

            }

            rowDivider

            Button {

                focusedField = nil

                showingDatePicker = true

            } label: {

                detailsActionRow(

                    title: "Date of birth",

                    value:

                        dateOfBirth?.formatted(

                            date: .abbreviated,

                            time: .omitted

                        )

                        ?? "Add"

                )

            }

            .buttonStyle(.plain)

            rowDivider

            countryMenu

            rowDivider

            detailsRow(

                title: "DL number"

            ) {

                TextField(

                    "Optional",

                    text: $dlNumber

                )

                .focused(

                    $focusedField,

                    equals: .dlNumber

                )

                .multilineTextAlignment(

                    .trailing

                )

            }

            rowDivider

            detailsRow(

                title: "Company card number"

            ) {

                TextField(

                    "Optional",

                    text: $companyCardNumber

                )

                .focused(

                    $focusedField,

                    equals: .companyCardNumber

                )

                .multilineTextAlignment(

                    .trailing

                )

            }

        }

        .background(

            Color(

                .secondarySystemGroupedBackground

            ),

            in: RoundedRectangle(

                cornerRadius: 20,

                style: .continuous

            )

        )

    }



    // MARK: Access Policy

    private var accessPolicyArea: some View {

        Button {

            focusedField = nil

            showingAccessPolicy = true

        } label: {

            VStack(

                alignment: .leading,

                spacing: 12

            ) {

                HStack {

                    Text("Access policy")

                        .font(.subheadline.weight(.semibold))

                        .foregroundStyle(.blue)

                    Spacer()

                    Image(systemName: "chevron.right")

                        .font(.caption.weight(.semibold))

                        .foregroundStyle(.tertiary)

                }

                HStack(spacing: 8) {

                    Label(

                        accessPolicy.locations,

                        systemImage: "mappin.and.ellipse"

                    )

                    .font(.subheadline)

                    .foregroundStyle(.primary)

                    .lineLimit(1)

                    Spacer(minLength: 6)

                    AccessTypeChip(

                        accessType: accessPolicy.accessType,

                        periodAccess: accessPolicy.periodAccess,

                        hasNote: !accessPolicy.note

                            .trimmingCharacters(

                                in: .whitespacesAndNewlines

                            )

                            .isEmpty,

                        isLimitedTime: accessPolicy.limitedTimeAccess

                    )



                }

            }

            .padding(.horizontal, 16)

            .padding(.vertical, 14)

            .frame(

                maxWidth: .infinity,

                alignment: .leading

            )

            .background(

                Color(.secondarySystemGroupedBackground),

                in: RoundedRectangle(

                    cornerRadius: 20,

                    style: .continuous

                )

            )

            .contentShape(Rectangle())

        }

        .buttonStyle(.plain)

    }

    // MARK: Menus

    private var titleMenu: some View {

        Menu {

            ForEach(

                titles,

                id: \.self

            ) { item in

                Button {

                    title = item

                } label: {

                    if title == item {

                        Label(

                            item,

                            systemImage: "checkmark"

                        )

                    } else {

                        Text(item)

                    }

                }

            }

        } label: {

            menuRow(

                label: "Title",

                value: title

            )

        }

        .buttonStyle(.plain)

    }



    private var countryMenu: some View {

        Menu {

            ForEach(

                countries,

                id: \.self

            ) { country in

                Button {

                    idCountry = country

                } label: {

                    if idCountry == country {

                        Label(

                            country,

                            systemImage: "checkmark"

                        )

                    } else {

                        Text(country)

                    }

                }

            }

        } label: {

            menuRow(

                label: "ID country",

                value: idCountry

            )

        }

        .buttonStyle(.plain)

    }



    // MARK: Helpers

    private func fieldLabel(

        _ title: String,

        required: Bool = false

    ) -> some View {

        HStack(spacing: 2) {

            Text(title)

                .font(

                    .subheadline.weight(.semibold)

                )

                .foregroundStyle(.secondary)

            if required {

                Text("*")

                    .font(

                        .subheadline.weight(.semibold)

                    )

                    .foregroundStyle(.red)

            }

        }

        .padding(.horizontal, 16)

    }



    @ViewBuilder

    private func formField<Content: View>(

        title: String,

        required: Bool = false,

        @ViewBuilder content: () -> Content

    ) -> some View {

        VStack(

            alignment: .leading,

            spacing: 6

        ) {

            fieldLabel(

                title,

                required: required

            )

            content()

                .padding(.horizontal, 16)

                .frame(

                    maxWidth: .infinity,

                    minHeight: 52,

                    alignment: .leading

                )

                .background(

                    Color(

                        .secondarySystemGroupedBackground

                    ),

                    in: RoundedRectangle(

                        cornerRadius: 20,

                        style: .continuous

                    )

                )

        }

    }



    private func menuRow(

        label: String,

        value: String

    ) -> some View {

        HStack {

            Text(label)

                .foregroundStyle(.primary)

            Spacer()

            HStack(spacing: 5) {

                Text(value)

                    .foregroundStyle(.blue)

                Image(

                    systemName:

                        "chevron.up.chevron.down"

                )

                .font(

                    .caption2.weight(.semibold)

                )

                .foregroundStyle(.blue)

            }

        }

        .frame(minHeight: 50)

        .padding(.horizontal, 16)

    }



    @ViewBuilder

    private func detailsRow<Content: View>(

        title: String,

        @ViewBuilder content: () -> Content

    ) -> some View {

        HStack {

            Text(title)

                .foregroundStyle(.primary)

            Spacer(minLength: 16)

            content()

                .frame(

                    maxWidth: 210,

                    alignment: .trailing

                )

        }

        .frame(minHeight: 50)

        .padding(.horizontal, 16)

    }



    private func detailsActionRow(

        title: String,

        value: String

    ) -> some View {

        HStack {

            Text(title)

                .foregroundStyle(.primary)

            Spacer()

            Text(value)

                .foregroundStyle(.blue)

        }

        .frame(minHeight: 50)

        .padding(.horizontal, 16)

    }



    private var rowDivider: some View {

        Divider()

            .padding(.leading, 16)

    }



    private var datePickerSheet: some View {

        NavigationStack {

            DatePicker(

                "Date of birth",

                selection: Binding(

                    get: {

                        dateOfBirth ?? Date()

                    },

                    set: {

                        dateOfBirth = $0

                    }

                ),

                displayedComponents: .date

            )

            .datePickerStyle(.graphical)

            .padding()

            .navigationTitle(

                "Date of birth"

            )

            .navigationBarTitleDisplayMode(

                .inline

            )

            .toolbar {

                ToolbarItem(

                    placement: .confirmationAction

                ) {

                    Button("Done") {

                        showingDatePicker = false

                    }

                }

            }

        }

        .presentationDetents([.medium])

    }



    private func handleScannedImage(_ image: UIImage) {
        scannedImage = image
        quickScanState = .scanning
        focusedField = nil

        Task {
            try? await Task.sleep(for: .seconds(1.6))
            guard !Task.isCancelled else { return }
            await MainActor.run {
                fillMockScannedData()
                quickScanState = .success
            }
        }
    }

    private func fillMockScannedData() {
        fullName = "Michael Thompson"
        organization = "Northstar Logistics"
        cdlNumber = "CDL-729184"
        title = "Driver"
        phoneNumber = "+1 416 555 0148"
        emailAddress = "michael.thompson@northstar.com"
        dateOfBirth = Calendar.current.date(from: DateComponents(year: 1989, month: 6, day: 14))
        idCountry = "Canada"
        dlNumber = "ON-582941"
        companyCardNumber = "NS-4812"
    }

    private func save() {

        focusedField = nil

        guard cdlNumber.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            savePerson()
            return
        }

        showingCDLConfirmation = true
    }

    private func savePerson() {

        // Save person + accessPolicy

        dismiss()

    }

}

private struct CameraPicker: UIViewControllerRepresentable {
    let onImagePicked: (UIImage) -> Void

    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.allowsEditing = false
        picker.sourceType = UIImagePickerController.isSourceTypeAvailable(.camera) ? .camera : .photoLibrary
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onImagePicked: onImagePicked, dismiss: dismiss)
    }

    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        private let onImagePicked: (UIImage) -> Void
        private let dismiss: DismissAction

        init(onImagePicked: @escaping (UIImage) -> Void, dismiss: DismissAction) {
            self.onImagePicked = onImagePicked
            self.dismiss = dismiss
        }

        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
        ) {
            if let image = info[.originalImage] as? UIImage {
                onImagePicked(image)
            }
            dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            dismiss()
        }
    }
}
