import SwiftUI

struct LocationPermissionEditor: View {
    @Environment(PermissionStore.self) private var permissionStore

    @Binding var location: InviteLocation
    @Binding var isPresented: Bool
    @State private var draft: InviteLocation

    init(location: Binding<InviteLocation>, isPresented: Binding<Bool>) {
        _location = location
        _isPresented = isPresented
        _draft = State(initialValue: location.wrappedValue)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    PermissionPresetGrid(
                        selectedPreset: draft.selectedPreset.editorPreset,
                        onSelect: applyPreset
                    )

                    PermissionPresetDescription(preset: draft.selectedPreset.editorPreset)

                    if draft.selectedPreset == .tenant {
                        tenantOrganizationField
                    }

                    PermissionFeatureSection(
                        permissions: $draft.permissions,
                        preset: draft.selectedPreset,
                        onChange: updatePermission
                    )
                }
                .padding(16)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Select access")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        save()
                    }
                    .disabled(draft.selectedPreset == .tenant && draft.tenantOrganizations.isEmpty)
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }

    private func applyPreset(_ preset: PermissionPreset) {
        withAnimation(.easeInOut(duration: 0.18)) {
            draft.applyPreset(preset)
        }
    }

    private func updatePermission(_ feature: PermissionFeature, _ level: AccessLevel) {
        guard let index = draft.permissions.firstIndex(where: { $0.feature == feature }) else {
            return
        }

        draft.permissions[index].access = level
        if draft.selectedPreset != .tenant {
            draft.selectedPreset = .custom
        }
    }

    private func save() {
        location = draft

        for permission in draft.permissions {
            if let appPermission = AppPermission(rawValue: permission.feature.rawValue) {
                permissionStore.setAccess(
                    AppAccessLevel(rawValue: permission.access.rawValue) ?? .full,
                    for: appPermission
                )
            }
        }

        isPresented = false
    }

    private var tenantOrganizationField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Organization name")
                .font(.headline)

            TenantOrganizationPickerControl(
                selections: $draft.tenantOrganizations,
                locationName: draft.name
            )
        }
    }
}

private struct PermissionPresetGrid: View {
    let selectedPreset: PermissionPreset
    let onSelect: (PermissionPreset) -> Void

    private let presets: [PermissionPreset] = [.edit, .view, .noAccess, .admin, .tenant, .custom]

    var body: some View {
        LazyVGrid(
            columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 3),
            spacing: 8
        ) {
            ForEach(presets) { preset in
                Button {
                    onSelect(preset)
                } label: {
                    VStack(spacing: 7) {
                        Image(systemName: preset.icon)
                            .font(.title3.weight(.medium))
                        Text(preset.title)
                            .font(.subheadline.weight(.medium))
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity, minHeight: 88)
                    .foregroundStyle(selectedPreset == preset ? .white : .primary)
                    .background(
                        selectedPreset == preset ? Color.blue : Color(.secondarySystemGroupedBackground),
                        in: RoundedRectangle(cornerRadius: 14, style: .continuous)
                    )
                    .overlay {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(
                                selectedPreset == preset ? Color.clear : Color.secondary.opacity(0.22),
                                lineWidth: 1
                            )
                    }
                }
                .buttonStyle(.plain)
                .accessibilityLabel(preset.title)
                .accessibilityAddTraits(selectedPreset == preset ? .isSelected : [])
            }
        }
    }
}

private struct PermissionPresetDescription: View {
    let preset: PermissionPreset

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(preset.title)
                .font(.title3.weight(.bold))
            Text(preset.explanation)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }
}

private struct TenantOrganizationPickerControl: View {
    @Binding var selections: [String]
    let locationName: String

    @State private var isPickerPresented = false

    private var selectionSummary: String {
        selections.isEmpty ? "Select organization" : selections.joined(separator: ", ")
    }

    var body: some View {
        Button {
            isPickerPresented = true
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "building.2.crop.circle.fill")
                    .foregroundStyle(.blue)

                Text(selectionSummary)
                    .foregroundStyle(selections.isEmpty ? Color.secondary : Color.blue)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Image(systemName: "chevron.up.chevron.down")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity, minHeight: 52)
            .background(
                Color(.secondarySystemGroupedBackground),
                in: RoundedRectangle(cornerRadius: 20, style: .continuous)
            )
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $isPickerPresented) {
            TenantOrganizationSelectionDrawer(
                selections: $selections,
                locationName: locationName
            )
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
    }
}

private struct TenantOrganizationSelectionDrawer: View {
    @Environment(\.dismiss) private var dismiss

    @Binding var selections: [String]
    let locationName: String

    @State private var draftSelections: Set<String>
    @State private var searchText = ""

    init(selections: Binding<[String]>, locationName: String) {
        _selections = selections
        self.locationName = locationName
        _draftSelections = State(initialValue: Set(selections.wrappedValue))
    }

    private var availableOrganizations: [OrganizationRecord] {
        OrganizationDirectory.records
            .filter {
                $0.locations.contains(locationName) || $0.locations.contains("All locations")
            }
            .sorted { $0.addedOrder > $1.addedOrder }
    }

    private var filteredOrganizations: [OrganizationRecord] {
        availableOrganizations.filter {
            searchText.isEmpty || $0.name.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        NavigationStack {
            List(filteredOrganizations) { organization in
                Button {
                    toggle(organization.name)
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "building.2.crop.circle.fill")
                            .foregroundStyle(.blue)

                        Text(organization.name)
                            .foregroundStyle(.primary)

                        Spacer()

                        Image(systemName: draftSelections.contains(organization.name) ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(draftSelections.contains(organization.name) ? .blue : .secondary)
                    }
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(draftSelections.contains(organization.name) ? .isSelected : [])
            }
            .navigationTitle("Select organizations")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, prompt: "Search organizations")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        selections = availableOrganizations
                            .filter { draftSelections.contains($0.name) }
                            .map(\.name)
                        dismiss()
                    }
                }
            }
            .overlay {
                if filteredOrganizations.isEmpty {
                    ContentUnavailableView.search(text: searchText)
                }
            }
        }
    }

    private func toggle(_ organizationName: String) {
        if draftSelections.contains(organizationName) {
            draftSelections.remove(organizationName)
        } else {
            draftSelections.insert(organizationName)
        }
    }
}

private struct PermissionFeatureSection: View {
    @Binding var permissions: [FeaturePermission]
    let preset: PermissionPreset
    let onChange: (PermissionFeature, AccessLevel) -> Void

    private var orderedPermissions: [FeaturePermission] {
        permissions
            .filter { $0.feature.isShownInPermissionEditor }
            .sorted { $0.feature.displayOrder < $1.feature.displayOrder }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Feature access")
                .font(.headline)

            Text("Set what this user can view and manage.")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            VStack(spacing: 0) {
                ForEach(orderedPermissions) { permission in
                    PermissionFeatureRow(
                        permission: permission,
                        preset: preset,
                        onChange: onChange
                    )

                    if permission.feature.endsFeatureGroup {
                        Divider()
                            .padding(.leading, 14)
                    }
                }
            }
            .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
    }
}

private struct PermissionFeatureRow: View {
    let permission: FeaturePermission
    let preset: PermissionPreset
    let onChange: (PermissionFeature, AccessLevel) -> Void

    private var isRestricted: Bool {
        preset == .tenant && !permission.feature.isTenantSupported
    }

    private var availableLevels: [AccessLevel] {
        if isRestricted {
            return [.noAccess]
        }

        if permission.feature == .requestTickets {
            return [.noAccess, .full]
        }

        if preset == .tenant && permission.feature.isTenantViewOnly {
            return [.noAccess, .view]
        }

        return AccessLevel.allCases
    }

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            Image(systemName: "building.2.crop.circle.fill")
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 3) {
                Text(permission.feature.title)
                    .font(.subheadline.weight(.medium))
                if let detail = permission.feature.editorDescription {
                    Text(detail)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer(minLength: 8)

            Menu {
                ForEach(availableLevels) { level in
                    Button {
                        onChange(permission.feature, level)
                    } label: {
                        Label(
                            level.title,
                            systemImage: level == permission.access ? "checkmark" : level.systemImage
                        )
                    }
                    .disabled(isRestricted)
                }
            } label: {
                PermissionAccessPill(level: permission.access, isDisabled: isRestricted)
            }
            .disabled(isRestricted)
        }
        .padding(14)
        .opacity(isRestricted ? 0.58 : 1)
    }
}

private struct PermissionAccessPill: View {
    let level: AccessLevel
    let isDisabled: Bool

    var body: some View {
        HStack(spacing: 5) {
            Text(level.title)
                .lineLimit(1)
            Image(systemName: "chevron.down")
                .font(.caption2.weight(.bold))
        }
        .font(.caption.weight(.semibold))
        .foregroundStyle(foregroundColor)
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .frame(minWidth: 108)
        .background(backgroundColor, in: Capsule())
    }

    private var foregroundColor: Color {
        if isDisabled || level == .noAccess {
            return .secondary
        }
        return .blue
    }

    private var backgroundColor: Color {
        level == .full && !isDisabled ? .blue.opacity(0.14) : Color(.tertiarySystemFill)
    }
}

extension PermissionPreset {
    var editorPreset: PermissionPreset {
        switch self {
        case .manager:
            return .edit
        case .employee:
            return .custom
        default:
            return self
        }
    }

    var title: String {
        switch self {
        case .admin: "Admin access"
        case .edit, .manager: "Edit access"
        case .view: "View access"
        case .noAccess: "No access"
        case .tenant: "Tenant access"
        case .custom, .employee: "Custom access"
        }
    }

    var icon: String {
        switch self {
        case .admin: "person.badge.key"
        case .edit, .manager: "pencil"
        case .view: "eye"
        case .noAccess: "nosign"
        case .tenant: "building.2"
        case .custom, .employee: "slider.horizontal.3"
        }
    }

    var explanation: String {
        switch self {
        case .admin:
            "User can view and manage every feature, including users and permissions."
        case .edit, .manager:
            "User can view and manage all records except users and their permissions."
        case .view:
            "User can view records but cannot make changes."
        case .noAccess:
            "User cannot access any records at this location."
        case .tenant:
            "User can only view and manage records associated with selected organizations."
        case .custom, .employee:
            "Choose a different access level for each feature."
        }
    }
}

extension PermissionFeature {
    var isTenantSupported: Bool {
        switch self {
        case .authorizedPeople, .authorizedOrganizations, .authorizedEquipment,
             .appointments, .accessPointRecords, .accessPointRecordsMedia:
            true
        default:
            false
        }
    }

    var isTenantViewOnly: Bool {
        self == .accessPointRecords || self == .accessPointRecordsMedia
    }

    var isShownInPermissionEditor: Bool {
        self != .equipment
    }

    var displayOrder: Int {
        switch self {
        case .authorizedPeople: 0
        case .authorizedOrganizations: 1
        case .authorizedEquipment: 2
        case .appointments: 3
        case .accessPointRecords: 4
        case .accessPointRecordsMedia: 5
        case .inventoryList: 6
        case .inventoryCheck: 7
        case .requestTickets: 8
        case .usersAndPermissions: 9
        case .equipment: 10
        }
    }

    var endsFeatureGroup: Bool {
        switch self {
        case .authorizedEquipment, .appointments, .accessPointRecordsMedia,
             .inventoryCheck, .requestTickets:
            true
        default:
            false
        }
    }

    var editorDescription: String? {
        switch self {
        case .requestTickets:
            "Submit requests to Birdseye through the app."
        case .usersAndPermissions:
            "Add, edit, authorize, or ban people from accessing locations."
        default:
            nil
        }
    }
}
