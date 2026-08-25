import SwiftUI

// MARK: - Authorizations

struct AuthorizationsView: View {

    var body: some View {

        List {

            Section("People") {

                AuthorizationRow(

                    name: "David Okafor",

                    detail: "Driver · Northstar Logistics",

                    status: "Active"

                )

                AuthorizationRow(

                    name: "Olivia Martin",

                    detail: "Site supervisor",

                    status: "Active"

                )

                AuthorizationRow(

                    name: "Elias Petrov",

                    detail: "Contractor",

                    status: "Pending"

                )

            }

            Section("Organizations") {

                AuthorizationRow(

                    name: "Northstar Logistics",

                    detail: "Carrier partner",

                    status: "Full access"

                )

                AuthorizationRow(

                    name: "SafeGate Services",

                    detail: "Security contractor",

                    status: "Review"

                )

            }

        }

        .birdseyeRefreshable()
        .navigationTitle("Authorizations")

    }

}



private struct AuthorizationRow: View {

    let name: String

    let detail: String

    let status: String

    var body: some View {

        LabeledContent {

            Text(status)

                .font(.subheadline)

                .foregroundStyle(

                    status == "Review"

                    ? .orange

                    : .blue

                )

        } label: {

            VStack(

                alignment: .leading,

                spacing: 4

            ) {

                Text(name)

                Text(detail)

                    .font(.subheadline)

                    .foregroundStyle(.secondary)

            }

        }

    }

}
