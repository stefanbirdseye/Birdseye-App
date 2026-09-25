import SwiftUI

struct AccessPointsOperationsView: View {
    private let accessPoints: [AccessPointRecord] = (1...100).map {
        AccessPointRecord(id: $0, name: "\(["North Gate", "Warehouse A", "South Gate"][ $0 % 3]) \($0)", type: $0.isMultiple(of: 2) ? "Vehicle gate" : "Pedestrian gate", status: $0.isMultiple(of: 9) ? "Offline" : "Online")
    }

    @State private var searchText = ""
    @State private var isSearchPresented = false
    @State private var showOfflineOnly = false
    @State private var sortOrder: AccessPointSortOrder = .nameAscending
    @State private var page = 0
    @State private var showingEditor = false
    @State private var selectedPoint: AccessPointRecord?
    @AppStorage("isExportListEnabled") private var isExportListEnabled = false

    private var filteredPoints: [AccessPointRecord] {
        let matchingPoints = accessPoints.filter {
            (searchText.isEmpty || $0.name.localizedCaseInsensitiveContains(searchText) || $0.type.localizedCaseInsensitiveContains(searchText))
                && (!showOfflineOnly || $0.status == "Offline")
        }

        switch sortOrder {
        case .nameAscending:
            return matchingPoints.sorted {
                $0.name.localizedStandardCompare($1.name) == .orderedAscending
            }
        case .nameDescending:
            return matchingPoints.sorted {
                $0.name.localizedStandardCompare($1.name) == .orderedDescending
            }
        case .type:
            return matchingPoints.sorted {
                $0.type.localizedStandardCompare($1.type) == .orderedAscending
            }
        case .status:
            return matchingPoints.sorted {
                $0.status.localizedStandardCompare($1.status) == .orderedAscending
            }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            List(filteredPoints.dropFirst(page * 20).prefix(20)) { point in
                Button { selectedPoint = point } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "door.left.hand.open").font(.title3).foregroundStyle(.blue).frame(width: 28)
                        VStack(alignment: .leading, spacing: 5) {
                            Text(point.name).font(.body.weight(.semibold))
                            Text(point.type).font(.subheadline).foregroundStyle(.secondary)
                            HStack(spacing: 8) {
                                Label("All locations", systemImage: "mappin.and.ellipse")
                                Text(point.status).foregroundStyle(point.status == "Offline" ? .orange : .blue)
                            }
                            .font(.caption)
                        }
                        Spacer()
                        Image(systemName: "chevron.right").font(.caption.weight(.semibold)).foregroundStyle(.tertiary)
                    }
                    .padding(.vertical, 5)
                }
                .buttonStyle(.plain)
            }
            .birdseyeRefreshable()
            .listStyle(.plain)
            DirectoryPaginationFooter(page: page, itemCount: filteredPoints.count, pageSize: 20, onPrevious: { page = max(page - 1, 0) }, onNext: { page = min(page + 1, max((filteredPoints.count - 1) / 20, 0)) })
        }
        .navigationTitle("Access points")
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button { isSearchPresented = true } label: { Image(systemName: "magnifyingglass") }
                Menu {
                    Menu("Sort", systemImage: "arrow.up.arrow.down") {
                        ForEach(AccessPointSortOrder.allCases) { order in
                            Button {
                                sortOrder = order
                                page = 0
                            } label: {
                                if sortOrder == order {
                                    Label(order.title, systemImage: "checkmark")
                                } else {
                                    Text(order.title)
                                }
                            }
                        }

                        Divider()

                        Button("Reset to default") {
                            sortOrder = .nameAscending
                            page = 0
                        }
                    }

                    Menu("Filter", systemImage: "line.3.horizontal.decrease.circle") {
                        Toggle("Offline only", isOn: $showOfflineOnly)

                        Divider()

                        Button("Reset to default") {
                            showOfflineOnly = false
                            page = 0
                        }
                    }

                    if showOfflineOnly || sortOrder != .nameAscending {
                        Button("Reset view") {
                            showOfflineOnly = false
                            sortOrder = .nameAscending
                            page = 0
                        }
                    }

                    if isExportListEnabled {
                        Section("Actions") {
                            Button {
                                // Export action
                            } label: {
                                Label("Export list", systemImage: "square.and.arrow.up")
                            }
                        }
                    }
                } label: {
                    Image(systemName: showOfflineOnly || sortOrder != .nameAscending ? "ellipsis.circle.fill" : "ellipsis")
                }
                Button { showingEditor = true } label: { Image(systemName: "plus") }
            }
        }
        .tint(.blue)
        .reportingSearchActivity()
        .searchable(text: $searchText, isPresented: $isSearchPresented, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search access points")
        .onChange(of: searchText) { _, _ in page = 0 }
        .onChange(of: showOfflineOnly) { _, _ in page = 0 }
        .sheet(isPresented: $showingEditor) { AccessPointEditorView() }
        .sheet(item: $selectedPoint) { AccessPointEditorView(point: $0) }
    }
}

private enum AccessPointSortOrder: String, CaseIterable, Identifiable {
    case nameAscending
    case nameDescending
    case type
    case status

    var id: Self { self }

    var title: String {
        switch self {
        case .nameAscending:
            return "Name A-Z"
        case .nameDescending:
            return "Name Z-A"
        case .type:
            return "Type"
        case .status:
            return "Status"
        }
    }
}

private struct AccessPointRecord: Identifiable {
    let id: Int
    let name: String
    let type: String
    let status: String
}

private struct AccessPointEditorView: View {
    @Environment(\.dismiss) private var dismiss
    let point: AccessPointRecord?
    @State private var name: String
    @State private var type: String

    init(point: AccessPointRecord? = nil) {
        self.point = point
        _name = State(initialValue: point?.name ?? "")
        _type = State(initialValue: point?.type ?? "Vehicle gate")
    }

    var body: some View {
        NavigationStack {
            Form {
                TextField("Access point name", text: $name)
                Picker("Type", selection: $type) {
                    Text("Vehicle gate").tag("Vehicle gate")
                    Text("Pedestrian gate").tag("Pedestrian gate")
                }
                LabeledContent("Location", value: "All locations")
                LabeledContent("Status", value: "Online")
            }
            .navigationTitle(point == nil ? "Add access point" : "Edit access point")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button(point == nil ? "Add" : "Save") { dismiss() }.tint(.blue) }
            }
        }
        .presentationDetents([.medium])
    }
}
