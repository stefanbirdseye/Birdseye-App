import SwiftUI
import UIKit

// MARK: - Access Records

struct AccessRecordsView: View {

    @State private var records = AccessRecord.samples

    @State private var searchText = ""
    @State private var isSearchPresented = false

    @State private var selectedLocationIndex = 0
    @State private var selectedRecord: AccessRecord?

    @State private var directionFilter: AccessDirectionFilter = .all
    @State private var vehicleTypeFilter: VehicleType?
    @State private var timeFilter: AccessRecordTimeFilter = .all
    @State private var sortOrder: AccessRecordSortOrder = .newest
    @AppStorage("isExportListEnabled") private var isExportListEnabled = false

    @State private var page = 0

    private let pageSize = 20

    private let locations = [
        "All locations",
        "Northstar (Oshawa)",
        "Northstar (Dallas)",
        "Northstar (Toronto)"
    ]

    private var cleanSearch: String {
        searchText.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
    }

    private var filteredRecords: [AccessRecord] {
        let selectedLocation =
            locations[selectedLocationIndex]

        let filtered = records.filter { record in

            let matchesSearch =
                cleanSearch.isEmpty ||
                record.fullName
                    .localizedCaseInsensitiveContains(
                        cleanSearch
                    ) ||
                record.company
                    .localizedCaseInsensitiveContains(
                        cleanSearch
                    ) ||
                record.vehicleType.title
                    .localizedCaseInsensitiveContains(
                        cleanSearch
                    ) ||
                record.vehicleNumber
                    .localizedCaseInsensitiveContains(
                        cleanSearch
                    ) ||
                record.accessPoint
                    .localizedCaseInsensitiveContains(
                        cleanSearch
                    ) ||
                record.location
                    .localizedCaseInsensitiveContains(
                        cleanSearch
                    )

            let matchesLocation =
                selectedLocation == "All locations" ||
                record.location == selectedLocation

            let matchesDirection: Bool = {
                switch directionFilter {
                case .all:
                    return true

                case .inOnly:
                    return record.direction == .in

                case .outOnly:
                    return record.direction == .out
                }
            }()

            let matchesVehicle = vehicleTypeFilter == nil ||
                record.vehicleType == vehicleTypeFilter

            let matchesTime = timeFilter.includes(record.date)

            return
                matchesSearch &&
                matchesLocation &&
                matchesDirection &&
                matchesVehicle &&
                matchesTime
        }

        switch sortOrder {
        case .newest:
            return filtered.sorted {
                $0.date > $1.date
            }

        case .oldest:
            return filtered.sorted {
                $0.date < $1.date
            }

        case .name:
            return filtered.sorted {
                $0.fullName.localizedStandardCompare(
                    $1.fullName
                ) == .orderedAscending
            }

        case .company:
            return filtered.sorted {
                $0.company.localizedStandardCompare(
                    $1.company
                ) == .orderedAscending
            }

        case .accessPoint:
            return filtered.sorted {
                $0.accessPoint.localizedStandardCompare(
                    $1.accessPoint
                ) == .orderedAscending
            }

        case .vehicleType:
            return filtered.sorted {
                $0.vehicleType.title.localizedStandardCompare(
                    $1.vehicleType.title
                ) == .orderedAscending
            }

        case .direction:
            return filtered.sorted {
                $0.direction.title.localizedStandardCompare(
                    $1.direction.title
                ) == .orderedAscending
            }
        }
    }

    private var pageRecords: [AccessRecord] {
        let start = page * pageSize

        guard start < filteredRecords.count else {
            return []
        }

        return Array(
            filteredRecords
                .dropFirst(start)
                .prefix(pageSize)
        )
    }

    var body: some View {
        VStack(spacing: 0) {
            AccessRecordsResultsContent(
                records: pageRecords,
                resultCount: filteredRecords.count,
                locations: locations,
                selectedLocationIndex:
                    $selectedLocationIndex,
                page: page,
                pageSize: pageSize,
                hasActiveSortOrFilter: directionFilter != .all
                    || selectedLocationIndex != 0
                    || vehicleTypeFilter != nil
                    || timeFilter != .all
                    || sortOrder != .newest,
                onResetSortAndFilters: {
                    directionFilter = .all
                    selectedLocationIndex = 0
                    vehicleTypeFilter = nil
                    timeFilter = .all
                    sortOrder = .newest
                    page = 0
                },
                onSelect: { record in
                    selectedRecord = record
                },
                onPrevious: {
                    page = max(
                        page - 1,
                        0
                    )
                },
                onNext: {
                    let maxPage = max(
                        (filteredRecords.count - 1)
                            / pageSize,
                        0
                    )

                    page = min(
                        page + 1,
                        maxPage
                    )
                }
            )
        }
        .navigationTitle(
            "Activity"
        )
        .navigationBarTitleDisplayMode(
            .inline
        )
        .toolbar {
            ToolbarItemGroup(
                placement: .topBarTrailing
            ) {

                Button {
                    HapticFeedback.lightImpact()
                    isSearchPresented = true
                } label: {
                    Image(
                        systemName:
                            "magnifyingglass"
                    )
                }
                .tint(.primary)
                .accessibilityLabel("Search")

                Menu {

                    Menu("Sort", systemImage: "arrow.up.arrow.down") {
                        ForEach(
                            AccessRecordSortOrder.allCases
                        ) { order in
                            Button {
                                sortOrder = order
                                page = 0
                            } label: {
                                if sortOrder == order {
                                    Label(
                                        order.title,
                                        systemImage:
                                            "checkmark"
                                    )
                                } else {
                                    Text(order.title)
                                }
                            }
                        }

                        Divider()

                        Button("Reset to default") {
                            sortOrder = .newest
                            page = 0
                        }
                    }

                    Menu("Filter", systemImage: "line.3.horizontal.decrease.circle") {
                        Menu("Direction", systemImage: "arrow.left.arrow.right") {
                            ForEach(AccessDirectionFilter.allCases) { filter in
                                Button {
                                    directionFilter = filter
                                    page = 0
                                } label: {
                                    if directionFilter == filter {
                                        Label(filter.title, systemImage: "checkmark")
                                    } else {
                                        Text(filter.title)
                                    }
                                }
                            }
                        }

                        Menu("Vehicle type", systemImage: "car") {
                            Button {
                                vehicleTypeFilter = nil
                                page = 0
                            } label: {
                                if vehicleTypeFilter == nil {
                                    Label("All vehicles", systemImage: "checkmark")
                                } else {
                                    Text("All vehicles")
                                }
                            }

                            ForEach(VehicleType.allCases, id: \.self) { vehicleType in
                                Button {
                                    vehicleTypeFilter = vehicleType
                                    page = 0
                                } label: {
                                    if vehicleTypeFilter == vehicleType {
                                        Label(vehicleType.title, systemImage: "checkmark")
                                    } else {
                                        Text(vehicleType.title)
                                    }
                                }
                            }
                        }

                        Menu("Time", systemImage: "calendar") {
                            ForEach(AccessRecordTimeFilter.allCases) { filter in
                                Button {
                                    timeFilter = filter
                                    page = 0
                                } label: {
                                    if timeFilter == filter {
                                        Label(filter.title, systemImage: "checkmark")
                                    } else {
                                        Text(filter.title)
                                    }
                                }
                            }
                        }

                        Divider()

                        Button("Reset to default") {
                            directionFilter = .all
                            vehicleTypeFilter = nil
                            timeFilter = .all
                            page = 0
                        }
                    }

                    if isExportListEnabled {
                        Section("Actions") {
                            Button {
                                // Export records
                            } label: {
                                Label(
                                    "Export records",
                                    systemImage:
                                        "square.and.arrow.up"
                                )
                            }
                        }
                    }

                    if directionFilter != .all ||
                        selectedLocationIndex != 0 ||
                        vehicleTypeFilter != nil ||
                        timeFilter != .all ||
                        sortOrder != .newest
                    {
                        Button {
                            directionFilter = .all
                            selectedLocationIndex = 0
                            vehicleTypeFilter = nil
                            timeFilter = .all
                            sortOrder = .newest
                            page = 0
                        } label: {
                            Text("Reset view")
                                .foregroundStyle(.blue)
                        }
                        .tint(.blue)
                    }

                } label: {
                    Image(
                        systemName: directionFilter != .all
                            || selectedLocationIndex != 0
                            || vehicleTypeFilter != nil
                            || timeFilter != .all
                            || sortOrder != .newest
                            ? "ellipsis.circle.fill"
                            : "ellipsis"
                    )
                }
                .tint(.primary)
                .accessibilityLabel(
                    "Sort, filter, and more"
                )
            }
        }
        .accessRecordsConditionalSearch(
            isPresented:
                $isSearchPresented,
            text:
                $searchText,
            prompt:
                "Search access records"
        )
        .onChange(
            of: searchText
        ) { _, _ in
            page = 0
        }
        .onChange(
            of: selectedLocationIndex
        ) { _, _ in
            page = 0
        }
        .onChange(
            of: directionFilter
        ) { _, _ in
            page = 0
        }
        .onChange(of: vehicleTypeFilter) { _, _ in
            page = 0
        }
        .onChange(of: timeFilter) { _, _ in
            page = 0
        }
        .onChange(
            of: sortOrder
        ) { _, _ in
            page = 0
        }
        .sheet(
            item: $selectedRecord
        ) { record in
            AccessRecordPreviewSheet(
                record: record
            ) { updatedRecord in
                if let index =
                    records.firstIndex(
                        where: {
                            $0.id ==
                                updatedRecord.id
                        }
                    )
                {
                    records[index] =
                        updatedRecord
                }
            }
        }
    }
}


// MARK: - Results

private struct AccessRecordsResultsContent: View {

    let records: [AccessRecord]
    let resultCount: Int

    let locations: [String]

    @Binding var selectedLocationIndex: Int

    let page: Int
    let pageSize: Int
    let hasActiveSortOrFilter: Bool
    let onResetSortAndFilters: () -> Void

    let onSelect:
        (AccessRecord) -> Void

    let onPrevious: () -> Void
    let onNext: () -> Void

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 18) {

                HStack(spacing: 12) {
                    Text(
                        "\(resultCount) results"
                    )
                    .font(
                        .subheadline.weight(
                            .medium
                        )
                    )
                    .foregroundStyle(
                        .secondary
                    )
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

                    AccessRecordsLocationSwitcher(
                        locations:
                            locations,
                        selectedIndex:
                            $selectedLocationIndex
                    )
                }
                .padding(
                    .horizontal,
                    16
                )

                if records.isEmpty {
                    ContentUnavailableView(
                        "No records found",
                        systemImage:
                            "door.left.hand.open",
                        description: Text(
                            "Try changing your search or filters."
                        )
                    )
                    .padding(.top, 54)
                    .padding(
                        .horizontal,
                        24
                    )

                } else {
                    AccessRecordsCard(
                        records: records,
                        onSelect: onSelect
                    )

                    AccessRecordsPaginationFooter(
                        page: page,
                        itemCount:
                            resultCount,
                        pageSize:
                            pageSize,
                        onPrevious:
                            onPrevious,
                        onNext:
                            onNext
                    )
                    .padding(
                        .horizontal,
                        16
                    )
                }
            }
            .padding(.top, 16)
            .padding(
                .bottom,
                110
            )
        }
        .background(
            Color(
                .systemGroupedBackground
            )
        )
    }
}


// MARK: - Records Card

private struct AccessRecordsCard: View {

    let records: [AccessRecord]

    let onSelect:
        (AccessRecord) -> Void

    var body: some View {
        VStack(spacing: 0) {
            ForEach(
                records.enumerated(),
                id: \.element.id
            ) { index, record in

                Button {
                    onSelect(record)
                } label: {
                    AccessRecordRow(
                        record: record
                    )
                }
                .buttonStyle(.plain)

                if index <
                    records.count - 1
                {
                    Divider()
                        .padding(
                            .leading,
                            76
                        )
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
        .padding(
            .horizontal,
            16
        )
    }
}


// MARK: - Record Row

private struct AccessRecordRow: View {

    let record: AccessRecord

    var body: some View {
        HStack(
            alignment: .top,
            spacing: 12
        ) {

            AccessRecordThumbnail(
                record: record
            )

            VStack(
                alignment: .leading,
                spacing: 6
            ) {

                topRow

                companyLabel

                ViewThatFits(
                    in: .horizontal
                ) {

                    HStack(spacing: 10) {
                        vehicleLabel
                        gateLabel
                    }
                    .fixedSize(
                        horizontal: true,
                        vertical: false
                    )

                    VStack(
                        alignment: .leading,
                        spacing: 6
                    ) {
                        vehicleLabel
                        gateLabel
                    }
                }
            }
            .frame(
                maxWidth: .infinity,
                alignment: .leading
            )
        }
        .padding(
            .horizontal,
            16
        )
        .padding(
            .vertical,
            14
        )
        .contentShape(
            Rectangle()
        )
    }

    private var topRow: some View {
        HStack(
            alignment: .firstTextBaseline,
            spacing: 8
        ) {

            Text(record.fullName)
                .font(
                    .body.weight(
                        .semibold
                    )
                )
                .foregroundStyle(
                    .primary
                )
                .lineLimit(1)

            Spacer(minLength: 8)

            AccessDirectionLabel(
                direction:
                    record.direction
            )

            Text(record.timeText)
                .font(
                    .subheadline.weight(
                        .medium
                    )
                )
                .foregroundStyle(
                    .secondary
                )
                .monospacedDigit()
        }
    }

    private var companyLabel: some View {
        HStack(spacing: 6) {

            Image(
                systemName:
                    "building.2"
            )
            .font(
                .caption.weight(
                    .medium
                )
            )

            Text(record.company)
                .lineLimit(1)
        }
        .font(.subheadline)
        .foregroundStyle(
            .secondary
        )
    }

    private var vehicleLabel: some View {
        HStack(spacing: 8) {

            Text(
                record.vehicleType.title
            )
            .font(.subheadline)
            .foregroundStyle(
                .secondary
            )
            .lineLimit(1)

            Text(
                record.vehicleNumber
            )
            .font(
                .caption.weight(
                    .semibold
                )
            )
            .foregroundStyle(
                .secondary
            )
            .padding(
                .horizontal,
                8
            )
            .padding(
                .vertical,
                4
            )
            .background(
                Color.secondary.opacity(
                    0.10
                ),
                in: RoundedRectangle(
                    cornerRadius: 7,
                    style: .continuous
                )
            )
        }
    }

    private var gateLabel: some View {
        HStack(spacing: 6) {

            Image(
                systemName:
                    "door.left.hand.open"
            )
            .font(
                .caption.weight(
                    .medium
                )
            )

            Text(
                record.accessPoint
            )
            .lineLimit(1)
        }
        .font(.subheadline)
        .foregroundStyle(
            .secondary
        )
    }
}


// MARK: - Media Thumbnail

private struct AccessRecordThumbnail: View {

    let record: AccessRecord

    var body: some View {
        ZStack(
            alignment: .bottomTrailing
        ) {
            ZStack {
                RoundedRectangle(
                    cornerRadius: 10,
                    style: .continuous
                )
                .fill(
                    Color.secondary.opacity(
                        0.10
                    )
                )

                AccessSnapshotImage(
                    snapshot: record.snapshots[0],
                    contentMode: .fill
                )
                .frame(width: 50, height: 50)
                .clipped()
            }
            .frame(width: 50, height: 50)
            .clipShape(
                RoundedRectangle(
                    cornerRadius: 10,
                    style: .continuous
                )
            )

            Text(
                "\(record.snapshots.count)"
            )
            .font(
                .system(
                    size: 9,
                    weight: .bold,
                    design: .rounded
                )
            )
            .monospacedDigit()
            .foregroundStyle(.white)
            .padding(
                .horizontal,
                7
            )
            .padding(
                .vertical,
                3
            )
            .background(
                .black.opacity(0.72),
                in: Capsule()
            )
            .offset(
                x: 4,
                y: 4
            )
        }
        .frame(
            width: 50,
            height: 50,
            alignment: .top
        )
        .accessibilityElement(
            children: .ignore
        )
        .accessibilityLabel(
            "\(record.snapshots.count) transaction images"
        )
    }
}


// MARK: - Direction Chip

private struct AccessDirectionLabel: View {

    let direction: AccessDirection

    var body: some View {
        Text(direction.title)
            .font(
                .caption.weight(
                    .bold
                )
            )
            .foregroundStyle(
                direction.color
            )
            .padding(
                .horizontal,
                10
            )
            .padding(
                .vertical,
                5
            )
            .background(
                direction.color.opacity(
                    0.12
                ),
                in: Capsule()
            )
            .fixedSize()
            .accessibilityLabel(
                direction == .in
                    ? "Entered"
                    : "Exited"
            )
    }
}


// MARK: - Location Switcher

private struct AccessRecordsLocationSwitcher: View {

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
                        locations
                            .firstIndex(
                                of: location
                            ) ?? 0
                } label: {
                    if location ==
                        locations[
                            selectedIndex
                        ]
                    {
                        Label(
                            location,
                            systemImage:
                                "checkmark"
                        )
                    } else {
                        Text(location)
                    }
                }
            }

        } label: {
            HStack(spacing: 5) {

                Text(
                    locations[
                        selectedIndex
                    ]
                )
                .lineLimit(1)

                Image(
                    systemName:
                        "chevron.up.chevron.down"
                )
                .font(
                    .caption2.weight(
                        .semibold
                    )
                )
            }
            .font(
                .subheadline.weight(
                    .medium
                )
            )
            .foregroundStyle(
                .secondary
            )
            .contentShape(
                Rectangle()
            )
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


// MARK: - Preview Sheet

private struct AccessRecordPreviewSheet: View {

    @Environment(\.dismiss)
    private var dismiss

    @State private var record: AccessRecord

    @State private var isEditing = false

    @State private var selectedSnapshotIndex = 0

    @State private var fullScreenSnapshot: AccessSnapshot?

    @GestureState private var previewMagnification = 1.0
    @State private var previewBaseScale = 1.0
    @GestureState private var previewDragTranslation = CGSize.zero
    @State private var previewBaseOffset = CGSize.zero

    let onSave:
        (AccessRecord) -> Void

    init(
        record: AccessRecord,
        onSave: @escaping
            (AccessRecord) -> Void
    ) {
        _record = State(
            initialValue: record
        )

        self.onSave = onSave
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(
                    alignment: .leading,
                    spacing: 20
                ) {
                    snapshotGallery

                    if isEditing {
                        editingContent
                    } else {
                        detailsContent
                    }
                }
                .padding(.top, 16)
                .padding(
                    .bottom,
                    40
                )
            }
            .background(
                Color(
                    .systemGroupedBackground
                )
            )
            .navigationTitle(
                "Access record"
            )
            .navigationBarTitleDisplayMode(
                .inline
            )
            .toolbar {

                ToolbarItem(
                    placement:
                        .cancellationAction
                ) {
                    Button("Close") {
                        dismiss()
                    }
                }

                ToolbarItem(
                    placement:
                        .confirmationAction
                ) {
                    if isEditing {
                        Button("Save") {
                            onSave(record)

                            withAnimation(
                                .snappy
                            ) {
                                isEditing = false
                            }
                        }
                        .buttonStyle(
                            .glassProminent
                        )
                        .tint(.blue)

                    } else {
                        Button("Edit") {
                            withAnimation(
                                .snappy
                            ) {
                                isEditing = true
                            }
                        }
                    }
                }
            }
        }
        .presentationDetents([
            .large
        ])
        .presentationDragIndicator(
            .visible
        )
        .fullScreenCover(item: $fullScreenSnapshot) { snapshot in
            let selectedIndex = record.snapshots.firstIndex {
                $0.id == snapshot.id
            } ?? 0

            ActivitySnapshotViewer(
                snapshots: record.snapshots,
                selectedSnapshotIndex: selectedIndex
            )
        }
    }

    // MARK: Gallery

    private var snapshotGallery: some View {
        VStack(
            alignment: .leading,
            spacing: 12
        ) {

            ZStack(
                alignment: .bottomLeading
            ) {
                Color.black

                GeometryReader { proxy in
                    AccessSnapshotImage(
                        snapshot: record.snapshots[selectedSnapshotIndex],
                        contentMode: .fit
                    )
                    .scaleEffect(previewScale)
                    .offset(previewOffset(in: proxy.size))
                }

                HStack {
                    Text(
                        "\(selectedSnapshotIndex + 1) of \(record.snapshots.count)"
                    )
                    .font(
                        .caption.weight(
                            .semibold
                        )
                    )
                    .foregroundStyle(
                        .white
                    )
                    .monospacedDigit()
                    .padding(
                        .horizontal,
                        9
                    )
                    .padding(
                        .vertical,
                        5
                    )
                    .background(
                        .black.opacity(
                            0.65
                        ),
                        in: Capsule()
                    )

                    Spacer()

                    Button {
                        fullScreenSnapshot = record.snapshots[selectedSnapshotIndex]
                    } label: {
                        Image(
                            systemName: "arrow.up.left.and.arrow.down.right"
                        )
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white)
                        .frame(width: 28, height: 28)
                        .background(
                            .black.opacity(0.65),
                            in: Circle()
                        )
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Open full-screen image")
                }
                .padding(12)
            }
            .aspectRatio(16 / 9, contentMode: .fit)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .gesture(
                MagnifyGesture()
                    .updating($previewMagnification) { value, state, _ in
                        state = value.magnification
                    }
                    .onEnded { value in
                        previewBaseScale = min(
                            max(previewBaseScale * value.magnification, 1),
                            4
                        )
                    }
            )
            .simultaneousGesture(
                DragGesture()
                    .updating($previewDragTranslation) { value, state, _ in
                        guard previewScale > 1 else {
                            return
                        }

                        state = value.translation
                    }
                    .onEnded { value in
                        guard previewBaseScale > 1 else {
                            return
                        }

                        previewBaseOffset = CGSize(
                            width: previewBaseOffset.width + value.translation.width,
                            height: previewBaseOffset.height + value.translation.height
                        )
                    }
            )
            .onTapGesture {
                if previewScale > 1 {
                    withAnimation(.snappy) {
                        previewBaseScale = 1
                        previewBaseOffset = .zero
                    }
                } else {
                    fullScreenSnapshot = record.snapshots[selectedSnapshotIndex]
                }
            }
            .accessibilityLabel("Open transaction image \(selectedSnapshotIndex + 1) of \(record.snapshots.count)")
            .accessibilityHint("Pinch to zoom. Tap to open full screen.")
            .padding(
                .horizontal,
                16
            )

            ScrollView(
                .horizontal,
                showsIndicators: false
            ) {
                HStack(spacing: 8) {
                    ForEach(
                        record.snapshots.indices,
                        id: \.self
                    ) { index in

                        Button {
                            selectedSnapshotIndex =
                                index
                            previewBaseScale = 1
                            previewBaseOffset = .zero
                        } label: {
                            AccessSnapshotImage(
                                snapshot: record.snapshots[index],
                                contentMode: .fill
                            )
                            .frame(
                                width: 72,
                                height: 40
                            )
                            .background(
                                Color.secondary.opacity(0.10),
                                in: RoundedRectangle(cornerRadius: 9, style: .continuous)
                            )
                            .clipShape(
                                RoundedRectangle(cornerRadius: 9, style: .continuous)
                            )
                            .overlay {
                                if index ==
                                    selectedSnapshotIndex
                                {
                                    RoundedRectangle(
                                        cornerRadius: 9,
                                        style: .continuous
                                    )
                                    .strokeBorder(
                                        .blue,
                                        lineWidth: 2
                                    )
                                }
                            }
                        }
                        .buttonStyle(
                            .plain
                        )
                    }
                }
                .padding(
                    .horizontal,
                    16
                )
            }
        }
    }

    private var previewScale: CGFloat {
        min(max(previewBaseScale * previewMagnification, 1), 4)
    }

    private func previewOffset(in size: CGSize) -> CGSize {
        let maximumHorizontalOffset = (previewScale - 1) * size.width / 2
        let maximumVerticalOffset = (previewScale - 1) * size.height / 2
        let offset = CGSize(
            width: previewBaseOffset.width + previewDragTranslation.width,
            height: previewBaseOffset.height + previewDragTranslation.height
        )

        return CGSize(
            width: min(max(offset.width, -maximumHorizontalOffset), maximumHorizontalOffset),
            height: min(max(offset.height, -maximumVerticalOffset), maximumVerticalOffset)
        )
    }

    // MARK: Details

    private var detailsContent: some View {
        VStack(spacing: 0) {

            AccessRecordDetailRow(
                title: "Direction"
            ) {
                AccessDirectionLabel(
                    direction:
                        record.direction
                )
            }

            rowDivider

            AccessRecordDetailRow(
                title: "Time",
                value:
                    record.timeText
            )

            rowDivider

            AccessRecordDetailRow(
                title: "Full name",
                value:
                    record.fullName
            )

            rowDivider

            AccessRecordDetailRow(
                title: "Company",
                value:
                    record.company
            )

            rowDivider

            AccessRecordDetailRow(
                title: "Vehicle type",
                value:
                    record.vehicleType.title
            )

            rowDivider

            AccessRecordDetailRow(
                title: "Vehicle number",
                value:
                    record.vehicleNumber
            )

            rowDivider

            AccessRecordDetailRow(
                title: "Access point",
                value:
                    record.accessPoint
            )

            rowDivider

            AccessRecordDetailRow(
                title: "Location",
                value:
                    record.location
            )

            rowDivider

            AccessRecordDetailRow(
                title:
                    "Transaction images",
                value:
                    "\(record.snapshots.count)"
            )
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
        .padding(
            .horizontal,
            16
        )
    }

    // MARK: Editing

    private var editingContent: some View {
        VStack(spacing: 0) {

            directionEditor

            rowDivider

            editingRow(
                title: "Full name",
                text:
                    $record.fullName
            )

            rowDivider

            editingRow(
                title: "Company",
                text:
                    $record.company
            )

            rowDivider

            vehicleTypeEditor

            rowDivider

            editingRow(
                title:
                    "Vehicle number",
                text:
                    $record.vehicleNumber
            )

            rowDivider

            editingRow(
                title:
                    "Access point",
                text:
                    $record.accessPoint
            )

            rowDivider

            locationEditor
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
        .padding(
            .horizontal,
            16
        )
    }

    private var directionEditor: some View {
        HStack {

            Text("Direction")

            Spacer()

            Menu {
                Button {
                    record.direction = .in
                } label: {
                    if record.direction ==
                        .in
                    {
                        Label(
                            "IN",
                            systemImage:
                                "checkmark"
                        )
                    } else {
                        Text("IN")
                    }
                }

                Button {
                    record.direction =
                        .out
                } label: {
                    if record.direction ==
                        .out
                    {
                        Label(
                            "OUT",
                            systemImage:
                                "checkmark"
                        )
                    } else {
                        Text("OUT")
                    }
                }

            } label: {
                AccessDirectionLabel(
                    direction:
                        record.direction
                )
            }
        }
        .padding(
            .horizontal,
            16
        )
        .frame(
            minHeight: 52
        )
    }

    private var vehicleTypeEditor: some View {
        Menu {
            ForEach(
                VehicleType.allCases,
                id: \.self
            ) { type in

                Button {
                    record.vehicleType =
                        type
                } label: {
                    if record.vehicleType ==
                        type
                    {
                        Label(
                            type.title,
                            systemImage:
                                "checkmark"
                        )
                    } else {
                        Text(type.title)
                    }
                }
            }

        } label: {
            HStack {
                Text("Vehicle type")
                    .foregroundStyle(
                        .primary
                    )

                Spacer()

                Text(
                    record.vehicleType.title
                )
                .foregroundStyle(
                    .secondary
                )

                Image(
                    systemName:
                        "chevron.up.chevron.down"
                )
                .font(
                    .caption2.weight(
                        .semibold
                    )
                )
                .foregroundStyle(
                    .tertiary
                )
            }
            .padding(
                .horizontal,
                16
            )
            .frame(
                minHeight: 52
            )
            .contentShape(
                Rectangle()
            )
        }
        .buttonStyle(.plain)
    }

    private var locationEditor: some View {
        Menu {
            ForEach(
                [
                    "Northstar (Oshawa)",
                    "Northstar (Dallas)",
                    "Northstar (Toronto)"
                ],
                id: \.self
            ) { location in

                Button {
                    record.location =
                        location
                } label: {
                    if record.location ==
                        location
                    {
                        Label(
                            location,
                            systemImage:
                                "checkmark"
                        )
                    } else {
                        Text(location)
                    }
                }
            }

        } label: {
            HStack {
                Text("Location")
                    .foregroundStyle(
                        .primary
                    )

                Spacer()

                Text(
                    record.location
                )
                .foregroundStyle(
                    .secondary
                )
                .lineLimit(1)

                Image(
                    systemName:
                        "chevron.up.chevron.down"
                )
                .font(
                    .caption2.weight(
                        .semibold
                    )
                )
                .foregroundStyle(
                    .tertiary
                )
            }
            .padding(
                .horizontal,
                16
            )
            .frame(
                minHeight: 52
            )
            .contentShape(
                Rectangle()
            )
        }
        .buttonStyle(.plain)
    }

    private var rowDivider: some View {
        Divider()
            .padding(
                .leading,
                16
            )
    }

    private func editingRow(
        title: String,
        text: Binding<String>
    ) -> some View {
        HStack(spacing: 16) {

            Text(title)

            Spacer()

            TextField(
                title,
                text: text
            )
            .multilineTextAlignment(
                .trailing
            )
        }
        .padding(
            .horizontal,
            16
        )
        .frame(
            minHeight: 52
        )
    }
}


// MARK: - Detail Row

private struct AccessRecordDetailRow<
    Trailing: View
>: View {

    let title: String
    let value: String?
    let trailing: Trailing

    init(
        title: String,
        value: String
    ) where Trailing == EmptyView {
        self.title = title
        self.value = value
        self.trailing = EmptyView()
    }

    init(
        title: String,
        @ViewBuilder trailing:
            () -> Trailing
    ) {
        self.title = title
        self.value = nil
        self.trailing = trailing()
    }

    var body: some View {
        HStack(spacing: 16) {

            Text(title)

            Spacer()

            if let value {
                Text(value)
                    .foregroundStyle(
                        .secondary
                    )
                    .multilineTextAlignment(
                        .trailing
                    )
            }

            trailing
        }
        .padding(
            .horizontal,
            16
        )
        .frame(
            minHeight: 52
        )
    }
}


// MARK: - Pagination

private struct AccessRecordsPaginationFooter: View {

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
            .foregroundStyle(
                .secondary
            )
            .monospacedDigit()

            Spacer()

            HStack(spacing: 10) {

                paginationButton(
                    systemImage:
                        "chevron.left",
                    disabled:
                        page == 0,
                    action:
                        onPrevious
                )

                Text(
                    "\(page + 1) of \(pageCount)"
                )
                .font(
                    .subheadline.weight(
                        .semibold
                    )
                )
                .foregroundStyle(
                    .primary
                )
                .monospacedDigit()
                .frame(
                    minWidth: 58
                )

                paginationButton(
                    systemImage:
                        "chevron.right",
                    disabled:
                        page >=
                        pageCount - 1,
                    action:
                        onNext
                )
            }
        }
        .padding(
            .horizontal,
            2
        )
    }

    private func paginationButton(
        systemImage: String,
        disabled: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(
            action: action
        ) {
            Image(
                systemName:
                    systemImage
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
            .contentShape(
                Circle()
            )
        }
        .buttonStyle(.glass)
        .buttonBorderShape(
            .circle
        )
        .tint(.primary)
        .disabled(disabled)
        .opacity(
            disabled
                ? 0.35
                : 1
        )
    }
}


// MARK: - Search

extension View {

    @ViewBuilder
    fileprivate func accessRecordsConditionalSearch(
        isPresented:
            Binding<Bool>,
        text:
            Binding<String>,
        prompt:
            String
    ) -> some View {

        if isPresented.wrappedValue {
            self.searchable(
                text: text,
                isPresented:
                    isPresented,
                placement:
                    .navigationBarDrawer(
                        displayMode:
                            .always
                    ),
                prompt:
                    prompt
            )
        } else {
            self
        }
    }
}


// MARK: - Direction

private enum AccessDirection:
    String,
    Hashable,
    CaseIterable
{
    case `in`
    case out

    var title: String {
        switch self {
        case .in:
            return "IN"

        case .out:
            return "OUT"
        }
    }

    var color: Color {
        switch self {
        case .in:
            return .blue

        case .out:
            return Color(
                red: 0.90,
                green: 0.60,
                blue: 0.13
            )
        }
    }
}


// MARK: - Vehicle Type

private enum VehicleType:
    String,
    CaseIterable,
    Hashable
{
    case truck
    case bobtailTruck
    case straightTruck
    case car
    case van
    case pickup
    case tractor
    case containerTruck

    var title: String {
        switch self {
        case .truck:
            return "Truck"

        case .bobtailTruck:
            return "Bobtail truck"

        case .straightTruck:
            return "Straight truck"

        case .car:
            return "Car"

        case .van:
            return "Van"

        case .pickup:
            return "Pickup"

        case .tractor:
            return "Tractor"

        case .containerTruck:
            return "Container truck"
        }
    }
}


// MARK: - Filters

private enum AccessDirectionFilter:
    String,
    CaseIterable,
    Identifiable
{
    case all
    case inOnly
    case outOnly

    var id: Self {
        self
    }

    var title: String {
        switch self {
        case .all:
            return "All records"

        case .inOnly:
            return "IN only"

        case .outOnly:
            return "OUT only"
        }
    }

    var systemImage: String {
        switch self {
        case .all:
            return "arrow.left.arrow.right"

        case .inOnly:
            return "arrow.down"

        case .outOnly:
            return "arrow.up"
        }
    }
}


private enum AccessRecordTimeFilter:
    CaseIterable,
    Identifiable
{
    case all
    case today
    case last24Hours

    var id: Self {
        self
    }

    var title: String {
        switch self {
        case .all:
            return "All time"
        case .today:
            return "Today"
        case .last24Hours:
            return "Last 24 hours"
        }
    }

    func includes(_ date: Date) -> Bool {
        switch self {
        case .all:
            return true
        case .today:
            return Calendar.current.isDateInToday(date)
        case .last24Hours:
            return date >= Date.now.addingTimeInterval(-86_400)
        }
    }
}


// MARK: - Sort

private enum AccessRecordSortOrder:
    String,
    CaseIterable,
    Identifiable
{
    case newest
    case oldest
    case name
    case company
    case accessPoint
    case vehicleType
    case direction

    var id: Self {
        self
    }

    var title: String {
        switch self {
        case .newest:
            return "Newest first"

        case .oldest:
            return "Oldest first"

        case .name:
            return "Name"

        case .company:
            return "Company"

        case .accessPoint:
            return "Access point"

        case .vehicleType:
            return "Vehicle type"

        case .direction:
            return "Direction"
        }
    }

    var systemImage: String {
        switch self {
        case .newest:
            return "clock.arrow.circlepath"

        case .oldest:
            return "clock"

        case .name:
            return "textformat.abc"

        case .company:
            return "building.2"

        case .accessPoint:
            return "door.left.hand.open"

        case .vehicleType:
            return "car"

        case .direction:
            return "arrow.left.arrow.right"
        }
    }
}


// MARK: - Snapshot

private struct AccessSnapshot:
    Identifiable
{
    let id = UUID()

    let systemImage: String
    let assetName: String?
}


private struct AccessSnapshotImage: View {

    let snapshot: AccessSnapshot
    let contentMode: ContentMode

    var body: some View {
        Group {
            if let assetName = snapshot.assetName {
                Image(assetName)
                    .resizable()
                    .aspectRatio(contentMode: contentMode)
            } else {
                Image(systemName: snapshot.systemImage)
                    .font(.system(size: 52, weight: .light))
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}


private struct ActivitySnapshotViewer: View {

    @Environment(\.dismiss) private var dismiss

    let snapshots: [AccessSnapshot]

    @State private var selectedSnapshotIndex: Int

    @GestureState private var gestureScale = 1.0
    @State private var baseScale = 1.0
    @GestureState private var dragTranslation = CGSize.zero
    @State private var baseOffset = CGSize.zero
    @State private var isSaveConfirmationPresented = false

    init(
        snapshots: [AccessSnapshot],
        selectedSnapshotIndex: Int
    ) {
        self.snapshots = snapshots
        _selectedSnapshotIndex = State(
            initialValue: min(
                max(selectedSnapshotIndex, 0),
                max(snapshots.count - 1, 0)
            )
        )
    }

    private var currentSnapshot: AccessSnapshot? {
        snapshots.indices.contains(selectedSnapshotIndex)
            ? snapshots[selectedSnapshotIndex]
            : nil
    }

    private var scale: CGFloat {
        min(max(baseScale * gestureScale, 1), 4)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black
                    .ignoresSafeArea()

                if snapshots.isEmpty {
                    ContentUnavailableView(
                        "No images available",
                        systemImage: "photo"
                    )
                    .foregroundStyle(.white)

                } else {
                    GeometryReader { proxy in
                        TabView(selection: $selectedSnapshotIndex) {
                            ForEach(snapshots.indices, id: \.self) { index in
                                snapshotPage(
                                    snapshots[index],
                                    in: proxy.size
                                )
                                .tag(index)
                            }
                        }
                        .tabViewStyle(.page(indexDisplayMode: .never))
                    }

                    VStack {
                        Spacer()

                        Text(
                            "\(selectedSnapshotIndex + 1) of \(snapshots.count)"
                        )
                        .font(.caption.weight(.semibold))
                        .monospacedDigit()
                        .foregroundStyle(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(.black.opacity(0.65), in: Capsule())
                        .padding(.bottom, 20)
                    }
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(
                        "Image \(selectedSnapshotIndex + 1) of \(snapshots.count)"
                    )
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }

                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button {
                        withAnimation(.snappy) {
                            baseScale = max(baseScale - 0.5, 1)
                            if baseScale == 1 {
                                baseOffset = .zero
                            }
                        }
                    } label: {
                        Image(systemName: "minus.magnifyingglass")
                    }
                    .disabled(baseScale <= 1)
                    .accessibilityLabel("Zoom out")

                    Button {
                        withAnimation(.snappy) {
                            baseScale = min(baseScale + 0.5, 4)
                        }
                    } label: {
                        Image(systemName: "plus.magnifyingglass")
                    }
                    .disabled(baseScale >= 4)
                    .accessibilityLabel("Zoom in")

                    if let currentSnapshot {
                        Button {
                            saveImage(currentSnapshot)
                        } label: {
                            Image(systemName: "arrow.down.to.line")
                        }
                        .accessibilityLabel("Save image to Photos")
                    }
                }
            }
            .tint(.white)
            .alert("Image Saved", isPresented: $isSaveConfirmationPresented) {
                Button("OK", role: .cancel) {
                }
            } message: {
                Text("The transaction image was saved to your photo library.")
            }
        }
        .onChange(of: selectedSnapshotIndex) { _, _ in
            baseScale = 1
            baseOffset = .zero
        }
    }

    @ViewBuilder
    private func snapshotPage(
        _ snapshot: AccessSnapshot,
        in size: CGSize
    ) -> some View {
        if baseScale > 1 {
            snapshotImage(snapshot, in: size)
                .simultaneousGesture(panGesture)
        } else {
            snapshotImage(snapshot, in: size)
        }
    }

    private func snapshotImage(
        _ snapshot: AccessSnapshot,
        in size: CGSize
    ) -> some View {
        Group {
            if let assetName = snapshot.assetName {
                Image(assetName)
                    .resizable()
                    .scaledToFit()
            } else {
                Image(systemName: snapshot.systemImage)
                    .font(.system(size: 96, weight: .light))
                    .foregroundStyle(.white)
            }
        }
        .frame(width: size.width, height: size.height)
        .scaleEffect(scale)
        .offset(imageOffset(in: size))
        .gesture(
            MagnifyGesture()
                .updating($gestureScale) { value, state, _ in
                    state = value.magnification
                }
                .onEnded { value in
                    baseScale = min(
                        max(baseScale * value.magnification, 1),
                        4
                    )
                    if baseScale == 1 {
                        baseOffset = .zero
                    }
                }
        )
        .onTapGesture(count: 2) {
            withAnimation(.snappy) {
                baseScale = baseScale > 1 ? 1 : 2
                baseOffset = .zero
            }
        }
        .accessibilityLabel("Transaction image")
        .accessibilityHint(
            "Swipe left or right to view another image. Pinch to zoom, then drag to pan. Double tap to toggle zoom."
        )
    }

    private var panGesture: some Gesture {
        DragGesture()
            .updating($dragTranslation) { value, state, _ in
                state = value.translation
            }
            .onEnded { value in
                baseOffset = CGSize(
                    width: baseOffset.width + value.translation.width,
                    height: baseOffset.height + value.translation.height
                )
            }
    }

    private func saveImage(_ snapshot: AccessSnapshot) {
        guard let assetName = snapshot.assetName,
              let image = UIImage(named: assetName) else {
            return
        }

        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
        isSaveConfirmationPresented = true
    }

    private func imageOffset(in size: CGSize) -> CGSize {
        let maximumHorizontalOffset = (scale - 1) * size.width / 2
        let maximumVerticalOffset = (scale - 1) * size.height / 2
        let offset = CGSize(
            width: baseOffset.width + dragTranslation.width,
            height: baseOffset.height + dragTranslation.height
        )

        return CGSize(
            width: min(max(offset.width, -maximumHorizontalOffset), maximumHorizontalOffset),
            height: min(max(offset.height, -maximumVerticalOffset), maximumVerticalOffset)
        )
    }
}


// MARK: - Record

private struct AccessRecord:
    Identifiable
{
    let id: UUID

    var direction:
        AccessDirection

    var date: Date

    var fullName: String
    var company: String

    var vehicleType:
        VehicleType

    var vehicleNumber:
        String

    var accessPoint:
        String

    var location:
        String

    var snapshots:
        [AccessSnapshot]

    init(
        id: UUID = UUID(),
        direction:
            AccessDirection,
        date: Date,
        fullName:
            String,
        company:
            String,
        vehicleType:
            VehicleType,
        vehicleNumber:
            String,
        accessPoint:
            String,
        location:
            String,
        snapshotCount:
            Int
    ) {
        self.id = id

        self.direction =
            direction

        self.date = date

        self.fullName =
            fullName

        self.company =
            company

        self.vehicleType =
            vehicleType

        self.vehicleNumber =
            vehicleNumber

        self.accessPoint =
            accessPoint

        self.location =
            location

        let symbols = [
            "photo",
            "photo.fill",
            "photo.on.rectangle",
            "photo.on.rectangle.angled"
        ]

        let activityImageNames = [
            "ActivityMultiCamera",
            "ActivityTrailer",
            "ActivityNightTrailer",
            "ActivityPlateRed",
            "ActivityPlateGray"
        ]

        let snapshotStart = fullName.unicodeScalars.reduce(0) { partialResult, scalar in
            partialResult + Int(scalar.value)
        } % activityImageNames.count

        self.snapshots =
            (0..<snapshotCount)
                .map { index in
                    AccessSnapshot(
                        systemImage:
                            symbols[
                                index %
                                symbols.count
                            ],
                        assetName:
                            activityImageNames[
                                (index + snapshotStart) % activityImageNames.count
                            ]
                    )
                }
    }

    var timeText: String {
        date.formatted(
            date: .omitted,
            time: .shortened
        )
    }
}


// MARK: - Sample Records

private extension AccessRecord {

    static let samples: [AccessRecord] = [

        AccessRecord(
            direction: .in,
            date: .now.addingTimeInterval(-60 * 4),
            fullName: "David Okafor",
            company: "Northstar Logistics",
            vehicleType: .truck,
            vehicleNumber: "T-204",
            accessPoint: "North Gate",
            location: "Northstar (Oshawa)",
            snapshotCount: 14
        ),

        AccessRecord(
            direction: .out,
            date: .now.addingTimeInterval(-60 * 10),
            fullName: "Milan Jović",
            company: "Bison Transport",
            vehicleType: .truck,
            vehicleNumber: "VNL-12",
            accessPoint: "South Gate",
            location: "Northstar (Oshawa)",
            snapshotCount: 12
        ),

        AccessRecord(
            direction: .in,
            date: .now.addingTimeInterval(-60 * 18),
            fullName: "Olivia Martin",
            company: "CargoTrucks",
            vehicleType: .bobtailTruck,
            vehicleNumber: "BT-33",
            accessPoint: "Warehouse A",
            location: "Northstar (Dallas)",
            snapshotCount: 16
        ),

        AccessRecord(
            direction: .out,
            date: .now.addingTimeInterval(-60 * 25),
            fullName: "Elias Petrov",
            company: "SafeGate Services",
            vehicleType: .car,
            vehicleNumber: "C-018",
            accessPoint: "Gate 3",
            location: "Northstar (Toronto)",
            snapshotCount: 11
        ),

        AccessRecord(
            direction: .in,
            date: .now.addingTimeInterval(-60 * 31),
            fullName: "Gurpreet Singh",
            company: "Honda Dealership",
            vehicleType: .truck,
            vehicleNumber: "P-579",
            accessPoint: "North Gate",
            location: "Northstar (Oshawa)",
            snapshotCount: 13
        ),

        AccessRecord(
            direction: .in,
            date: .now.addingTimeInterval(-60 * 38),
            fullName: "Marcus Johnson",
            company: "DHL Supply Chain",
            vehicleType: .straightTruck,
            vehicleNumber: "DHL-882",
            accessPoint: "Gate 2",
            location: "Northstar (Dallas)",
            snapshotCount: 18
        ),

        AccessRecord(
            direction: .out,
            date: .now.addingTimeInterval(-60 * 44),
            fullName: "Sarah Patel",
            company: "FedEx Ground",
            vehicleType: .van,
            vehicleNumber: "FX-319",
            accessPoint: "East Gate",
            location: "Northstar (Toronto)",
            snapshotCount: 15
        ),

        AccessRecord(
            direction: .in,
            date: .now.addingTimeInterval(-60 * 52),
            fullName: "Daniel Brooks",
            company: "Arnold Brothers",
            vehicleType: .tractor,
            vehicleNumber: "AB-771",
            accessPoint: "South Gate",
            location: "Northstar (Oshawa)",
            snapshotCount: 12
        ),

        AccessRecord(
            direction: .out,
            date: .now.addingTimeInterval(-60 * 59),
            fullName: "James Wilson",
            company: "UPS Freight",
            vehicleType: .truck,
            vehicleNumber: "UPS-440",
            accessPoint: "North Gate",
            location: "Northstar (Dallas)",
            snapshotCount: 17
        ),

        AccessRecord(
            direction: .in,
            date: .now.addingTimeInterval(-60 * 67),
            fullName: "Michael Chen",
            company: "Ryder Logistics",
            vehicleType: .pickup,
            vehicleNumber: "RY-218",
            accessPoint: "Employee Gate",
            location: "Northstar (Toronto)",
            snapshotCount: 10
        ),

        AccessRecord(
            direction: .out,
            date: .now.addingTimeInterval(-60 * 76),
            fullName: "Andre Thompson",
            company: "XPO Logistics",
            vehicleType: .containerTruck,
            vehicleNumber: "XPO-93",
            accessPoint: "Gate 4",
            location: "Northstar (Oshawa)",
            snapshotCount: 21
        ),

        AccessRecord(
            direction: .in,
            date: .now.addingTimeInterval(-60 * 84),
            fullName: "Lucas Martinez",
            company: "Kenco Logistics",
            vehicleType: .truck,
            vehicleNumber: "KL-204",
            accessPoint: "West Gate",
            location: "Northstar (Dallas)",
            snapshotCount: 14
        ),

        AccessRecord(
            direction: .out,
            date: .now.addingTimeInterval(-60 * 93),
            fullName: "Emily Carter",
            company: "Amazon Freight",
            vehicleType: .van,
            vehicleNumber: "AMZ-82",
            accessPoint: "Warehouse B",
            location: "Northstar (Toronto)",
            snapshotCount: 12
        ),

        AccessRecord(
            direction: .in,
            date: .now.addingTimeInterval(-60 * 101),
            fullName: "Robert Garcia",
            company: "Penske Logistics",
            vehicleType: .straightTruck,
            vehicleNumber: "PL-518",
            accessPoint: "North Gate",
            location: "Northstar (Oshawa)",
            snapshotCount: 16
        ),

        AccessRecord(
            direction: .out,
            date: .now.addingTimeInterval(-60 * 112),
            fullName: "Noah Williams",
            company: "Old Dominion Freight",
            vehicleType: .truck,
            vehicleNumber: "OD-927",
            accessPoint: "South Gate",
            location: "Northstar (Dallas)",
            snapshotCount: 13
        ),

        AccessRecord(
            direction: .in,
            date: .now.addingTimeInterval(-60 * 123),
            fullName: "Aiden Brown",
            company: "J.B. Hunt",
            vehicleType: .tractor,
            vehicleNumber: "JBH-31",
            accessPoint: "Gate 3",
            location: "Northstar (Toronto)",
            snapshotCount: 19
        ),

        AccessRecord(
            direction: .in,
            date: .now.addingTimeInterval(-60 * 134),
            fullName: "Priya Sharma",
            company: "CEVA Logistics",
            vehicleType: .car,
            vehicleNumber: "CV-204",
            accessPoint: "Employee Gate",
            location: "Northstar (Oshawa)",
            snapshotCount: 11
        ),

        AccessRecord(
            direction: .out,
            date: .now.addingTimeInterval(-60 * 145),
            fullName: "Anthony Davis",
            company: "Schneider",
            vehicleType: .truck,
            vehicleNumber: "SCH-61",
            accessPoint: "North Gate",
            location: "Northstar (Dallas)",
            snapshotCount: 14
        ),

        AccessRecord(
            direction: .in,
            date: .now.addingTimeInterval(-60 * 157),
            fullName: "Mohammed Hassan",
            company: "Maersk Logistics",
            vehicleType: .containerTruck,
            vehicleNumber: "MSK-88",
            accessPoint: "Container Gate",
            location: "Northstar (Toronto)",
            snapshotCount: 24
        ),

        AccessRecord(
            direction: .out,
            date: .now.addingTimeInterval(-60 * 170),
            fullName: "Kevin Anderson",
            company: "Sysco",
            vehicleType: .straightTruck,
            vehicleNumber: "SYS-105",
            accessPoint: "Warehouse A",
            location: "Northstar (Oshawa)",
            snapshotCount: 15
        ),

        AccessRecord(
            direction: .in,
            date: .now.addingTimeInterval(-60 * 184),
            fullName: "Jason Lee",
            company: "Canadian Tire",
            vehicleType: .van,
            vehicleNumber: "CT-991",
            accessPoint: "South Gate",
            location: "Northstar (Dallas)",
            snapshotCount: 10
        ),

        AccessRecord(
            direction: .out,
            date: .now.addingTimeInterval(-60 * 198),
            fullName: "Christopher Moore",
            company: "Walmart Logistics",
            vehicleType: .truck,
            vehicleNumber: "WM-384",
            accessPoint: "North Gate",
            location: "Northstar (Toronto)",
            snapshotCount: 18
        ),

        AccessRecord(
            direction: .in,
            date: .now.addingTimeInterval(-60 * 214),
            fullName: "Ryan Campbell",
            company: "PepsiCo",
            vehicleType: .straightTruck,
            vehicleNumber: "PEP-214",
            accessPoint: "Warehouse B",
            location: "Northstar (Oshawa)",
            snapshotCount: 12
        ),

        AccessRecord(
            direction: .out,
            date: .now.addingTimeInterval(-60 * 229),
            fullName: "Matthew Clark",
            company: "Coca-Cola",
            vehicleType: .straightTruck,
            vehicleNumber: "CC-507",
            accessPoint: "Gate 2",
            location: "Northstar (Dallas)",
            snapshotCount: 13
        ),

        AccessRecord(
            direction: .in,
            date: .now.addingTimeInterval(-60 * 244),
            fullName: "Benjamin Walker",
            company: "Home Depot",
            vehicleType: .truck,
            vehicleNumber: "HD-330",
            accessPoint: "West Gate",
            location: "Northstar (Toronto)",
            snapshotCount: 16
        ),

        AccessRecord(
            direction: .out,
            date: .now.addingTimeInterval(-60 * 261),
            fullName: "Nathan Young",
            company: "Lowe's Distribution",
            vehicleType: .bobtailTruck,
            vehicleNumber: "LOW-92",
            accessPoint: "South Gate",
            location: "Northstar (Oshawa)",
            snapshotCount: 14
        ),

        AccessRecord(
            direction: .in,
            date: .now.addingTimeInterval(-60 * 279),
            fullName: "Samuel King",
            company: "Costco Wholesale",
            vehicleType: .truck,
            vehicleNumber: "CST-117",
            accessPoint: "North Gate",
            location: "Northstar (Dallas)",
            snapshotCount: 19
        ),

        AccessRecord(
            direction: .out,
            date: .now.addingTimeInterval(-60 * 298),
            fullName: "Henry Wright",
            company: "Target Distribution",
            vehicleType: .van,
            vehicleNumber: "TGT-404",
            accessPoint: "Employee Gate",
            location: "Northstar (Toronto)",
            snapshotCount: 10
        ),

        AccessRecord(
            direction: .in,
            date: .now.addingTimeInterval(-60 * 318),
            fullName: "Connor Mitchell",
            company: "General Motors",
            vehicleType: .car,
            vehicleNumber: "GM-802",
            accessPoint: "Gate 3",
            location: "Northstar (Oshawa)",
            snapshotCount: 11
        ),

        AccessRecord(
            direction: .out,
            date: .now.addingTimeInterval(-60 * 339),
            fullName: "Adam Scott",
            company: "Toyota Logistics",
            vehicleType: .truck,
            vehicleNumber: "TY-292",
            accessPoint: "Warehouse A",
            location: "Northstar (Dallas)",
            snapshotCount: 17
        ),

        AccessRecord(
            direction: .in,
            date: .now.addingTimeInterval(-60 * 361),
            fullName: "Victor Hernandez",
            company: "Tesla Logistics",
            vehicleType: .containerTruck,
            vehicleNumber: "TSL-47",
            accessPoint: "Container Gate",
            location: "Northstar (Toronto)",
            snapshotCount: 23
        ),

        AccessRecord(
            direction: .out,
            date: .now.addingTimeInterval(-60 * 384),
            fullName: "Jonathan Evans",
            company: "Magna International",
            vehicleType: .pickup,
            vehicleNumber: "MAG-61",
            accessPoint: "North Gate",
            location: "Northstar (Oshawa)",
            snapshotCount: 12
        ),

        AccessRecord(
            direction: .in,
            date: .now.addingTimeInterval(-60 * 408),
            fullName: "Eric Robinson",
            company: "Caterpillar",
            vehicleType: .straightTruck,
            vehicleNumber: "CAT-29",
            accessPoint: "Gate 4",
            location: "Northstar (Dallas)",
            snapshotCount: 15
        ),

        AccessRecord(
            direction: .out,
            date: .now.addingTimeInterval(-60 * 433),
            fullName: "Derek Lewis",
            company: "John Deere",
            vehicleType: .truck,
            vehicleNumber: "JD-508",
            accessPoint: "South Gate",
            location: "Northstar (Toronto)",
            snapshotCount: 14
        ),

        AccessRecord(
            direction: .in,
            date: .now.addingTimeInterval(-60 * 459),
            fullName: "Patrick Hall",
            company: "Cummins",
            vehicleType: .van,
            vehicleNumber: "CM-707",
            accessPoint: "Employee Gate",
            location: "Northstar (Oshawa)",
            snapshotCount: 10
        ),

        AccessRecord(
            direction: .out,
            date: .now.addingTimeInterval(-60 * 486),
            fullName: "Brian Allen",
            company: "CN Rail Logistics",
            vehicleType: .containerTruck,
            vehicleNumber: "CN-184",
            accessPoint: "Container Gate",
            location: "Northstar (Dallas)",
            snapshotCount: 22
        ),

        AccessRecord(
            direction: .in,
            date: .now.addingTimeInterval(-60 * 514),
            fullName: "Sean Baker",
            company: "Purolator",
            vehicleType: .van,
            vehicleNumber: "PUR-231",
            accessPoint: "North Gate",
            location: "Northstar (Toronto)",
            snapshotCount: 13
        ),

        AccessRecord(
            direction: .out,
            date: .now.addingTimeInterval(-60 * 543),
            fullName: "Thomas Nelson",
            company: "Canada Post",
            vehicleType: .straightTruck,
            vehicleNumber: "CP-920",
            accessPoint: "Warehouse B",
            location: "Northstar (Oshawa)",
            snapshotCount: 16
        ),

        AccessRecord(
            direction: .in,
            date: .now.addingTimeInterval(-60 * 573),
            fullName: "Alex Turner",
            company: "Loblaws",
            vehicleType: .truck,
            vehicleNumber: "LOB-58",
            accessPoint: "South Gate",
            location: "Northstar (Dallas)",
            snapshotCount: 18
        ),

        AccessRecord(
            direction: .out,
            date: .now.addingTimeInterval(-60 * 604),
            fullName: "Joshua White",
            company: "Metro Distribution",
            vehicleType: .bobtailTruck,
            vehicleNumber: "MET-402",
            accessPoint: "Gate 2",
            location: "Northstar (Toronto)",
            snapshotCount: 12
        )
    ]
}


// MARK: - Events

struct EventsView: View {

    var body: some View {
        List {

            Section("Needs review") {
                Label(
                    "Unknown visitor at North Gate",
                    systemImage:
                        "exclamationmark.triangle"
                )

                Label(
                    "Plate mismatch at Warehouse A",
                    systemImage: "car"
                )
            }

            Section("Recent activity") {
                Label(
                    "David Okafor entered North Gate",
                    systemImage:
                        "checkmark.circle"
                )

                Label(
                    "Milan Jović exited South Gate",
                    systemImage:
                        "checkmark.circle"
                )
            }
        }
        .birdseyeRefreshable()
        .navigationTitle("Events")
    }
}
