import Foundation

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

struct AccessPolicy: Equatable {
    var locations = "All locations"
    var accessType = "Default Access"
    var periodAccess = "Ongoing"
    var note = ""
    var limitedTimeAccess = false
    var startDate = Date()
    var endDate: Date?
    var monday = DayAccess(title: "Monday", enabled: true)
    var tuesday = DayAccess(title: "Tuesday", enabled: true)
    var wednesday = DayAccess(title: "Wednesday", enabled: true)
    var thursday = DayAccess(title: "Thursday", enabled: true)
    var friday = DayAccess(title: "Friday", enabled: true)
    var saturday = DayAccess(title: "Saturday", enabled: false)
    var sunday = DayAccess(title: "Sunday", enabled: false)
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