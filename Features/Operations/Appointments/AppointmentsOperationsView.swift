import SwiftUI

struct AppointmentsOperationsView: View {
    private let appointments: [AppointmentRecord] = (1...100).map {
        AppointmentRecord(id: $0, time: String(format: "%02d:%02d", 8 + ($0 % 10), ($0 * 7) % 60), company: ["Honda Dealership", "Bison", "Canada Cartage"][ $0 % 3], visitor: "Driver \($0)", gate: $0.isMultiple(of: 2) ? "Main gate" : "Carrier gate")
    }

    @State private var searchText = ""
    @State private var isSearchPresented = false
    @State private var showUpcomingOnly = false
    @State private var page = 0
    @State private var showingEditor = false
    @State private var selectedAppointment: AppointmentRecord?

    private var filteredAppointments: [AppointmentRecord] {
        appointments.filter {
            (searchText.isEmpty || $0.company.localizedCaseInsensitiveContains(searchText) || $0.visitor.localizedCaseInsensitiveContains(searchText))
                && (!showUpcomingOnly || $0.id <= 50)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            List(filteredAppointments.dropFirst(page * 20).prefix(20)) { appointment in
                Button { selectedAppointment = appointment } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "calendar.badge.clock").font(.title3).foregroundStyle(.blue).frame(width: 28)
                        VStack(alignment: .leading, spacing: 5) {
                            Text(appointment.company).font(.body.weight(.semibold))
                            Text("\(appointment.visitor) · \(appointment.gate)").font(.subheadline).foregroundStyle(.secondary)
                            Label("All locations", systemImage: "mappin.and.ellipse").font(.caption).foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text(appointment.time).font(.subheadline.weight(.medium)).foregroundStyle(.secondary)
                        Image(systemName: "chevron.right").font(.caption.weight(.semibold)).foregroundStyle(.tertiary)
                    }
                    .padding(.vertical, 5)
                }
                .buttonStyle(.plain)
            }
            .birdseyeRefreshable()
            .listStyle(.plain)
            DirectoryPaginationFooter(page: page, itemCount: filteredAppointments.count, pageSize: 20, onPrevious: { page = max(page - 1, 0) }, onNext: { page = min(page + 1, max((filteredAppointments.count - 1) / 20, 0)) })
        }
        .navigationTitle("Appointments")
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button { isSearchPresented = true } label: { Image(systemName: "magnifyingglass") }
                Menu {
                    Toggle("Upcoming only", isOn: $showUpcomingOnly)
                    Button("Reset filters") { searchText = ""; showUpcomingOnly = false; page = 0 }
                } label: { Image(systemName: "line.3.horizontal.decrease.circle") }
                Menu { Button("Sort by time") { }; Button("Export list") { } } label: { Image(systemName: "ellipsis") }
                Button { showingEditor = true } label: { Image(systemName: "plus") }
            }
        }
        .tint(.blue)
        .reportingSearchActivity()
        .searchable(text: $searchText, isPresented: $isSearchPresented, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search appointments")
        .onChange(of: searchText) { _, _ in page = 0 }
        .onChange(of: showUpcomingOnly) { _, _ in page = 0 }
        .sheet(isPresented: $showingEditor) { AppointmentEditorView() }
        .sheet(item: $selectedAppointment) { AppointmentEditorView(appointment: $0) }
    }
}

private struct AppointmentRecord: Identifiable {
    let id: Int
    let time: String
    let company: String
    let visitor: String
    let gate: String
}

private struct AppointmentEditorView: View {
    @Environment(\.dismiss) private var dismiss
    let appointment: AppointmentRecord?
    @State private var company: String
    @State private var visitor: String

    init(appointment: AppointmentRecord? = nil) {
        self.appointment = appointment
        _company = State(initialValue: appointment?.company ?? "")
        _visitor = State(initialValue: appointment?.visitor ?? "")
    }

    var body: some View {
        NavigationStack {
            Form {
                TextField("Company", text: $company)
                TextField("Visitor", text: $visitor)
                LabeledContent("Location", value: "All locations")
                DatePicker("Time", selection: .constant(Date()), displayedComponents: [.date, .hourAndMinute])
            }
            .navigationTitle(appointment == nil ? "Add appointment" : "Edit appointment")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button(appointment == nil ? "Add" : "Save") { dismiss() }.tint(.blue) }
            }
        }
        .presentationDetents([.medium])
    }
}
