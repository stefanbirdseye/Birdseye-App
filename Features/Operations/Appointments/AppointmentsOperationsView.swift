import SwiftUI

struct AppointmentsOperationsView: View {

    private let appointments = AppointmentRecord.mockData

    private let locations = [
        "All locations",
        "Northstar (Oshawa)",
        "Northstar (Dallas)",
        "Northstar (Toronto)",
    ]

    @State private var selectedLocationIndex = 1
    @State private var searchText = ""
    @State private var isSearchPresented = false

    @State private var appointmentFilter: AppointmentFilter = .all
    @State private var sortOrder: AppointmentSortOrder = .appointmentSoonest

    @State private var page = 0
    @State private var showingAdd = false
    @State private var selectedAppointment: AppointmentRecord?

    private let pageSize = 20

    private var cleanSearch: String {
        searchText.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
    }

    private var filteredAppointments: [AppointmentRecord] {

        let matchingAppointments = appointments.filter { appointment in

            let matchesSearch =
                cleanSearch.isEmpty
                || appointment.organizationName
                    .localizedCaseInsensitiveContains(cleanSearch)
                || appointment.personName
                    .localizedCaseInsensitiveContains(cleanSearch)
                || appointment.gate
                    .localizedCaseInsensitiveContains(cleanSearch)
                || appointment.direction
                    .localizedCaseInsensitiveContains(cleanSearch)
                || appointment.vehicleType
                    .localizedCaseInsensitiveContains(cleanSearch)
                || appointment.vehicleIdentifier
                    .localizedCaseInsensitiveContains(cleanSearch)
                || appointment.trailerIdentifier
                    .localizedCaseInsensitiveContains(cleanSearch)
                || appointment.cargoReference
                    .localizedCaseInsensitiveContains(cleanSearch)

            let selectedLocation =
                locations[selectedLocationIndex]

            let matchesLocation =
                selectedLocation == "All locations"
                || appointment.location == selectedLocation

            let matchesFilter: Bool

            switch appointmentFilter {

            case .all:
                matchesFilter = true

            case .inbound:
                matchesFilter =
                    appointment.direction == "IN"

            case .outbound:
                matchesFilter =
                    appointment.direction == "OUT"

            case .anyGate:
                matchesFilter =
                    appointment.gate == "Any gate"

            case .mainGate:
                matchesFilter =
                    appointment.gate == "Main gate"

            case .carrierGate:
                matchesFilter =
                    appointment.gate == "Carrier gate"

            case .hasVehicle:
                matchesFilter =
                    !appointment.vehicleIdentifier.isEmpty

            case .hasTrailer:
                matchesFilter =
                    !appointment.trailerIdentifier.isEmpty

            case .hasCargo:
                matchesFilter =
                    !appointment.cargoReference.isEmpty
            }

            return matchesSearch
                && matchesLocation
                && matchesFilter
        }

        switch sortOrder {

        case .appointmentSoonest:
            return matchingAppointments.sorted {
                $0.date < $1.date
            }

        case .appointmentLatest:
            return matchingAppointments.sorted {
                $0.date > $1.date
            }

        case .organizationAscending:
            return matchingAppointments.sorted {
                $0.organizationName.localizedStandardCompare(
                    $1.organizationName
                ) == .orderedAscending
            }

        case .organizationDescending:
            return matchingAppointments.sorted {
                $0.organizationName.localizedStandardCompare(
                    $1.organizationName
                ) == .orderedDescending
            }

        case .person:
            return matchingAppointments.sorted {
                $0.personName.localizedStandardCompare(
                    $1.personName
                ) == .orderedAscending
            }

        case .gate:
            return matchingAppointments.sorted {
                $0.gate.localizedStandardCompare(
                    $1.gate
                ) == .orderedAscending
            }

        case .direction:
            return matchingAppointments.sorted {
                $0.direction.localizedStandardCompare(
                    $1.direction
                ) == .orderedAscending
            }
        }
    }

    private var pageAppointments: [AppointmentRecord] {

        let start = page * pageSize

        guard start < filteredAppointments.count else {
            return []
        }

        return Array(
            filteredAppointments
                .dropFirst(start)
                .prefix(pageSize)
        )
    }

    var body: some View {

        VStack(spacing: 0) {

            AppointmentsResultsContent(
                appointments: pageAppointments,
                resultCount: filteredAppointments.count,
                locations: locations,
                selectedLocationIndex: $selectedLocationIndex,
                page: page,
                pageSize: pageSize,
                hasActiveSortOrFilter: appointmentFilter != .all
                    || selectedLocationIndex != 1
                    || sortOrder != .appointmentSoonest,
                onResetSortAndFilters: {
                    appointmentFilter = .all
                    selectedLocationIndex = 1
                    sortOrder = .appointmentSoonest
                    page = 0
                },
                onSelect: { appointment in
                    selectedAppointment = appointment
                },
                onPrevious: {
                    page = max(page - 1, 0)
                },
                onNext: {

                    let maxPage = max(
                        (filteredAppointments.count - 1) / pageSize,
                        0
                    )

                    page = min(
                        page + 1,
                        maxPage
                    )
                }
            )
        }
        .navigationTitle("Appointments")
        .navigationBarTitleDisplayMode(.inline)
        .reportingPageContext("Appointments")
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

                        ForEach(
                            AppointmentSortOrder.allCases
                        ) { order in

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
                            sortOrder = .appointmentSoonest
                            page = 0
                        }
                    }

                    Menu("Filter", systemImage: "line.3.horizontal.decrease.circle") {

                        ForEach(
                            AppointmentFilter.allCases
                        ) { filter in

                            Button {

                                appointmentFilter = filter
                                page = 0

                            } label: {

                                if appointmentFilter == filter {

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
                            appointmentFilter = .all
                            page = 0
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

                        if appointmentFilter != .all
                            || selectedLocationIndex != 1
                            || sortOrder != .appointmentSoonest
                        {

                            Button {

                                appointmentFilter = .all
                                selectedLocationIndex = 1
                                sortOrder = .appointmentSoonest
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
                        systemName: appointmentFilter != .all
                            || selectedLocationIndex != 1
                            || sortOrder != .appointmentSoonest
                            ? "ellipsis.circle.fill"
                            : "ellipsis"
                    )
                }
                .tint(.primary)
                .accessibilityLabel(
                    "Sort, filter, and more"
                )

                Button {
                    HapticFeedback.lightImpact()
                    showingAdd = true
                } label: {
                    Image(systemName: "plus")
                        .font(.body.weight(.semibold))
                }
                .tint(.blue)
                .accessibilityLabel("Add appointment")
            }
        }
        .appointmentConditionalSearch(
            isPresented: $isSearchPresented,
            text: $searchText,
            prompt: "Search appointments"
        )
        .onChange(of: searchText) { _, _ in
            page = 0
        }
        .onChange(of: appointmentFilter) { _, _ in
            page = 0
        }
        .onChange(of: selectedLocationIndex) { _, _ in
            page = 0
        }
        .onChange(of: sortOrder) { _, _ in
            page = 0
        }
        .sheet(isPresented: $showingAdd) {

            AppointmentEditorView()
        }
        .sheet(item: $selectedAppointment) { appointment in

            AppointmentEditorView(
                appointment: appointment
            )
        }
    }
}


// MARK: - Sorting

private enum AppointmentSortOrder:
    String,
    CaseIterable,
    Identifiable
{
    case appointmentSoonest
    case appointmentLatest
    case organizationAscending
    case organizationDescending
    case person
    case gate
    case direction

    var id: Self { self }

    var title: String {

        switch self {

        case .appointmentSoonest:
            return "Appointment soonest"

        case .appointmentLatest:
            return "Appointment latest"

        case .organizationAscending:
            return "Organization A-Z"

        case .organizationDescending:
            return "Organization Z-A"

        case .person:
            return "Person name"

        case .gate:
            return "Gate"

        case .direction:
            return "Direction"
        }
    }

    var systemImage: String {

        switch self {

        case .appointmentSoonest:
            return "calendar.badge.clock"

        case .appointmentLatest:
            return "calendar"

        case .organizationAscending:
            return "building.2"

        case .organizationDescending:
            return "building.2"

        case .person:
            return "person"

        case .gate:
            return "mappin.and.ellipse"

        case .direction:
            return "arrow.left.arrow.right"
        }
    }
}


// MARK: - Filtering

private enum AppointmentFilter:
    String,
    CaseIterable,
    Identifiable
{
    case all
    case inbound
    case outbound
    case anyGate
    case mainGate
    case carrierGate
    case hasVehicle
    case hasTrailer
    case hasCargo

    var id: Self { self }

    var title: String {

        switch self {

        case .all:
            return "All appointments"

        case .inbound:
            return "Inbound only"

        case .outbound:
            return "Outbound only"

        case .anyGate:
            return "Any gate"

        case .mainGate:
            return "Main gate"

        case .carrierGate:
            return "Carrier gate"

        case .hasVehicle:
            return "Has vehicle"

        case .hasTrailer:
            return "Has trailer"

        case .hasCargo:
            return "Has cargo"
        }
    }

    var systemImage: String {

        switch self {

        case .all:
            return "calendar"

        case .inbound:
            return "arrow.down.left"

        case .outbound:
            return "arrow.up.right"

        case .anyGate:
            return "mappin"

        case .mainGate:
            return "door.left.hand.open"

        case .carrierGate:
            return "truck.box"

        case .hasVehicle:
            return "truck.box"

        case .hasTrailer:
            return "box.truck"

        case .hasCargo:
            return "shippingbox"
        }
    }
}


// MARK: - Appointment Record

struct AppointmentRecord: Identifiable {

    let id: Int

    let date: Date

    let location: String
    let gate: String
    let direction: String

    let personName: String
    let organizationName: String

    let vehicleType: String
    let vehicleIdentifier: String
    let fuelType: String

    let trailerIdentifier: String
    let trailerMake: String
    let trailerCondition: String

    let cargoReference: String
    let cargoTime: String

    var shortDate: String {
        Self.dateFormatter.string(
            from: date
        )
    }

    var shortTime: String {
        Self.timeFormatter.string(
            from: date
        )
    }

    private static let dateFormatter: DateFormatter = {

        let formatter = DateFormatter()

        formatter.locale = Locale(
            identifier: "en_US_POSIX"
        )

        formatter.dateFormat = "MMM d"

        return formatter
    }()

    private static let timeFormatter: DateFormatter = {

        let formatter = DateFormatter()

        formatter.locale = Locale(
            identifier: "en_US_POSIX"
        )

        formatter.dateFormat = "HH:mm"

        return formatter
    }()
}


// MARK: - Mock Data

extension AppointmentRecord {

    static let mockData: [AppointmentRecord] = {

        var calendar = Calendar(
            identifier: .gregorian
        )

        calendar.timeZone = .current

        func makeDate(
            year: Int = 2025,
            month: Int = 3,
            day: Int = 11,
            hour: Int,
            minute: Int
        ) -> Date {

            calendar.date(
                from: DateComponents(
                    year: year,
                    month: month,
                    day: day,
                    hour: hour,
                    minute: minute
                )
            ) ?? Date()
        }

        var records: [AppointmentRecord] = [

            AppointmentRecord(
                id: 1,
                date: makeDate(
                    hour: 8,
                    minute: 30
                ),
                location: "Northstar (Oshawa)",
                gate: "Any gate",
                direction: "IN",
                personName: "Gurpreet Singh",
                organizationName: "Honda Dealership",
                vehicleType: "Truck",
                vehicleIdentifier: "6165AD",
                fuelType: "Diesel",
                trailerIdentifier: "6165AD3823",
                trailerMake: "HOND",
                trailerCondition: "Good",
                cargoReference: "2457",
                cargoTime: "08:30"
            ),

            AppointmentRecord(
                id: 2,
                date: makeDate(
                    hour: 10,
                    minute: 15
                ),
                location: "Northstar (Oshawa)",
                gate: "Any gate",
                direction: "IN",
                personName: "Johnathan Driver",
                organizationName: "Bison",
                vehicleType: "Truck",
                vehicleIdentifier: "BIS-204",
                fuelType: "Diesel",
                trailerIdentifier: "BIS-9942",
                trailerMake: "HYUN",
                trailerCondition: "Good",
                cargoReference: "6381",
                cargoTime: "10:15"
            ),

            AppointmentRecord(
                id: 3,
                date: makeDate(
                    hour: 14,
                    minute: 20
                ),
                location: "Northstar (Oshawa)",
                gate: "Main gate",
                direction: "OUT",
                personName: "William Benedict Robertson",
                organizationName: "Canada Cartage",
                vehicleType: "Truck",
                vehicleIdentifier: "CC-8861",
                fuelType: "Diesel",
                trailerIdentifier: "CC-44591",
                trailerMake: "WAB",
                trailerCondition: "Good",
                cargoReference: "3120",
                cargoTime: "14:20"
            ),

            AppointmentRecord(
                id: 4,
                date: makeDate(
                    hour: 17,
                    minute: 0
                ),
                location: "Northstar (Oshawa)",
                gate: "Carrier gate",
                direction: "IN",
                personName: "Virginia Bain",
                organizationName: "Carmel Transportation",
                vehicleType: "Truck",
                vehicleIdentifier: "CT-901",
                fuelType: "Diesel",
                trailerIdentifier: "CT-7731",
                trailerMake: "UTIL",
                trailerCondition: "Good",
                cargoReference: "8814",
                cargoTime: "17:00"
            ),
        ]

        let organizations = [
            "Northstar Logistics",
            "Bison Transport",
            "Canada Cartage",
            "Carmel Transportation",
            "Honda Dealership",
            "CargoTrucks",
            "SafeGate Services",
        ]

        let people = [
            "Mason Williams",
            "Olivia Brown",
            "Ethan Davis",
            "Sophia Wilson",
            "Liam Anderson",
            "Emma Thompson",
            "Noah Martin",
        ]

        let locations = [
            "Northstar (Oshawa)",
            "Northstar (Dallas)",
            "Northstar (Toronto)",
        ]

        let gates = [
            "Any gate",
            "Main gate",
            "Carrier gate",
        ]

        let directions = [
            "IN",
            "IN",
            "OUT",
        ]

        let baseDate = makeDate(
            hour: 7,
            minute: 0
        )

        for index in 5...100 {

            let appointmentDate =
                calendar.date(
                    byAdding: .minute,
                    value: index * 95,
                    to: baseDate
                ) ?? baseDate

            records.append(
                AppointmentRecord(
                    id: index,
                    date: appointmentDate,
                    location:
                        locations[index % locations.count],
                    gate:
                        gates[index % gates.count],
                    direction:
                        directions[index % directions.count],
                    personName:
                        people[index % people.count],
                    organizationName:
                        organizations[
                            index % organizations.count
                        ],
                    vehicleType:
                        index.isMultiple(of: 4)
                            ? "Van"
                            : "Truck",
                    vehicleIdentifier:
                        "TRK-\(5000 + index)",
                    fuelType:
                        index.isMultiple(of: 6)
                            ? "Electric"
                            : "Diesel",
                    trailerIdentifier:
                        index.isMultiple(of: 5)
                            ? ""
                            : "TRL-\(8000 + index)",
                    trailerMake:
                        index.isMultiple(of: 5)
                            ? ""
                            : "HOND",
                    trailerCondition:
                        index.isMultiple(of: 5)
                            ? ""
                            : "Good",
                    cargoReference:
                        index.isMultiple(of: 7)
                            ? ""
                            : "\(2000 + index)",
                    cargoTime:
                        AppointmentRecord
                            .timeFormatter
                            .string(
                                from: appointmentDate
                            )
                )
            )
        }

        return records
    }()
}


// MARK: - Results

private struct AppointmentsResultsContent: View {

    let appointments: [AppointmentRecord]

    let resultCount: Int
    let locations: [String]

    @Binding var selectedLocationIndex: Int

    let page: Int
    let pageSize: Int
    let hasActiveSortOrFilter: Bool
    let onResetSortAndFilters: () -> Void

    let onSelect: (AppointmentRecord) -> Void
    let onPrevious: () -> Void
    let onNext: () -> Void

    var body: some View {

        ScrollView {

            LazyVStack(spacing: 18) {

                HStack(spacing: 12) {

                    Text("\(resultCount) results")
                        .font(
                            .subheadline.weight(.medium)
                        )
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

                    AppointmentLocationSwitcher(
                        locations: locations,
                        selectedIndex:
                            $selectedLocationIndex
                    )
                }
                .padding(.horizontal, 16)

                if appointments.isEmpty {

                    ContentUnavailableView(
                        "No appointments found",
                        systemImage:
                            "calendar.badge.exclamationmark",
                        description: Text(
                            "Try changing your search or filters."
                        )
                    )
                    .padding(.top, 54)
                    .padding(.horizontal, 24)

                } else {

                    AppointmentsCard(
                        appointments: appointments,
                        onSelect: onSelect
                    )

                    AppointmentPaginationFooter(
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


// MARK: - Appointments Card

private struct AppointmentsCard: View {

    let appointments: [AppointmentRecord]

    let onSelect: (AppointmentRecord) -> Void

    var body: some View {

        VStack(spacing: 0) {

            ForEach(
                appointments.enumerated(),
                id: \.element.id
            ) { index, appointment in

                Button {

                    onSelect(appointment)

                } label: {

                    AppointmentRow(
                        appointment: appointment
                    )
                }
                .buttonStyle(.plain)

                if index < appointments.count - 1 {

                    Divider()
                        .padding(.leading, 62)
                }
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
        .padding(.horizontal, 16)
    }
}


// MARK: - Appointment Row

private struct AppointmentRow: View {

    let appointment: AppointmentRecord

    private var rowTitle: String {
        [
            appointment.personName,
            appointment.vehicleIdentifier,
            appointment.trailerIdentifier,
            appointment.cargoReference,
        ]
        .first {
            !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        } ?? "Appointment"
    }

    private var rowDescription: String {
        [
            appointment.shortDate,
            appointment.shortTime,
            appointment.gate,
            appointment.direction,
        ]
        .joined(separator: " · ")
    }

    var body: some View {

        HStack(
            alignment: .top,
            spacing: 12
        ) {

            Image(systemName: "calendar")
                .font(
                    .subheadline.weight(.semibold)
                )
                .foregroundStyle(.secondary)
                .frame(
                    width: 34,
                    height: 34
                )
                .background(
                    Color.secondary.opacity(0.10),
                    in: RoundedRectangle(
                        cornerRadius: 10,
                        style: .continuous
                    )
                )

            VStack(
                alignment: .leading,
                spacing: 5
            ) {

                Text(rowTitle)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                Text(rowDescription)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            .frame(
                maxWidth: .infinity,
                alignment: .leading
            )
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .contentShape(Rectangle())
    }
}


// MARK: - Gate Label

private struct AppointmentGateLabel: View {

    let gate: String

    var body: some View {

        HStack(spacing: 5) {

            Image(
                systemName: "mappin.and.ellipse"
            )
            .font(
                .subheadline.weight(.medium)
            )

            Text(gate)
                .font(
                    .subheadline.weight(.medium)
                )
                .lineLimit(1)
                .minimumScaleFactor(0.85)
        }
        .foregroundStyle(.secondary)
        .accessibilityElement(
            children: .combine
        )
        .accessibilityLabel("Gate")
        .accessibilityValue(gate)
    }
}


// MARK: - Direction Chip

private struct AppointmentDirectionChip: View {

    let direction: String

    private var tint: Color {

        direction == "OUT"
            ? .orange
            : .blue
    }

    var body: some View {

        Text(direction)
            .font(
                .caption.weight(.semibold)
            )
            .foregroundStyle(tint)
            .padding(.horizontal, 9)
            .padding(.vertical, 5)
            .background(
                tint.opacity(0.12),
                in: Capsule()
            )
            .fixedSize()
    }
}


// MARK: - Date Chip

private struct AppointmentDateChip: View {

    let date: String
    let time: String

    var body: some View {

        Text("\(date) · \(time)")
            .font(
                .caption.weight(.semibold)
            )
            .foregroundStyle(.primary)
            .monospacedDigit()
            .padding(.horizontal, 9)
            .padding(.vertical, 5)
            .background(
                Color.secondary.opacity(0.12),
                in: Capsule()
            )
            .fixedSize()
    }
}


// MARK: - Conditional Search

extension View {

    @ViewBuilder
    fileprivate func appointmentConditionalSearch(
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

private struct AppointmentLocationSwitcher: View {

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

                    if location
                        == locations[selectedIndex]
                    {

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

                Text(
                    locations[selectedIndex]
                )
                .lineLimit(1)

                Image(
                    systemName:
                        "chevron.up.chevron.down"
                )
                .font(
                    .caption2.weight(.semibold)
                )
            }
            .font(
                .subheadline.weight(.medium)
            )
            .foregroundStyle(.secondary)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(
            "Choose location"
        )
        .accessibilityValue(
            locations[selectedIndex]
        )
    }
}


// MARK: - Editor

struct AppointmentEditorView: View {

    @Environment(\.dismiss)
    private var dismiss

    let appointment: AppointmentRecord?

    @State private var appointmentDate: Date

    @State private var gate: String
    @State private var direction: String

    @State private var personName: String
    @State private var organizationName: String

    @State private var vehicleType: String
    @State private var unitNumber = ""
    @State private var vehicleIdentifier: String
    @State private var fuelType: String

    @State private var trailerIdentifier: String
    @State private var trailerMake: String
    @State private var trailerCondition: String

    @State private var cargoReference: String
    @State private var cargoTime: String
    @State private var cargoStatus = ""
    @State private var cargoSealNumber = ""
    @State private var externalAppointmentNumber = ""
    @State private var additionalNote = ""
    @State private var detailValues: [String: String] = [:]

    // MARK: Disclosure state

    @State private var isPersonExpanded = false
    @State private var isVehicleExpanded = false
    @State private var isTrailerExpanded = false
    @State private var isCargoExpanded = false
    @State private var isTrailerSectionExpanded = false
    @State private var isCargoSectionExpanded = false
    @State private var isGeneralDetailsExpanded = false

    private let gates = [
        "Any gate",
        "Main gate",
        "Carrier gate",
    ]

    private let directions = [
        "IN",
        "OUT",
    ]

    private let cargoStatuses = [
        "Empty",
        "Loaded",
        "-",
    ]

    private let vehicleTypes = [
        "Truck",
        "Van",
        "Car",
        "Other",
    ]

    private let fuelTypes = [
        "Diesel",
        "Gasoline",
        "Electric",
        "Hybrid",
        "Other",
    ]

    private let trailerConditions = [
        "Good",
        "Damaged",
        "Needs inspection",
        "Unknown",
    ]

    private static let personDetailFields = [
        "DOT #",
        "ID type",
        "ID number",
        "Phone number",
        "ID present",
        "SCAC",
        "ID country",
        "Company card number",
        "First name",
        "Last name",
        "ID expiration date",
        "Driver PIN #",
        "Carrier",
    ]

    private static let vehicleDetailFields = [
        "Fuel type",
        "Vehicle info",
        "Fuel level",
        "LP country",
        "Class",
        "Fuel receipt",
        "VIN #",
    ]

    private static let trailerDetailFields = [
        "Equipment #",
        "Container #",
        "Chassis #",
        "Tag #",
        "Parking spot #",
        "Trailer owner",
        "Trailer condition",
        "Dolly",
        "Dolly number",
        "Size",
        "Trailer license plate #",
        "Customer",
        "Trailer usage",
        "Trailer SCAC",
    ]

    private static let cargoDetailFields = [
        "Parking spot #",
        "Cargo status",
        "Cargo type",
        "Reefer",
        "Reefer fuel",
        "Reefer temp",
        "Setpoint",
        "Cargo seal",
        "Cargo route #",
        "Cargo trip #",
        "Cargo move #",
        "Cargo pickup #",
        "Shipment number",
        "Units on arrival",
        "Units on departure",
        "Units total",
        "Brands",
        "Brand count",
        "Brand #2 count",
        "Hazard load",
        "Reefer running",
        "Tag number #",
        "BOL #",
        "BOL ASN #",
        "BOL ORS #",
        "Load type",
        "BOL PO #",
        "Seal color",
        "Load brand (tires)",
        "BOL CID #",
        "Load pallet #",
        "Release #",
        "Units dropped",
        "Units scanned",
        "Brand name",
        "Brand #2 name",
        "BOL sent",
        "Total unit number",
        "Booking #",
        "Load details",
        "Cargo load status",
        "Order #",
        "Reefer temp #2",
        "Setpoint #2",
        "Leaving Georgia",
        "LTS chassis",
        "FourKites started",
        "OCR verified",
        "Trailer status",
        "LOB",
        "Genset #",
    ]

    init(
        appointment: AppointmentRecord? = nil
    ) {
        self.appointment = appointment

        _appointmentDate = State(
            initialValue: appointment?.date ?? Date()
        )

        _gate = State(
            initialValue: appointment?.gate ?? "Any gate"
        )

        _direction = State(
            initialValue: appointment?.direction ?? ""
        )

        _personName = State(
            initialValue: appointment?.personName ?? ""
        )

        _organizationName = State(
            initialValue: appointment?.organizationName ?? ""
        )

        _vehicleType = State(
            initialValue: appointment?.vehicleType ?? ""
        )

        _vehicleIdentifier = State(
            initialValue: appointment?.vehicleIdentifier ?? ""
        )

        _fuelType = State(
            initialValue: appointment?.fuelType ?? ""
        )

        _trailerIdentifier = State(
            initialValue: appointment?.trailerIdentifier ?? ""
        )

        _trailerMake = State(
            initialValue: appointment?.trailerMake ?? ""
        )

        _trailerCondition = State(
            initialValue: appointment?.trailerCondition ?? ""
        )

        _cargoReference = State(
            initialValue: appointment?.cargoReference ?? ""
        )

        _cargoTime = State(
            initialValue: appointment?.cargoTime ?? ""
        )

        _cargoSealNumber = State(initialValue: "")
    }

    private var canSave: Bool {
        !personName
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .isEmpty
        &&
        !organizationName
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .isEmpty
    }

    var body: some View {

        NavigationStack {

            Form {
                Section("General") {
                    DatePicker(
                        "Date",
                        selection: $appointmentDate,
                        displayedComponents: .date
                    )

                    DatePicker(
                        "Time",
                        selection: $appointmentDate,
                        displayedComponents: .hourAndMinute
                    )

                    LabeledContent("Direction") {
                        Picker("Direction", selection: $direction) {
                            ForEach(directions, id: \.self) { direction in
                                Text(direction).tag(direction)
                            }
                        }
                        .labelsHidden()
                        .pickerStyle(.segmented)
                        .frame(width: 160)
                    }

                    DisclosureGroup(
                        "More details",
                        isExpanded: $isGeneralDetailsExpanded
                    ) {
                        trailingMenuRow(
                            title: "Gate",
                            selection: $gate,
                            options: gates
                        )

                        trailingTextField(
                            title: "External appt. #",
                            text: $externalAppointmentNumber,
                            placeholder: "Optional"
                        )
                    }
                }

                AppointmentEditorDetailSection(
                    title: "Person",
                    summaryValues: [
                        personName.isEmpty ? "" : "Name: \(personName)",
                        organizationName.isEmpty
                            ? ""
                            : "Company: \(organizationName)",
                    ],
                    detailFieldTitles: Self.personDetailFields,
                    values: $detailValues,
                    isExpanded: $isPersonExpanded
                ) {
                    trailingTextField(
                        title: "Full name",
                        text: $personName,
                        placeholder: "Full name"
                    )

                    trailingTextField(
                        title: "Company name",
                        text: $organizationName,
                        placeholder: "Company name"
                    )
                }

                AppointmentEditorDetailSection(
                    title: "Vehicle",
                    summaryValues: [
                        "Transport: \(vehicleType)",
                        unitNumber.isEmpty ? "" : "Unit #: \(unitNumber)",
                        vehicleIdentifier.isEmpty
                            ? ""
                            : "License plate: \(vehicleIdentifier)",
                    ],
                    detailFieldTitles: Self.vehicleDetailFields,
                    values: $detailValues,
                    isExpanded: $isVehicleExpanded
                ) {
                    trailingMenuRow(
                        title: "Transport",
                        selection: $vehicleType,
                        options: vehicleTypes
                    )

                    trailingTextField(
                        title: "Unit #",
                        text: $unitNumber,
                        placeholder: "Optional"
                    )

                    trailingTextField(
                        title: "License plate #",
                        text: $vehicleIdentifier,
                        placeholder: "Optional"
                    )
                }

                AppointmentEditorDetailSection(
                    title: "Trailer",
                    summaryValues: [],
                    detailFieldTitles: Self.trailerDetailFields,
                    values: $detailValues,
                    isExpanded: $isTrailerExpanded
                ) {
                    trailingTextField(
                        title: "Trailer #",
                        text: $trailerIdentifier,
                        placeholder: "Optional"
                    )


                }

                AppointmentEditorDetailSection(
                    title: "Cargo",
                    summaryValues: [],
                    detailFieldTitles: Self.cargoDetailFields,
                    values: $detailValues,
                    isExpanded: $isCargoExpanded
                ) {
                    trailingMenuRow(
                        title: "Cargo status",
                        selection: $cargoStatus,
                        options: cargoStatuses
                    )

                    trailingTextField(
                        title: "Seal #",
                        text: $cargoSealNumber,
                        placeholder: "Optional"
                    )
                }

                Section("Additional") {
                    trailingTextField(
                        title: "Note",
                        text: $additionalNote,
                        placeholder: "Optional"
                    )

                }
            }
            .navigationTitle(
                appointment == nil
                    ? "Add appointment"
                    : "Edit appointment"
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

                    Button(
                        appointment == nil
                            ? "Add"
                            : "Save"
                    ) {
                        dismiss()
                    }
                    .tint(.blue)
                    .disabled(!canSave)
                }
            }
        }
        .presentationDetents([.large])
    }

    private var updateDetails: some View {
        Section {
            LabeledContent(
                "Updated by",
                value: "maya@northstar.com  "
            )
            LabeledContent(
                "Updated at",
                value: "Today, 10:30 AM"
            )
        }
        .font(.footnote)
        .foregroundStyle(.secondary)
    }

    // MARK: - Section label

    private var personDetailsSummary: [String] {
        [
            "Name: \(personName)",
            "Organization: \(organizationName)",
        ]
    }

    private var vehicleDetailsSummary: [String] {
        [
            "Type: \(vehicleType)",
            vehicleIdentifier.isEmpty ? "" : "Plate / ID: \(vehicleIdentifier)",
            "Fuel: \(fuelType)",
        ]
    }

    private var trailerDetailsSummary: [String] {
        [
            trailerIdentifier.isEmpty ? "" : "Trailer ID: \(trailerIdentifier)",
            trailerMake.isEmpty ? "" : "Make: \(trailerMake)",
            "Condition: \(trailerCondition)",
        ]
    }

    private var cargoDetailsSummary: [String] {
        [
            cargoReference.isEmpty ? "" : "Reference: \(cargoReference)",
            cargoTime.isEmpty ? "" : "Cargo time: \(cargoTime)",
        ]
    }

    private func collapsibleSectionLabel(
        _ title: String,
        isExpanded: Bool,
        values: [String]
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)

            if !isExpanded {
                detailsSummary(values)
            }
        }
    }

    @ViewBuilder
    private func detailsSummary(_ values: [String]) -> some View {
        let nonEmptyValues = values.filter {
            !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }

        if nonEmptyValues.isEmpty {
            Text("No details added")
                .font(.caption)
                .foregroundStyle(.tertiary)
        } else {
            WrappingDetailFlowLayout(spacing: 6) {
                ForEach(nonEmptyValues, id: \.self) { value in
                    Text(value)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.leading)
                        .padding(.horizontal, 9)
                        .padding(.vertical, 5)
                        .background(
                            Color(.tertiarySystemGroupedBackground),
                            in: RoundedRectangle(
                                cornerRadius: 9,
                                style: .continuous
                            )
                        )
                }
            }
        }
    }

    // MARK: - Trailing text field

    private func trailingTextField(
        title: String,
        text: Binding<String>,
        placeholder: String
    ) -> some View {

        LabeledContent(title) {

            TextField(
                placeholder,
                text: text
            )
            .multilineTextAlignment(.trailing)
            .foregroundStyle(.secondary)
            .frame(
                maxWidth: 240,
                alignment: .trailing
            )
        }
    }

    // MARK: - Trailing menu picker

    private func trailingMenuRow(
        title: String,
        selection: Binding<String>,
        options: [String]
    ) -> some View {

        LabeledContent(title) {

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

                HStack(spacing: 5) {

                    Text(
                        selection.wrappedValue.isEmpty
                            ? "Select"
                            : selection.wrappedValue
                    )

                    Image(
                        systemName:
                            "chevron.up.chevron.down"
                    )
                    .font(
                        .caption2.weight(.semibold)
                    )
                }
                .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
        }
    }
}

private struct AppointmentEditorDetailSection<PrimaryContent: View>: View {
    let title: String
    let summaryValues: [String]
    let detailFieldTitles: [String]
    let isCollapsible: Bool
    let collapsedSummaryValues: [String]

    @Binding private var values: [String: String]
    @Binding private var isExpanded: Bool

    private let isSectionExpanded: Binding<Bool>?
    private let primaryContent: PrimaryContent

    init(
        title: String,
        summaryValues: [String],
        detailFieldTitles: [String],
        values: Binding<[String: String]>,
        isExpanded: Binding<Bool>,
        isCollapsible: Bool = false,
        isSectionExpanded: Binding<Bool>? = nil,
        collapsedSummaryValues: [String] = [],
        @ViewBuilder primaryContent: () -> PrimaryContent
    ) {
        self.title = title
        self.summaryValues = summaryValues
        self.detailFieldTitles = detailFieldTitles
        self.isCollapsible = isCollapsible
        self.isSectionExpanded = isSectionExpanded
        self.collapsedSummaryValues = collapsedSummaryValues
        _values = values
        _isExpanded = isExpanded
        self.primaryContent = primaryContent()
    }

    var body: some View {
        if isCollapsible, let isSectionExpanded {
            Section {
                DisclosureGroup(isExpanded: isSectionExpanded) {
                    primaryContent

                    AppointmentEditorMoreDetails(
                        fieldTitles: detailFieldTitles,
                        values: $values,
                        isExpanded: $isExpanded
                    )
                } label: {
                    AppointmentEditorCollapsedSectionSummary(title: title)
                }
            }
        } else {
            Section(title) {
                primaryContent

                AppointmentEditorMoreDetails(
                    fieldTitles: detailFieldTitles,
                    values: $values,
                    isExpanded: $isExpanded
                )
            }
        }
    }
}

private struct AppointmentEditorMoreDetails: View {
    let fieldTitles: [String]

    @Binding private var values: [String: String]
    @Binding private var isExpanded: Bool

    @State private var showsAllDetails = false

    init(
        fieldTitles: [String],
        values: Binding<[String: String]>,
        isExpanded: Binding<Bool>
    ) {
        self.fieldTitles = fieldTitles
        _values = values
        _isExpanded = isExpanded
    }

    private var visibleFieldTitles: [String] {
        showsAllDetails
            ? fieldTitles
            : Array(fieldTitles.prefix(10))
    }

    private var filledSummaryValues: [String] {
        fieldTitles.compactMap { title in
            guard let value = values[title]?
                .trimmingCharacters(in: .whitespacesAndNewlines),
                !value.isEmpty
            else {
                return nil
            }

            return "\(title): \(value)"
        }
    }

    var body: some View {
        DisclosureGroup(isExpanded: $isExpanded) {
            ForEach(visibleFieldTitles, id: \.self) { fieldTitle in
                LabeledContent(fieldTitle) {
                    TextField(
                        "Optional",
                        text: binding(for: fieldTitle)
                    )
                    .multilineTextAlignment(.trailing)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: 240, alignment: .trailing)
                }
            }

            if fieldTitles.count > 10, !showsAllDetails {
                Button("Load more") {
                    showsAllDetails = true
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        } label: {
            AppointmentEditorDetailSummary(
                values: filledSummaryValues,
                isExpanded: isExpanded
            )
        }
    }

    private func binding(for fieldTitle: String) -> Binding<String> {
        Binding(
            get: {
                values[fieldTitle, default: ""]
            },
            set: { newValue in
                values[fieldTitle] = newValue
            }
        )
    }
}

private struct AppointmentEditorCollapsedSectionSummary: View {
    let title: String

    var body: some View {
        Text(title)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.secondary)
    }
}

private struct AppointmentEditorDetailSummary: View {
    let values: [String]
    let isExpanded: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("More details")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)

            if !isExpanded {
                if values.isEmpty {
                    Text("No details added")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                } else {
                    WrappingDetailFlowLayout(spacing: 6) {
                        ForEach(values, id: \.self) { value in
                            Text(value)
                                .font(.caption.weight(.medium))
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.leading)
                                .padding(.horizontal, 9)
                                .padding(.vertical, 5)
                                .background(
                                    Color(.tertiarySystemGroupedBackground),
                                    in: RoundedRectangle(
                                        cornerRadius: 9,
                                        style: .continuous
                                    )
                                )
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Pagination

private struct AppointmentPaginationFooter: View {

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
