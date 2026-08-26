import SwiftUI
import PhotosUI
import UniformTypeIdentifiers
import UIKit

struct AuthorizedPeopleOperationsView: View {
  @Environment(SnackbarCenter.self) private var snackbarCenter

  @State private var people: [AuthorizedPeopleDirectoryEntry] = (1...100).map { index in
    let names = [
      "David Okafor",
      "Olivia Martin",
      "Elias Petrov",
      "Milan Jović",
    ]
    let organizations = [
      "Northstar Logistics",
      "CargoTrucks",
      "Bison Transport",
    ]
    let titles = [
      "Driver",
      "Site supervisor",
      "Contractor",
    ]
    let locationSets = [
      ["All locations"],
      ["Northstar (Oshawa)"],
      ["Northstar (Dallas)"],
      ["Northstar (Toronto)"],
      ["Northstar (Oshawa)", "Northstar (Dallas)"],
      ["Northstar (Oshawa)", "Northstar (Toronto)"],
    ]
    // Most people use Default Access.
    // Banned appears occasionally.
    // Priority and Specialized are intentionally rare.
    let accessType: String
    if index.isMultiple(of: 19) {
      accessType = "Specialized Access"
    } else if index.isMultiple(of: 13) {
      accessType = "Priority Access"
    } else if index.isMultiple(of: 7) {
      accessType = "Banned Access"
    } else {
      accessType = "Default Access"
    }
    // Keep most authorizations ongoing.
    let periodAccess =
      index.isMultiple(of: 8)
      ? "One-time"
      : "Ongoing"
    // Notes should feel exceptional instead of appearing everywhere.
    let hasNote =
      accessType == "Banned Access"
      || index.isMultiple(of: 11)
    // Limited time is mostly useful for exceptional access.
    let isLimitedTime =
      accessType == "Priority Access"
      || accessType == "Specialized Access"
      || index.isMultiple(of: 17)
    return AuthorizedPeopleDirectoryEntry(
      person: ExistingPerson(
        fullName: names[index % names.count] + " \(index)",
        organization: organizations[index % organizations.count],
        title: titles[index % titles.count],
        cdlNumber: "",
        phoneNumber: "",
        emailAddress: "",
        dateOfBirth: nil,
        idCountry: "Canada",
        dlNumber: "",
        companyCardNumber: ""
      ),
      locations: locationSets[index % locationSets.count],
      accessType: accessType,
      periodAccess: periodAccess,
      hasNote: hasNote,
      isLimitedTime: isLimitedTime,
      isActive: !index.isMultiple(of: 9),
      addedOrder: index,
      isNewThisWeek: index > 97
    )
  }
  private let locations = [
    "All locations",
    "Northstar (Oshawa)",
    "Northstar (Dallas)",
    "Northstar (Toronto)",
  ]
  @State private var selectedLocationIndex = 1
  @State private var searchText = ""
  @State private var isSearchPresented = false
  @State private var peopleFilter: PeopleFilter = .all
  @State private var page = 0
  @State private var showingAdd = false
  @State private var selectedPerson: ExistingPerson?
  @State private var sortOrder: PeopleSortOrder = .recentlyAdded
  private let pageSize = 20
  private var cleanSearch: String {
    searchText.trimmingCharacters(
      in: .whitespacesAndNewlines
    )
  }
  private var filteredPeople: [AuthorizedPeopleDirectoryEntry] {
    let matchingPeople = people.filter { entry in
      let person = entry.person
      let matchesSearch =
        cleanSearch.isEmpty
        || person.fullName.localizedCaseInsensitiveContains(cleanSearch)
        || person.organization.localizedCaseInsensitiveContains(cleanSearch)
        || person.title.localizedCaseInsensitiveContains(cleanSearch)
        || entry.locations
          .joined(separator: " ")
          .localizedCaseInsensitiveContains(cleanSearch)
        || entry.accessType
          .localizedCaseInsensitiveContains(cleanSearch)
      let selectedLocation = locations[selectedLocationIndex]
      let matchesLocation =
        selectedLocation == "All locations"
        || entry.locations.contains(selectedLocation)
        || entry.locations.contains("All locations")
      let matchesFilter: Bool
      switch peopleFilter {
      case .all:
        matchesFilter = true
      case .activeOnly:
        matchesFilter = entry.isActive
      case .inactiveOnly:
        matchesFilter = !entry.isActive
      case .bannedOnly:
        matchesFilter = entry.accessType == "Banned Access"
      case .defaultOnly:
        matchesFilter = entry.accessType == "Default Access"
      case .priorityOnly:
        matchesFilter = entry.accessType == "Priority Access"
      case .specializedOnly:
        matchesFilter = entry.accessType == "Specialized Access"
      case .oneTimeOnly:
        matchesFilter = entry.periodAccess == "One-time"
      case .ongoingOnly:
        matchesFilter = entry.periodAccess == "Ongoing"
      case .newThisWeek:
        matchesFilter = entry.isNewThisWeek
      case .hasNotes:
        matchesFilter = entry.hasNote
      }
      return matchesSearch
        && matchesLocation
        && matchesFilter
    }
    switch sortOrder {
    case .recentlyAdded:
      return matchingPeople.sorted {
        $0.addedOrder > $1.addedOrder
      }
    case .oldestAdded:
      return matchingPeople.sorted {
        $0.addedOrder < $1.addedOrder
      }
    case .nameAscending:
      return matchingPeople.sorted {
        $0.person.fullName.localizedStandardCompare(
          $1.person.fullName
        ) == .orderedAscending
      }
    case .nameDescending:
      return matchingPeople.sorted {
        $0.person.fullName.localizedStandardCompare(
          $1.person.fullName
        ) == .orderedDescending
      }
    case .organization:
      return matchingPeople.sorted {
        $0.person.organization.localizedStandardCompare(
          $1.person.organization
        ) == .orderedAscending
      }
    case .location:
      return matchingPeople.sorted {
        $0.locations.joined(separator: " ")
          .localizedStandardCompare(
            $1.locations.joined(separator: " ")
          ) == .orderedAscending
      }
    case .accessType:
      return matchingPeople.sorted {
        $0.accessType.localizedStandardCompare(
          $1.accessType
        ) == .orderedAscending
      }
    case .status:
      return matchingPeople.sorted {
        if $0.isActive == $1.isActive {
          return $0.person.fullName.localizedStandardCompare(
            $1.person.fullName
          ) == .orderedAscending
        }
        return $0.isActive && !$1.isActive
      }
    }
  }
  private var pagePeople: [AuthorizedPeopleDirectoryEntry] {
    let start = page * pageSize
    guard start < filteredPeople.count else {
      return []
    }
    return Array(
      filteredPeople
        .dropFirst(start)
        .prefix(pageSize)
    )
  }
  var body: some View {
    VStack(spacing: 0) {
      AuthorizedPeopleResultsContent(
        people: pagePeople,
        resultCount: filteredPeople.count,
        locations: locations,
        selectedLocationIndex: $selectedLocationIndex,
        page: page,
        pageSize: pageSize,
        onSelect: { entry in
          selectedPerson = entry.person
        },
        onPrevious: {
          page = max(page - 1, 0)
        },
        onNext: {
          let maxPage = max(
            (filteredPeople.count - 1) / pageSize,
            0
          )
          page = min(page + 1, maxPage)
        }
      )
    }
    .navigationTitle("People")
    .navigationBarTitleDisplayMode(.inline)
    .reportingPageContext("People")
    .toolbar {
      ToolbarItemGroup(
        placement: .topBarTrailing
      ) {
        Button {
          HapticFeedback.lightImpact()
          isSearchPresented = true
        } label: {
          Image(systemName: "magnifyingglass")
        }
        .tint(.primary)
        .accessibilityLabel("Search")
        Menu {
          Section("Sort") {
            ForEach(PeopleSortOrder.allCases) { order in
              Button {
                sortOrder = order
                page = 0
              } label: {
                if sortOrder == order {
                  Label(
                    order.title,
                    systemImage: "checkmark"
                  )
                } else {
                  Label(
                    order.title,
                    systemImage: order.systemImage
                  )
                }
              }
            }
          }
          Section("Filter") {
            ForEach(PeopleFilter.allCases) { filter in
              Button {
                peopleFilter = filter
                page = 0
              } label: {
                if peopleFilter == filter {
                  Label(
                    filter.title,
                    systemImage: "checkmark"
                  )
                } else {
                  Label(
                    filter.title,
                    systemImage: filter.systemImage
                  )
                }
              }
            }
          }
          Section("Actions") {
            Button {
              // Export action
            } label: {
              Label(
                "Export list",
                systemImage: "square.and.arrow.up"
              )
            }
            if peopleFilter != .all
              || !searchText.isEmpty
              || selectedLocationIndex != 1
              || sortOrder != .recentlyAdded
            {
              Button {
                peopleFilter = .all
                searchText = ""
                selectedLocationIndex = 1
                sortOrder = .recentlyAdded
                page = 0
              } label: {
                Label(
                  "Reset view",
                  systemImage: "arrow.counterclockwise"
                )
              }
            }
          }
        } label: {
          Image(systemName: "ellipsis")
        }
        .tint(.primary)
        .accessibilityLabel("Sort, filter, and more")
        Button {
          HapticFeedback.lightImpact()
          showingAdd = true
        } label: {
          Image(systemName: "plus")
            .font(.body.weight(.semibold))
        }
        .tint(.blue)
        .accessibilityLabel("Add person")
      }
    }
    .conditionalSearch(
      isPresented: $isSearchPresented,
      text: $searchText,
      prompt: "Search people"
    )
    .onChange(of: searchText) { _, _ in
      page = 0
    }
    .onChange(of: peopleFilter) { _, _ in
      page = 0
    }
    .onChange(of: selectedLocationIndex) { _, _ in
      page = 0
    }
    .onChange(of: sortOrder) { _, _ in
      page = 0
    }
    .sheet(isPresented: $showingAdd) {
      AddPersonAuthorizationView { person, policy in
        let entry = AuthorizedPeopleDirectoryEntry(
          person: person,
          locations: policy.locations == "All locations"
            ? ["All locations"]
            : policy.locations.split(separator: ",").map {
                $0.trimmingCharacters(in: .whitespaces)
              },
          accessType: policy.accessType,
          periodAccess: policy.periodAccess,
          hasNote: !policy.note.trimmingCharacters(
            in: .whitespacesAndNewlines
          ).isEmpty,
          isLimitedTime: policy.limitedTimeAccess,
          isActive: true,
          addedOrder: (people.map(\.addedOrder).max() ?? 0) + 1,
          isNewThisWeek: true
        )

        people.insert(entry, at: 0)
        snackbarCenter.show(
          "\(person.fullName) is saved to \(policy.locations.lowercased()).",
          onOpen: {
            selectedPerson = person
          },
          onUndo: {
            people.removeAll { $0.person.id == person.id }
            if selectedPerson?.id == person.id {
              selectedPerson = nil
            }
          }
        )
      }
    }
    .sheet(item: $selectedPerson) { person in
      EditPersonAuthorizationView(
        person: person,
        onSave: {
          snackbarCenter.show("Authorization updated for \(person.fullName).")
        }
      )
    }
  }
}
// MARK: - Sorting
private enum PeopleSortOrder: String, CaseIterable, Identifiable {
  case recentlyAdded
  case oldestAdded
  case nameAscending
  case nameDescending
  case organization
  case location
  case accessType
  case status
  var id: Self { self }
  var title: String {
    switch self {
    case .recentlyAdded:
      return "Recently added"
    case .oldestAdded:
      return "Oldest added"
    case .nameAscending:
      return "Name A-Z"
    case .nameDescending:
      return "Name Z-A"
    case .organization:
      return "Organization"
    case .location:
      return "Location"
    case .accessType:
      return "Access type"
    case .status:
      return "Status"
    }
  }
  var systemImage: String {
    switch self {
    case .recentlyAdded:
      return "clock.arrow.circlepath"
    case .oldestAdded:
      return "clock"
    case .nameAscending:
      return "textformat.abc"
    case .nameDescending:
      return "textformat.abc"
    case .organization:
      return "building.2"
    case .location:
      return "mappin.and.ellipse"
    case .accessType:
      return "key"
    case .status:
      return "checkmark.circle"
    }
  }
}
// MARK: - Filtering
private enum PeopleFilter: String, CaseIterable, Identifiable {
  case all
  case activeOnly
  case inactiveOnly
  case bannedOnly
  case defaultOnly
  case priorityOnly
  case specializedOnly
  case oneTimeOnly
  case ongoingOnly
  case newThisWeek
  case hasNotes
  var id: Self { self }
  var title: String {
    switch self {
    case .all:
      return "All people"
    case .activeOnly:
      return "Active only"
    case .inactiveOnly:
      return "Inactive only"
    case .bannedOnly:
      return "Banned only"
    case .defaultOnly:
      return "Default access only"
    case .priorityOnly:
      return "Priority access only"
    case .specializedOnly:
      return "Specialized access only"
    case .oneTimeOnly:
      return "One-time access"
    case .ongoingOnly:
      return "Ongoing access"
    case .newThisWeek:
      return "New this week"
    case .hasNotes:
      return "Has notes"
    }
  }
  var systemImage: String {
    switch self {
    case .all:
      return "person.2"
    case .activeOnly:
      return "checkmark.circle"
    case .inactiveOnly:
      return "pause.circle"
    case .bannedOnly:
      return "nosign"
    case .defaultOnly:
      return "infinity"
    case .priorityOnly:
      return "star"
    case .specializedOnly:
      return "slider.horizontal.3"
    case .oneTimeOnly:
      return "clock"
    case .ongoingOnly:
      return "repeat"
    case .newThisWeek:
      return "sparkles"
    case .hasNotes:
      return "note.text"
    }
  }
}
// MARK: - Directory Entry
private struct AuthorizedPeopleDirectoryEntry: Identifiable {
  let person: ExistingPerson
  let locations: [String]
  let accessType: String
  let periodAccess: String
  let hasNote: Bool
  let isLimitedTime: Bool
  let isActive: Bool
  let addedOrder: Int
  let isNewThisWeek: Bool
  var id: UUID {
    person.id
  }
}
// MARK: - Results
private struct AuthorizedPeopleResultsContent: View {
  let people: [AuthorizedPeopleDirectoryEntry]
  let resultCount: Int
  let locations: [String]
  @Binding var selectedLocationIndex: Int
  let page: Int
  let pageSize: Int
  let onSelect: (AuthorizedPeopleDirectoryEntry) -> Void
  let onPrevious: () -> Void
  let onNext: () -> Void
  var body: some View {
    ScrollView {
      LazyVStack(spacing: 18) {
        HStack(spacing: 12) {
          Text("\(resultCount) results")
            .font(.subheadline.weight(.medium))
            .foregroundStyle(.secondary)
            .monospacedDigit()
          Spacer()
          DirectoryLocationSwitcher(
            locations: locations,
            selectedIndex: $selectedLocationIndex
          )
        }
        .padding(.horizontal, 16)
        if people.isEmpty {
          ContentUnavailableView(
            "No people found",
            systemImage:
              "person.crop.circle.badge.questionmark",
            description: Text(
              "Try changing your search or filters."
            )
          )
          .padding(.top, 54)
          .padding(.horizontal, 24)
        } else {
          AuthorizedPeopleCard(
            people: people,
            onSelect: onSelect
          )
          DirectoryPaginationFooter(
            page: page,
            itemCount: resultCount,
            pageSize: pageSize,
            onPrevious: onPrevious,
            onNext: onNext
          )
          .padding(.horizontal, 16)
        }
      }
      .padding(.top, 16)
      .padding(.bottom, 110)
    }
    .background(
      Color(.systemGroupedBackground)
    )
  }
}
// MARK: - People Card
private struct AuthorizedPeopleCard: View {
  let people: [AuthorizedPeopleDirectoryEntry]
  let onSelect: (AuthorizedPeopleDirectoryEntry) -> Void
  var body: some View {
    VStack(spacing: 0) {
      ForEach(
        people.enumerated(),
        id: \.element.id
      ) { index, entry in
        Button {
          onSelect(entry)
        } label: {
          AuthorizedPersonRow(
            entry: entry
          )
        }
        .buttonStyle(.plain)
        if index < people.count - 1 {
          Divider()
            .padding(.leading, 62)
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
    .padding(.horizontal, 16)
  }
}
// MARK: - Conditional Search
extension View {
  @ViewBuilder
  fileprivate func conditionalSearch(
    isPresented: Binding<Bool>,
    text: Binding<String>,
    prompt: String
  ) -> some View {
    if isPresented.wrappedValue {
      self
        .reportingSearchActivity()
        .searchable(
          text: text,
          isPresented: isPresented,
          placement:
            .navigationBarDrawer(
              displayMode: .always
            ),
          prompt: prompt
        )
    } else {
      self
    }
  }
}
// MARK: - Location Switcher
private struct DirectoryLocationSwitcher: View {
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
            locations.firstIndex(
              of: location
            ) ?? 0
        } label: {
          if location == locations[selectedIndex] {
            Label(
              location,
              systemImage: "checkmark"
            )
          } else {
            Text(location)
          }
        }
      }
    } label: {
      HStack(spacing: 5) {
        Text(locations[selectedIndex])
          .lineLimit(1)
        Image(systemName: "chevron.up.chevron.down")
          .font(.caption2.weight(.semibold))
      }
      .font(.subheadline.weight(.medium))
      .foregroundStyle(.secondary)
      .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
    .accessibilityLabel("Choose location")
    .accessibilityValue(
      locations[selectedIndex]
    )
  }
}
// MARK: - Person Row
private struct AuthorizedPersonRow: View {
  let entry: AuthorizedPeopleDirectoryEntry

  private var accessColor: Color {
    switch entry.accessType {
    case "Banned Access":
      return .red
    case "Priority Access":
      return .blue
    case "Specialized Access":
      return .orange
    default:
      return .secondary
    }
  }

  var body: some View {
    HStack(
      alignment: .top,
      spacing: 12
    ) {
      Image(systemName: "person.fill")
        .font(.subheadline.weight(.semibold))
        .foregroundStyle(accessColor)
        .frame(
          width: 34,
          height: 34
        )
        .background(
          accessColor.opacity(0.10),
          in: RoundedRectangle(
            cornerRadius: 10,
            style: .continuous
          )
        )

      VStack(
        alignment: .leading,
        spacing: 6
      ) {
        Text(entry.person.fullName)
          .font(.body.weight(.semibold))
          .foregroundStyle(.primary)
          .lineLimit(1)

        ViewThatFits(in: .horizontal) {
          wideMetadataRow
            .fixedSize(
              horizontal: true,
              vertical: false
            )

          compactMetadataRows
        }
      }
      .frame(
        maxWidth: .infinity,
        alignment: .leading
      )

      if entry.isNewThisWeek {
        Text("New")
          .font(.caption2.weight(.bold))
          .foregroundStyle(.blue)
          .textCase(.uppercase)
          .padding(.horizontal, 8)
          .padding(.vertical, 5)
          .background(
            .blue.opacity(0.14),
            in: Capsule()
          )
          .fixedSize()
          .accessibilityLabel("New this week")
      }
    }
    .padding(.horizontal, 16)
    .padding(.vertical, 14)
    .contentShape(Rectangle())
  }

  // On wider windows everything stays on one metadata line:
  // title · organization · location · access
  private var wideMetadataRow: some View {
    HStack(spacing: 6) {
      Text(entry.person.title)

      metadataSeparator

      Text(entry.person.organization)

      metadataSeparator

      LocationAccessLabel(
        locations: entry.locations
      )

      DirectoryAccessTypeChip(
        accessType: entry.accessType,
        periodAccess: entry.periodAccess,
        hasNote: entry.hasNote,
        isLimitedTime: entry.isLimitedTime
      )
    }
    .font(.subheadline)
    .foregroundStyle(.secondary)
    .lineLimit(1)
  }

  // On compact widths title/organization use line 2.
  // Location + access use the next line, and split into two
  // separate lines only when they cannot fit beside each other.
  private var compactMetadataRows: some View {
    VStack(
      alignment: .leading,
      spacing: 6
    ) {
      HStack(spacing: 4) {
        Text(entry.person.title)

        metadataSeparator

        Text(entry.person.organization)
      }
      .font(.subheadline)
      .foregroundStyle(.secondary)
      .lineLimit(1)

      compactLocationAndAccess
    }
  }

  private var compactLocationAndAccess: some View {
    ViewThatFits(in: .horizontal) {
      HStack(spacing: 8) {
        LocationAccessLabel(
          locations: entry.locations
        )

        DirectoryAccessTypeChip(
          accessType: entry.accessType,
          periodAccess: entry.periodAccess,
          hasNote: entry.hasNote,
          isLimitedTime: entry.isLimitedTime
        )
      }
      .fixedSize(
        horizontal: true,
        vertical: false
      )

      VStack(
        alignment: .leading,
        spacing: 5
      ) {
        LocationAccessLabel(
          locations: entry.locations
        )

        DirectoryAccessTypeChip(
          accessType: entry.accessType,
          periodAccess: entry.periodAccess,
          hasNote: entry.hasNote,
          isLimitedTime: entry.isLimitedTime
        )
      }
    }
  }

  private var metadataSeparator: some View {
    Text("·")
      .foregroundStyle(.tertiary)
  }
}


// MARK: - Location Label

private struct LocationAccessLabel: View {
  let locations: [String]

  private var label: String {
    locations.joined(
      separator: " · "
    )
  }

  var body: some View {
    HStack(spacing: 5) {
      Image(systemName: "mappin.and.ellipse")
        .font(.subheadline.weight(.medium))

      Text(label)
        .font(.caption.weight(.medium))
        .lineLimit(1)
        .truncationMode(.tail)
    }
    .foregroundStyle(.secondary)
    .accessibilityLabel("Authorized locations")
    .accessibilityValue(label)
  }
}


// MARK: - Directory Access Chip

private struct DirectoryAccessTypeChip: View {
  let accessType: String
  let periodAccess: String
  let hasNote: Bool
  let isLimitedTime: Bool

  private var tint: Color {
    switch accessType {
    case "Banned Access":
      return .red
    case "Priority Access":
      return .blue
    case "Specialized Access":
      return .orange
    default:
      return .secondary
    }
  }

  var body: some View {
    HStack(spacing: 5) {
      Text(accessType)
        .font(.caption2.weight(.semibold))

      if periodAccess == "One-time" {
        Image(systemName: "1.circle.fill")
          .font(.caption.weight(.semibold))
      }

      if hasNote {
        Image(systemName: "note.text")
          .font(.caption.weight(.semibold))
      }

      if isLimitedTime {
        Image(systemName: "clock.fill")
          .font(.caption.weight(.semibold))
      }
    }
    .foregroundStyle(tint)
    .padding(.horizontal, 7)
    .padding(.vertical, 3)
    .overlay {
      Capsule()
        .strokeBorder(
          tint.opacity(0.32),
          lineWidth: 0.75
        )
    }
    .fixedSize(
      horizontal: true,
      vertical: false
    )
    .accessibilityElement(children: .combine)
  }
}


// MARK: - Pagination
struct DirectoryPaginationFooter: View {
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
      .foregroundStyle(.secondary)
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
        .foregroundStyle(.primary)
        .monospacedDigit()
        .frame(minWidth: 58)
        paginationButton(
          systemImage:
            "chevron.right",
          disabled:
            page >= pageCount - 1,
          action:
            onNext
        )
      }
    }
    .padding(.horizontal, 2)
  }
  private func paginationButton(
    systemImage: String,
    disabled: Bool,
    action: @escaping () -> Void
  ) -> some View {
    Button(action: action) {
      Image(
        systemName: systemImage
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
      .contentShape(Circle())
    }
    .buttonStyle(.glass)
    .buttonBorderShape(.circle)
    .tint(.primary)
    .disabled(disabled)
    .opacity(
      disabled ? 0.35 : 1
    )
  }
}


struct AddPersonAuthorizationView: View {

    var onSave: (ExistingPerson, AccessPolicy) -> Void = { _, _ in }

    private enum QuickScanState {
        case empty
        case scanning
        case success
    }

    @Environment(\.dismiss)

    private var dismiss

    @State private var fullName = ""

    @State private var organization = ""

    @State private var cdlNumber = ""

    @State private var title = "Driver"

    @State private var phoneNumber = ""

    @State private var emailAddress = ""

    @State private var dateOfBirth: Date?

    @State private var idCountry = "Canada"

    @State private var dlNumber = ""

    @State private var companyCardNumber = ""

    @State private var accessPolicy = AccessPolicy()

    @State private var moreDetailsExpanded = false

    @State private var showingDatePicker = false

    @State private var showingAccessPolicy = false

    @State private var selectedExistingPerson: ExistingPerson?

    @State private var quickScanState: QuickScanState = .empty
    @State private var scannedImage: UIImage?
    @State private var showingScanOptions = false
    @State private var showingCamera = false
    @State private var showingPhotos = false
    @State private var showingFiles = false
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var showingCDLConfirmation = false

    @FocusState

    private var focusedField: Field?

    private enum Field {

        case fullName

        case organization

        case cdl

        case phone

        case email

        case dlNumber

        case companyCardNumber

    }



    // MARK: Existing People

    private let existingPeople: [ExistingPerson] = [

        ExistingPerson(

            fullName: "David Okafor",

            organization: "Northstar Logistics",

            title: "Driver",

            cdlNumber: "CDL-483920",

            phoneNumber: "+1 416 555 0182",

            emailAddress: "david.okafor@northstar.com",

            dateOfBirth: nil,

            idCountry: "Canada",

            dlNumber: "ON-829104",

            companyCardNumber: "NS-2841"

        ),

        ExistingPerson(

            fullName: "Olivia Martin",

            organization: "CargoTrucks",

            title: "Site supervisor",

            cdlNumber: "",

            phoneNumber: "+1 647 555 0197",

            emailAddress: "olivia@cargotrucks.com",

            dateOfBirth: nil,

            idCountry: "Canada",

            dlNumber: "",

            companyCardNumber: "CT-1108"

        ),

        ExistingPerson(

            fullName: "Elias Petrov",

            organization: "SafeGate Services",

            title: "Contractor",

            cdlNumber: "",

            phoneNumber: "+1 905 555 0144",

            emailAddress: "elias@safegate.com",

            dateOfBirth: nil,

            idCountry: "Canada",

            dlNumber: "",

            companyCardNumber: "SG-0292"

        ),

        ExistingPerson(

            fullName: "Milan Jović",

            organization: "Bison Transport",

            title: "Driver",

            cdlNumber: "CDL-882013",

            phoneNumber: "+1 204 555 0124",

            emailAddress: "milan.jovic@bisontransport.com",

            dateOfBirth: nil,

            idCountry: "Canada",

            dlNumber: "MB-420931",

            companyCardNumber: ""

        ),

        ExistingPerson(

            fullName: "Gurpreet Singh",

            organization: "Honda Dealership",

            title: "Driver",

            cdlNumber: "CDL-109274",

            phoneNumber: "+1 416 555 0168",

            emailAddress: "gurpreet@honda.com",

            dateOfBirth: nil,

            idCountry: "Canada",

            dlNumber: "ON-520184",

            companyCardNumber: "HD-4412"

        )

    ]

    private let titles = [

        "Driver",

        "Employee",

        "Contractor",

        "Visitor",

        "Supervisor"

    ]

    private let countries = [

        "Canada",

        "United States",

        "Mexico",

        "United Kingdom",

        "France",

        "Germany"

    ]



    // MARK: Search

    private var cleanFullName: String {

        fullName.trimmingCharacters(

            in: .whitespacesAndNewlines

        )

    }

    private var filteredPeople: [ExistingPerson] {

        guard !cleanFullName.isEmpty else {

            return []

        }

        return existingPeople

            .filter { person in

                person.fullName

                    .localizedCaseInsensitiveContains(

                        cleanFullName

                    )

                ||

                person.organization

                    .localizedCaseInsensitiveContains(

                        cleanFullName

                    )

            }

            .prefix(3)

            .map { $0 }

    }

    private var shouldShowPeopleSuggestions: Bool {

        focusedField == .fullName &&

        !cleanFullName.isEmpty &&

        selectedExistingPerson == nil

    }



    // MARK: Validation

    private var canSave: Bool {

        !cleanFullName.isEmpty &&

        !organization

            .trimmingCharacters(

                in: .whitespacesAndNewlines

            )

            .isEmpty

    }



    // MARK: Body

    var body: some View {

        NavigationStack {

            Form {

                quickScanSection

                VStack(

                    alignment: .leading,

                    spacing: 20

                ) {

                    fullNameField

                    organizationField

                    cdlField

                    moreDetailsArea

                    accessPolicyArea

                }

                .listRowInsets(

                    EdgeInsets(

                        top: 0,

                        leading: 0,

                        bottom: 4,

                        trailing: 0

                    )

                )

                .listRowSeparator(.hidden)

                .listRowBackground(Color.clear)

            }

            .contentMargins(

                .top,

                8,

                for: .scrollContent

            )

            .scrollDismissesKeyboard(

                .interactively

            )

            .navigationTitle(

                "Add person"

            )

            .navigationBarTitleDisplayMode(

                .inline

            )

            .toolbar {

                ToolbarItem(

                    placement: .cancellationAction

                ) {

                    Button("Cancel") {

                        focusedField = nil

                        dismiss()

                    }

                }

                ToolbarItem(

                    placement: .confirmationAction

                ) {

                    Button("Save") {

                        save()

                    }

                    .buttonStyle(.glassProminent)

                    .tint(.blue)

                    .disabled(!canSave)

                }

            }
            .alert(
                "CDL number improves security",
                isPresented: $showingCDLConfirmation
            ) {
                Button("Continue without CDL number") {
                    savePerson()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Adding a CDL number helps us verify the driver's identity.\nAre you sure you want to continue without one?")
            }
            .photosPicker(
                isPresented: $showingPhotos,
                selection: $selectedPhotoItem,
                matching: .images,
                photoLibrary: .shared()
            )
            .onChange(of: selectedPhotoItem) { _, newItem in
                guard let newItem else { return }
                Task {
                    guard let data = try? await newItem.loadTransferable(type: Data.self),
                          let image = UIImage(data: data) else { return }
                    await MainActor.run {
                        handleScannedImage(image)
                        selectedPhotoItem = nil
                    }
                }
            }
            .fileImporter(
                isPresented: $showingFiles,
                allowedContentTypes: [.image],
                allowsMultipleSelection: false
            ) { result in
                guard case .success(let urls) = result, let url = urls.first else { return }
                let hasAccess = url.startAccessingSecurityScopedResource()
                defer { if hasAccess { url.stopAccessingSecurityScopedResource() } }
                guard let data = try? Data(contentsOf: url),
                      let image = UIImage(data: data) else { return }
                handleScannedImage(image)
            }
            .sheet(isPresented: $showingCamera) {
                CameraPicker { image in
                    showingCamera = false
                    handleScannedImage(image)
                }
                .ignoresSafeArea()
            }

            .sheet(

                isPresented: $showingDatePicker

            ) {

                datePickerSheet

            }

            .sheet(

                item: $selectedExistingPerson

            ) { person in

                EditPersonAuthorizationView(

                    person: person

                )

            }

            .sheet(

                isPresented: $showingAccessPolicy

            ) {

                AccessPolicyEditorView(

                    policy: accessPolicy

                ) { updatedPolicy in

                    accessPolicy = updatedPolicy

                }

            }

        }

    }



    // MARK: Quick Scan

    private var quickScanSection: some View {
        Section {
            Button {
                focusedField = nil
                showingScanOptions = true
            } label: {
                HStack(spacing: 12) {
                    Group {
                        if let scannedImage {
                            Image(uiImage: scannedImage)
                                .resizable()
                                .scaledToFill()
                        } else {
                            Image(systemName: "text.viewfinder")
                                .font(.title3.weight(.semibold))
                                .foregroundStyle(.blue)
                        }
                    }
                    .frame(width: 44, height: 44)
                    .background(
                        scannedImage == nil ? Color.blue.opacity(0.08) : Color.clear,
                        in: RoundedRectangle(cornerRadius: 10, style: .continuous)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

                    VStack(alignment: .leading, spacing: 3) {
                        switch quickScanState {
                        case .empty:
                            Text("Quick scan")
                                .font(.body.weight(.semibold))
                                .foregroundStyle(.blue)
                            Text("Scan the driver's license to fill in the data.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)

                        case .scanning:
                            Text("Scanning license...")
                                .font(.body.weight(.semibold))
                            HStack(spacing: 7) {
                                ProgressView().controlSize(.small)
                                Text("Reading driver information")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }

                        case .success:
                            HStack(spacing: 6) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                                Text("License scanned")
                                    .font(.body.weight(.semibold))
                            }
                            Text("Driver information was filled in.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }

                    
                }
                .padding(.vertical, 2)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .disabled(quickScanState == .scanning)
            .confirmationDialog(
                "Quick scan",
                isPresented: $showingScanOptions,
                titleVisibility: .visible
            ) {
                Button("Camera", systemImage: "camera") { showingCamera = true }
                Button("Photos", systemImage: "photo") { showingPhotos = true }
                Button("Files", systemImage: "folder") { showingFiles = true }
                Button("Cancel", role: .cancel) {}
            }
        }
    }

    // MARK: Full Name

    private var fullNameField: some View {

        VStack(

            alignment: .leading,

            spacing: 6

        ) {

            fieldLabel(

                "Full name",

                required: true

            )

            VStack(spacing: 0) {

                TextField(

                    "Enter full name",

                    text: $fullName

                )

                .focused(

                    $focusedField,

                    equals: .fullName

                )

                .textContentType(.name)

                .textInputAutocapitalization(

                    .words

                )

                .submitLabel(.next)

                .padding(.horizontal, 16)

                .frame(

                    maxWidth: .infinity,

                    minHeight: 52,

                    alignment: .leading

                )

                .onSubmit {

                    focusedField = .organization

                }

                if shouldShowPeopleSuggestions {

                    Divider()

                        .padding(.leading, 16)

                    existingPeopleSuggestions

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

        }

    }



    // MARK: Organization

    private var organizationField: some View {

        formField(

            title: "Organization name",

            required: true

        ) {

            TextField(

                "Enter organization name",

                text: $organization

            )

            .focused(

                $focusedField,

                equals: .organization

            )

            .textContentType(

                .organizationName

            )

            .textInputAutocapitalization(

                .words

            )

            .submitLabel(.next)

            .onSubmit {

                focusedField = .cdl

            }

        }

    }



    // MARK: CDL

    private var cdlField: some View {

        formField(

            title: "CDL number"

        ) {

            TextField(

                "Optional",

                text: $cdlNumber

            )

            .focused(

                $focusedField,

                equals: .cdl

            )

            .textInputAutocapitalization(

                .characters

            )

            .autocorrectionDisabled()

            .submitLabel(.done)

            .onSubmit {

                focusedField = nil

            }

        }

    }



    // MARK: Existing People

    @ViewBuilder

    private var existingPeopleSuggestions: some View {

        if filteredPeople.isEmpty {

            HStack(spacing: 10) {

                Image(

                    systemName: "magnifyingglass"

                )

                .foregroundStyle(.secondary)

                Text("No existing people found")

                    .font(.subheadline)

                    .foregroundStyle(.secondary)

                Spacer()

            }

            .padding(.horizontal, 16)

            .frame(minHeight: 52)

        } else {

            VStack(spacing: 0) {

                ForEach(

                    Array(

                        filteredPeople.enumerated()

                    ),

                    id: \.element.id

                ) { index, person in

                    Button {

                        focusedField = nil

                        DispatchQueue.main.async {

                            selectedExistingPerson = person

                        }

                    } label: {

                        HStack(spacing: 12) {

                            Image(

                                systemName:

                                    "person.crop.circle.fill"

                            )

                            .font(.title2)

                            .foregroundStyle(.blue)

                            .frame(

                                width: 32,

                                height: 32

                            )

                            VStack(

                                alignment: .leading,

                                spacing: 2

                            ) {

                                Text(person.fullName)

                                    .font(

                                        .body.weight(.medium)

                                    )

                                    .foregroundStyle(.primary)

                                Text(person.subtitle)

                                    .font(.subheadline)

                                    .foregroundStyle(.secondary)

                            }

                            Spacer()

                            Image(

                                systemName: "chevron.right"

                            )

                            .font(

                                .caption.weight(.semibold)

                            )

                            .foregroundStyle(.tertiary)

                        }

                        .padding(.horizontal, 16)

                        .frame(minHeight: 58)

                        .contentShape(Rectangle())

                    }

                    .buttonStyle(.plain)

                    if index < filteredPeople.count - 1 {

                        Divider()

                            .padding(.leading, 60)

                    }

                }

            }

        }

    }



    // MARK: More Details

    private var moreDetailsArea: some View {

        VStack(

            alignment: .leading,

            spacing: 10

        ) {

            moreDetailsDisclosure

            if moreDetailsExpanded {

                moreDetailsFields

                    .transition(.opacity)

            }

        }

    }



    private var moreDetailsDisclosure: some View {

        Button {

            focusedField = nil

            moreDetailsExpanded.toggle()

        } label: {

            VStack(

                alignment: .leading,

                spacing: 8

            ) {

                HStack {

                    Text("More details")

                        .font(

                            .subheadline.weight(.semibold)

                        )

                        .foregroundStyle(.secondary)

                    Spacer()

                    Image(

                        systemName:

                            moreDetailsExpanded

                            ? "chevron.up"

                            : "chevron.down"

                    )

                    .font(

                        .caption.weight(.semibold)

                    )

                    .foregroundStyle(.secondary)

                }

                if !moreDetailsExpanded {

                    MoreDetailsChips(

                        title: title,

                        phoneNumber: phoneNumber,

                        emailAddress: emailAddress,

                        dateOfBirth: dateOfBirth,

                        idCountry: idCountry,

                        dlNumber: dlNumber,

                        companyCardNumber: companyCardNumber

                    )

                    .transition(.opacity)

                }

            }

            .padding(.horizontal, 16)

            .contentShape(Rectangle())

        }

        .buttonStyle(.plain)

    }

    private var moreDetailsFields: some View {

        VStack(spacing: 0) {

            titleMenu

            rowDivider

            detailsRow(

                title: "Phone number"

            ) {

                TextField(

                    "Optional",

                    text: $phoneNumber

                )

                .focused(

                    $focusedField,

                    equals: .phone

                )

                .keyboardType(.phonePad)

                .multilineTextAlignment(

                    .trailing

                )

            }

            rowDivider

            detailsRow(

                title: "Email"

            ) {

                TextField(

                    "Optional",

                    text: $emailAddress

                )

                .focused(

                    $focusedField,

                    equals: .email

                )

                .keyboardType(.emailAddress)

                .textInputAutocapitalization(

                    .never

                )

                .autocorrectionDisabled()

                .multilineTextAlignment(

                    .trailing

                )

            }

            rowDivider

            Button {

                focusedField = nil

                showingDatePicker = true

            } label: {

                detailsActionRow(

                    title: "Date of birth",

                    value:

                        dateOfBirth?.formatted(

                            date: .abbreviated,

                            time: .omitted

                        )

                        ?? "Add"

                )

            }

            .buttonStyle(.plain)

            rowDivider

            countryMenu

            rowDivider

            detailsRow(

                title: "DL number"

            ) {

                TextField(

                    "Optional",

                    text: $dlNumber

                )

                .focused(

                    $focusedField,

                    equals: .dlNumber

                )

                .multilineTextAlignment(

                    .trailing

                )

            }

            rowDivider

            detailsRow(

                title: "Company card number"

            ) {

                TextField(

                    "Optional",

                    text: $companyCardNumber

                )

                .focused(

                    $focusedField,

                    equals: .companyCardNumber

                )

                .multilineTextAlignment(

                    .trailing

                )

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

    }



    // MARK: Access Policy

    private var accessPolicyArea: some View {

        Button {

            focusedField = nil

            showingAccessPolicy = true

        } label: {

            VStack(

                alignment: .leading,

                spacing: 12

            ) {

                HStack {

                    Text("Access policy")

                        .font(.subheadline.weight(.semibold))

                        .foregroundStyle(.blue)

                    Spacer()

                    Image(systemName: "chevron.right")

                        .font(.caption.weight(.semibold))

                        .foregroundStyle(.tertiary)

                }

                HStack(spacing: 8) {

                    Label(

                        accessPolicy.locations,

                        systemImage: "mappin.and.ellipse"

                    )

                    .font(.subheadline)

                    .foregroundStyle(.primary)

                    .lineLimit(1)

                    Spacer(minLength: 6)

                    AccessTypeChip(

                        accessType: accessPolicy.accessType,

                        periodAccess: accessPolicy.periodAccess,

                        hasNote: !accessPolicy.note

                            .trimmingCharacters(

                                in: .whitespacesAndNewlines

                            )

                            .isEmpty,

                        isLimitedTime: accessPolicy.limitedTimeAccess

                    )



                }

            }

            .padding(.horizontal, 16)

            .padding(.vertical, 14)

            .frame(

                maxWidth: .infinity,

                alignment: .leading

            )

            .background(

                Color(.secondarySystemGroupedBackground),

                in: RoundedRectangle(

                    cornerRadius: 20,

                    style: .continuous

                )

            )

            .contentShape(Rectangle())

        }

        .buttonStyle(.plain)

    }

    // MARK: Menus

    private var titleMenu: some View {

        Menu {

            ForEach(

                titles,

                id: \.self

            ) { item in

                Button {

                    title = item

                } label: {

                    if title == item {

                        Label(

                            item,

                            systemImage: "checkmark"

                        )

                    } else {

                        Text(item)

                    }

                }

            }

        } label: {

            menuRow(

                label: "Title",

                value: title

            )

        }

        .buttonStyle(.plain)

    }



    private var countryMenu: some View {

        Menu {

            ForEach(

                countries,

                id: \.self

            ) { country in

                Button {

                    idCountry = country

                } label: {

                    if idCountry == country {

                        Label(

                            country,

                            systemImage: "checkmark"

                        )

                    } else {

                        Text(country)

                    }

                }

            }

        } label: {

            menuRow(

                label: "ID country",

                value: idCountry

            )

        }

        .buttonStyle(.plain)

    }



    // MARK: Helpers

    private func fieldLabel(

        _ title: String,

        required: Bool = false

    ) -> some View {

        HStack(spacing: 2) {

            Text(title)

                .font(

                    .subheadline.weight(.semibold)

                )

                .foregroundStyle(.secondary)

            if required {

                Text("*")

                    .font(

                        .subheadline.weight(.semibold)

                    )

                    .foregroundStyle(.red)

            }

        }

        .padding(.horizontal, 16)

    }



    @ViewBuilder

    private func formField<Content: View>(

        title: String,

        required: Bool = false,

        @ViewBuilder content: () -> Content

    ) -> some View {

        VStack(

            alignment: .leading,

            spacing: 6

        ) {

            fieldLabel(

                title,

                required: required

            )

            content()

                .padding(.horizontal, 16)

                .frame(

                    maxWidth: .infinity,

                    minHeight: 52,

                    alignment: .leading

                )

                .background(

                    Color(

                        .secondarySystemGroupedBackground

                    ),

                    in: RoundedRectangle(

                        cornerRadius: 20,

                        style: .continuous

                    )

                )

        }

    }



    private func menuRow(

        label: String,

        value: String

    ) -> some View {

        HStack {

            Text(label)

                .foregroundStyle(.primary)

            Spacer()

            HStack(spacing: 5) {

                Text(value)

                    .foregroundStyle(.blue)

                Image(

                    systemName:

                        "chevron.up.chevron.down"

                )

                .font(

                    .caption2.weight(.semibold)

                )

                .foregroundStyle(.blue)

            }

        }

        .frame(minHeight: 50)

        .padding(.horizontal, 16)

    }



    @ViewBuilder

    private func detailsRow<Content: View>(

        title: String,

        @ViewBuilder content: () -> Content

    ) -> some View {

        HStack {

            Text(title)

                .foregroundStyle(.primary)

            Spacer(minLength: 16)

            content()

                .frame(

                    maxWidth: 210,

                    alignment: .trailing

                )

        }

        .frame(minHeight: 50)

        .padding(.horizontal, 16)

    }



    private func detailsActionRow(

        title: String,

        value: String

    ) -> some View {

        HStack {

            Text(title)

                .foregroundStyle(.primary)

            Spacer()

            Text(value)

                .foregroundStyle(.blue)

        }

        .frame(minHeight: 50)

        .padding(.horizontal, 16)

    }



    private var rowDivider: some View {

        Divider()

            .padding(.leading, 16)

    }



    private var datePickerSheet: some View {

        NavigationStack {

            DatePicker(

                "Date of birth",

                selection: Binding(

                    get: {

                        dateOfBirth ?? Date()

                    },

                    set: {

                        dateOfBirth = $0

                    }

                ),

                displayedComponents: .date

            )

            .datePickerStyle(.graphical)

            .padding()

            .navigationTitle(

                "Date of birth"

            )

            .navigationBarTitleDisplayMode(

                .inline

            )

            .toolbar {

                ToolbarItem(

                    placement: .confirmationAction

                ) {

                    Button("Done") {

                        showingDatePicker = false

                    }

                }

            }

        }

        .presentationDetents([.medium])

    }



    private func handleScannedImage(_ image: UIImage) {
        scannedImage = image
        quickScanState = .scanning
        focusedField = nil

        Task {
            try? await Task.sleep(for: .seconds(1.6))
            guard !Task.isCancelled else { return }
            await MainActor.run {
                fillMockScannedData()
                quickScanState = .success
            }
        }
    }

    private func fillMockScannedData() {
        fullName = "Michael Thompson"
        organization = "Northstar Logistics"
        cdlNumber = "CDL-729184"
        title = "Driver"
        phoneNumber = "+1 416 555 0148"
        emailAddress = "michael.thompson@northstar.com"
        dateOfBirth = Calendar.current.date(from: DateComponents(year: 1989, month: 6, day: 14))
        idCountry = "Canada"
        dlNumber = "ON-582941"
        companyCardNumber = "NS-4812"
    }

    private func save() {

        focusedField = nil

        guard cdlNumber.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            savePerson()
            return
        }

        showingCDLConfirmation = true
    }

    private func savePerson() {
        let person = ExistingPerson(
            fullName: cleanFullName,
            organization: organization.trimmingCharacters(in: .whitespacesAndNewlines),
            title: title,
            cdlNumber: cdlNumber,
            phoneNumber: phoneNumber,
            emailAddress: emailAddress,
            dateOfBirth: dateOfBirth,
            idCountry: idCountry,
            dlNumber: dlNumber,
            companyCardNumber: companyCardNumber
        )

        onSave(person, accessPolicy)
        dismiss()
    }

}

private struct CameraPicker: UIViewControllerRepresentable {
    let onImagePicked: (UIImage) -> Void

    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.allowsEditing = false
        picker.sourceType = UIImagePickerController.isSourceTypeAvailable(.camera) ? .camera : .photoLibrary
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onImagePicked: onImagePicked, dismiss: dismiss)
    }

    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        private let onImagePicked: (UIImage) -> Void
        private let dismiss: DismissAction

        init(onImagePicked: @escaping (UIImage) -> Void, dismiss: DismissAction) {
            self.onImagePicked = onImagePicked
            self.dismiss = dismiss
        }

        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
        ) {
            if let image = info[.originalImage] as? UIImage {
                onImagePicked(image)
            }
            dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            dismiss()
        }
    }
}


struct EditPersonAuthorizationView: View {

    @Environment(\.dismiss)
    private var dismiss

    let person: ExistingPerson
    let onSave: () -> Void

    @State private var fullName: String
    @State private var organization: String
    @State private var cdlNumber: String

    @State private var title: String
    @State private var phoneNumber: String
    @State private var emailAddress: String
    @State private var dateOfBirth: Date?
    @State private var idCountry: String
    @State private var dlNumber: String
    @State private var companyCardNumber: String

    @State private var accessPolicy: AccessPolicy

    @State private var moreDetailsExpanded = false
    @State private var showingDatePicker = false
    @State private var showingAccessPolicy = false
    @State private var showingCDLConfirmation = false

    @FocusState
    private var focusedField: Field?

    private enum Field {
        case fullName
        case organization
        case cdl
        case phone
        case email
        case dlNumber
        case companyCardNumber
    }

    private let titles = [
        "Driver",
        "Employee",
        "Contractor",
        "Visitor",
        "Supervisor"
    ]

    private let countries = [
        "Canada",
        "United States",
        "Mexico",
        "United Kingdom",
        "France",
        "Germany"
    ]


    init(
        person: ExistingPerson,
        onSave: @escaping () -> Void = {}
    ) {

        self.person = person
        self.onSave = onSave

        _fullName = State(
            initialValue: person.fullName
        )

        _organization = State(
            initialValue: person.organization
        )

        _cdlNumber = State(
            initialValue: person.cdlNumber
        )

        _title = State(
            initialValue: person.title
        )

        _phoneNumber = State(
            initialValue: person.phoneNumber
        )

        _emailAddress = State(
            initialValue: person.emailAddress
        )

        _dateOfBirth = State(
            initialValue: person.dateOfBirth
        )

        _idCountry = State(
            initialValue: person.idCountry
        )

        _dlNumber = State(
            initialValue: person.dlNumber
        )

        _companyCardNumber = State(
            initialValue: person.companyCardNumber
        )

        _accessPolicy = State(
            initialValue: AccessPolicy()
        )
    }


    private var canSave: Bool {

        !fullName
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            )
            .isEmpty

        &&

        !organization
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            )
            .isEmpty
    }


    var body: some View {

        NavigationStack {

            Form {

                VStack(
                    alignment: .leading,
                    spacing: 20
                ) {

                    fullNameField

                    organizationField

                    cdlField

                    moreDetailsArea

                    accessPolicyArea

                    updateDetails
                }
                .listRowInsets(
                    EdgeInsets(
                        top: 0,
                        leading: 0,
                        bottom: 4,
                        trailing: 0
                    )
                )
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
            }
            .contentMargins(
                .top,
                8,
                for: .scrollContent
            )
            .scrollDismissesKeyboard(
                .interactively
            )
            .navigationTitle(
                "Edit authorization"
            )
            .navigationBarTitleDisplayMode(
                .inline
            )
            .toolbar {

                ToolbarItem(
                    placement: .cancellationAction
                ) {

                    Button("Cancel") {

                        focusedField = nil
                        dismiss()
                    }
                }

                ToolbarItem(
                    placement: .confirmationAction
                ) {

                    Button("Save") {
                        save()
                    }
                    .buttonStyle(.glassProminent)
                    .tint(.blue)
                    .disabled(!canSave)
                }
            }
            .alert(
                "CDL number improves security",
                isPresented: $showingCDLConfirmation
            ) {
                Button("Continue without CDL number") {
                    savePerson()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Adding a CDL number helps us verify the driver's identity.\nAre you sure you want to continue without one?")
            }
            .sheet(
                isPresented: $showingDatePicker
            ) {
                datePickerSheet
            }
            .sheet(
                isPresented: $showingAccessPolicy
            ) {

                AccessPolicyEditorView(
                    policy: accessPolicy
                ) { updatedPolicy in

                    accessPolicy = updatedPolicy
                }
            }
        }
    }


    private var updateDetails: some View {
        VStack(
            alignment: .leading,
            spacing: 4
        ) {
            Text("Updated by: maya@northstar.com")
            Text("Updated at: Today, 10:30 AM")
        }
        .font(.footnote)
        .foregroundStyle(.secondary)
        .padding(.horizontal, 16)
        .padding(.top, 4)
    }

    private var fullNameField: some View {

        formField(
            title: "Full name",
            required: true
        ) {

            TextField(
                "Enter full name",
                text: $fullName
            )
            .focused(
                $focusedField,
                equals: .fullName
            )
            .submitLabel(.next)
            .onSubmit {
                focusedField = .organization
            }
        }
    }


    private var organizationField: some View {

        formField(
            title: "Organization name",
            required: true
        ) {

            TextField(
                "Enter organization name",
                text: $organization
            )
            .focused(
                $focusedField,
                equals: .organization
            )
            .submitLabel(.next)
            .onSubmit {
                focusedField = .cdl
            }
        }
    }


    private var cdlField: some View {

        formField(
            title: "CDL number"
        ) {

            TextField(
                "Optional",
                text: $cdlNumber
            )
            .focused(
                $focusedField,
                equals: .cdl
            )
            .submitLabel(.done)
            .onSubmit {
                focusedField = nil
            }
        }
    }


    // MARK: More Details

    private var moreDetailsArea: some View {
        VStack(
            alignment: .leading,
            spacing: 10
        ) {
            Button {
                focusedField = nil
                moreDetailsExpanded.toggle()
            } label: {
                VStack(
                    alignment: .leading,
                    spacing: 8
                ) {
                    HStack {
                        Text("More details")
                            .font(
                                .subheadline.weight(.semibold)
                            )
                            .foregroundStyle(.secondary)

                        Spacer()

                        Image(
                            systemName:
                                moreDetailsExpanded
                                ? "chevron.up"
                                : "chevron.down"
                        )
                        .font(
                            .caption.weight(.semibold)
                        )
                        .foregroundStyle(.secondary)
                    }

                    if !moreDetailsExpanded {
                        MoreDetailsChips(
                            title: title,
                            phoneNumber: phoneNumber,
                            emailAddress: emailAddress,
                            dateOfBirth: dateOfBirth,
                            idCountry: idCountry,
                            dlNumber: dlNumber,
                            companyCardNumber: companyCardNumber
                        )
                        .transition(.opacity)
                    }
                }
                .padding(.horizontal, 16)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if moreDetailsExpanded {
                moreDetailsFields
                    .transition(.opacity)
            }
        }
    }

    private var moreDetailsFields: some View {

        VStack(spacing: 0) {

            titleMenu

            rowDivider

            detailsRow(
                title: "Phone number"
            ) {

                TextField(
                    "Optional",
                    text: $phoneNumber
                )
                .focused(
                    $focusedField,
                    equals: .phone
                )
                .keyboardType(.phonePad)
                .multilineTextAlignment(
                    .trailing
                )
            }

            rowDivider

            detailsRow(
                title: "Email"
            ) {

                TextField(
                    "Optional",
                    text: $emailAddress
                )
                .focused(
                    $focusedField,
                    equals: .email
                )
                .keyboardType(.emailAddress)
                .multilineTextAlignment(
                    .trailing
                )
            }

            rowDivider

            Button {

                focusedField = nil
                showingDatePicker = true

            } label: {

                detailsActionRow(
                    title: "Date of birth",
                    value:
                        dateOfBirth?.formatted(
                            date: .abbreviated,
                            time: .omitted
                        )
                        ?? "Add"
                )
            }
            .buttonStyle(.plain)

            rowDivider

            countryMenu

            rowDivider

            detailsRow(
                title: "DL number"
            ) {

                TextField(
                    "Optional",
                    text: $dlNumber
                )
                .focused(
                    $focusedField,
                    equals: .dlNumber
                )
                .multilineTextAlignment(
                    .trailing
                )
            }

            rowDivider

            detailsRow(
                title: "Company card number"
            ) {

                TextField(
                    "Optional",
                    text: $companyCardNumber
                )
                .focused(
                    $focusedField,
                    equals: .companyCardNumber
                )
                .multilineTextAlignment(
                    .trailing
                )
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
    }


    // MARK: Access Policy

    private var accessPolicyArea: some View {
        Button {
            focusedField = nil
            showingAccessPolicy = true
        } label: {
            VStack(
                alignment: .leading,
                spacing: 12
            ) {
                HStack {
                    Text("Access policy")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.blue)

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.tertiary)
                }

                HStack(spacing: 8) {
                    Label(
                        accessPolicy.locations,
                        systemImage: "mappin.and.ellipse"
                    )
                    .font(.subheadline)
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                    Spacer(minLength: 6)

                    AccessTypeChip(
                        accessType: accessPolicy.accessType,
                        periodAccess: accessPolicy.periodAccess,
                        hasNote: !accessPolicy.note
                            .trimmingCharacters(
                                in: .whitespacesAndNewlines
                            )
                            .isEmpty,
                        isLimitedTime: accessPolicy.limitedTimeAccess
                    )


                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .frame(
                maxWidth: .infinity,
                alignment: .leading
            )
            .background(
                Color(.secondarySystemGroupedBackground),
                in: RoundedRectangle(
                    cornerRadius: 20,
                    style: .continuous
                )
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
    // MARK: Menus

    private var titleMenu: some View {

        Menu {

            ForEach(
                titles,
                id: \.self
            ) { item in

                Button {
                    title = item
                } label: {

                    if title == item {

                        Label(
                            item,
                            systemImage: "checkmark"
                        )

                    } else {

                        Text(item)
                    }
                }
            }

        } label: {

            menuRow(
                label: "Title",
                value: title
            )
        }
        .buttonStyle(.plain)
    }


    private var countryMenu: some View {

        Menu {

            ForEach(
                countries,
                id: \.self
            ) { country in

                Button {
                    idCountry = country
                } label: {

                    if idCountry == country {

                        Label(
                            country,
                            systemImage: "checkmark"
                        )

                    } else {

                        Text(country)
                    }
                }
            }

        } label: {

            menuRow(
                label: "ID country",
                value: idCountry
            )
        }
        .buttonStyle(.plain)
    }


    // MARK: Helpers

    @ViewBuilder
    private func formField<Content: View>(
        title: String,
        required: Bool = false,
        @ViewBuilder content: () -> Content
    ) -> some View {

        VStack(
            alignment: .leading,
            spacing: 6
        ) {

            HStack(spacing: 2) {

                Text(title)
                    .font(
                        .subheadline.weight(.semibold)
                    )
                    .foregroundStyle(.secondary)

                if required {

                    Text("*")
                        .foregroundStyle(.red)
                }
            }
            .padding(.horizontal, 16)

            content()
                .padding(.horizontal, 16)
                .frame(
                    maxWidth: .infinity,
                    minHeight: 52,
                    alignment: .leading
                )
                .background(
                    Color(
                        .secondarySystemGroupedBackground
                    ),
                    in: RoundedRectangle(
                        cornerRadius: 20,
                        style: .continuous
                    )
                )
        }
    }


    private func menuRow(
        label: String,
        value: String
    ) -> some View {

        HStack {

            Text(label)
                .foregroundStyle(.primary)

            Spacer()

            HStack(spacing: 5) {

                Text(value)
                    .foregroundStyle(.blue)

                Image(
                    systemName:
                        "chevron.up.chevron.down"
                )
                .font(
                    .caption2.weight(.semibold)
                )
                .foregroundStyle(.blue)
            }
        }
        .frame(minHeight: 50)
        .padding(.horizontal, 16)
    }


    @ViewBuilder
    private func detailsRow<Content: View>(
        title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {

        HStack {

            Text(title)
                .foregroundStyle(.primary)

            Spacer()

            content()
                .frame(
                    maxWidth: 210,
                    alignment: .trailing
                )
        }
        .frame(minHeight: 50)
        .padding(.horizontal, 16)
    }


    private func detailsActionRow(
        title: String,
        value: String
    ) -> some View {

        HStack {

            Text(title)
                .foregroundStyle(.primary)

            Spacer()

            Text(value)
                .foregroundStyle(.blue)
        }
        .frame(minHeight: 50)
        .padding(.horizontal, 16)
    }


    private var rowDivider: some View {

        Divider()
            .padding(.leading, 16)
    }


    private var datePickerSheet: some View {

        NavigationStack {

            DatePicker(
                "Date of birth",
                selection: Binding(
                    get: {
                        dateOfBirth ?? Date()
                    },
                    set: {
                        dateOfBirth = $0
                    }
                ),
                displayedComponents: .date
            )
            .datePickerStyle(.graphical)
            .padding()
            .navigationTitle(
                "Date of birth"
            )
            .navigationBarTitleDisplayMode(
                .inline
            )
            .toolbar {

                ToolbarItem(
                    placement: .confirmationAction
                ) {

                    Button("Done") {
                        showingDatePicker = false
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }


    private func save() {

        focusedField = nil

        guard cdlNumber.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            savePerson()
            return
        }

        showingCDLConfirmation = true
    }

    private func savePerson() {
        onSave()
        dismiss()
    }
}
