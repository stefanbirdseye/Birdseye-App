import SwiftUI

struct AuthorizedPeopleView: View {

    private let people = [

        (

            "David Okafor",

            "Driver · Northstar Logistics",

            "Active"

        ),

        (

            "Olivia Martin",

            "Site supervisor",

            "Active"

        ),

        (

            "Elias Petrov",

            "Contractor",

            "Pending"

        )

    ]

    @State private var showingAddPersonSheet = false

    var body: some View {

        AuthorizationDirectoryView(

            title: "Authorized people",

            systemImage: "person.2.fill",

            rows: people,

            onAdd: {

                showingAddPersonSheet = true

            }

        )

        .sheet(

            isPresented: $showingAddPersonSheet

        ) {

            AddPersonAuthorizationView()

        }

    }

}



// MARK: - Authorized Organizations

struct AuthorizedOrganizationsView: View {

    private let organizations = [

        (

            "Northstar Logistics",

            "Carrier partner",

            "Full access"

        ),

        (

            "SafeGate Services",

            "Security contractor",

            "Review"

        ),

        (

            "CargoTrucks",

            "Transportation partner",

            "Active"

        )

    ]

    var body: some View {

        AuthorizationDirectoryView(

            title: "Authorized organizations",

            systemImage: "building.2.fill",

            rows: organizations

        )

    }

}



// MARK: - Authorization Directory

private struct AuthorizationDirectoryView: View {

    let title: String

    let systemImage: String

    let rows: [(String, String, String)]

    var onAdd: (() -> Void)? = nil

    var body: some View {

        List(

            rows,

            id: \.0

        ) { row in

            NavigationLink {

                Text("\(title) details")

                    .navigationTitle(row.0)

            } label: {

                HStack(spacing: 12) {

                    Image(

                        systemName: systemImage

                    )

                    .foregroundStyle(.blue)

                    VStack(

                        alignment: .leading,

                        spacing: 4

                    ) {

                        Text(row.0)

                        Text(row.1)

                            .font(.subheadline)

                            .foregroundStyle(.secondary)

                    }

                    Spacer()

                    Text(row.2)

                        .font(.subheadline)

                        .foregroundStyle(

                            row.2 == "Review"

                            ? .orange

                            : .blue

                        )

                }

            }

        }

        .birdseyeRefreshable()
        .navigationTitle(title)

        .toolbar {

            if let onAdd {

                ToolbarItem(

                    placement: .primaryAction

                ) {

                    Button(

                        "Add",

                        systemImage: "plus",

                        action: onAdd

                    )

                }

            }

        }

    }

}




// MARK: - Existing Person Model

struct ExistingPerson: Identifiable {
    let id = UUID()

    let fullName: String
    let organization: String
    let title: String
    let cdlNumber: String
    let phoneNumber: String
    let emailAddress: String
    let dateOfBirth: Date?
    let idCountry: String
    let dlNumber: String
    let companyCardNumber: String

    var subtitle: String {
        if organization.isEmpty {
            return title
        }

        return "\(title) · \(organization)"
    }
}


// MARK: - Add Person Authorization
import SwiftUI


// MARK: - Access Policy Model

struct AccessPolicy: Equatable {

    var locations = "All locations"
    var accessType = "Default Access"
    var periodAccess = "Ongoing"
    var note = ""

    var limitedTimeAccess = false

    var startDate = Date()
    var endDate: Date?

    var monday = DayAccess(
        title: "Monday",
        enabled: true
    )

    var tuesday = DayAccess(
        title: "Tuesday",
        enabled: true
    )

    var wednesday = DayAccess(
        title: "Wednesday",
        enabled: true
    )

    var thursday = DayAccess(
        title: "Thursday",
        enabled: true
    )

    var friday = DayAccess(
        title: "Friday",
        enabled: true
    )

    var saturday = DayAccess(
        title: "Saturday",
        enabled: false
    )

    var sunday = DayAccess(
        title: "Sunday",
        enabled: false
    )
}


struct DayAccess: Equatable {

    var title: String
    var enabled: Bool

    var startTime: Date = Calendar.current.date(
        bySettingHour: 9,
        minute: 0,
        second: 0,
        of: Date()
    ) ?? Date()

    var endTime: Date = Calendar.current.date(
        bySettingHour: 17,
        minute: 0,
        second: 0,
        of: Date()
    ) ?? Date()
}


