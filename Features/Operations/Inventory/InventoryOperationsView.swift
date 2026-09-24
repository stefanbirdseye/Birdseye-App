// COUNTER CHIPS + ICON ACTIONS + CAPSULE GLASS COMPLETE - 2026-08-28
// UPDATED ROW ACTIONS + GLASS COMPLETE + COUNTERS - 2026-08-28
// NATIVE INVENTORY CHECK SELECTION BUILD - 2026-08-28 16:10
// NEW INVENTORY CHECK BUILD - 2026-08-28 14:00
// FINAL INVENTORY CHECK LAYOUT - 2026-08-28 15:33
import SwiftUI

struct InventoryOperationsView: View {

    @State private var inventory = InventoryRecord.samples
    @State private var inventoryCheckHistory = InventoryCheckSummary.samples

    private let locations = [
        "All locations",
        "Northstar (Oshawa)",
        "Northstar (Dallas)",
        "Northstar (Toronto)",
    ]

    @State private var selectedLocationIndex = 1
    @State private var searchText = ""
    @State private var isSearchPresented = false
    @State private var inventoryFilter: InventoryFilter = .all
    @State private var sortOrder: InventorySortOrder = .recentCheckIn
    @State private var page = 0
    @State private var showingEditor = false
    @State private var selectedItem: InventoryRecord?

    private let pageSize = 20

    private var cleanSearch: String {
        searchText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var selectedLocation: String {
        locations[selectedLocationIndex]
    }

    private var inventoryForStatistics: [InventoryRecord] {
        inventory.filter { item in
            selectedLocation == "All locations"
                || item.location == selectedLocation
        }
    }

    private var filteredInventory: [InventoryRecord] {
        let matchingInventory = inventory.filter { item in
            let matchesSearch =
                cleanSearch.isEmpty
                || item.equipmentNumber.localizedCaseInsensitiveContains(cleanSearch)
                || item.category.localizedCaseInsensitiveContains(cleanSearch)
                || item.equipmentType.localizedCaseInsensitiveContains(cleanSearch)
                || item.referenceID.localizedCaseInsensitiveContains(cleanSearch)
                || item.licensePlate.localizedCaseInsensitiveContains(cleanSearch)
                || item.vinNumber.localizedCaseInsensitiveContains(cleanSearch)
                || item.organizationName.localizedCaseInsensitiveContains(cleanSearch)
                || item.location.localizedCaseInsensitiveContains(cleanSearch)
                || item.yardArea.localizedCaseInsensitiveContains(cleanSearch)
                || item.cargoType.localizedCaseInsensitiveContains(cleanSearch)
                || item.shipmentNumber.localizedCaseInsensitiveContains(cleanSearch)
                || item.cargoSeal.localizedCaseInsensitiveContains(cleanSearch)

            let matchesLocation =
                selectedLocation == "All locations"
                || item.location == selectedLocation

            let matchesFilter: Bool

            switch inventoryFilter {
            case .all:
                matchesFilter = true
            case .trucksOnly:
                matchesFilter = ["Bobtail", "Straight truck"].contains(item.category)
            case .trailersOnly:
                matchesFilter = item.category == "Trailer"
            case .containersOnly:
                matchesFilter = item.category == "Container"
            case .carsOnly:
                matchesFilter = item.category == "Car"
            case .forkliftsOnly:
                matchesFilter = item.category == "Forklift"
            case .reefersOnly:
                matchesFilter = item.isReefer
            case .checkedInToday:
                matchesFilter = Calendar.current.isDateInToday(item.checkInDate)
            case .over24Hours:
                matchesFilter = item.hoursInYard >= 24
            }

            return matchesSearch && matchesLocation && matchesFilter
        }

        switch sortOrder {
        case .recentCheckIn:
            return matchingInventory.sorted { $0.checkInDate > $1.checkInDate }
        case .longestInYard:
            return matchingInventory.sorted { $0.checkInDate < $1.checkInDate }
        case .numberAscending:
            return matchingInventory.sorted {
                $0.equipmentNumber.localizedStandardCompare($1.equipmentNumber) == .orderedAscending
            }
        case .numberDescending:
            return matchingInventory.sorted {
                $0.equipmentNumber.localizedStandardCompare($1.equipmentNumber) == .orderedDescending
            }
        case .category:
            return matchingInventory.sorted {
                $0.category.localizedStandardCompare($1.category) == .orderedAscending
            }
        case .location:
            return matchingInventory.sorted {
                $0.location.localizedStandardCompare($1.location) == .orderedAscending
            }
        case .organization:
            return matchingInventory.sorted {
                $0.organizationName.localizedStandardCompare($1.organizationName) == .orderedAscending
            }
        }
    }

    private var pageInventory: [InventoryRecord] {
        let start = page * pageSize

        guard start < filteredInventory.count else {
            return []
        }

        return Array(
            filteredInventory
                .dropFirst(start)
                .prefix(pageSize)
        )
    }

    var body: some View {
        InventoryResultsContent(
            inventory: pageInventory,
            statisticsInventory: inventoryForStatistics,
            resultCount: filteredInventory.count,
            locations: locations,
            selectedLocationIndex: $selectedLocationIndex,
            checkHistory: $inventoryCheckHistory,
            page: page,
            pageSize: pageSize,
            onSelect: { item in
                selectedItem = item
            },
            onPrevious: {
                page = max(page - 1, 0)
            },
            onNext: {
                let maxPage = max(
                    (filteredInventory.count - 1) / pageSize,
                    0
                )

                page = min(page + 1, maxPage)
            }
        )
        .navigationTitle("Inventory")
        .navigationBarTitleDisplayMode(.inline)
        .reportingPageContext("Inventory")
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button {
                    HapticFeedback.lightImpact()
                    isSearchPresented = true
                } label: {
                    Image(systemName: "magnifyingglass")
                }
                .tint(.primary)
                .accessibilityLabel("Search inventory")

                Menu {
                    Menu("Sort", systemImage: "arrow.up.arrow.down") {
                        ForEach(InventorySortOrder.allCases) { order in
                            Button {
                                sortOrder = order
                                page = 0
                            } label: {
                                if sortOrder == order {
                                    Label(order.title, systemImage: "checkmark")
                                } else {
                                    Label(order.title, systemImage: order.systemImage)
                                }
                            }
                        }

                        Divider()

                        Button("Reset to default") {
                            sortOrder = .recentCheckIn
                            page = 0
                        }
                    }

                    Menu("Filter", systemImage: "line.3.horizontal.decrease.circle") {
                        ForEach(InventoryFilter.allCases) { filter in
                            Button {
                                inventoryFilter = filter
                                page = 0
                            } label: {
                                if inventoryFilter == filter {
                                    Label(filter.title, systemImage: "checkmark")
                                } else {
                                    Label(filter.title, systemImage: filter.systemImage)
                                }
                            }
                        }

                        Divider()

                        Button("Reset to default") {
                            inventoryFilter = .all
                            page = 0
                        }
                    }

                    Section("Actions") {
                        Button {
                            // Export inventory
                        } label: {
                            Label("Export inventory", systemImage: "square.and.arrow.up")
                        }

                        if inventoryFilter != .all
                            || !searchText.isEmpty
                            || selectedLocationIndex != 1
                            || sortOrder != .recentCheckIn
                        {
                            Button {
                                inventoryFilter = .all
                                searchText = ""
                                selectedLocationIndex = 1
                                sortOrder = .recentCheckIn
                                page = 0
                            } label: {
                                Label("Reset view", systemImage: "arrow.counterclockwise")
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
                    showingEditor = true
                } label: {
                    Image(systemName: "plus")
                        .font(.body.weight(.semibold))
                }
                .tint(.blue)
                .accessibilityLabel("Add inventory entry")
            }
        }
        .inventoryConditionalSearch(
            isPresented: $isSearchPresented,
            text: $searchText,
            prompt: "Search inventory"
        )
        .onChange(of: searchText) { _, _ in
            page = 0
        }
        .onChange(of: inventoryFilter) { _, _ in
            page = 0
        }
        .onChange(of: selectedLocationIndex) { _, _ in
            page = 0
        }
        .onChange(of: sortOrder) { _, _ in
            page = 0
        }
        .sheet(isPresented: $showingEditor) {
            InventoryEditorView(
                lockedLocation: selectedLocation == "All locations"
                    ? nil
                    : selectedLocation
            ) { newItem in
                inventory.append(newItem)
            }
        }
        .sheet(item: $selectedItem) { item in
            InventoryEditorView(item: item) { updatedItem in
                guard let index = inventory.firstIndex(where: { $0.id == updatedItem.id }) else {
                    return
                }

                inventory[index] = updatedItem
            }
        }
    }
}


// MARK: - Sorting

private enum InventorySortOrder:
    String,
    CaseIterable,
    Identifiable
{
    case recentCheckIn
    case longestInYard
    case numberAscending
    case numberDescending
    case category
    case location
    case organization

    var id: Self { self }

    var title: String {
        switch self {
        case .recentCheckIn:
            return "Most recently checked in"
        case .longestInYard:
            return "Longest in yard"
        case .numberAscending:
            return "Equipment number A-Z"
        case .numberDescending:
            return "Equipment number Z-A"
        case .category:
            return "Category"
        case .location:
            return "Location"
        case .organization:
            return "Organization"
        }
    }

    var systemImage: String {
        switch self {
        case .recentCheckIn:
            return "clock.arrow.circlepath"
        case .longestInYard:
            return "clock"
        case .numberAscending, .numberDescending:
            return "textformat.abc"
        case .category:
            return "square.grid.2x2"
        case .location:
            return "mappin.and.ellipse"
        case .organization:
            return "building.2"
        }
    }
}


// MARK: - Filtering

private enum InventoryFilter:
    String,
    CaseIterable,
    Identifiable
{
    case all
    case trucksOnly
    case trailersOnly
    case containersOnly
    case carsOnly
    case forkliftsOnly
    case reefersOnly
    case checkedInToday
    case over24Hours

    var id: Self { self }

    var title: String {
        switch self {
        case .all:
            return "All inventory"
        case .trucksOnly:
            return "Trucks only"
        case .trailersOnly:
            return "Trailers only"
        case .containersOnly:
            return "Containers only"
        case .carsOnly:
            return "Cars only"
        case .forkliftsOnly:
            return "Forklifts only"
        case .reefersOnly:
            return "Reefers only"
        case .checkedInToday:
            return "Checked in today"
        case .over24Hours:
            return "In yard over 24 hours"
        }
    }

    var systemImage: String {
        switch self {
        case .all:
            return "shippingbox"
        case .trucksOnly:
            return "truck.box"
        case .trailersOnly:
            return "rectangle.landscape"
        case .containersOnly:
            return "shippingbox.fill"
        case .carsOnly:
            return "car.side"
        case .forkliftsOnly:
            return "shippingbox.and.arrow.backward"
        case .reefersOnly:
            return "snowflake"
        case .checkedInToday:
            return "calendar"
        case .over24Hours:
            return "clock.badge.exclamationmark"
        }
    }
}


// MARK: - Inventory Record

private struct InventoryRecord: Identifiable, Equatable {
    let id: Int

    var equipmentNumber: String
    var category: String
    var equipmentType: String
    var referenceID: String
    var licensePlate: String
    var vinNumber: String
    var organizationName: String
    var location: String
    var yardArea: String
    var checkInDate: Date
    var cargoType: String
    var shipmentNumber: String
    var cargoSeal: String
    var isReefer: Bool
    var reeferTemperature: String

    var hoursInYard: Int {
        max(
            Int(Date.now.timeIntervalSince(checkInDate) / 3600),
            0
        )
    }

    var durationText: String {
        let totalMinutes = max(
            Int(Date.now.timeIntervalSince(checkInDate) / 60),
            0
        )

        let days = totalMinutes / 1_440
        let hours = (totalMinutes % 1_440) / 60
        let minutes = totalMinutes % 60

        if days > 0 {
            return "\(days)d \(hours)h"
        }

        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }

        return "\(minutes)m"
    }

    static let samples: [InventoryRecord] = {
        let locations = [
            "Northstar (Oshawa)",
            "Northstar (Dallas)",
            "Northstar (Toronto)",
        ]

        let yardAreas = [
            "Inbound staging",
            "North lot",
            "Trailer row C",
            "Dock 12",
            "South lot",
            "Outbound staging",
        ]

        let organizations = [
            "Northstar Logistics",
            "Bison Transport",
            "CargoTrucks",
            "Arnold Brothers",
            "Kenco Logistics",
            "DHL Supply Chain",
        ]

        return (1...216).map { index in
            let category: String

            switch index % 10 {
            case 0:
                category = "Car"
            case 1, 2:
                category = "Bobtail"
            case 3:
                category = "Straight truck"
            case 4, 5, 6, 7:
                category = "Trailer"
            case 8:
                category = "Container"
            default:
                category = "Forklift"
            }

            let equipmentType: String

            switch category {
            case "Car":
                equipmentType = "Passenger car"
            case "Bobtail":
                equipmentType = "Semi tractor"
            case "Straight truck":
                equipmentType = "Box truck"
            case "Trailer":
                equipmentType = index.isMultiple(of: 5)
                    ? "Reefer trailer"
                    : "Dry van trailer"
            case "Container":
                equipmentType = index.isMultiple(of: 2)
                    ? "40 ft container"
                    : "20 ft container"
            default:
                equipmentType = "Yard forklift"
            }

            let equipmentNumber: String

            switch category {
            case "Car":
                equipmentNumber = "CAR-\(100 + index)"
            case "Bobtail":
                equipmentNumber = "TRK-\(500 + index)"
            case "Straight truck":
                equipmentNumber = "ST-\(300 + index)"
            case "Trailer":
                equipmentNumber = "TRL-\(8000 + index)"
            case "Container":
                equipmentNumber = "CONT-\(2200 + index)"
            default:
                equipmentNumber = "FLT-\(40 + index)"
            }

            let hasCargo = [
                "Bobtail",
                "Straight truck",
                "Trailer",
                "Container",
            ].contains(category)

            let isReefer =
                category == "Trailer"
                && index.isMultiple(of: 5)

            let minutesInYard =
                18
                + ((index * 197) % 46_000)

            return InventoryRecord(
                id: index,
                equipmentNumber: equipmentNumber,
                category: category,
                equipmentType: equipmentType,
                referenceID: "Birdseye_\(30000 + index)",
                licensePlate: ["Car", "Bobtail", "Straight truck"].contains(category)
                    ? "ON \(3200 + index)"
                    : "",
                vinNumber:
                    ["Car", "Bobtail", "Straight truck"].contains(category)
                    && index.isMultiple(of: 3)
                    ? "1GYS9BKL4TR\(420000 + index)"
                    : "",
                organizationName: organizations[index % organizations.count],
                location: locations[(index - 1) % locations.count],
                yardArea: yardAreas[index % yardAreas.count],
                checkInDate: Date.now.addingTimeInterval(-Double(minutesInYard * 60)),
                cargoType: hasCargo
                    ? [
                        "General freight",
                        "Food products",
                        "Packaging",
                        "Automotive parts",
                        "Empty",
                    ][index % 5]
                    : "",
                shipmentNumber: hasCargo && !index.isMultiple(of: 4)
                    ? "SHP-\(78000 + index)"
                    : "",
                cargoSeal: hasCargo && index.isMultiple(of: 3)
                    ? "SEAL-\(9000 + index)"
                    : "",
                isReefer: isReefer,
                reeferTemperature: isReefer
                    ? "\(2 + (index % 4)) C"
                    : ""
            )
        }
    }()
}


// MARK: - Main Results

private struct InventoryResultsContent: View {
    let inventory: [InventoryRecord]
    let statisticsInventory: [InventoryRecord]
    let resultCount: Int
    let locations: [String]

    @Binding var selectedLocationIndex: Int
    @Binding var checkHistory: [InventoryCheckSummary]

    let page: Int
    let pageSize: Int
    let onSelect: (InventoryRecord) -> Void
    let onPrevious: () -> Void
    let onNext: () -> Void

    private var selectedLocation: String {
        locations[selectedLocationIndex]
    }

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 18) {
                InventoryStatisticsStrip(
                    inventory: statisticsInventory,
                    selectedLocation: selectedLocation,
                    checkHistory: $checkHistory
                )

                HStack(spacing: 12) {
                    Text("\(resultCount) results")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.secondary)
                        .monospacedDigit()

                    Spacer()

                    InventoryLocationSwitcher(
                        locations: locations,
                        selectedIndex: $selectedLocationIndex
                    )
                }
                .padding(.horizontal, 16)

                if inventory.isEmpty {
                    ContentUnavailableView(
                        "No inventory found",
                        systemImage: "shippingbox",
                        description: Text(
                            "Try changing your search, location, or filters."
                        )
                    )
                    .padding(.top, 54)
                    .padding(.horizontal, 24)
                } else {
                    InventoryCard(
                        inventory: inventory,
                        onSelect: onSelect
                    )

                    InventoryPaginationFooter(
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
        .background(Color(.systemGroupedBackground))
    }
}


// MARK: - Statistics Strip

private struct InventoryStatisticsStrip: View {
    let inventory: [InventoryRecord]
    let selectedLocation: String

    @Binding var checkHistory: [InventoryCheckSummary]

    private var truckCount: Int {
        inventory.filter {
            ["Bobtail", "Straight truck"].contains($0.category)
        }.count
    }

    private var trailerCount: Int {
        inventory.filter { $0.category == "Trailer" }.count
    }

    private var containerCount: Int {
        inventory.filter { $0.category == "Container" }.count
    }

    private var reeferCount: Int {
        inventory.filter(\.isReefer).count
    }

    private var over24HoursCount: Int {
        inventory.filter { $0.hoursInYard >= 24 }.count
    }

    private var checkedInTodayCount: Int {
        inventory.filter {
            Calendar.current.isDateInToday($0.checkInDate)
        }.count
    }

    private var lastCheck: InventoryCheckSummary? {
        checkHistory
            .filter {
                selectedLocation == "All locations"
                    || $0.location == selectedLocation
            }
            .sorted { $0.date > $1.date }
            .first
    }

    var body: some View {
        ScrollView(
            .horizontal,
            showsIndicators: false
        ) {
            HStack(spacing: 10) {
                NavigationLink {
                    InventoryChecksView(
                        location: selectedLocation,
                        inventory: inventory,
                        history: $checkHistory
                    )
                } label: {
                    InventoryCheckStatisticCard(
                        lastCheck: lastCheck,
                        location: selectedLocation
                    )
                }
                .buttonStyle(.plain)

                InventoryStatisticCard(
                    title: "In yard",
                    value: "\(inventory.count)",
                    detail: "Total equipment",
                    systemImage: "shippingbox.fill",
                    tint: .blue
                )

                InventoryStatisticCard(
                    title: "Trucks",
                    value: "\(truckCount)",
                    detail: "Bobtail + straight",
                    systemImage: "truck.box.fill",
                    tint: .indigo
                )

                InventoryStatisticCard(
                    title: "Trailers",
                    value: "\(trailerCount)",
                    detail: "Currently in yard",
                    systemImage: "rectangle.landscape",
                    tint: .orange
                )

                InventoryStatisticCard(
                    title: "Containers",
                    value: "\(containerCount)",
                    detail: "Currently in yard",
                    systemImage: "shippingbox.fill",
                    tint: .purple
                )

                InventoryStatisticCard(
                    title: "Reefers",
                    value: "\(reeferCount)",
                    detail: "Temperature controlled",
                    systemImage: "snowflake",
                    tint: .cyan
                )

                InventoryStatisticCard(
                    title: "Over 24 hours",
                    value: "\(over24HoursCount)",
                    detail: "Long-stay equipment",
                    systemImage: "clock.badge.exclamationmark",
                    tint: .orange
                )

                InventoryStatisticCard(
                    title: "Today",
                    value: "\(checkedInTodayCount)",
                    detail: "Checked in today",
                    systemImage: "calendar",
                    tint: .green
                )
            }
            .padding(.horizontal, 16)
        }
        .scrollClipDisabled()
    }
}

private struct InventoryCheckStatisticCard: View {

    let lastCheck: InventoryCheckSummary?
    let location: String

    private var canStartCheck: Bool {
        location != "All locations"
    }

    var body: some View {
        VStack(
            alignment: .leading,
            spacing: 0
        ) {

            // Header
            HStack(spacing: 8) {
                Image(systemName: "checklist")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.blue)

                Text("Inventory check")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
            }

            Spacer(minLength: 8)

            // Last check
            if let lastCheck {
                Text("Last \(lastCheck.relativeDateText)")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text(
                    "\(lastCheck.matched) matched · \(lastCheck.corrected) corrected"
                )
                .font(.caption)
                .foregroundStyle(.secondary.opacity(0.7))
                .padding(.top, 2)

            } else {
                Text("No checks yet")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text("Start the first inventory check")
                    .font(.caption)
                    .foregroundStyle(.secondary.opacity(0.7))
                    .padding(.top, 2)
            }

            Spacer(minLength: 10)

            // Primary action
            Text(
                canStartCheck
                    ? "Start check"
                    : "Select a location"
            )
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(canStartCheck ? .blue : .secondary)
        }
        .padding(16)
        .frame(
            width: 216,
            height: 126,
            alignment: .leading
        )
        .background(
            Color(.secondarySystemGroupedBackground),
            in: RoundedRectangle(
                cornerRadius: 20,
                style: .continuous
            )
        )
    }
}
private struct InventoryStatisticCard: View {
    let title: String
    let value: String
    let detail: String
    let systemImage: String
    let tint: Color

    var body: some View {
        VStack(
            alignment: .leading,
            spacing: 10
        ) {
            HStack(spacing: 8) {
                Image(systemName: systemImage)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(tint)

                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Text(value)
                .font(.title2.weight(.bold))
                .monospacedDigit()

            Text(detail)
                .font(.caption)
                .foregroundStyle(.tertiary)
                .lineLimit(1)
        }
        .padding(14)
        .frame(
            width: 158,
            height: 126,
            alignment: .leading
        )
        .background(
            Color(.secondarySystemGroupedBackground),
            in: RoundedRectangle(
                cornerRadius: 20,
                style: .continuous
            )
        )
    }
}


// MARK: - Inventory Check History

private struct InventoryChecksView: View {
    let location: String
    let inventory: [InventoryRecord]

    @Binding var history: [InventoryCheckSummary]

    @State private var isStartingCheck = false

    private var canStartCheck: Bool {
        location != "All locations"
    }

    private var locationHistory: [InventoryCheckSummary] {
        history
            .filter {
                location == "All locations"
                    || $0.location == location
            }
            .sorted { $0.date > $1.date }
    }

    var body: some View {
        ScrollView {
            LazyVStack(
                alignment: .leading,
                spacing: 18
            ) {
                VStack(
                    alignment: .leading,
                    spacing: 10
                ) {
                    Button {
                        HapticFeedback.lightImpact()
                        isStartingCheck = true
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: "checkmark.circle.fill")
                            Text("Start inventory check")
                                .fontWeight(.semibold)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption.weight(.bold))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                    }
                    .buttonStyle(.glassProminent)
                    .tint(.blue)
                    .disabled(!canStartCheck)

                    if canStartCheck {
                        Label(
                            location,
                            systemImage: "mappin.and.ellipse"
                        )
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    } else {
                        Text(
                            "Choose one location on the Inventory page before starting a check."
                        )
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }
                }
                .padding(.horizontal, 16)

                Text("Previous checks")
                    .font(.headline)
                    .padding(.horizontal, 16)

                if locationHistory.isEmpty {
                    ContentUnavailableView(
                        "No inventory checks",
                        systemImage: "checklist",
                        description: Text(
                            "Completed checks for this location will appear here."
                        )
                    )
                    .padding(.top, 36)
                } else {
                    VStack(spacing: 0) {
                        ForEach(
                            Array(locationHistory.enumerated()),
                            id: \.element.id
                        ) { index, check in
                            NavigationLink {
                                InventoryCheckSummaryDetailView(
                                    summary: check
                                )
                            } label: {
                                InventoryCheckHistoryRow(
                                    summary: check
                                )
                            }
                            .buttonStyle(.plain)

                            if index < locationHistory.count - 1 {
                                Divider()
                                    .padding(.leading, 56)
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
            .padding(.top, 16)
            .padding(.bottom, 100)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Inventory Checks")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(
            isPresented: $isStartingCheck
        ) {
            InventoryCheckSessionView(
                location: location,
                inventory: inventory
            ) { completedCheck in
                history.insert(completedCheck, at: 0)
                isStartingCheck = false
            }
        }
    }
}

private struct InventoryCheckHistoryRow: View {
    let summary: InventoryCheckSummary

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .font(.title3)
                .foregroundStyle(.green)
                .frame(width: 32)

            VStack(
                alignment: .leading,
                spacing: 4
            ) {
                Text(summary.name)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                Text(
                    "\(summary.location) · \(summary.dateText)"
                )
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(1)

                Text(
                    "\(summary.matched) matched · \(summary.corrected) corrected"
                )
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(
                alignment: .trailing,
                spacing: 4
            ) {
                Text("\(summary.reviewedTotal)")
                    .font(.subheadline.weight(.semibold))
                    .monospacedDigit()

                Text("checked")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }

            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.tertiary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .contentShape(Rectangle())
    }
}


// MARK: - Active Inventory Check

private enum InventoryCheckListFilter:
    String,
    CaseIterable,
    Identifiable
{
    case toCheck = "To check"
    case checked = "Checked"
    case all = "All"

    var id: Self { self }
}

private enum InventoryCheckItemStatus: Equatable {
    case pending
    case matched
    case edited
    case deleted
    case added

    var title: String {
        switch self {
        case .pending:
            return ""
        case .matched:
            return "Matched"
        case .edited:
            return "Edited"
        case .deleted:
            return "Deleted"
        case .added:
            return "Added"
        }
    }

    var systemImage: String {
        switch self {
        case .pending:
            return "circle"
        case .matched:
            return "checkmark.circle.fill"
        case .edited:
            return "pencil.circle.fill"
        case .deleted:
            return "trash.circle.fill"
        case .added:
            return "plus.circle.fill"
        }
    }

    var tint: Color {
        switch self {
        case .pending:
            return .secondary
        case .matched:
            return .green
        case .edited:
            return .blue
        case .deleted:
            return .red
        case .added:
            return .blue
        }
    }

    var isChecked: Bool {
        self != .pending
    }
}

private struct InventoryCheckSessionView: View {
    let location: String
    let inventory: [InventoryRecord]
    let onComplete: (InventoryCheckSummary) -> Void

    @State private var sessionItems: [InventoryRecord]
    @State private var statuses: [Int: InventoryCheckItemStatus]
    @State private var searchText = ""
    @State private var isSearchPresented = false
    @State private var listFilter: InventoryCheckListFilter = .toCheck
    @State private var checkName: String
    @State private var draftCheckName = ""
    @State private var showingRenameCheck = false
    @State private var editingItem: InventoryRecord?
    @State private var showingAddItem = false
    @State private var completedSummary: InventoryCheckSummary?
    @State private var selectedItemIDs: Set<Int> = []
    @State private var lingeringItemIDs: Set<Int> = []
    @State private var transientFeedback: [Int: InventoryCheckTransientFeedback] = [:]

    private let originalByID: [Int: InventoryRecord]
    private let originalIDs: Set<Int>
    private let startedAt: Date

    init(
        location: String,
        inventory: [InventoryRecord],
        onComplete: @escaping (InventoryCheckSummary) -> Void
    ) {
        self.location = location
        self.inventory = inventory
        self.onComplete = onComplete

        let startDate = Date.now
        self.startedAt = startDate

        let startingItems = inventory.filter {
            $0.location == location
        }

        originalByID = Dictionary(
            uniqueKeysWithValues: startingItems.map {
                ($0.id, $0)
            }
        )
        originalIDs = Set(startingItems.map(\.id))

        _sessionItems = State(initialValue: startingItems)
        _statuses = State(
            initialValue: Dictionary(
                uniqueKeysWithValues: startingItems.map {
                    ($0.id, InventoryCheckItemStatus.pending)
                }
            )
        )
        _checkName = State(
            initialValue:
                "Inventory check "
                + startDate.formatted(
                    .dateTime
                        .month(.abbreviated)
                        .day()
                        .hour()
                        .minute()
                )
        )
    }

    private var cleanSearch: String {
        searchText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var reviewedOriginalCount: Int {
        originalIDs.filter { id in
            status(for: id).isChecked
        }.count
    }

    private var originalTotal: Int {
        originalIDs.count
    }

    private var isSelectionMode: Bool {
        !selectedItemIDs.isEmpty
    }

    private var toCheckCount: Int {
        originalIDs.filter { itemID in
            status(for: itemID) == .pending
        }.count
    }

    private var checkedCount: Int {
        sessionItems.filter { item in
            status(for: item.id).isChecked
        }.count
    }

    private var allCount: Int {
        sessionItems.count
    }

    private var filteredItems: [InventoryRecord] {
        sessionItems.filter { item in
            let matchesSearch =
                cleanSearch.isEmpty
                || item.equipmentNumber.localizedCaseInsensitiveContains(cleanSearch)
                || item.category.localizedCaseInsensitiveContains(cleanSearch)
                || item.equipmentType.localizedCaseInsensitiveContains(cleanSearch)
                || item.referenceID.localizedCaseInsensitiveContains(cleanSearch)
                || item.licensePlate.localizedCaseInsensitiveContains(cleanSearch)
                || item.vinNumber.localizedCaseInsensitiveContains(cleanSearch)
                || item.organizationName.localizedCaseInsensitiveContains(cleanSearch)
                || item.yardArea.localizedCaseInsensitiveContains(cleanSearch)

            guard matchesSearch else {
                return false
            }

            let itemStatus = status(for: item.id)

            switch listFilter {
            case .toCheck:
                return lingeringItemIDs.contains(item.id)
                    || (
                        originalIDs.contains(item.id)
                            && itemStatus == .pending
                    )
            case .checked:
                return lingeringItemIDs.contains(item.id)
                    || itemStatus.isChecked
            case .all:
                return true
            }
        }
    }

    var body: some View {
        Group {
            if let completedSummary {
                InventoryCheckCompletedContent(
                    summary: completedSummary
                ) {
                    onComplete(completedSummary)
                }
            } else {
                checkContent
            }
        }
        .navigationTitle(
            completedSummary == nil
                ? ""
                : "Check Complete"
        )
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(
            completedSummary == nil && isSelectionMode
        )
    }

    private var checkContent: some View {
        ScrollView {
            LazyVStack(
                alignment: .leading,
                spacing: 16
            ) {
                if !isSelectionMode {
                    VStack(
                        alignment: .leading,
                        spacing: 4
                    ) {
                        Text(checkName)
                            .font(.title2.weight(.bold))
                            .foregroundStyle(.primary)
                            .lineLimit(2)

                        Text(
                            "\(location) · Started \(startedAt.formatted(.dateTime.hour().minute()))"
                        )
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                    }
                    .frame(
                        maxWidth: .infinity,
                        alignment: .leading
                    )
                    .padding(.horizontal, 16)

                    Button {
                        completeCheck()
                    } label: {
                        HStack(spacing: 12) {
                            Text("Complete inventory check")
                                .font(.body.weight(.semibold))

                            Spacer()

                            Text("\(reviewedOriginalCount)/\(originalTotal)")
                                .font(.subheadline.weight(.semibold))
                                .monospacedDigit()
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.glassProminent)
                    .buttonBorderShape(.capsule)
                    .controlSize(.large)
                    .tint(.blue)
                    .padding(.horizontal, 16)

                    InventoryCheckFilterControl(
                        selection: $listFilter,
                        toCheckCount: toCheckCount,
                        checkedCount: checkedCount,
                        allCount: allCount
                    )
                    .padding(.horizontal, 16)
                }

                if filteredItems.isEmpty {
                    ContentUnavailableView(
                        emptyTitle,
                        systemImage: emptySystemImage,
                        description: Text(emptyDescription)
                    )
                    .padding(.top, 48)
                    .padding(.horizontal, 24)
                } else {
                    VStack(spacing: 0) {
                        ForEach(
                            Array(filteredItems.enumerated()),
                            id: \.element.id
                        ) { index, item in
                            InventoryCheckRow(
                                item: item,
                                status: status(for: item.id),
                                isSelectionMode: isSelectionMode,
                                isSelected: selectedItemIDs.contains(item.id),
                                transientFeedback: transientFeedback[item.id],
                                onToggleSelection: {
                                    toggleSelection(item.id)
                                },
                                onMatch: {
                                    setStatus(.matched, for: item.id)
                                },
                                onEdit: {
                                    editingItem = item
                                },
                                onDelete: {
                                    setStatus(.deleted, for: item.id)
                                },
                                onUndo: {
                                    undo(itemID: item.id)
                                }
                            )

                            if index < filteredItems.count - 1 {
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
            .padding(
                .top,
                isSelectionMode ? 6 : 16
            )
            .padding(.bottom, 110)
        }
        .background(Color(.systemGroupedBackground))
        .inventoryConditionalSearch(
            isPresented: $isSearchPresented,
            text: $searchText,
            prompt: "Search this inventory check"
        )
        .toolbar {
            if isSelectionMode {
                selectionToolbar
            } else {
                standardToolbar
            }
        }
        .alert(
            "Edit inventory check name",
            isPresented: $showingRenameCheck
        ) {
            TextField(
                "Name",
                text: $draftCheckName
            )

            Button("Cancel", role: .cancel) {}

            Button("Save") {
                let cleanedName = draftCheckName
                    .trimmingCharacters(
                        in: .whitespacesAndNewlines
                    )

                if !cleanedName.isEmpty {
                    checkName = cleanedName
                }
            }
        } message: {
            Text("This name will be saved with the completed check.")
        }
        .sheet(isPresented: $showingAddItem) {
            InventoryEditorView(
                lockedLocation: location
            ) { newItem in
                sessionItems.append(newItem)
                statuses[newItem.id] = .added
                listFilter = .checked
            }
        }
        .sheet(item: $editingItem) { item in
            InventoryEditorView(
                item: item,
                lockedLocation: location
            ) { updatedItem in
                guard let index = sessionItems.firstIndex(
                    where: { $0.id == updatedItem.id }
                ) else {
                    return
                }

                sessionItems[index] = updatedItem
                transitionStatus(.edited, for: updatedItem.id)
            }
        }
    }

    @ToolbarContentBuilder
    private var standardToolbar: some ToolbarContent {
        ToolbarItemGroup(placement: .topBarTrailing) {
            Button {
                HapticFeedback.lightImpact()
                isSearchPresented = true
            } label: {
                Image(systemName: "magnifyingglass")
            }
            .tint(.primary)
            .accessibilityLabel("Search inventory check")

            Menu {
                Section("Select") {
                    Button {
                        selectAllVisible()
                    } label: {
                        Label("Select all", systemImage: "checkmark.circle")
                    }

                    Button {
                        selectVisibleCategories(["Bobtail", "Straight truck"])
                    } label: {
                        Label("Select trucks", systemImage: "truck.box")
                    }

                    Button {
                        selectVisibleCategories(["Trailer"])
                    } label: {
                        Label("Select trailers", systemImage: "rectangle.landscape")
                    }

                    Button {
                        selectVisibleCategories(["Container"])
                    } label: {
                        Label("Select containers", systemImage: "shippingbox")
                    }

                    Button {
                        selectVisibleCategories(["Car"])
                    } label: {
                        Label("Select cars", systemImage: "car.side")
                    }

                    Button {
                        selectVisibleCategories(["Forklift"])
                    } label: {
                        Label(
                            "Select forklifts",
                            systemImage: "shippingbox.and.arrow.backward"
                        )
                    }
                }

                Section("Check") {
                    Button {
                        draftCheckName = checkName
                        showingRenameCheck = true
                    } label: {
                        Label("Edit check name", systemImage: "pencil")
                    }
                }
            } label: {
                Image(systemName: "ellipsis")
            }
            .tint(.primary)
            .accessibilityLabel("Inventory check options")

            Button {
                HapticFeedback.lightImpact()
                showingAddItem = true
            } label: {
                Image(systemName: "plus")
                    .font(.body.weight(.semibold))
            }
            .tint(.blue)
            .accessibilityLabel("Add missing inventory")
        }
    }

    @ToolbarContentBuilder
    private var selectionToolbar: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Button {
                HapticFeedback.lightImpact()
                selectedItemIDs.removeAll()
            } label: {
                Image(systemName: "xmark")
            }
            .accessibilityLabel("Cancel selection")
        }

        ToolbarItem(placement: .principal) {
            Text("\(selectedItemIDs.count) selected")
                .font(.headline)
                .monospacedDigit()
        }

        ToolbarItemGroup(placement: .topBarTrailing) {
            if listFilter == .checked {
                Button {
                    bulkUndoSelected()
                } label: {
                    Label(
                        "Undo status",
                        systemImage: "arrow.uturn.backward"
                    )
                    .fontWeight(.semibold)
                }
            } else {
                Button {
                    bulkMatchSelected()
                } label: {
                    Label(
                        "Match",
                        systemImage: "checkmark"
                    )
                    .fontWeight(.semibold)
                    .foregroundStyle(.green)
                }

                Menu {
                    Button {
                        // Bulk editing stays unavailable because selected
                        // inventory items can have different field values.
                    } label: {
                        Label(
                            "Edit selected",
                            systemImage: "pencil"
                        )
                    }
                    .disabled(true)

                    Button(role: .destructive) {
                        bulkDeleteSelected()
                    } label: {
                        Label(
                            "Delete selected",
                            systemImage: "trash"
                        )
                    }
                } label: {
                    Label(
                        "Mismatch",
                        systemImage: "xmark"
                    )
                    .fontWeight(.semibold)
                    .foregroundStyle(.red)
                }
            }
        }
    }

    private var emptyTitle: String {
        switch listFilter {
        case .toCheck:
            return reviewedOriginalCount == originalTotal
                ? "Everything is checked"
                : "No items to check"
        case .checked:
            return "Nothing checked yet"
        case .all:
            return "No inventory found"
        }
    }

    private var emptySystemImage: String {
        switch listFilter {
        case .toCheck:
            return reviewedOriginalCount == originalTotal
                ? "checkmark.circle.fill"
                : "shippingbox"
        case .checked:
            return "checkmark.circle"
        case .all:
            return "shippingbox"
        }
    }

    private var emptyDescription: String {
        switch listFilter {
        case .toCheck:
            return reviewedOriginalCount == originalTotal
                ? "You can now complete this inventory check."
                : "Try a different search."
        case .checked:
            return "Matched, edited, deleted, and added items will appear here."
        case .all:
            return "Try a different search."
        }
    }

    private func status(
        for itemID: Int
    ) -> InventoryCheckItemStatus {
        statuses[itemID] ?? .pending
    }

    private func setStatus(
        _ newStatus: InventoryCheckItemStatus,
        for itemID: Int
    ) {
        HapticFeedback.lightImpact()
        transitionStatus(newStatus, for: itemID)
    }

    private func transitionStatus(
        _ newStatus: InventoryCheckItemStatus,
        for itemID: Int
    ) {
        let oldStatus = status(for: itemID)
        let leavesCurrentPage =
            matchesCurrentFilter(
                status: oldStatus,
                itemID: itemID
            )
            && !matchesCurrentFilter(
                status: newStatus,
                itemID: itemID
            )

        if leavesCurrentPage {
            lingeringItemIDs.insert(itemID)
            transientFeedback[itemID] = feedback(
                for: newStatus
            )
        }

        withAnimation(
            .easeOut(duration: 0.10)
        ) {
            statuses[itemID] = newStatus
        }

        guard leavesCurrentPage else {
            return
        }

        DispatchQueue.main.asyncAfter(
            deadline: .now() + 0.16
        ) {
            withAnimation(
                .easeOut(duration: 0.10)
            ) {
                lingeringItemIDs.remove(itemID)
                transientFeedback.removeValue(
                    forKey: itemID
                )
            }
        }
    }

    private func matchesCurrentFilter(
        status itemStatus: InventoryCheckItemStatus,
        itemID: Int
    ) -> Bool {
        switch listFilter {
        case .toCheck:
            return originalIDs.contains(itemID)
                && itemStatus == .pending

        case .checked:
            return itemStatus.isChecked

        case .all:
            return true
        }
    }

    private func feedback(
        for status: InventoryCheckItemStatus
    ) -> InventoryCheckTransientFeedback {
        switch status {
        case .pending:
            return InventoryCheckTransientFeedback(
                title: "Undone",
                systemImage: "arrow.uturn.backward.circle.fill",
                tint: .blue
            )

        case .matched:
            return InventoryCheckTransientFeedback(
                title: "Matched",
                systemImage: "checkmark.circle.fill",
                tint: .green
            )

        case .edited:
            return InventoryCheckTransientFeedback(
                title: "Edited",
                systemImage: "pencil.circle.fill",
                tint: .blue
            )

        case .deleted:
            return InventoryCheckTransientFeedback(
                title: "Deleted",
                systemImage: "trash.circle.fill",
                tint: .red
            )

        case .added:
            return InventoryCheckTransientFeedback(
                title: "Added",
                systemImage: "plus.circle.fill",
                tint: .blue
            )
        }
    }

    private func toggleSelection(
        _ itemID: Int
    ) {
        HapticFeedback.lightImpact()

        if selectedItemIDs.contains(itemID) {
            selectedItemIDs.remove(itemID)
        } else {
            isSearchPresented = false
            selectedItemIDs.insert(itemID)
        }
    }

    private func selectAllVisible() {
        HapticFeedback.lightImpact()
        isSearchPresented = false
        selectedItemIDs = Set(filteredItems.map(\.id))
    }

    private func selectVisibleCategories(
        _ categories: Set<String>
    ) {
        HapticFeedback.lightImpact()
        isSearchPresented = false

        let matchingIDs = filteredItems
            .filter { categories.contains($0.category) }
            .map(\.id)

        selectedItemIDs.formUnion(matchingIDs)
    }

    private func bulkMatchSelected() {
        HapticFeedback.lightImpact()

        let ids = selectedItemIDs
        selectedItemIDs.removeAll()

        for itemID in ids {
            guard originalIDs.contains(itemID) else {
                continue
            }

            transitionStatus(.matched, for: itemID)
        }
    }

    private func bulkDeleteSelected() {
        HapticFeedback.lightImpact()

        let ids = selectedItemIDs
        selectedItemIDs.removeAll()

        for itemID in ids {
            if status(for: itemID) == .added {
                removeAddedItemWithTransition(itemID)
            } else if originalIDs.contains(itemID) {
                transitionStatus(.deleted, for: itemID)
            }
        }
    }

    private func bulkUndoSelected() {
        HapticFeedback.lightImpact()

        let ids = selectedItemIDs
        selectedItemIDs.removeAll()

        for itemID in ids {
            let currentStatus = status(for: itemID)

            if currentStatus == .added {
                removeAddedItemWithTransition(itemID)
                continue
            }

            if currentStatus == .edited,
               let original = originalByID[itemID],
               let index = sessionItems.firstIndex(
                    where: { $0.id == itemID }
               )
            {
                sessionItems[index] = original
            }

            if originalIDs.contains(itemID) {
                transitionStatus(.pending, for: itemID)
            }
        }
    }

    private func undo(
        itemID: Int
    ) {
        HapticFeedback.lightImpact()

        let currentStatus = status(for: itemID)

        if currentStatus == .added {
            removeAddedItemWithTransition(itemID)
            return
        }

        if currentStatus == .edited,
           let original = originalByID[itemID],
           let index = sessionItems.firstIndex(
                where: { $0.id == itemID }
           )
        {
            sessionItems[index] = original
        }

        transitionStatus(.pending, for: itemID)
    }

    private func removeAddedItemWithTransition(
        _ itemID: Int
    ) {
        let shouldLinger = listFilter == .checked

        if shouldLinger {
            lingeringItemIDs.insert(itemID)
            transientFeedback[itemID] =
                InventoryCheckTransientFeedback(
                    title: "Removed",
                    systemImage: "minus.circle.fill",
                    tint: .secondary
                )
        }

        let remove = {
            withAnimation(
                .easeOut(duration: 0.10)
            ) {
                sessionItems.removeAll {
                    $0.id == itemID
                }
                statuses.removeValue(
                    forKey: itemID
                )
                lingeringItemIDs.remove(itemID)
                transientFeedback.removeValue(
                    forKey: itemID
                )
            }
        }

        if shouldLinger {
            DispatchQueue.main.asyncAfter(
                deadline: .now() + 0.16,
                execute: remove
            )
        } else {
            remove()
        }
    }

    private func completeCheck() {
        HapticFeedback.lightImpact()

        let matched = originalIDs.filter {
            status(for: $0) == .matched
        }.count

        let edited = originalIDs.filter {
            status(for: $0) == .edited
        }.count

        let deleted = originalIDs.filter {
            status(for: $0) == .deleted
        }.count

        let added = sessionItems.filter {
            status(for: $0.id) == .added
        }.count

        completedSummary = InventoryCheckSummary(
            id: UUID(),
            name: checkName,
            date: .now,
            location: location,
            matched: matched,
            edited: edited,
            deleted: deleted,
            added: added,
            originalTotal: originalTotal,
            performedBy: "Maya Chen"
        )
    }
}

private struct InventoryCheckTransientFeedback {
    let title: String
    let systemImage: String
    let tint: Color
}

// MARK: - Inventory Check Filter

private struct InventoryCheckFilterControl: View {
    @Binding var selection: InventoryCheckListFilter

    let toCheckCount: Int
    let checkedCount: Int
    let allCount: Int

    var body: some View {
        HStack(spacing: 2) {
            segment(
                title: "To check",
                count: toCheckCount,
                value: .toCheck
            )

            segment(
                title: "Checked",
                count: checkedCount,
                value: .checked
            )

            segment(
                title: "All",
                count: allCount,
                value: .all
            )
        }
        .padding(3)
        .background(
            Color(.secondarySystemFill),
            in: Capsule()
        )
        .transaction { transaction in
            transaction.animation = nil
        }
        .accessibilityElement(children: .contain)
    }

    private func segment(
        title: String,
        count: Int,
        value: InventoryCheckListFilter
    ) -> some View {
        Button {
            selection = value
        } label: {
            HStack(spacing: 6) {
                Text(title)
                    .font(
                        .subheadline.weight(
                            selection == value
                                ? .semibold
                                : .regular
                        )
                    )
                    .lineLimit(1)

                Text("\(count)")
                    .font(.caption2.weight(.semibold))
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
                    .frame(width: 28)
                    .padding(.vertical, 3)
                    .background(
                        Color.primary.opacity(0.08),
                        in: Capsule()
                    )
            }
            .foregroundStyle(.primary)
            .frame(
                maxWidth: .infinity,
                minHeight: 34
            )
            .contentShape(Capsule())
            .background {
                if selection == value {
                    Capsule()
                        .fill(
                            Color(.secondarySystemGroupedBackground)
                        )
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
        .accessibilityValue("\(count)")
        .accessibilityAddTraits(
            selection == value
                ? .isSelected
                : []
        )
    }
}


// MARK: - Inventory Check Row

private struct InventoryCheckRow: View {
    let item: InventoryRecord
    let status: InventoryCheckItemStatus
    let isSelectionMode: Bool
    let isSelected: Bool
    let transientFeedback: InventoryCheckTransientFeedback?

    let onToggleSelection: () -> Void
    let onMatch: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void
    let onUndo: () -> Void

    private var accentColor: Color {
        switch item.category {
        case "Bobtail", "Straight truck":
            return .blue
        case "Trailer":
            return .orange
        case "Container":
            return .purple
        case "Forklift":
            return .teal
        case "Car":
            return .indigo
        default:
            return .secondary
        }
    }

    var body: some View {
        HStack(
            alignment: .center,
            spacing: 12
        ) {
            Button(action: onToggleSelection) {
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.blue)
                        .frame(width: 34, height: 34)
                } else {
                    InventoryEquipmentIcon(
                        category: item.category,
                        tint: accentColor
                    )
                }
            }
            .buttonStyle(.plain)
            .accessibilityLabel(
                isSelected
                    ? "Deselect \(item.equipmentNumber)"
                    : "Select \(item.equipmentNumber)"
            )

            Button {
                if isSelectionMode {
                    onToggleSelection()
                } else {
                    onEdit()
                }
            } label: {
                VStack(
                    alignment: .leading,
                    spacing: 5
                ) {
                    HStack(spacing: 7) {
                        Text(item.equipmentNumber)
                            .font(.body.weight(.semibold))
                            .foregroundStyle(
                                status == .deleted
                                    ? .secondary
                                    : .primary
                            )
                            .lineLimit(1)

                        if item.isReefer {
                            Image(systemName: "snowflake")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.cyan)
                        }
                    }

                    HStack(spacing: 5) {
                        Text(item.category)

                        Text("·")
                            .foregroundStyle(.quaternary)

                        Text(item.equipmentType)
                    }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                    HStack(spacing: 5) {
                        Image(systemName: "mappin.and.ellipse")
                            .font(.caption2)

                        Text(item.yardArea)
                            .lineLimit(1)
                    }
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                }
                .frame(
                    maxWidth: .infinity,
                    alignment: .leading
                )
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if !isSelectionMode {
                trailingAction
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .opacity(status == .deleted ? 0.65 : 1)
        .animation(
            .easeOut(duration: 0.10),
            value: transientFeedback?.title
        )
    }

    @ViewBuilder
    private var trailingAction: some View {
        if let transientFeedback {
            statusChip(
                title: transientFeedback.title,
                systemImage: transientFeedback.systemImage,
                tint: transientFeedback.tint
            )
            .transition(.opacity)
        } else if status == .pending {
            HStack(spacing: 8) {
                Button(action: onMatch) {
                    Image(systemName: "checkmark")
                        .font(.subheadline.weight(.semibold))
                        .frame(width: 30, height: 30)
                }
                .buttonStyle(.bordered)
                .buttonBorderShape(.circle)
                .controlSize(.small)
                .tint(.green)
                .accessibilityLabel("Match")

                Menu {
                    Button(action: onEdit) {
                        Label(
                            "Edit item",
                            systemImage: "pencil"
                        )
                    }

                    Button(
                        role: .destructive,
                        action: onDelete
                    ) {
                        Label(
                            "Delete item",
                            systemImage: "trash"
                        )
                    }
                } label: {
                    Image(systemName: "xmark")
                        .font(.subheadline.weight(.semibold))
                        .frame(width: 30, height: 30)
                }
                .buttonStyle(.bordered)
                .buttonBorderShape(.circle)
                .controlSize(.small)
                .tint(.red)
                .accessibilityLabel("Mismatch")
            }
            .fixedSize()
        } else {
            HStack(spacing: 8) {
                statusChip(
                    title: status.title,
                    systemImage: status.systemImage,
                    tint: status.tint
                )

                Button(action: onUndo) {
                    Image(systemName: "arrow.uturn.backward")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.blue)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Undo \(status.title.lowercased())")
            }
            .fixedSize()
        }
    }

    private func statusChip(
        title: String,
        systemImage: String,
        tint: Color
    ) -> some View {
        Label(
            title,
            systemImage: systemImage
        )
        .font(.caption.weight(.semibold))
        .foregroundStyle(tint)
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(
            tint.opacity(0.12),
            in: Capsule()
        )
        .fixedSize()
    }
}


// MARK: - Completed Check

private struct InventoryCheckCompletedContent: View {
    let summary: InventoryCheckSummary
    let onDone: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                VStack(spacing: 10) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 54))
                        .foregroundStyle(.green)

                    Text("Inventory check complete")
                        .font(.title2.weight(.bold))

                    Text(summary.name)
                        .font(.headline)

                    Text(summary.location)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Text(summary.dateText)
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                .padding(.top, 32)

                HStack(spacing: 10) {
                    InventoryCheckResultCard(
                        value: summary.matched,
                        title: "Matched",
                        systemImage: "checkmark.circle.fill",
                        tint: .green
                    )

                    InventoryCheckResultCard(
                        value: summary.edited,
                        title: "Edited",
                        systemImage: "pencil.circle.fill",
                        tint: .blue
                    )
                }

                HStack(spacing: 10) {
                    InventoryCheckResultCard(
                        value: summary.deleted,
                        title: "Deleted",
                        systemImage: "trash.circle.fill",
                        tint: .red
                    )

                    InventoryCheckResultCard(
                        value: summary.added,
                        title: "Added",
                        systemImage: "plus.circle.fill",
                        tint: .blue
                    )
                }

                Button(action: onDone) {
                    Text("Done")
                        .font(.body.weight(.semibold))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.glassProminent)
                .tint(.blue)
                .padding(.top, 6)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 80)
        }
        .background(Color(.systemGroupedBackground))
    }
}

private struct InventoryCheckResultCard: View {
    let value: Int
    let title: String
    let systemImage: String
    let tint: Color

    var body: some View {
        VStack(
            alignment: .leading,
            spacing: 8
        ) {
            Image(systemName: systemImage)
                .font(.headline)
                .foregroundStyle(tint)

            Text("\(value)")
                .font(.title2.weight(.bold))
                .monospacedDigit()

            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(14)
        .frame(
            maxWidth: .infinity,
            alignment: .leading
        )
        .background(
            Color(.secondarySystemGroupedBackground),
            in: RoundedRectangle(
                cornerRadius: 18,
                style: .continuous
            )
        )
    }
}

private struct InventoryCheckSummaryDetailView: View {
    let summary: InventoryCheckSummary

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                VStack(
                    alignment: .leading,
                    spacing: 8
                ) {
                    Text(summary.name)
                        .font(.title3.weight(.semibold))

                    Text(
                        "\(summary.location) · \(summary.dateText)"
                    )
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                    Label(
                        "Completed by \(summary.performedBy)",
                        systemImage: "person.fill"
                    )
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
                .frame(
                    maxWidth: .infinity,
                    alignment: .leading
                )

                HStack(spacing: 10) {
                    InventoryCheckResultCard(
                        value: summary.matched,
                        title: "Matched",
                        systemImage: "checkmark.circle.fill",
                        tint: .green
                    )

                    InventoryCheckResultCard(
                        value: summary.edited,
                        title: "Edited",
                        systemImage: "pencil.circle.fill",
                        tint: .blue
                    )
                }

                HStack(spacing: 10) {
                    InventoryCheckResultCard(
                        value: summary.deleted,
                        title: "Deleted",
                        systemImage: "trash.circle.fill",
                        tint: .red
                    )

                    InventoryCheckResultCard(
                        value: summary.added,
                        title: "Added",
                        systemImage: "plus.circle.fill",
                        tint: .blue
                    )
                }
            }
            .padding(16)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Check Details")
        .navigationBarTitleDisplayMode(.inline)
    }
}


// MARK: - Check Summary Model

private struct InventoryCheckSummary:
    Identifiable,
    Equatable
{
    let id: UUID
    let name: String
    let date: Date
    let location: String
    let matched: Int
    let edited: Int
    let deleted: Int
    let added: Int
    let originalTotal: Int
    let performedBy: String

    var corrected: Int {
        edited + deleted + added
    }

    var reviewedTotal: Int {
        originalTotal
    }

    var dateText: String {
        date.formatted(
            .dateTime
                .month(.abbreviated)
                .day()
                .year()
                .hour()
                .minute()
        )
    }

    var relativeDateText: String {
        let calendar = Calendar.current

        if calendar.isDateInToday(date) {
            return "Today, \(timeText)"
        }

        if calendar.isDateInYesterday(date) {
            return "Yesterday, \(timeText)"
        }

        return date.formatted(
            .dateTime
                .month(.abbreviated)
                .day()
                .hour()
                .minute()
        )
    }

    private var timeText: String {
        date.formatted(
            .dateTime
                .hour()
                .minute()
        )
    }

    static let samples: [InventoryCheckSummary] = {
        let calendar = Calendar.current

        func date(
            daysAgo: Int,
            hour: Int,
            minute: Int
        ) -> Date {
            let base = calendar.date(
                byAdding: .day,
                value: -daysAgo,
                to: .now
            ) ?? .now

            return calendar.date(
                bySettingHour: hour,
                minute: minute,
                second: 0,
                of: base
            ) ?? base
        }

        return [
            InventoryCheckSummary(
                id: UUID(),
                name: "Inventory Check",
                date: date(
                    daysAgo: 1,
                    hour: 10,
                    minute: 42
                ),
                location: "Northstar (Oshawa)",
                matched: 70,
                edited: 1,
                deleted: 1,
                added: 0,
                originalTotal: 72,
                performedBy: "Maya Chen"
            ),
            InventoryCheckSummary(
                id: UUID(),
                name: "Inventory Check",
                date: date(
                    daysAgo: 3,
                    hour: 14,
                    minute: 18
                ),
                location: "Northstar (Oshawa)",
                matched: 71,
                edited: 1,
                deleted: 0,
                added: 0,
                originalTotal: 72,
                performedBy: "Daniel Brooks"
            ),
            InventoryCheckSummary(
                id: UUID(),
                name: "Inventory Check",
                date: date(
                    daysAgo: 2,
                    hour: 9,
                    minute: 15
                ),
                location: "Northstar (Dallas)",
                matched: 69,
                edited: 1,
                deleted: 1,
                added: 1,
                originalTotal: 71,
                performedBy: "Sarah Patel"
            ),
            InventoryCheckSummary(
                id: UUID(),
                name: "Inventory Check",
                date: date(
                    daysAgo: 4,
                    hour: 16,
                    minute: 6
                ),
                location: "Northstar (Toronto)",
                matched: 72,
                edited: 0,
                deleted: 0,
                added: 0,
                originalTotal: 72,
                performedBy: "James Wilson"
            ),
        ]
    }()
}


// MARK: - Main Inventory Card

private struct InventoryCard: View {
    let inventory: [InventoryRecord]
    let onSelect: (InventoryRecord) -> Void

    var body: some View {
        VStack(spacing: 0) {
            ForEach(
                Array(inventory.enumerated()),
                id: \.element.id
            ) { index, item in
                Button {
                    onSelect(item)
                } label: {
                    InventoryRow(item: item)
                }
                .buttonStyle(.plain)

                if index < inventory.count - 1 {
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

private struct InventoryRow: View {
    let item: InventoryRecord

    private var accentColor: Color {
        switch item.category {
        case "Bobtail", "Straight truck":
            return .blue
        case "Trailer":
            return .orange
        case "Container":
            return .purple
        case "Forklift":
            return .teal
        case "Car":
            return .indigo
        default:
            return .secondary
        }
    }

    var body: some View {
        HStack(
            alignment: .top,
            spacing: 12
        ) {
            InventoryEquipmentIcon(
                category: item.category,
                tint: accentColor
            )

            VStack(
                alignment: .leading,
                spacing: 6
            ) {
                HStack(
                    alignment: .firstTextBaseline,
                    spacing: 8
                ) {
                    Text(item.equipmentNumber)
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(1)

                    if item.isReefer {
                        Image(systemName: "snowflake")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.cyan)
                            .accessibilityLabel("Reefer")
                    }
                }

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

            VStack(
                alignment: .trailing,
                spacing: 3
            ) {
                Text(item.durationText)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                    .monospacedDigit()

                Text("in yard")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .fixedSize()
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

            InventoryLocationLabel(
                location: item.location
            )

            Text(item.yardArea)
                .foregroundStyle(.tertiary)
        }
        .font(.subheadline)
        .foregroundStyle(.secondary)
        .lineLimit(1)
    }

    private var compactMetadataRows: some View {
        VStack(
            alignment: .leading,
            spacing: 5
        ) {
            HStack(spacing: 5) {
                Text(item.category)
                metadataSeparator
                Text(item.equipmentType)
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .lineLimit(1)

            HStack(spacing: 6) {
                InventoryLocationLabel(
                    location: item.location
                )

                Text(item.yardArea)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .lineLimit(1)
            }
        }
    }

    private var metadataSeparator: some View {
        Text("·")
            .foregroundStyle(.quaternary)
    }
}

private struct InventoryEquipmentIcon: View {
    let category: String
    let tint: Color

    private var systemImage: String {
        switch category {
        case "Bobtail", "Straight truck":
            return "truck.box"
        case "Trailer":
            return "shippingbox"
        case "Container":
            return "shippingbox.fill"
        case "Forklift":
            return "shippingbox.and.arrow.backward"
        case "Car":
            return "car.side"
        default:
            return "shippingbox"
        }
    }

    var body: some View {
        Image(systemName: systemImage)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(tint)
            .frame(
                width: 34,
                height: 34
            )
            .background(
                tint.opacity(0.10),
                in: RoundedRectangle(
                    cornerRadius: 10,
                    style: .continuous
                )
            )
    }
}


// MARK: - Location

private struct InventoryLocationLabel: View {
    let location: String

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "mappin.and.ellipse")
                .font(.caption2.weight(.medium))

            Text(location)
                .font(.caption)
                .lineLimit(1)
                .truncationMode(.tail)
        }
        .foregroundStyle(.secondary)
        .accessibilityLabel("Location")
        .accessibilityValue(location)
    }
}

private struct InventoryLocationSwitcher: View {
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
            .font(.caption.weight(.semibold))
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


// MARK: - Pagination

private struct InventoryPaginationFooter: View {
    let page: Int
    let itemCount: Int
    let pageSize: Int
    let onPrevious: () -> Void
    let onNext: () -> Void

    private var pageCount: Int {
        max(
            (itemCount + pageSize - 1) / pageSize,
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
                "\(rangeStart)-\(rangeEnd) of \(itemCount)"
            )
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .monospacedDigit()

            Spacer()

            HStack(spacing: 10) {
                paginationButton(
                    systemImage: "chevron.left",
                    disabled: page == 0,
                    accessibilityLabel: "Previous page",
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
                    disabled: page >= pageCount - 1,
                    accessibilityLabel: "Next page",
                    action: onNext
                )
            }
        }
        .padding(.horizontal, 2)
    }

    private func paginationButton(
        systemImage: String,
        disabled: Bool,
        accessibilityLabel: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
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
        .accessibilityLabel(accessibilityLabel)
    }
}


// MARK: - Conditional Search

extension View {
    @ViewBuilder
    fileprivate func inventoryConditionalSearch(
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


// MARK: - Inventory Editor

private struct InventoryEditorView: View {
    @Environment(\.dismiss) private var dismiss

    let item: InventoryRecord?
    let lockedLocation: String?
    let onSave: (InventoryRecord) -> Void

    @State private var category: String
    @State private var equipmentNumber: String
    @State private var referenceID: String
    @State private var licensePlate: String
    @State private var vinNumber: String
    @State private var organizationName: String
    @State private var location: String
    @State private var yardArea: String
    @State private var checkInDate: Date
    @State private var cargoType: String
    @State private var shipmentNumber: String
    @State private var cargoSeal: String
    @State private var isReefer: Bool
    @State private var reeferTemperature: String

    @FocusState private var focusedField: Field?

    private enum Field {
        case equipmentNumber
        case referenceID
        case licensePlate
        case vinNumber
        case organization
        case shipment
        case seal
        case reeferTemperature
    }

    private let categories = [
        "Car",
        "Bobtail",
        "Straight truck",
        "Trailer",
        "Container",
        "Forklift",
    ]

    private let locations = [
        "Northstar (Oshawa)",
        "Northstar (Dallas)",
        "Northstar (Toronto)",
    ]

    private let yardAreas = [
        "Inbound staging",
        "North lot",
        "Trailer row C",
        "Dock 12",
        "South lot",
        "Outbound staging",
    ]

    private let cargoTypes = [
        "None",
        "General freight",
        "Food products",
        "Packaging",
        "Automotive parts",
        "Empty",
    ]

    init(
        item: InventoryRecord? = nil,
        lockedLocation: String? = nil,
        onSave: @escaping (InventoryRecord) -> Void
    ) {
        self.item = item
        self.lockedLocation = lockedLocation
        self.onSave = onSave

        _category = State(
            initialValue:
                item?.category ?? "Straight truck"
        )

        _equipmentNumber = State(
            initialValue:
                item?.equipmentNumber ?? ""
        )

        _referenceID = State(
            initialValue:
                item?.referenceID ?? ""
        )

        _licensePlate = State(
            initialValue:
                item?.licensePlate ?? ""
        )

        _vinNumber = State(
            initialValue:
                item?.vinNumber ?? ""
        )

        _organizationName = State(
            initialValue:
                item?.organizationName ?? ""
        )

        _location = State(
            initialValue:
                lockedLocation
                ?? item?.location
                ?? "Northstar (Oshawa)"
        )

        _yardArea = State(
            initialValue:
                item?.yardArea ?? "Inbound staging"
        )

        _checkInDate = State(
            initialValue:
                item?.checkInDate ?? .now
        )

        _cargoType = State(
            initialValue:
                item?.cargoType.isEmpty == false
                ? item!.cargoType
                : "None"
        )

        _shipmentNumber = State(
            initialValue:
                item?.shipmentNumber ?? ""
        )

        _cargoSeal = State(
            initialValue:
                item?.cargoSeal ?? ""
        )

        _isReefer = State(
            initialValue:
                item?.isReefer ?? false
        )

        _reeferTemperature = State(
            initialValue:
                item?.reeferTemperature ?? ""
        )
    }

    private var canSave: Bool {
        !equipmentNumber
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            )
            .isEmpty
    }

    private var derivedEquipmentType: String {
        switch category {
        case "Car":
            return "Passenger car"
        case "Bobtail":
            return "Semi tractor"
        case "Straight truck":
            return "Box truck"
        case "Trailer":
            return isReefer
                ? "Reefer trailer"
                : "Dry van trailer"
        case "Container":
            return "40 ft container"
        case "Forklift":
            return "Yard forklift"
        default:
            return category
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Equipment") {
                    Picker(
                        "Category",
                        selection: $category
                    ) {
                        ForEach(
                            categories,
                            id: \.self
                        ) { category in
                            Text(category)
                        }
                    }

                    TextField(
                        "Equipment number",
                        text: $equipmentNumber
                    )
                    .focused(
                        $focusedField,
                        equals: .equipmentNumber
                    )
                    .textInputAutocapitalization(.characters)
                    .autocorrectionDisabled()

                    TextField(
                        "Reference ID",
                        text: $referenceID
                    )
                    .focused(
                        $focusedField,
                        equals: .referenceID
                    )
                    .textInputAutocapitalization(.characters)
                    .autocorrectionDisabled()

                    TextField(
                        "License plate",
                        text: $licensePlate
                    )
                    .focused(
                        $focusedField,
                        equals: .licensePlate
                    )
                    .textInputAutocapitalization(.characters)
                    .autocorrectionDisabled()

                    TextField(
                        "VIN number",
                        text: $vinNumber
                    )
                    .focused(
                        $focusedField,
                        equals: .vinNumber
                    )
                    .textInputAutocapitalization(.characters)
                    .autocorrectionDisabled()
                }

                Section("Yard") {
                    if let lockedLocation {
                        LabeledContent(
                            "Location",
                            value: lockedLocation
                        )
                    } else {
                        Picker(
                            "Location",
                            selection: $location
                        ) {
                            ForEach(
                                locations,
                                id: \.self
                            ) { location in
                                Text(location)
                            }
                        }
                    }

                    Picker(
                        "Yard area",
                        selection: $yardArea
                    ) {
                        ForEach(
                            yardAreas,
                            id: \.self
                        ) { area in
                            Text(area)
                        }
                    }

                    DatePicker(
                        "Checked in",
                        selection: $checkInDate,
                        in: ...Date.now,
                        displayedComponents: [
                            .date,
                            .hourAndMinute,
                        ]
                    )
                }

                Section("Organization") {
                    TextField(
                        "Organization",
                        text: $organizationName
                    )
                    .focused(
                        $focusedField,
                        equals: .organization
                    )
                }

                Section("Cargo") {
                    Picker(
                        "Cargo type",
                        selection: $cargoType
                    ) {
                        ForEach(
                            cargoTypes,
                            id: \.self
                        ) { cargoType in
                            Text(cargoType)
                        }
                    }

                    TextField(
                        "Shipment number",
                        text: $shipmentNumber
                    )
                    .focused(
                        $focusedField,
                        equals: .shipment
                    )
                    .textInputAutocapitalization(.characters)
                    .autocorrectionDisabled()

                    TextField(
                        "Cargo seal",
                        text: $cargoSeal
                    )
                    .focused(
                        $focusedField,
                        equals: .seal
                    )
                    .textInputAutocapitalization(.characters)
                    .autocorrectionDisabled()

                    Toggle(
                        "Reefer",
                        isOn: $isReefer
                    )

                    if isReefer {
                        TextField(
                            "Temperature",
                            text: $reeferTemperature
                        )
                        .focused(
                            $focusedField,
                            equals: .reeferTemperature
                        )
                        .keyboardType(.decimalPad)
                    }
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle(
                item == nil
                    ? "Add inventory"
                    : "Inventory details"
            )
            .navigationBarTitleDisplayMode(.inline)
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
                    Button(
                        item == nil
                            ? "Add"
                            : "Save"
                    ) {
                        focusedField = nil

                        let savedItem = InventoryRecord(
                            id: item?.id
                                ?? Int(Date.now.timeIntervalSince1970 * 1000),
                            equipmentNumber: equipmentNumber,
                            category: category,
                            equipmentType: derivedEquipmentType,
                            referenceID: referenceID,
                            licensePlate: licensePlate,
                            vinNumber: vinNumber,
                            organizationName: organizationName,
                            location: lockedLocation ?? location,
                            yardArea: yardArea,
                            checkInDate: checkInDate,
                            cargoType: cargoType == "None"
                                ? ""
                                : cargoType,
                            shipmentNumber: shipmentNumber,
                            cargoSeal: cargoSeal,
                            isReefer: isReefer,
                            reeferTemperature: isReefer
                                ? reeferTemperature
                                : ""
                        )

                        onSave(savedItem)
                        dismiss()
                    }
                    .buttonStyle(.glassProminent)
                    .tint(.blue)
                    .disabled(!canSave)
                }
            }
        }
    }
}
