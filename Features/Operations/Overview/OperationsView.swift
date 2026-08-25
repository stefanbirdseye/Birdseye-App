import SwiftUI

struct OperationsView: View {

    var body: some View {

        NavigationStack {

            List {

                Section("Access activity") {

                    NavigationLink {

                        AccessPointsOperationsView()

                    } label: {

                        Label(

                            "Access Point Records",

                            systemImage: "door.left.hand.open"

                        )

                    }

                    NavigationLink {

                        EventsView()

                    } label: {

                        Label(

                            "Events needing review",

                            systemImage: "exclamationmark.triangle"

                        )

                    }

                }

                Section("Authorizations") {

                    NavigationLink {

                        AuthorizedPeopleOperationsView()

                    } label: {

                        Label(

                            "Authorized people",

                            systemImage: "person.fill"

                        )

                    }

                    NavigationLink {

                        AuthorizedOrganizationsOperationsView()

                    } label: {

                        Label(

                            "Authorized organizations",

                            systemImage: "building.2.fill"

                        )

                    }

                    NavigationLink {

                        EquipmentOperationsView()

                    } label: {

                        Label(

                            "Equipment",

                            systemImage: "truck.box"

                        )

                    }

                }

                Section("Planning") {

                    NavigationLink {

                        AppointmentsOperationsView()

                    } label: {

                        Label(

                            "Appointments",

                            systemImage: "calendar"

                        )

                    }

                    NavigationLink {

                        InventoryOperationsView()

                    } label: {

                        Label(

                            "Inventory",

                            systemImage: "shippingbox"

                        )

                    }

                }

            }

            .birdseyeRefreshable()
            .navigationTitle("Operations")

            .toolbar {
                GlobalWorkspaceToolbar()

                ToolbarItem(placement: .primaryAction) {

                    Button("New", systemImage: "plus") { }

                }

            }

        }

    }

}
