import SwiftUI

// MARK: - Access Records

struct AccessRecordsView: View {

    private let records = [

        (

            "David Okafor",

            "Northstar Logistics",

            "North Gate",

            "08:42",

            "IN"

        ),

        (

            "Olivia Martin",

            "CargoTrucks",

            "Warehouse A",

            "08:18",

            "IN"

        ),

        (

            "Milan Jović",

            "Bison Transport",

            "South Gate",

            "07:56",

            "OUT"

        ),

        (

            "Unknown visitor",

            "Unknown",

            "North Gate",

            "07:31",

            "Review"

        )

    ]

    @State private var searchText = ""

    private var filteredRecords: [(String, String, String, String, String)] {
        let normalizedSearch = searchText
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()

        guard !normalizedSearch.isEmpty else {
            return records
        }

        return records.filter { record in
            record.0.lowercased().contains(normalizedSearch)
                || record.1.lowercased().contains(normalizedSearch)
                || record.2.lowercased().contains(normalizedSearch)
                || record.4.lowercased().contains(normalizedSearch)
        }
    }

    var body: some View {

        List(filteredRecords, id: \.0) { record in

            NavigationLink {

                Text("Access record details")

                    .navigationTitle(record.0)

            } label: {

                LabeledContent {

                    Text(record.3)

                        .foregroundStyle(.secondary)

                } label: {

                    VStack(

                        alignment: .leading,

                        spacing: 4

                    ) {

                        Text(record.0)

                        Text("\(record.1) · \(record.2)")

                            .font(.subheadline)

                            .foregroundStyle(.secondary)

                        Text(record.4)

                            .font(.caption.weight(.semibold))

                            .foregroundStyle(

                                record.4 == "Review"

                                ? .orange

                                : .blue

                            )

                    }

                }

            }

        }

        .birdseyeRefreshable()
        .navigationTitle("Access Records")

        .reportingSearchActivity()

        .searchable(

            text: $searchText,

            prompt: "Search records"

        )

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
