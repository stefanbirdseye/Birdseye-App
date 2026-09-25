import SwiftUI

struct EquipmentOperationsView: View {

    @State private var equipment: [EquipmentRecord] = (1...100).map { index in
        let categories = [
            "Car",
            "Bobtail",
            "Straight truck",
            "Trailer",
            "Container",
            "Forklift",
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

        let category = categories[index % categories.count]
        let equipmentNumber: String

        if ["Bobtail", "Straight truck"].contains(category) {
            equipmentNumber = "\(50000 + index)"
        } else if index.isMultiple(of: 5) {
            equipmentNumber = "TR-\(500 + index)"
        } else {
            equipmentNumber = "Unit \(index)"
        }

        return EquipmentRecord(
            id: index,
            equipmentNumber: equipmentNumber,
            category: category,
            equipmentType: category,
            referenceID: "Birdseye_\(30000 + index)",
            licensePlate: index.isMultiple(of: 3)
                ? "\(32000 + index)"
                : "",
            vinNumber: index.isMultiple(of: 4)
                ? "1GYS9BKL4TR\(420000 + index)"
                : "",
            fullName: index.isMultiple(of: 6)
                ? "David Okafor"
                : "",
            organizationName: index.isMultiple(of: 4)
                ? "Northstar Logistics"
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
    @State private var equipmentFilter: EquipmentFilter = .all
    @State private var sortOrder: EquipmentSortOrder = .recentlyAdded
    @State private var page = 0
    @State private var showingEditor = false
    @State private var selectedEquipment: EquipmentRecord?
    @AppStorage("isExportListEnabled") private var isExportListEnabled = false

    private let pageSize = 20

    private var cleanSearch: String {
        searchText.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
    }

    private var filteredEquipment: [EquipmentRecord] {
        let matchingEquipment = equipment.filter { item in
            let matchesSearch =
                cleanSearch.isEmpty
                || item.equipmentNumber.localizedCaseInsensitiveContains(cleanSearch)
                || item.category.localizedCaseInsensitiveContains(cleanSearch)
                || item.equipmentType.localizedCaseInsensitiveContains(cleanSearch)
                || item.referenceID.localizedCaseInsensitiveContains(cleanSearch)
                || item.licensePlate.localizedCaseInsensitiveContains(cleanSearch)
                || item.vinNumber.localizedCaseInsensitiveContains(cleanSearch)
                || item.fullName.localizedCaseInsensitiveContains(cleanSearch)
                || item.organizationName.localizedCaseInsensitiveContains(cleanSearch)
                || item.locations
                    .joined(separator: " ")
                    .localizedCaseInsensitiveContains(cleanSearch)
                || item.accessType
                    .localizedCaseInsensitiveContains(cleanSearch)

            let selectedLocation = locations[selectedLocationIndex]

            let matchesLocation =
                selectedLocation == "All locations"
                || item.locations.contains(selectedLocation)
                || item.locations.contains("All locations")

            let matchesFilter: Bool

            switch equipmentFilter {
            case .all:
                matchesFilter = true

            case .activeOnly:
                matchesFilter = item.isActive

            case .trucksOnly:
                matchesFilter = ["Bobtail", "Straight truck"].contains(item.category)

            case .trailersOnly:
                matchesFilter = item.category == "Trailer"

            case .forkliftsOnly:
                matchesFilter = item.category == "Forklift"

            case .containersOnly:
                matchesFilter = item.category == "Container"

            case .bannedOnly:
                matchesFilter = item.accessType == "Banned Access"

            case .priorityOnly:
                matchesFilter = item.accessType == "Priority Access"

            case .specializedOnly:
                matchesFilter = item.accessType == "Specialized Access"

            case .newThisWeek:
                matchesFilter = item.isNewThisWeek
            }

            return matchesSearch
                && matchesLocation
                && matchesFilter
        }

        switch sortOrder {
        case .recentlyAdded:
            return matchingEquipment.sorted {
                $0.addedOrder > $1.addedOrder
            }

        case .oldestAdded:
            return matchingEquipment.sorted {
                $0.addedOrder < $1.addedOrder
            }

        case .numberAscending:
            return matchingEquipment.sorted {
                $0.equipmentNumber.localizedStandardCompare(
                    $1.equipmentNumber
                ) == .orderedAscending
            }

        case .numberDescending:
            return matchingEquipment.sorted {
                $0.equipmentNumber.localizedStandardCompare(
                    $1.equipmentNumber
                ) == .orderedDescending
            }

        case .category:
            return matchingEquipment.sorted {
                $0.category.localizedStandardCompare(
                    $1.category
                ) == .orderedAscending
            }

        case .type:
            return matchingEquipment.sorted {
                $0.equipmentType.localizedStandardCompare(
                    $1.equipmentType
                ) == .orderedAscending
            }

        case .location:
            return matchingEquipment.sorted {
                $0.locations
                    .joined(separator: " ")
                    .localizedStandardCompare(
                        $1.locations.joined(separator: " ")
                    ) == .orderedAscending
            }

        case .accessType:
            return matchingEquipment.sorted {
                $0.accessType.localizedStandardCompare(
                    $1.accessType
                ) == .orderedAscending
            }
        }
    }

    private var pageEquipment: [EquipmentRecord] {
        let start = page * pageSize

        guard start < filteredEquipment.count else {
            return []
        }

        return Array(
            filteredEquipment
                .dropFirst(start)
                .prefix(pageSize)
        )
    }

    var body: some View {
        VStack(spacing: 0) {
            EquipmentResultsContent(
                equipment: pageEquipment,
                resultCount: filteredEquipment.count,
                locations: locations,
                selectedLocationIndex: $selectedLocationIndex,
                page: page,
                pageSize: pageSize,
                hasActiveSortOrFilter: equipmentFilter != .all
                    || selectedLocationIndex != 1
                    || sortOrder != .recentlyAdded,
                onResetSortAndFilters: {
                    equipmentFilter = .all
                    selectedLocationIndex = 1
                    sortOrder = .recentlyAdded
                    page = 0
                },
                onSelect: { item in
                    selectedEquipment = item
                },
                onPrevious: {
                    page = max(page - 1, 0)
                },
                onNext: {
                    let maxPage = max(
                        (filteredEquipment.count - 1) / pageSize,
                        0
                    )

                    page = min(page + 1, maxPage)
                }
            )
        }
        .navigationTitle("Equipment")
        .navigationBarTitleDisplayMode(.inline)
        .reportingPageContext("Equipment")
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
                    Menu("Sort", systemImage: "arrow.up.arrow.down") {
                        ForEach(EquipmentSortOrder.allCases) { order in
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
                                    Text(order.title)
                                }
                            }
                        }

                        Divider()

                        Button("Reset to default") {
                            sortOrder = .recentlyAdded
                            page = 0
                        }
                    }

                    Menu("Filter", systemImage: "line.3.horizontal.decrease.circle") {
                        ForEach(EquipmentFilter.allCases) { filter in
                            Button {
                                equipmentFilter = filter
                                page = 0
                            } label: {
                                if equipmentFilter == filter {
                                    Label(
                                        filter.title,
                                        systemImage: "checkmark"
                                    )
                                } else {
                                    Text(filter.title)
                                }
                            }
                        }

                        Divider()

                        Button("Reset to default") {
                            equipmentFilter = .all
                            page = 0
                        }
                    }

                    if isExportListEnabled {
                        Section("Actions") {
                            Button {
                                // Export action
                            } label: {
                                Label(
                                    "Export list",
                                    systemImage: "square.and.arrow.up"
                                )
                            }
                        }

                        if equipmentFilter != .all
                            || selectedLocationIndex != 1
                            || sortOrder != .recentlyAdded
                        {
                            Button {
                                equipmentFilter = .all
                                selectedLocationIndex = 1
                                sortOrder = .recentlyAdded
                                page = 0
                            } label: {
                                Text("Reset view")
                                    .foregroundStyle(.blue)
                            }
                            .tint(.blue)
                        }
                    }
                } label: {
                    Image(
                        systemName: equipmentFilter != .all
                            || selectedLocationIndex != 1
                            || sortOrder != .recentlyAdded
                            ? "ellipsis.circle.fill"
                            : "ellipsis"
                    )
                }
                .tint(.primary)
                .accessibilityLabel("Sort, filter, and more")

                Button {
                    HapticFeedback.lightImpact()
                    showingEditor = true
                } label: {
                    Image(systemName: "plus")
                        .font(.body.weight(.semibold))
                }
                .tint(.blue)
                .accessibilityLabel("Add equipment")
            }
        }
        .equipmentConditionalSearch(
            isPresented: $isSearchPresented,
            text: $searchText,
            prompt: "Search equipment"
        )
        .onChange(of: searchText) { _, _ in
            page = 0
        }
        .onChange(of: equipmentFilter) { _, _ in
            page = 0
        }
        .onChange(of: selectedLocationIndex) { _, _ in
            page = 0
        }
        .onChange(of: sortOrder) { _, _ in
            page = 0
        }
        .sheet(isPresented: $showingEditor) {
            EquipmentEditorView()
        }
        .sheet(item: $selectedEquipment) { equipment in
            EquipmentEditorView(
                equipment: equipment,
                isAuthorizationActive: self.equipment.first(
                    where: { $0.id == equipment.id }
                )?.isActive ?? true,
                onRemoveAuthorization: {
                    guard let index = self.equipment.firstIndex(
                        where: { $0.id == equipment.id }
                    ) else {
                        return
                    }

                    self.equipment[index].isActive = false
                }
            )
        }
    }
}


// MARK: - Sorting

private enum EquipmentSortOrder:
    String,
    CaseIterable,
    Identifiable
{
    case recentlyAdded
    case oldestAdded
    case numberAscending
    case numberDescending
    case category
    case type
    case location
    case accessType

    var id: Self { self }

    var title: String {
        switch self {
        case .recentlyAdded:
            return "Recently added"
        case .oldestAdded:
            return "Oldest added"
        case .numberAscending:
            return "Equipment number A-Z"
        case .numberDescending:
            return "Equipment number Z-A"
        case .category:
            return "Category"
        case .type:
            return "Type"
        case .location:
            return "Location"
        case .accessType:
            return "Access type"
        }
    }

    var systemImage: String {
        switch self {
        case .recentlyAdded:
            return "clock.arrow.circlepath"
        case .oldestAdded:
            return "clock"
        case .numberAscending:
            return "textformat.abc"
        case .numberDescending:
            return "textformat.abc"
        case .category:
            return "square.grid.2x2"
        case .type:
            return "truck.box"
        case .location:
            return "mappin.and.ellipse"
        case .accessType:
            return "key"
        }
    }
}


// MARK: - Filtering

private enum EquipmentFilter:
    String,
    CaseIterable,
    Identifiable
{
    case all
    case activeOnly
    case trucksOnly
    case trailersOnly
    case forkliftsOnly
    case containersOnly
    case bannedOnly
    case priorityOnly
    case specializedOnly
    case newThisWeek

    var id: Self { self }

    var title: String {
        switch self {
        case .all:
            return "All equipment"
        case .activeOnly:
            return "Active only"
        case .trucksOnly:
            return "Trucks only"
        case .trailersOnly:
            return "Trailers only"
        case .forkliftsOnly:
            return "Forklifts only"
        case .containersOnly:
            return "Containers only"
        case .bannedOnly:
            return "Banned only"
        case .priorityOnly:
            return "Priority access only"
        case .specializedOnly:
            return "Specialized access only"
        case .newThisWeek:
            return "New this week"
        }
    }

    var systemImage: String {
        switch self {
        case .all:
            return "truck.box"
        case .activeOnly:
            return "checkmark.circle"
        case .trucksOnly:
            return "truck.box"
        case .trailersOnly:
            return "shippingbox"
        case .forkliftsOnly:
            return "shippingbox.and.arrow.backward"
        case .containersOnly:
            return "shippingbox.fill"
        case .bannedOnly:
            return "nosign"
        case .priorityOnly:
            return "star"
        case .specializedOnly:
            return "slider.horizontal.3"
        case .newThisWeek:
            return "sparkles"
        }
    }
}


// MARK: - Equipment Record

struct EquipmentRecord: Identifiable {
    let id: Int
    let equipmentNumber: String
    let category: String
    let equipmentType: String
    let referenceID: String
    let licensePlate: String
    let vinNumber: String
    let fullName: String
    let organizationName: String
    let locations: [String]
    let accessType: String
    let periodAccess: String
    let hasNote: Bool
    let isLimitedTime: Bool
    var isActive: Bool
    let addedOrder: Int
    let isNewThisWeek: Bool
}


// MARK: - Results

private struct EquipmentResultsContent: View {
    let equipment: [EquipmentRecord]
    let resultCount: Int
    let locations: [String]

    @Binding var selectedLocationIndex: Int

    let page: Int
    let pageSize: Int
    let hasActiveSortOrFilter: Bool
    let onResetSortAndFilters: () -> Void

    let onSelect: (EquipmentRecord) -> Void
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

                    if hasActiveSortOrFilter {
                        Button("Reset view") {
                            onResetSortAndFilters()
                        }
                        .font(.subheadline.weight(.semibold))
                        .buttonStyle(.plain)
                        .foregroundStyle(.blue)
                    }

                    Spacer()

                    EquipmentLocationSwitcher(
                        locations: locations,
                        selectedIndex: $selectedLocationIndex
                    )
                }
                .padding(.horizontal, 16)

                if equipment.isEmpty {
                    ContentUnavailableView(
                        "No equipment found",
                        systemImage: "truck.box",
                        description: Text(
                            "Try changing your search or filters."
                        )
                    )
                    .padding(.top, 54)
                    .padding(.horizontal, 24)
                } else {
                    EquipmentCard(
                        equipment: equipment,
                        onSelect: onSelect
                    )

                    EquipmentPaginationFooter(
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


// MARK: - Equipment Card

private struct EquipmentCard: View {
    let equipment: [EquipmentRecord]
    let onSelect: (EquipmentRecord) -> Void

    var body: some View {
        VStack(spacing: 0) {
            ForEach(
                equipment.enumerated(),
                id: \.element.id
            ) { index, item in
                Button {
                    onSelect(item)
                } label: {
                    EquipmentRow(
                        item: item
                    )
                }
                .buttonStyle(.plain)

                if index < equipment.count - 1 {
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
    fileprivate func equipmentConditionalSearch(
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

private struct EquipmentLocationSwitcher: View {
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


// MARK: - Equipment Row

private struct EquipmentRow: View {
    let item: EquipmentRecord

    private var accentColor: Color {
        switch item.accessType {
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

    private var equipmentIcon: EquipmentCategoryIcon {
        EquipmentCategoryIcon(
            category: item.category,
            tint: accentColor
        )
    }

    var body: some View {
        HStack(
            alignment: .top,
            spacing: 12
        ) {
            equipmentIcon
                .frame(
                    width: 34,
                    height: 34
                )
                .background(
                    accentColor.opacity(0.10),
                    in: RoundedRectangle(
                        cornerRadius: 10,
                        style: .continuous
                    )
                )

            VStack(
                alignment: .leading,
                spacing: 6
            ) {
                Text("\(item.equipmentType) · \(item.equipmentNumber)")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.primary)

                if let detailsSummary {
                    Text(detailsSummary)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                compactLocationAndAccess
            }
            .frame(
                maxWidth: .infinity,
                alignment: .leading
            )

            if item.isNewThisWeek {
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

    private var detailsSummary: String? {
        let values = [
            item.licensePlate,
            item.vinNumber,
            item.fullName,
            item.organizationName,
        ]
        .filter {
            !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
        .prefix(2)

        guard !values.isEmpty else {
            return nil
        }

        return values.joined(separator: " · ")
    }

    private var compactLocationAndAccess: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 8) {
                EquipmentLocationLabel(
                    locations: item.locations
                )

                EquipmentAccessTypeChip(
                    accessType: item.accessType,
                    periodAccess: item.periodAccess,
                    hasNote: item.hasNote,
                    isLimitedTime: item.isLimitedTime
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
                EquipmentLocationLabel(
                    locations: item.locations
                )

                EquipmentAccessTypeChip(
                    accessType: item.accessType,
                    periodAccess: item.periodAccess,
                    hasNote: item.hasNote,
                    isLimitedTime: item.isLimitedTime
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

private struct EquipmentLocationLabel: View {
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

private struct EquipmentAccessTypeChip: View {
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

struct EquipmentEditorView: View {
    @Environment(\.dismiss) private var dismiss

    let equipment: EquipmentRecord?
    @State private var isAuthorizationActive: Bool
    let onRemoveAuthorization: () -> Void

    @State private var equipmentCategory: String
    @State private var equipmentNumber: String
    @State private var licensePlate: String
    @State private var vinNumber: String
    @State private var fullName: String
    @State private var organizationName: String
    @State private var accessPoint: String
    @State private var accessPolicy: AccessPolicy

    @State private var moreDetailsExpanded = false
    @State private var showingQuickScanOptions = false
    @State private var showingAccessPolicy = false
    @State private var showingRemoveAuthorizationConfirmation = false

    @FocusState private var focusedField: Field?

    private enum Field {
        case equipmentNumber
        case licensePlate
        case vinNumber
    }

    private let categories = [
        "Car",
        "Bobtail",
        "Straight truck",
        "Trailer",
        "Container",
        "Forklift",
    ]

    private let people = [
        "Select a person",
        "David Okafor",
        "Olivia Martin",
        "Elias Petrov",
        "Milan Jović",
    ]

    private let organizations = [
        "Select an organization",
        "Northstar Logistics",
        "CargoTrucks",
        "Bison Transport",
    ]

    private let accessPoints = [
        "Full Facility Access",
        "Main Gate",
        "Gate In",
        "Gate Out",
    ]

    init(
        equipment: EquipmentRecord? = nil,
        isAuthorizationActive: Bool = true,
        onRemoveAuthorization: @escaping () -> Void = {}
    ) {
        self.equipment = equipment
        _isAuthorizationActive = State(initialValue: isAuthorizationActive)
        self.onRemoveAuthorization = onRemoveAuthorization

        _equipmentCategory = State(
            initialValue:
                equipment?.category ?? "Straight truck"
        )

        _equipmentNumber = State(
            initialValue:
                equipment?.equipmentNumber ?? ""
        )

        _licensePlate = State(
            initialValue:
                equipment?.licensePlate ?? ""
        )

        _vinNumber = State(
            initialValue:
                equipment?.vinNumber ?? ""
        )

        _fullName = State(
            initialValue:
                equipment?.fullName.isEmpty == false
                    ? equipment!.fullName
                    : "Select a person"
        )

        _organizationName = State(
            initialValue:
                equipment?.organizationName.isEmpty == false
                    ? equipment!.organizationName
                    : "Select an organization"
        )

        _accessPoint = State(
            initialValue:
                "Full Facility Access"
        )

        var policy = AccessPolicy()

        if let equipment {
            policy.locations = equipment.locations.joined(
                separator: ", "
            )
            policy.accessType = equipment.accessType
            policy.periodAccess = equipment.periodAccess
            policy.limitedTimeAccess = equipment.isLimitedTime

            if equipment.hasNote {
                policy.note = "Existing authorization note"
            }
        }

        _accessPolicy = State(
            initialValue: policy
        )
    }

    private var canSave: Bool {
        !equipmentNumber
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            )
            .isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                if equipment == nil {
                    quickScanSection
                }

                VStack(
                    alignment: .leading,
                    spacing: 20
                ) {
                    categoryField
                    equipmentNumberField
                    moreDetailsArea
                    accessPolicyArea

                    if equipment != nil {
                        updateDetails
                        removeAuthorizationButton
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
                equipment == nil
                    ? "Add equipment"
                    : "Edit equipment"
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
                isPresented:
                    $showingQuickScanOptions,
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
                    "Choose how you want to scan the equipment tag or label."
                )
            }
            .alert(
                "Remove authorization?",
                isPresented: $showingRemoveAuthorizationConfirmation
            ) {
                Button("Remove authorization", role: .destructive) {
                    focusedField = nil
                    onRemoveAuthorization()
                    dismiss()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will not delete \(equipment?.equipmentNumber ?? "this equipment"). It will be marked inactive and will no longer have access. Its name will remain in the system for previous records and history. To give it access again later, add a new access policy.")
            }
            .sheet(
                isPresented: $showingAccessPolicy
            ) {
                AccessPolicyEditorView(
                    policy: accessPolicy,
                    onSave: { updatedPolicy in
                        accessPolicy = updatedPolicy
                    }
                )
            }
        }
    }

    private var removeAuthorizationButton: some View {
        Button(role: .destructive) {
            focusedField = nil
            showingRemoveAuthorizationConfirmation = true
        } label: {
            Text("Remove authorization")
                .font(.caption.weight(.medium))
        }
        .padding(.horizontal, 16)
        .padding(.top, 4)
        .disabled(!isAuthorizationActive)
        .accessibilityHint(
            isAuthorizationActive
                ? "Marks this equipment inactive and removes its access."
                : "Authorization has already been removed."
        )
    }

    // MARK: Quick Scan

    private var quickScanSection: some View {
        Section {
            Button {
                focusedField = nil
                showingQuickScanOptions = true
            } label: {
                HStack(spacing: 12) {
                    Image(
                        systemName: "text.viewfinder"
                    )
                    .font(
                        .title3.weight(.semibold)
                    )
                    .foregroundStyle(.blue)
                    .frame(
                        width: 44,
                        height: 44
                    )
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
                            .font(
                                .body.weight(.semibold)
                            )
                            .foregroundStyle(.blue)

                        Text(
                            "Scan the equipment tag or label to fill in the data."
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

    private var categoryField: some View {
        menuField(
            title: "Equipment category",
            required: true,
            selection: $equipmentCategory,
            options: categories
        )
    }

    private var equipmentNumberField: some View {
        formField(
            title: "Equipment number",
            required: true
        ) {
            TextField(
                "Enter equipment number",
                text: $equipmentNumber
            )
            .focused(
                $focusedField,
                equals: .equipmentNumber
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
            licensePlate,
            vinNumber,
            fullName == "Select a person"
                ? ""
                : fullName,
            organizationName ==
                "Select an organization"
                ? ""
                : organizationName,
            accessPoint ==
                "Full Facility Access"
                ? ""
                : accessPoint,
        ]
        .filter {
            !$0.trimmingCharacters(
                in: .whitespacesAndNewlines
            ).isEmpty
        }

        if values.isEmpty {
            Text("No additional details")
                .font(.subheadline)
                .foregroundStyle(.tertiary)
        } else {
            WrappingDetailFlowLayout(spacing: 6) {
                ForEach(
                    values,
                    id: \.self
                ) { value in
                    Text(value)
                        .font(
                            .caption.weight(.medium)
                        )
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.leading)
                        .padding(.horizontal, 9)
                        .padding(.vertical, 5)
                        .background(
                            Color(.secondarySystemGroupedBackground),
                            in: RoundedRectangle(cornerRadius: 9, style: .continuous)
                        )
                }
            }
        }
    }

    private var moreDetailsFields: some View {
        VStack(spacing: 0) {
            detailsRow(
                title: "License plate"
            ) {
                TextField(
                    "Optional",
                    text: $licensePlate,
                    axis: .vertical
                )
                .focused(
                    $focusedField,
                    equals: .licensePlate
                )
                .textInputAutocapitalization(
                    .characters
                )
                .autocorrectionDisabled()
                .multilineTextAlignment(
                    .trailing
                )
            }

            rowDivider

            detailsRow(
                title: "VIN number"
            ) {
                TextField(
                    "Optional",
                    text: $vinNumber,
                    axis: .vertical
                )
                .focused(
                    $focusedField,
                    equals: .vinNumber
                )
                .textInputAutocapitalization(
                    .characters
                )
                .autocorrectionDisabled()
                .multilineTextAlignment(
                    .trailing
                )
            }

            rowDivider
            personMenu
            rowDivider
            organizationMenu
            rowDivider
            accessPointMenu
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

    private var personMenu: some View {
        Menu {
            ForEach(
                people,
                id: \.self
            ) { person in
                Button {
                    fullName = person
                } label: {
                    if fullName == person {
                        Label(
                            person,
                            systemImage: "checkmark"
                        )
                    } else {
                        Text(person)
                    }
                }
            }
        } label: {
            menuRow(
                label: "Full name",
                value:
                    fullName ==
                        "Select a person"
                    ? "Optional"
                    : fullName
            )
        }
        .buttonStyle(.plain)
    }

    private var organizationMenu: some View {
        Menu {
            ForEach(
                organizations,
                id: \.self
            ) { organization in
                Button {
                    organizationName =
                        organization
                } label: {
                    if organizationName ==
                        organization
                    {
                        Label(
                            organization,
                            systemImage: "checkmark"
                        )
                    } else {
                        Text(organization)
                    }
                }
            }
        } label: {
            menuRow(
                label: "Organization",
                value:
                    organizationName ==
                        "Select an organization"
                    ? "Optional"
                    : organizationName
            )
        }
        .buttonStyle(.plain)
    }

    private var accessPointMenu: some View {
        Menu {
            ForEach(
                accessPoints,
                id: \.self
            ) { point in
                Button {
                    accessPoint = point
                } label: {
                    if accessPoint == point {
                        Label(
                            point,
                            systemImage: "checkmark"
                        )
                    } else {
                        Text(point)
                    }
                }
            }
        } label: {
            menuRow(
                label: "Access points",
                value: accessPoint
            )
        }
        .buttonStyle(.plain)
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
                        HStack(spacing: 10) {
                            EquipmentCategoryIcon(
                                category: option
                            )
                            .frame(width: 28, height: 18)

                            Text(option)

                            if selection.wrappedValue == option {
                                Spacer()
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                HStack(spacing: 10) {
                    EquipmentCategoryIcon(
                        category: selection.wrappedValue
                    )
                    .frame(width: 32, height: 20)

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

            HStack(spacing: 5) {
                Text(value)
                    .foregroundStyle(.blue)
                    .multilineTextAlignment(.trailing)
                    .frame(maxWidth: 180, alignment: .trailing)

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


// MARK: - Editor Access Chip

private struct EquipmentEditorAccessChip: View {
    let accessType: String

    private var tint: Color {
        switch accessType {
        case "Banned Access":
            return .red
        case "Priority Access":
            return .blue
        case "Specialized Access":
            return .orange
        default:
            return .primary
        }
    }

    var body: some View {
        HStack(spacing: 5) {
            Text(accessType)
                .font(
                    .caption.weight(
                        .semibold
                    )
                )

            Image(
                systemName:
                    "infinity"
            )
            .font(
                .caption.weight(
                    .semibold
                )
            )
        }
        .foregroundStyle(tint)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Color(
                .secondarySystemBackground
            ),
            in: Capsule()
        )
    }
}


// MARK: - Pagination

private struct EquipmentPaginationFooter: View {
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
