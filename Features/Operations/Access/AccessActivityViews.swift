import SwiftUI

// MARK: - Access Records

struct AccessRecordsView: View {
    var body: some View {
        Text("Access Point Records")
            .navigationTitle("Access Point Records")
    }
}

// MARK: - Events

struct EventsView: View {
    var body: some View {
        List {
            Section("Needs review") {
                Label(
                    "Unknown visitor at North Gate",
                    systemImage: "exclamationmark.triangle"
                )

                Label(
                    "Plate mismatch at Warehouse A",
                    systemImage: "car"
                )
            }

            Section("Recent activity") {
                Label(
                    "David Okafor entered North Gate",
                    systemImage: "checkmark.circle"
                )

                Label(
                    "Milan Jović exited South Gate",
                    systemImage: "checkmark.circle"
                )
            }
        }
        .birdseyeRefreshable()
        .navigationTitle("Events")
    }
}
