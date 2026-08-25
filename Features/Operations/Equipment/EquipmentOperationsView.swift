import SwiftUI

struct EquipmentOperationsView: View {

    private let equipment: [EquipmentRecord] = (1...100).map { index in
        let categories = [
            "Truck",
            "Trailer",
            "Forklift",
            "Container",
        ]

        let equipmentTypes = [
            "Truck",
            "Box",
            "4-door car",
            "Container",
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

        return EquipmentRecord(
            id: index,
            equipmentNumber: index.isMultiple(of: 5)
                ? "TR-\(500 + index)"
                : "Unit \(index)",
            category: categories[index % categories.count],
            equipmentType: equipmentTypes[index % equipmentTypes.count],
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
                matchesFilter = item.category == "Truck"

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
                    isSearchPresented = true
                } label: {
                    Image(systemName: "magnifyingglass")
                }
                .tint(.primary)
                .accessibilityLabel("Search")

                Menu {
                    Section("Sort") {
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
                                    Label(
                                        order.title,
                                        systemImage: order.systemImage
                                    )
                                }
                            }
                        }
                    }

                    Section("Filter") {
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

                        if equipmentFilter != .all
                            || !searchText.isEmpty
                            || selectedLocationIndex != 1
                            || sortOrder != .recentlyAdded
                        {
                            Button {
                                equipmentFilter = .all
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
                equipment: equipment
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

private struct EquipmentRecord: Identifiable {
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
    let isActive: Bool
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

    private var equipmentIcon: String {
        switch item.category {
        case "Truck":
            return "truck.box.fill"
        case "Trailer":
            return "shippingbox.fill"
        case "Forklift":
            return "shippingbox.and.arrow.backward.fill"
        case "Container":
            return "shippingbox.fill"
        default:
            return "truck.box.fill"
        }
    }

    var body: some View {
        HStack(
            alignment: .top,
            spacing: 12
        ) {
            Image(systemName: equipmentIcon)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(accentColor)
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
                Text(item.equipmentNumber)
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

    private var wideMetadataRow: some View {
        HStack(spacing: 6) {
            Text(item.category)

            metadataSeparator

            Text(item.equipmentType)

            metadataSeparator

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
                Text(item.category)

                metadataSeparator

                Text(item.equipmentType)
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

            if periodAccess == "Ongoing" {
                Image(systemName: "infinity")
                    .font(.caption.weight(.semibold))
            } else {
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

private struct EquipmentEditorView: View {
    @Environment(\.dismiss) private var dismiss

    let equipment: EquipmentRecord?

    @State private var equipmentCategory: String
    @State private var equipmentNumber: String
    @State private var licensePlate: String
    @State private var vinNumber: String
    @State private var fullName: String
    @State private var organizationName: String
    @State private var accessPoint: String
    @State private var accessType: String

    @State private var moreDetailsExpanded = true
    @State private var showingQuickScanOptions = false

    private let categories = [
        "Truck",
        "Trailer",
        "Forklift",
        "Container",
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

    private let accessTypes = [
        "Default Access",
        "Priority Access",
        "Specialized Access",
        "Banned Access",
    ]

    init(
        equipment: EquipmentRecord? = nil
    ) {
        self.equipment = equipment

        _equipmentCategory = State(
            initialValue:
                equipment?.category ?? "Truck"
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
            initialValue: "Full Facility Access"
        )

        _accessType = State(
            initialValue:
                equipment?.accessType ?? "Default Access"
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
            ScrollView {
                VStack(
                    alignment: .leading,
                    spacing: 26
                ) {
                    quickScanButton

                    VStack(
                        alignment: .leading,
                        spacing: 20
                    ) {
                        pickerField(
                            title: "Equipment category",
                            required: true,
                            selection: $equipmentCategory,
                            options: categories
                        )

                        textField(
                            title: "Equipment number",
                            required: true,
                            placeholder: "Enter equipment number",
                            text: $equipmentNumber
                        )

                        moreDetailsArea
                    }

                    authorizationSection
                }
                .padding(.horizontal, 20)
                .padding(.top, 18)
                .padding(.bottom, 40)
            }
            .navigationTitle(
                equipment == nil
                    ? "Add equipment authorization"
                    : "Edit equipment authorization"
            )
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(
                    placement: .cancellationAction
                ) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(
                    placement: .confirmationAction
                ) {
                    Button("Save") {
                        dismiss()
                    }
                    .tint(.blue)
                    .disabled(!canSave)
                }
            }
            .confirmationDialog(
                "Quick scan",
                isPresented: $showingQuickScanOptions,
                titleVisibility: .visible
            ) {
                Button("Camera") { }
                Button("Photos") { }
                Button("Files") { }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text(
                    "Choose how you want to scan the equipment tag or label."
                )
            }
        }
        .presentationDetents([
            .large,
        ])
    }

    private var quickScanButton: some View {
        Button {
            showingQuickScanOptions = true
        } label: {
            HStack(spacing: 14) {
                Image(
                    systemName:
                        "viewfinder.circle"
                )
                .font(.title3.weight(.semibold))

                VStack(
                    alignment: .leading,
                    spacing: 3
                ) {
                    Text(
                        "Quick scan for equipment details"
                    )
                    .font(
                        .headline.weight(
                            .semibold
                        )
                    )

                    Text(
                        "Scan the equipment tag or label."
                    )
                    .font(.subheadline)
                    .foregroundStyle(
                        .secondary
                    )
                }

                Spacer()
            }
            .foregroundStyle(.blue)
            .padding(.horizontal, 18)
            .padding(.vertical, 13)
            .background(
                .blue.opacity(0.12),
                in: RoundedRectangle(
                    cornerRadius: 18,
                    style: .continuous
                )
            )
        }
        .buttonStyle(.plain)
    }

    private var moreDetailsArea: some View {
        VStack(
            alignment: .leading,
            spacing: 18
        ) {
            Button {
                withAnimation(
                    .easeInOut(duration: 0.18)
                ) {
                    moreDetailsExpanded.toggle()
                }
            } label: {
                HStack(spacing: 6) {
                    Text("More details")
                        .font(
                            .subheadline.weight(
                                .semibold
                            )
                        )

                    Image(
                        systemName:
                            moreDetailsExpanded
                                ? "chevron.up"
                                : "chevron.down"
                    )
                    .font(
                        .caption.weight(
                            .semibold
                        )
                    )
                }
                .foregroundStyle(
                    .secondary
                )
            }
            .buttonStyle(.plain)

            if moreDetailsExpanded {
                VStack(
                    alignment: .leading,
                    spacing: 20
                ) {
                    textField(
                        title: "License plate",
                        placeholder:
                            "Enter license plate",
                        text: $licensePlate
                    )

                    textField(
                        title: "VIN number",
                        placeholder:
                            "Enter VIN number",
                        text: $vinNumber
                    )

                    pickerField(
                        title: "Full name",
                        selection: $fullName,
                        options: people
                    )

                    pickerField(
                        title: "Organization name",
                        selection: $organizationName,
                        options: organizations
                    )

                    pickerField(
                        title: "Access points",
                        selection: $accessPoint,
                        options: accessPoints
                    )
                }
                .transition(.opacity)
            }
        }
    }

    private var authorizationSection: some View {
        VStack(
            alignment: .leading,
            spacing: 18
        ) {
            Text("Authorization")
                .font(
                    .title3.weight(
                        .semibold
                    )
                )

            HStack(
                alignment: .top,
                spacing: 12
            ) {
                Image(
                    systemName:
                        "mappin.and.ellipse"
                )
                .font(.body.weight(.semibold))
                .frame(
                    width: 34,
                    height: 34
                )
                .background(
                    Color(
                        .secondarySystemBackground
                    ),
                    in: Circle()
                )

                VStack(
                    alignment: .leading,
                    spacing: 7
                ) {
                    HStack(spacing: 8) {
                        Text(
                            "Northstar (Oshawa)"
                        )
                        .font(
                            .subheadline.weight(
                                .medium
                            )
                        )
                        .foregroundStyle(
                            .secondary
                        )

                        EquipmentEditorAccessChip(
                            accessType:
                                accessType
                        )
                    }

                    Text(
                        "Ongoing access period"
                    )
                    .font(.subheadline)
                    .foregroundStyle(
                        .secondary
                    )
                }

                Spacer()

                Menu {
                    ForEach(
                        accessTypes,
                        id: \.self
                    ) { type in
                        Button {
                            accessType = type
                        } label: {
                            if accessType == type {
                                Label(
                                    type,
                                    systemImage:
                                        "checkmark"
                                )
                            } else {
                                Text(type)
                            }
                        }
                    }
                } label: {
                    Label(
                        "Edit",
                        systemImage:
                            "pencil"
                    )
                    .font(
                        .subheadline.weight(
                            .semibold
                        )
                    )
                    .padding(
                        .horizontal,
                        14
                    )
                    .padding(
                        .vertical,
                        9
                    )
                    .background(
                        Color(
                            .secondarySystemBackground
                        ),
                        in: Capsule()
                    )
                }
                .buttonStyle(.plain)
                .foregroundStyle(
                    .secondary
                )
            }
        }
        .padding(.top, 6)
    }

    private func textField(
        title: String,
        required: Bool = false,
        placeholder: String,
        text: Binding<String>
    ) -> some View {
        VStack(
            alignment: .leading,
            spacing: 8
        ) {
            HStack(spacing: 2) {
                Text(title)

                if required {
                    Text("*")
                        .foregroundStyle(
                            .red
                        )
                }
            }
            .font(
                .subheadline.weight(
                    .medium
                )
            )

            TextField(
                placeholder,
                text: text
            )
            .textFieldStyle(.roundedBorder)
        }
    }

    private func pickerField(
        title: String,
        required: Bool = false,
        selection: Binding<String>,
        options: [String]
    ) -> some View {
        VStack(
            alignment: .leading,
            spacing: 8
        ) {
            HStack(spacing: 2) {
                Text(title)

                if required {
                    Text("*")
                        .foregroundStyle(
                            .red
                        )
                }
            }
            .font(
                .subheadline.weight(
                    .medium
                )
            )

            Picker(
                title,
                selection: selection
            ) {
                ForEach(
                    options,
                    id: \.self
                ) { option in
                    Text(option)
                        .tag(option)
                }
            }
            .pickerStyle(.menu)
            .frame(
                maxWidth: .infinity,
                alignment: .leading
            )
            .padding(.horizontal, 12)
            .frame(height: 44)
            .background(
                Color(
                    .secondarySystemBackground
                ),
                in: RoundedRectangle(
                    cornerRadius: 12,
                    style: .continuous
                )
            )
            .overlay {
                RoundedRectangle(
                    cornerRadius: 12,
                    style: .continuous
                )
                .strokeBorder(
                    Color.secondary
                        .opacity(0.2),
                    lineWidth: 1
                )
            }
        }
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
