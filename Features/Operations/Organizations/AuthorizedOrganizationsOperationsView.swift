import SwiftUI

struct AuthorizedOrganizationsOperationsView: View {

    private let organizations: [OrganizationRecord] = (1...100).map { index in
        let names = [
            "Northstar Logistics",
            "SafeGate Services",
            "CargoTrucks",
            "Bison Transport",
        ]

        let relationTypes = [
            "Tenant",
            "Vendor",
            "Third-party carrier",
        ]

        let industries = [
            "Transportation",
            "Security",
            "Trucking",
            "Automotive",
        ]

        let addresses = [
            "100 Harbour St, Toronto, ON",
            "2200 Airport Rd, Oshawa, ON",
            "6358 Viscount Rd, Mississauga, ON",
            "4100 Logistics Way, Dallas, TX",
        ]

        let locationSets = [
            ["All locations"],
            ["Northstar (Oshawa)"],
            ["Northstar (Dallas)"],
            ["Northstar (Toronto)"],
            ["Northstar (Oshawa)", "Northstar (Dallas)"],
            ["Northstar (Oshawa)", "Northstar (Toronto)"],
        ]

        let accessType: String

        if index.isMultiple(of: 19) {
            accessType = "Specialized Access"
        } else if index.isMultiple(of: 13) {
            accessType = "Priority Access"
        } else if index.isMultiple(of: 11) {
            accessType = "Banned Access"
        } else {
            accessType = "Default Access"
        }

        let periodAccess =
            index.isMultiple(of: 8)
            ? "One-time"
            : "Ongoing"

        let hasNote =
            accessType == "Banned Access"
            || index.isMultiple(of: 17)

        let isLimitedTime =
            accessType == "Priority Access"
            || accessType == "Specialized Access"
            || index.isMultiple(of: 23)

        return OrganizationRecord(
            id: index,
            name: names[index % names.count] + " \(index)",
            relationType: relationTypes[index % relationTypes.count],
            industry: industries[index % industries.count],
            address: addresses[index % addresses.count],
            phoneNumber: index.isMultiple(of: 4) ? "1234567890" : "",
            emailAddress: index.isMultiple(of: 3)
                ? "ops\(index)@northstarlogistics.com"
                : "",
            locations: locationSets[index % locationSets.count],
            accessType: accessType,
            periodAccess: periodAccess,
            hasNote: hasNote,
            isLimitedTime: isLimitedTime,
            isActive: !index.isMultiple(of: 9),
            addedOrder: index,
            isNewThisWeek: index > 97
        )
    }

    private let locations = [
        "All locations",
        "Northstar (Oshawa)",
        "Northstar (Dallas)",
        "Northstar (Toronto)",
    ]

    @State private var selectedLocationIndex = 1
    @State private var searchText = ""
    @State private var isSearchPresented = false
    @State private var organizationFilter: OrganizationFilter = .all
    @State private var sortOrder: OrganizationSortOrder = .recentlyAdded
    @State private var page = 0
    @State private var showingAdd = false
    @State private var selectedOrganization: OrganizationRecord?

    private let pageSize = 20

    private var cleanSearch: String {
        searchText.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
    }

    private var filteredOrganizations: [OrganizationRecord] {
        let matchingOrganizations = organizations.filter { organization in
            let matchesSearch =
                cleanSearch.isEmpty
                || organization.name.localizedCaseInsensitiveContains(cleanSearch)
                || organization.relationType.localizedCaseInsensitiveContains(cleanSearch)
                || organization.industry.localizedCaseInsensitiveContains(cleanSearch)
                || organization.address.localizedCaseInsensitiveContains(cleanSearch)
                || organization.emailAddress.localizedCaseInsensitiveContains(cleanSearch)
                || organization.phoneNumber.localizedCaseInsensitiveContains(cleanSearch)
                || organization.locations
                    .joined(separator: " ")
                    .localizedCaseInsensitiveContains(cleanSearch)
                || organization.accessType
                    .localizedCaseInsensitiveContains(cleanSearch)

            let selectedLocation = locations[selectedLocationIndex]

            let matchesLocation =
                selectedLocation == "All locations"
                || organization.locations.contains(selectedLocation)
                || organization.locations.contains("All locations")

            let matchesFilter: Bool

            switch organizationFilter {
            case .all:
                matchesFilter = true

            case .activeOnly:
                matchesFilter = organization.isActive

            case .inactiveOnly:
                matchesFilter = !organization.isActive

            case .bannedOnly:
                matchesFilter = organization.accessType == "Banned Access"

            case .defaultOnly:
                matchesFilter = organization.accessType == "Default Access"

            case .priorityOnly:
                matchesFilter = organization.accessType == "Priority Access"

            case .specializedOnly:
                matchesFilter = organization.accessType == "Specialized Access"

            case .tenantOnly:
                matchesFilter = organization.relationType == "Tenant"

            case .vendorOnly:
                matchesFilter = organization.relationType == "Vendor"

            case .carrierOnly:
                matchesFilter = organization.relationType == "Third-party carrier"

            case .newThisWeek:
                matchesFilter = organization.isNewThisWeek

            case .hasNotes:
                matchesFilter = organization.hasNote
            }

            return matchesSearch
                && matchesLocation
                && matchesFilter
        }

        switch sortOrder {
        case .recentlyAdded:
            return matchingOrganizations.sorted {
                $0.addedOrder > $1.addedOrder
            }

        case .oldestAdded:
            return matchingOrganizations.sorted {
                $0.addedOrder < $1.addedOrder
            }

        case .nameAscending:
            return matchingOrganizations.sorted {
                $0.name.localizedStandardCompare($1.name) == .orderedAscending
            }

        case .nameDescending:
            return matchingOrganizations.sorted {
                $0.name.localizedStandardCompare($1.name) == .orderedDescending
            }

        case .relationType:
            return matchingOrganizations.sorted {
                $0.relationType.localizedStandardCompare(
                    $1.relationType
                ) == .orderedAscending
            }

        case .industry:
            return matchingOrganizations.sorted {
                $0.industry.localizedStandardCompare(
                    $1.industry
                ) == .orderedAscending
            }

        case .location:
            return matchingOrganizations.sorted {
                $0.locations
                    .joined(separator: " ")
                    .localizedStandardCompare(
                        $1.locations.joined(separator: " ")
                    ) == .orderedAscending
            }

        case .accessType:
            return matchingOrganizations.sorted {
                $0.accessType.localizedStandardCompare(
                    $1.accessType
                ) == .orderedAscending
            }

        case .status:
            return matchingOrganizations.sorted {
                if $0.isActive == $1.isActive {
                    return $0.name.localizedStandardCompare(
                        $1.name
                    ) == .orderedAscending
                }

                return $0.isActive && !$1.isActive
            }
        }
    }

    private var pageOrganizations: [OrganizationRecord] {
        let start = page * pageSize

        guard start < filteredOrganizations.count else {
            return []
        }

        return Array(
            filteredOrganizations
                .dropFirst(start)
                .prefix(pageSize)
        )
    }

    var body: some View {
        VStack(spacing: 0) {
            AuthorizedOrganizationsResultsContent(
                organizations: pageOrganizations,
                resultCount: filteredOrganizations.count,
                locations: locations,
                selectedLocationIndex: $selectedLocationIndex,
                page: page,
                pageSize: pageSize,
                onSelect: { organization in
                    selectedOrganization = organization
                },
                onPrevious: {
                    page = max(page - 1, 0)
                },
                onNext: {
                    let maxPage = max(
                        (filteredOrganizations.count - 1) / pageSize,
                        0
                    )

                    page = min(page + 1, maxPage)
                }
            )
        }
        .navigationTitle("Organizations")
        .navigationBarTitleDisplayMode(.inline)
        .reportingPageContext("Organizations")
        .toolbar {
            ToolbarItemGroup(
                placement: .topBarTrailing
            ) {
                Button {
                    HapticFeedback.lightImpact()
                    isSearchPresented = true
                } label: {
                    Image(systemName: "magnifyingglass")
                }
                .tint(.primary)
                .accessibilityLabel("Search")

                Menu {
                    Section("Sort") {
                        ForEach(OrganizationSortOrder.allCases) { order in
                            Button {
                                sortOrder = order
                                page = 0
                            } label: {
                                if sortOrder == order {
                                    Label(
                                        order.title,
                                        systemImage: "checkmark"
                                    )
                                } else {
                                    Label(
                                        order.title,
                                        systemImage: order.systemImage
                                    )
                                }
                            }
                        }
                    }

                    Section("Filter") {
                        ForEach(OrganizationFilter.allCases) { filter in
                            Button {
                                organizationFilter = filter
                                page = 0
                            } label: {
                                if organizationFilter == filter {
                                    Label(
                                        filter.title,
                                        systemImage: "checkmark"
                                    )
                                } else {
                                    Label(
                                        filter.title,
                                        systemImage: filter.systemImage
                                    )
                                }
                            }
                        }
                    }

                    Section("Actions") {
                        Button {
                            // Export action
                        } label: {
                            Label(
                                "Export list",
                                systemImage: "square.and.arrow.up"
                            )
                        }

                        if organizationFilter != .all
                            || !searchText.isEmpty
                            || selectedLocationIndex != 1
                            || sortOrder != .recentlyAdded
                        {
                            Button {
                                organizationFilter = .all
                                searchText = ""
                                selectedLocationIndex = 1
                                sortOrder = .recentlyAdded
                                page = 0
                            } label: {
                                Label(
                                    "Reset view",
                                    systemImage: "arrow.counterclockwise"
                                )
                            }
                        }
                    }
                } label: {
                    Image(systemName: "ellipsis")
                }
                .tint(.primary)
                .accessibilityLabel("Sort, filter, and more")

                Button {
                    HapticFeedback.lightImpact()
                    showingAdd = true
                } label: {
                    Image(systemName: "plus")
                        .font(.body.weight(.semibold))
                }
                .tint(.blue)
                .accessibilityLabel("Add organization")
            }
        }
        .organizationConditionalSearch(
            isPresented: $isSearchPresented,
            text: $searchText,
            prompt: "Search organizations"
        )
        .onChange(of: searchText) { _, _ in
            page = 0
        }
        .onChange(of: organizationFilter) { _, _ in
            page = 0
        }
        .onChange(of: selectedLocationIndex) { _, _ in
            page = 0
        }
        .onChange(of: sortOrder) { _, _ in
            page = 0
        }
        .sheet(isPresented: $showingAdd) {
            OrganizationEditorView()
        }
        .sheet(item: $selectedOrganization) { organization in
            OrganizationEditorView(
                organization: organization
            )
        }
    }
}


// MARK: - Sorting

private enum OrganizationSortOrder:
    String,
    CaseIterable,
    Identifiable
{
    case recentlyAdded
    case oldestAdded
    case nameAscending
    case nameDescending
    case relationType
    case industry
    case location
    case accessType
    case status

    var id: Self { self }

    var title: String {
        switch self {
        case .recentlyAdded:
            return "Recently added"
        case .oldestAdded:
            return "Oldest added"
        case .nameAscending:
            return "Name A-Z"
        case .nameDescending:
            return "Name Z-A"
        case .relationType:
            return "Relation type"
        case .industry:
            return "Industry"
        case .location:
            return "Location"
        case .accessType:
            return "Access type"
        case .status:
            return "Status"
        }
    }

    var systemImage: String {
        switch self {
        case .recentlyAdded:
            return "clock.arrow.circlepath"
        case .oldestAdded:
            return "clock"
        case .nameAscending:
            return "textformat.abc"
        case .nameDescending:
            return "textformat.abc"
        case .relationType:
            return "arrow.left.arrow.right"
        case .industry:
            return "building.2"
        case .location:
            return "mappin.and.ellipse"
        case .accessType:
            return "key"
        case .status:
            return "checkmark.circle"
        }
    }
}


// MARK: - Filtering

private enum OrganizationFilter:
    String,
    CaseIterable,
    Identifiable
{
    case all
    case activeOnly
    case inactiveOnly
    case bannedOnly
    case defaultOnly
    case priorityOnly
    case specializedOnly
    case tenantOnly
    case vendorOnly
    case carrierOnly
    case newThisWeek
    case hasNotes

    var id: Self { self }

    var title: String {
        switch self {
        case .all:
            return "All organizations"
        case .activeOnly:
            return "Active only"
        case .inactiveOnly:
            return "Inactive only"
        case .bannedOnly:
            return "Banned only"
        case .defaultOnly:
            return "Default access only"
        case .priorityOnly:
            return "Priority access only"
        case .specializedOnly:
            return "Specialized access only"
        case .tenantOnly:
            return "Tenants only"
        case .vendorOnly:
            return "Vendors only"
        case .carrierOnly:
            return "Third-party carriers only"
        case .newThisWeek:
            return "New this week"
        case .hasNotes:
            return "Has notes"
        }
    }

    var systemImage: String {
        switch self {
        case .all:
            return "building.2"
        case .activeOnly:
            return "checkmark.circle"
        case .inactiveOnly:
            return "pause.circle"
        case .bannedOnly:
            return "nosign"
        case .defaultOnly:
            return "infinity"
        case .priorityOnly:
            return "star"
        case .specializedOnly:
            return "slider.horizontal.3"
        case .tenantOnly:
            return "house"
        case .vendorOnly:
            return "shippingbox"
        case .carrierOnly:
            return "truck.box"
        case .newThisWeek:
            return "sparkles"
        case .hasNotes:
            return "note.text"
        }
    }
}


// MARK: - Organization Record

struct OrganizationRecord: Identifiable {
    let id: Int
    let name: String
    let relationType: String
    let industry: String
    let address: String
    let phoneNumber: String
    let emailAddress: String
    let locations: [String]
    let accessType: String
    let periodAccess: String
    let hasNote: Bool
    let isLimitedTime: Bool
    let isActive: Bool
    let addedOrder: Int
    let isNewThisWeek: Bool
}


// MARK: - Results

private struct AuthorizedOrganizationsResultsContent: View {
    let organizations: [OrganizationRecord]
    let resultCount: Int
    let locations: [String]

    @Binding var selectedLocationIndex: Int

    let page: Int
    let pageSize: Int

    let onSelect: (OrganizationRecord) -> Void
    let onPrevious: () -> Void
    let onNext: () -> Void

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 18) {
                HStack(spacing: 12) {
                    Text("\(resultCount) results")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.secondary)
                        .monospacedDigit()

                    Spacer()

                    OrganizationLocationSwitcher(
                        locations: locations,
                        selectedIndex: $selectedLocationIndex
                    )
                }
                .padding(.horizontal, 16)

                if organizations.isEmpty {
                    ContentUnavailableView(
                        "No organizations found",
                        systemImage: "building.2.crop.circle",
                        description: Text(
                            "Try changing your search or filters."
                        )
                    )
                    .padding(.top, 54)
                    .padding(.horizontal, 24)
                } else {
                    AuthorizedOrganizationsCard(
                        organizations: organizations,
                        onSelect: onSelect
                    )

                    OrganizationPaginationFooter(
                        page: page,
                        itemCount: resultCount,
                        pageSize: pageSize,
                        onPrevious: onPrevious,
                        onNext: onNext
                    )
                    .padding(.horizontal, 16)
                }
            }
            .padding(.top, 16)
            .padding(.bottom, 110)
        }
        .birdseyeRefreshable()
        .background(
            Color(.systemGroupedBackground)
        )
    }
}


// MARK: - Organizations Card

private struct AuthorizedOrganizationsCard: View {
    let organizations: [OrganizationRecord]
    let onSelect: (OrganizationRecord) -> Void

    var body: some View {
        VStack(spacing: 0) {
            ForEach(
                organizations.enumerated(),
                id: \.element.id
            ) { index, organization in
                Button {
                    onSelect(organization)
                } label: {
                    AuthorizedOrganizationRow(
                        organization: organization
                    )
                }
                .buttonStyle(.plain)

                if index < organizations.count - 1 {
                    Divider()
                        .padding(.leading, 62)
                }
            }
        }
        .background(
            Color(.secondarySystemGroupedBackground),
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
        .padding(.horizontal, 16)
    }
}


// MARK: - Conditional Search

extension View {
    @ViewBuilder
    fileprivate func organizationConditionalSearch(
        isPresented: Binding<Bool>,
        text: Binding<String>,
        prompt: String
    ) -> some View {
        if isPresented.wrappedValue {
            self
                .reportingSearchActivity()
                .searchable(
                    text: text,
                    isPresented: isPresented,
                    placement:
                        .navigationBarDrawer(
                            displayMode: .always
                        ),
                    prompt: prompt
                )
        } else {
            self
        }
    }
}


// MARK: - Location Switcher

private struct OrganizationLocationSwitcher: View {
    let locations: [String]

    @Binding var selectedIndex: Int

    var body: some View {
        Menu {
            ForEach(
                locations,
                id: \.self
            ) { location in
                Button {
                    selectedIndex =
                        locations.firstIndex(
                            of: location
                        ) ?? 0
                } label: {
                    if location == locations[selectedIndex] {
                        Label(
                            location,
                            systemImage: "checkmark"
                        )
                    } else {
                        Text(location)
                    }
                }
            }
        } label: {
            HStack(spacing: 5) {
                Text(locations[selectedIndex])
                    .lineLimit(1)

                Image(
                    systemName:
                        "chevron.up.chevron.down"
                )
                .font(.caption2.weight(.semibold))
            }
            .font(.subheadline.weight(.medium))
            .foregroundStyle(.secondary)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Choose location")
        .accessibilityValue(
            locations[selectedIndex]
        )
    }
}


// MARK: - Organization Row

private struct AuthorizedOrganizationRow: View {
    let organization: OrganizationRecord

    private var accessColor: Color {
        switch organization.accessType {
        case "Banned Access":
            return .red
        case "Priority Access":
            return .blue
        case "Specialized Access":
            return .orange
        default:
            return .secondary
        }
    }

    var body: some View {
        HStack(
            alignment: .top,
            spacing: 12
        ) {
            Image(systemName: "building.2.fill")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(accessColor)
                .frame(
                    width: 34,
                    height: 34
                )
                .background(
                    accessColor.opacity(0.10),
                    in: RoundedRectangle(
                        cornerRadius: 10,
                        style: .continuous
                    )
                )

            VStack(
                alignment: .leading,
                spacing: 6
            ) {
                Text(organization.name)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                ViewThatFits(in: .horizontal) {
                    wideMetadataRow
                        .fixedSize(
                            horizontal: true,
                            vertical: false
                        )

                    compactMetadataRows
                }
            }
            .frame(
                maxWidth: .infinity,
                alignment: .leading
            )

            if organization.isNewThisWeek {
                Text("New")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.blue)
                    .textCase(.uppercase)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(
                        .blue.opacity(0.14),
                        in: Capsule()
                    )
                    .fixedSize()
                    .accessibilityLabel("New this week")
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .contentShape(Rectangle())
    }

    private var wideMetadataRow: some View {
        HStack(spacing: 6) {
            Text(organization.relationType)

            metadataSeparator

            Text(organization.industry)

            metadataSeparator

            OrganizationLocationLabel(
                locations: organization.locations
            )

            OrganizationAccessTypeChip(
                accessType: organization.accessType,
                periodAccess: organization.periodAccess,
                hasNote: organization.hasNote,
                isLimitedTime: organization.isLimitedTime
            )
        }
        .font(.subheadline)
        .foregroundStyle(.secondary)
        .lineLimit(1)
    }

    private var compactMetadataRows: some View {
        VStack(
            alignment: .leading,
            spacing: 6
        ) {
            HStack(spacing: 4) {
                Text(organization.relationType)

                metadataSeparator

                Text(organization.industry)
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .lineLimit(1)

            compactLocationAndAccess
        }
    }

    private var compactLocationAndAccess: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 8) {
                OrganizationLocationLabel(
                    locations: organization.locations
                )

                OrganizationAccessTypeChip(
                    accessType: organization.accessType,
                    periodAccess: organization.periodAccess,
                    hasNote: organization.hasNote,
                    isLimitedTime: organization.isLimitedTime
                )
            }
            .fixedSize(
                horizontal: true,
                vertical: false
            )

            VStack(
                alignment: .leading,
                spacing: 5
            ) {
                OrganizationLocationLabel(
                    locations: organization.locations
                )

                OrganizationAccessTypeChip(
                    accessType: organization.accessType,
                    periodAccess: organization.periodAccess,
                    hasNote: organization.hasNote,
                    isLimitedTime: organization.isLimitedTime
                )
            }
        }
    }

    private var metadataSeparator: some View {
        Text("·")
            .foregroundStyle(.tertiary)
    }
}


// MARK: - Location Label

private struct OrganizationLocationLabel: View {
    let locations: [String]

    private var label: String {
        locations.joined(
            separator: " · "
        )
    }

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: "mappin.and.ellipse")
                .font(.subheadline.weight(.medium))

            Text(label)
                .font(.caption.weight(.medium))
                .lineLimit(1)
                .truncationMode(.tail)
        }
        .foregroundStyle(.secondary)
        .accessibilityLabel("Authorized locations")
        .accessibilityValue(label)
    }
}


// MARK: - Access Chip

private struct OrganizationAccessTypeChip: View {
    let accessType: String
    let periodAccess: String
    let hasNote: Bool
    let isLimitedTime: Bool

    private var tint: Color {
        switch accessType {
        case "Banned Access":
            return .red
        case "Priority Access":
            return .blue
        case "Specialized Access":
            return .orange
        default:
            return .secondary
        }
    }

    var body: some View {
        HStack(spacing: 5) {
            Text(accessType)
                .font(.caption2.weight(.semibold))

            if periodAccess == "One-time" {
                Image(systemName: "1.circle.fill")
                    .font(.caption.weight(.semibold))
            }

            if hasNote {
                Image(systemName: "note.text")
                    .font(.caption.weight(.semibold))
            }

            if isLimitedTime {
                Image(systemName: "clock.fill")
                    .font(.caption.weight(.semibold))
            }
        }
        .foregroundStyle(tint)
        .padding(.horizontal, 7)
        .padding(.vertical, 3)
        .overlay {
            Capsule()
                .strokeBorder(
                    tint.opacity(0.32),
                    lineWidth: 0.75
                )
        }
        .fixedSize(
            horizontal: true,
            vertical: false
        )
        .accessibilityElement(children: .combine)
    }
}


// MARK: - Editor

struct OrganizationEditorView: View {
    @Environment(\.dismiss) private var dismiss

    let organization: OrganizationRecord?

    @State private var name: String
    @State private var relationType: String
    @State private var industry: String
    @State private var address: String
    @State private var emailAddress: String
    @State private var phoneNumber: String
    @State private var selectedAccessPoints: Set<String>
    @State private var accessPolicy: AccessPolicy

    @State private var moreDetailsExpanded = false
    @State private var showingQuickScanOptions = false
    @State private var showingAccessPolicy = false

    @FocusState private var focusedField: Field?

    private enum Field {
        case name
        case address
        case email
        case phone
    }

    private let relationTypes = [
        "Tenant",
        "Third Party Carrier",
        "Vendor",
    ]

    private let industries = [
        "None",
        "Automotive",
        "Trucking",
        "Residential",
    ]

    private let accessPointOptions = [
        "Full Facility Access",
        "Main Gate IN",
        "Main Gate OUT",
        "Carrier Gate IN",
        "Carrier Gate OUT",
    ]

    init(
        organization: OrganizationRecord? = nil
    ) {
        self.organization = organization

        _name = State(
            initialValue:
                organization?.name ?? ""
        )

        _relationType = State(
            initialValue:
                organization?.relationType ?? "Tenant"
        )

        _industry = State(
            initialValue:
                organization?.industry ?? "None"
        )

        _address = State(
            initialValue:
                organization?.address ?? ""
        )

        _emailAddress = State(
            initialValue:
                organization?.emailAddress ?? ""
        )

        _phoneNumber = State(
            initialValue:
                organization?.phoneNumber ?? ""
        )

        _selectedAccessPoints = State(
            initialValue: ["Full Facility Access"]
        )

        var policy = AccessPolicy()

        if let organization {
            policy.locations = organization.locations.joined(
                separator: ", "
            )
            policy.accessType = organization.accessType
            policy.periodAccess = organization.periodAccess
            policy.limitedTimeAccess = organization.isLimitedTime

            if organization.hasNote {
                policy.note = "Existing authorization note"
            }
        }

        _accessPolicy = State(
            initialValue: policy
        )
    }

    private var canSave: Bool {
        !name
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            )
            .isEmpty
        && !relationType
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            )
            .isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                if organization == nil {
                    quickScanSection
                }

                VStack(
                    alignment: .leading,
                    spacing: 20
                ) {
                    nameField
                    relationTypeField
                    moreDetailsArea
                    accessPolicyArea

                    if organization != nil {
                        updateDetails
                    }
                }
                .listRowInsets(
                    EdgeInsets(
                        top: 0,
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
                organization == nil
                    ? "Add organization"
                    : "Edit organization"
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
                        focusedField = nil
                        dismiss()
                    }
                    .buttonStyle(.glassProminent)
                    .tint(.blue)
                    .disabled(!canSave)
                }
            }
            .confirmationDialog(
                "Quick scan",
                isPresented: $showingQuickScanOptions,
                titleVisibility: .visible
            ) {
                Button(
                    "Camera",
                    systemImage: "camera"
                ) { }

                Button(
                    "Photos",
                    systemImage: "photo"
                ) { }

                Button(
                    "Files",
                    systemImage: "folder"
                ) { }

                Button(
                    "Cancel",
                    role: .cancel
                ) { }
            } message: {
                Text(
                    "Choose how you want to scan the company card or document."
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
                showingQuickScanOptions = true
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "text.viewfinder")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.blue)
                        .frame(width: 44, height: 44)
                        .background(
                            Color.blue.opacity(0.08),
                            in: RoundedRectangle(
                                cornerRadius: 10,
                                style: .continuous
                            )
                        )

                    VStack(
                        alignment: .leading,
                        spacing: 3
                    ) {
                        Text("Quick scan")
                            .font(.body.weight(.semibold))
                            .foregroundStyle(.blue)

                        Text(
                            "Scan the company card or document to fill in the data."
                        )
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    }

                    Spacer()
                }
                .padding(.vertical, 2)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: Primary fields

    private var nameField: some View {
        formField(
            title: "Organization name",
            required: true
        ) {
            TextField(
                "Enter organization name",
                text: $name
            )
            .focused(
                $focusedField,
                equals: .name
            )
            .textContentType(
                .organizationName
            )
            .textInputAutocapitalization(
                .words
            )
            .submitLabel(.next)
            .onSubmit {
                focusedField = nil
            }
        }
    }

    private var relationTypeField: some View {
        menuField(
            title: "Relation type",
            required: true,
            selection: $relationType,
            options: relationTypes
        )
    }

    // MARK: More Details

    private var moreDetailsArea: some View {
        VStack(
            alignment: .leading,
            spacing: 10
        ) {
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
                        detailsSummary
                            .transition(.opacity)
                    }
                }
                .padding(.horizontal, 16)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if moreDetailsExpanded {
                moreDetailsFields
                    .transition(.opacity)
            }
        }
    }

    @ViewBuilder
    private var detailsSummary: some View {
        let values = [
            "Industry: \(industry)",
            address.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                ? nil
                : "Address: \(address)",
            emailAddress.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                ? nil
                : "Email: \(emailAddress)",
            phoneNumber.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                ? nil
                : "Phone: \(phoneNumber)",
            "Access: \(accessPointSummary)",
        ]
        .compactMap { $0 }

        ScrollView(
            .horizontal,
            showsIndicators: false
        ) {
            HStack(spacing: 8) {
                ForEach(
                    values,
                    id: \.self
                ) { value in
                    Text(value)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .padding(.horizontal, 9)
                        .padding(.vertical, 5)
                        .background(
                            Color(
                                .secondarySystemGroupedBackground
                            ),
                            in: Capsule()
                        )
                }
            }
        }
        .scrollClipDisabled()
    }

    private var accessPointSummary: String {
        if selectedAccessPoints.isEmpty {
            return "Select access points"
        }

        if selectedAccessPoints.contains("Full Facility Access") {
            return "Full Facility Access"
        }

        return accessPointOptions
            .filter { selectedAccessPoints.contains($0) }
            .joined(separator: ", ")
    }

    private var moreDetailsFields: some View {
        VStack(spacing: 0) {
            Menu {
                ForEach(industries, id: \.self) { option in
                    Button {
                        industry = option
                    } label: {
                        if industry == option {
                            Label(option, systemImage: "checkmark")
                        } else {
                            Text(option)
                        }
                    }
                }
            } label: {
                menuRow(
                    label: "Industry type",
                    value: industry
                )
            }
            .buttonStyle(.plain)

            rowDivider

            detailsRow(
                title: "Address"
            ) {
                TextField(
                    "Optional",
                    text: $address
                )
                .focused(
                    $focusedField,
                    equals: .address
                )
                .multilineTextAlignment(.trailing)
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
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .multilineTextAlignment(.trailing)
            }

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
                .multilineTextAlignment(.trailing)
            }

            rowDivider
            accessPointsMenu
        }
        .background(
            Color(.secondarySystemGroupedBackground),
            in: RoundedRectangle(
                cornerRadius: 20,
                style: .continuous
            )
        )
    }

    private var accessPointsMenu: some View {
        Menu {
            ForEach(accessPointOptions, id: \.self) { point in
                Button {
                    toggleAccessPoint(point)
                } label: {
                    if selectedAccessPoints.contains(point) {
                        Label(point, systemImage: "checkmark")
                    } else {
                        Text(point)
                    }
                }
            }
        } label: {
            menuRow(
                label: "Access points",
                value: accessPointSummary
            )
        }
        .buttonStyle(.plain)
    }

    private func toggleAccessPoint(_ point: String) {
        if point == "Full Facility Access" {
            selectedAccessPoints = Set(accessPointOptions)
            return
        }

        selectedAccessPoints.remove("Full Facility Access")

        if selectedAccessPoints.contains(point) {
            selectedAccessPoints.remove(point)
        } else {
            selectedAccessPoints.insert(point)
        }
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
                        .font(
                            .subheadline.weight(.semibold)
                        )
                        .foregroundStyle(.blue)

                    Spacer()

                    Image(
                        systemName: "chevron.right"
                    )
                    .font(
                        .caption.weight(.semibold)
                    )
                    .foregroundStyle(.tertiary)
                }

                HStack(spacing: 8) {
                    Label(
                        accessPolicy.locations,
                        systemImage:
                            "mappin.and.ellipse"
                    )
                    .font(.subheadline)
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                    Spacer(minLength: 6)

                    AccessTypeChip(
                        accessType:
                            accessPolicy.accessType,
                        periodAccess:
                            accessPolicy.periodAccess,
                        hasNote:
                            !accessPolicy.note
                                .trimmingCharacters(
                                    in: .whitespacesAndNewlines
                                )
                                .isEmpty,
                        isLimitedTime:
                            accessPolicy.limitedTimeAccess
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
                Color(
                    .secondarySystemGroupedBackground
                ),
                in: RoundedRectangle(
                    cornerRadius: 20,
                    style: .continuous
                )
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: Helpers

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

    private func menuField(
        title: String,
        required: Bool = false,
        selection: Binding<String>,
        options: [String]
    ) -> some View {
        VStack(
            alignment: .leading,
            spacing: 6
        ) {
            fieldLabel(
                title,
                required: required
            )

            Menu {
                ForEach(
                    options,
                    id: \.self
                ) { option in
                    Button {
                        selection.wrappedValue = option
                    } label: {
                        if selection.wrappedValue == option {
                            Label(
                                option,
                                systemImage: "checkmark"
                            )
                        } else {
                            Text(option)
                        }
                    }
                }
            } label: {
                HStack {
                    Text(
                        selection.wrappedValue
                    )
                    .foregroundStyle(.primary)

                    Spacer()

                    Image(
                        systemName:
                            "chevron.up.chevron.down"
                    )
                    .font(
                        .caption2.weight(.semibold)
                    )
                    .foregroundStyle(.blue)
                }
                .padding(.horizontal, 16)
                .frame(
                    maxWidth: .infinity,
                    minHeight: 52
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
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
    }

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
                    .foregroundStyle(.red)
            }
        }
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

            Spacer()

            content()
                .frame(
                    maxWidth: 210,
                    alignment: .trailing
                )
        }
        .frame(minHeight: 50)
        .padding(.horizontal, 16)
    }

    private func menuRow(
        label: String,
        value: String
    ) -> some View {
        HStack {
            Text(label)
                .foregroundStyle(.primary)

            Spacer()

            Text(value)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .multilineTextAlignment(.trailing)

            Image(systemName: "chevron.up.chevron.down")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.blue)
        }
        .frame(minHeight: 50)
        .padding(.horizontal, 16)
        .contentShape(Rectangle())
    }

    private var rowDivider: some View {
        Divider()
            .padding(.leading, 16)
    }

    private var updateDetails: some View {
        VStack(
            alignment: .leading,
            spacing: 4
        ) {
            Text(
                "Updated by: maya@northstar.com"
            )
            Text(
                "Updated at: Today, 10:30 AM"
            )
        }
        .font(.footnote)
        .foregroundStyle(.secondary)
        .padding(.horizontal, 16)
        .padding(.top, 4)
    }
}


// MARK: - Pagination

private struct OrganizationPaginationFooter: View {
    let page: Int
    let itemCount: Int
    let pageSize: Int
    let onPrevious: () -> Void
    let onNext: () -> Void

    private var pageCount: Int {
        max(
            (itemCount + pageSize - 1)
                / pageSize,
            1
        )
    }

    private var rangeStart: Int {
        guard itemCount > 0 else {
            return 0
        }

        return min(
            page * pageSize + 1,
            itemCount
        )
    }

    private var rangeEnd: Int {
        guard itemCount > 0 else {
            return 0
        }

        return min(
            (page + 1) * pageSize,
            itemCount
        )
    }

    var body: some View {
        HStack(spacing: 12) {
            Text(
                "\(rangeStart)–\(rangeEnd) of \(itemCount)"
            )
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .monospacedDigit()

            Spacer()

            HStack(spacing: 10) {
                paginationButton(
                    systemImage: "chevron.left",
                    disabled: page == 0,
                    action: onPrevious
                )

                Text(
                    "\(page + 1) of \(pageCount)"
                )
                .font(
                    .subheadline.weight(
                        .semibold
                    )
                )
                .foregroundStyle(.primary)
                .monospacedDigit()
                .frame(minWidth: 58)

                paginationButton(
                    systemImage: "chevron.right",
                    disabled:
                        page >= pageCount - 1,
                    action: onNext
                )
            }
        }
        .padding(.horizontal, 2)
    }

    private func paginationButton(
        systemImage: String,
        disabled: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(
                systemName: systemImage
            )
            .font(
                .subheadline.weight(
                    .semibold
                )
            )
            .frame(
                width: 36,
                height: 36
            )
            .contentShape(Circle())
        }
        .buttonStyle(.glass)
        .buttonBorderShape(.circle)
        .tint(.primary)
        .disabled(disabled)
        .opacity(
            disabled ? 0.35 : 1
        )
    }
}
