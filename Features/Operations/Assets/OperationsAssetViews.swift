import SwiftUI

// MARK: - Equipment

struct EquipmentView: View {

    var body: some View {

        List {

            Section("On site") {

                Label(

                    "Unit 204 · Truck",

                    systemImage: "truck.box"

                )

                Label(

                    "Forklift 07",

                    systemImage: "wrench.and.screwdriver"

                )

                Label(

                    "Unit 118 · Truck",

                    systemImage: "truck.box"

                )

            }

            Section("Access") {

                Text("46 authorized equipment records")

                    .foregroundStyle(.secondary)

            }

        }

        .navigationTitle("Equipment")

    }

}



// MARK: - Inventory

struct InventoryView: View {

    var body: some View {

        List {

            InventoryRow(

                title: "Trucks",

                value: "15"

            )

            InventoryRow(

                title: "Trailers",

                value: "23"

            )

            InventoryRow(

                title: "Loaded trailers",

                value: "472"

            )

            InventoryRow(

                title: "Empty trailers",

                value: "408"

            )

            InventoryRow(

                title: "Total inventory",

                value: "765"

            )

        }

        .navigationTitle("Inventory")

    }

}



private struct InventoryRow: View {

    let title: String

    let value: String

    var body: some View {

        LabeledContent(

            title,

            value: value

        )

    }

}



// MARK: - Appointments

struct AppointmentsView: View {

    private let appointments = [

        (

            "08:30",

            "Honda Dealership",

            "Gurpreet Singh",

            "Main gate"

        ),

        (

            "10:15",

            "Bison",

            "Johnathan Driver",

            "Carrier gate"

        ),

        (

            "14:20",

            "Canada Cartage",

            "William Robertson",

            "Main gate"

        ),

        (

            "17:00",

            "Carmel Transportation",

            "Virginia Bain",

            "Carrier gate"

        )

    ]

    var body: some View {

        List(

            appointments,

            id: \.0

        ) { appointment in

            NavigationLink {

                Text("Appointment details")

                    .navigationTitle(appointment.1)

            } label: {

                LabeledContent {

                    Text(appointment.0)

                        .foregroundStyle(.secondary)

                } label: {

                    VStack(

                        alignment: .leading,

                        spacing: 4

                    ) {

                        Text(appointment.1)

                        Text(

                            "\(appointment.2) · \(appointment.3)"

                        )

                        .font(.subheadline)

                        .foregroundStyle(.secondary)

                    }

                }

            }

        }

        .navigationTitle("Appointments")

        .toolbar {

            ToolbarItem(placement: .primaryAction) {

                Button(

                    "Add",

                    systemImage: "plus"

                ) { }

            }

        }

    }

}




