import SwiftUI

import UIKit

struct TeamView: View {

    @Environment(SnackbarCenter.self) private var snackbarCenter

    @State private var isInvitePresented = false
    @State private var teamInvitationEmail = ""

    @State private var members = [

        TeamMember(

            email: "maya.chen@northstar.com",

            locationCount: 12,

            status: .active

        ),

        TeamMember(

            email: "daniel.brooks@northstar.com",

            locationCount: 8,

            status: .active

        ),

        TeamMember(

            email: "sarah.patel@northstar.com",

            locationCount: 4,

            status: .inactive

        ),

        TeamMember(

            email: "james.wilson@northstar.com",

            locationCount: 6,

            status: .active

        )

    ]

    var body: some View {

        NavigationStack {

            ScrollView {

                VStack(

                    alignment: .leading,

                    spacing: 24

                ) {

                    BirdseyePageTitle(title: "Team")
                        .padding(.top, 16)

                    InviteTeamActionCard(
                        invitationEmail: $teamInvitationEmail,
                        isInvitePresented: $isInvitePresented
                    )

                    workspaceMembers

                }

                .padding(.horizontal, 16)

                .padding(.bottom, 70)

            }

            .birdseyeRefreshable()

            .background(

                Color(.systemGroupedBackground)

            )

            .birdseyeMainTabPage()

            .sheet(isPresented: $isInvitePresented) {

                InviteTeamMemberView(email: $teamInvitationEmail) { email, locationCount in

                    members.append(

                        TeamMember(

                            email: email,

                            locationCount: locationCount,

                            status: .invited

                        )

                    )

                    snackbarCenter.show("Invitation sent to \(email).")
                    teamInvitationEmail = ""

                }

            }

        }

    }

    private var workspaceMembers: some View {

        VStack(

            alignment: .leading,

            spacing: 8

        ) {

            Text("Workspace members")

                .font(.subheadline.weight(.semibold))

                .foregroundStyle(.secondary)

                .padding(.horizontal, 4)

            VStack(spacing: 0) {

                ForEach(displayedMembers) { member in

                    NavigationLink {

                        TeamMemberView(

                            member: memberBinding(for: member.id),

                            onRemoveInvite: {

                                members.removeAll { $0.id == member.id }

                            }

                        )

                    } label: {

                        TeamMemberRow(member: member)

                    }

                    .buttonStyle(.plain)

                    if member.id != displayedMembers.last?.id {

                        Divider()

                            .padding(.leading, 66)

                    }

                }

            }

            .background(

                Color(.secondarySystemGroupedBackground),

                in: RoundedRectangle(

                    cornerRadius: 20,

                    style: .continuous

                )

            )

        }

    }

    private var displayedMembers: [TeamMember] {

        members.sorted { $0.status.sortOrder < $1.status.sortOrder }

    }

    private func memberBinding(for id: TeamMember.ID) -> Binding<TeamMember> {

        Binding(

            get: {

                members.first(where: { $0.id == id }) ?? .unavailable

            },

            set: { updatedMember in

                guard let index = members.firstIndex(where: { $0.id == id }) else {

                    return

                }

                members[index] = updatedMember

            }

        )

    }

}



private struct TeamActionCardCarousel: View {

    let onAuthorizeDriver: () -> Void
    let onInviteMember: () -> Void
    let onSendRequest: () -> Void

    var body: some View {
        ScrollView(.horizontal) {
            LazyHStack(spacing: 16) {
                TeamActionCard(
                    title: "Authorize a driver",
                    description: "Set up the right access for people who visit your locations.",
                    iconName: "person.text.rectangle",
                    actionLabel: "Authorize a driver",
                    actionIconName: "person.badge.key",
                    action: onAuthorizeDriver
                )

                TeamActionCard(
                    title: "Invite a member",
                    description: "Manage access, view activity, and submit requests together in Birdseye.",
                    iconName: "person.2.badge.plus",
                    actionLabel: "Email address",
                    actionIconName: "envelope",
                    action: onInviteMember
                )

                TeamActionCard(
                    title: "Send a request to Birdseye",
                    description: "Tell us what you need and keep track of every update in one place.",
                    iconName: "paperplane",
                    actionLabel: "Describe your request",
                    actionIconName: "text.bubble",
                    action: onSendRequest
                )
            }
            .scrollTargetLayout()
            .padding(.horizontal, 16)
        }
        .contentMargins(.horizontal, -16, for: .scrollContent)
        .scrollIndicators(.hidden)
        .scrollTargetBehavior(.viewAligned)
        .accessibilityLabel("Team actions")
    }
}

private struct TeamActionCard: View {

    @Environment(\.colorScheme) private var colorScheme

    let title: LocalizedStringKey
    let description: LocalizedStringKey
    let iconName: String
    let actionLabel: LocalizedStringKey
    let actionIconName: String
    let action: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            HStack(alignment: .top, spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(title)
                        .font(.title2.weight(.bold))

                    Text(description)
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)

                Image(systemName: iconName)
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(.blue)
                    .frame(width: 80, height: 80)
                    .background(iconBackground, in: RoundedRectangle(cornerRadius: 26, style: .continuous))
            }

            Spacer(minLength: 0)

            Button(action: action) {
                HStack(spacing: 14) {
                    Image(systemName: actionIconName)
                        .font(.title3)
                        .foregroundStyle(.secondary)

                    Text(actionLabel)
                        .font(.title3)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)

                    Spacer(minLength: 0)

                    Image(systemName: "arrow.right")
                        .font(.headline.weight(.bold))
                        .foregroundStyle(.white)
                        .frame(width: 56, height: 56)
                        .background(.blue, in: Circle())
                }
                .padding(.leading, 18)
                .padding(.trailing, 12)
                .frame(maxWidth: .infinity, minHeight: 80)
                .background(inputBackground, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
            }
            .buttonStyle(.plain)
            .accessibilityLabel(title)
        }
        .padding(24)
        .frame(width: 340, height: 310, alignment: .topLeading)
        .background(cardBackground, in: RoundedRectangle(cornerRadius: 36, style: .continuous))
    }

    private var cardBackground: Color {
        colorScheme == .dark
            ? Color(red: 0.0, green: 0.09, blue: 0.14)
            : Color(red: 0.88, green: 0.93, blue: 0.99)
    }

    private var inputBackground: Color {
        colorScheme == .dark
            ? Color(red: 0.06, green: 0.07, blue: 0.09)
            : Color(.systemBackground)
    }

    private var iconBackground: Color {
        colorScheme == .dark
            ? Color(red: 0.0, green: 0.18, blue: 0.30)
            : Color.blue.opacity(0.14)
    }
}



// MARK: - Invite member

struct InviteTeamMemberView: View {

    @Environment(\.dismiss) private var dismiss

    let onInvite: (String, Int) -> Void

    @Binding var email: String

    init(
        email: Binding<String>,
        onInvite: @escaping (String, Int) -> Void
    ) {
        _email = email
        self.onInvite = onInvite
    }

    @State private var organizations: [InviteOrganization] = [

        .northstar

    ]

    @State private var availableOrganizations: [InviteOrganization] = [

        .atlas,

        .summit

    ]

    private var canSend: Bool {

        !email

            .trimmingCharacters(

                in: .whitespacesAndNewlines

            )

            .isEmpty



    }

    private var locationCount: Int {

        organizations.reduce(0) { count, organization in

            count + organization.locations.filter(\.hasGrantedAccess).count

        }

    }

    var body: some View {

        NavigationStack {

            ScrollView {

                VStack(

                    alignment: .leading,

                    spacing: 28

                ) {

                    memberDetails

                    Divider()

                    permissions

                }

                .padding(.horizontal, 20)

                .padding(.top, 20)

                .padding(.bottom, 40)

            }

            .background(

                Color(.systemGroupedBackground)

            )

            .navigationTitle("Invite team member")

            .navigationBarTitleDisplayMode(.inline)

            .toolbar {

                ToolbarItem(

                    placement: .cancellationAction

                ) {

                    Button("Cancel") {

                        dismiss()

                    }

                }

                ToolbarItem(

                    placement: .confirmationAction

                ) {

                    Button("Invite") {

                        sendInvite()

                    }

                    .fontWeight(.semibold)

                    .tint(.blue)

                    .disabled(!canSend)

                }

            }

        }

    }

    private var memberDetails: some View {

        TeamMemberDetailsSection(email: $email)

    }

    private var permissions: some View {

        TeamMemberPermissionsSection(

            organizations: $organizations,

            availableOrganizations: availableOrganizations,

            onAddOrganization: addOrganization,

            onDeleteOrganization: removeOrganization

        )

    }

    private func addOrganization(

        _ organization: InviteOrganization

    ) {

        withAnimation(

            .easeInOut(duration: 0.2)

        ) {

            organizations.append(

                organization

            )

            availableOrganizations.removeAll {

                $0.id == organization.id

            }

        }

    }

    private func removeOrganization(

        _ id: UUID

    ) {

        guard let index = organizations.firstIndex(

            where: {

                $0.id == id

            }

        ) else {

            return

        }

        let organization =

            organizations[index]

        withAnimation(

            .easeInOut(duration: 0.2)

        ) {

            organizations.remove(

                at: index

            )

            availableOrganizations.append(

                organization

            )

        }

    }

    private func sendInvite() {

        onInvite(email, locationCount)

        dismiss()

    }

}



// MARK: - Organization

private struct OrganizationPermissionCard: View {

    @Binding var organization: InviteOrganization

    let onDelete: () -> Void

    @State private var isExpanded = true

    var body: some View {

        VStack(spacing: 0) {

            organizationHeader

            if isExpanded {

                Divider()

                    .padding(.leading, 16)

                VStack(spacing: 0) {

                    ForEach(

                        organization.locations.indices,

                        id: \.self

                    ) { index in

                        LocationPermissionView(

                            location:

                                $organization.locations[index],

                            otherLocations:

                                organization.locations.filter {

                                    $0.id !=

                                        organization.locations[index].id

                                },

                            onCopyTo: { destinationID in

                                copyPermissions(

                                    from:

                                        organization.locations[index].id,

                                    to:

                                        destinationID

                                )

                            },

                            onCopyToAll: {

                                copyPermissionsToAll(

                                    from:

                                        organization.locations[index].id

                                )

                            }

                        )

                        if index <

                            organization.locations.count - 1 {

                            Divider()

                                .padding(.leading, 16)

                        }

                    }

                }

            }

        }

        .background(

            Color(.secondarySystemGroupedBackground),

            in: RoundedRectangle(

                cornerRadius: 18,

                style: .continuous

            )

        )

        .clipShape(

            RoundedRectangle(

                cornerRadius: 18,

                style: .continuous

            )

        )

    }

    private var organizationHeader: some View {

        HStack(spacing: 12) {

            VStack(

                alignment: .leading,

                spacing: 4

            ) {

                Text(organization.name)

                    .font(.headline)

                Text(locationSummary)

                    .font(.subheadline)

                    .foregroundStyle(.secondary)

                    .lineLimit(2)

            }

            Spacer()

            Button {

                withAnimation(

                    .easeInOut(duration: 0.2)

                ) {

                    isExpanded.toggle()

                }

            } label: {

                Image(

                    systemName:

                        isExpanded

                        ? "chevron.up"

                        : "chevron.down"

                )

                .font(

                    .caption.weight(.semibold)

                )

                .foregroundStyle(.secondary)

                .frame(

                    width: 32,

                    height: 32

                )

            }

            .buttonStyle(.plain)

            Button(

                role: .destructive

            ) {

                HapticFeedback.criticalAction()

                onDelete()

            } label: {

                Image(

                    systemName: "trash"

                )

                .frame(

                    width: 32,

                    height: 32

                )

            }

            .buttonStyle(.plain)

            .foregroundStyle(.secondary)

        }

        .padding(16)

    }

    private var locationSummary: String {

        let locationCount = organization.locations.filter(\.hasGrantedAccess).count

        return locationCount == 1

            ? "1 location"

            : "\(locationCount) locations"

    }

    private func copyPermissions(

        from sourceID: UUID,

        to destinationID: UUID

    ) {

        guard

            let sourceIndex =

                organization.locations.firstIndex(

                    where: {

                        $0.id == sourceID

                    }

                ),

            let destinationIndex =

                organization.locations.firstIndex(

                    where: {

                        $0.id == destinationID

                    }

                )

        else {

            return

        }

        let sourcePermissions =

            organization

                .locations[sourceIndex]

                .permissions

        withAnimation(

            .easeInOut(duration: 0.18)

        ) {

            organization

                .locations[destinationIndex]

                .permissions =

                sourcePermissions

        }

    }

    private func copyPermissionsToAll(

        from sourceID: UUID

    ) {

        guard let sourceIndex =

            organization.locations.firstIndex(

                where: {

                    $0.id == sourceID

                }

            )

        else {

            return

        }

        let permissions =

            organization

                .locations[sourceIndex]

                .permissions

        withAnimation(

            .easeInOut(duration: 0.18)

        ) {

            for index in

                organization.locations.indices

            where

                organization.locations[index].id

                != sourceID

            {

                organization

                    .locations[index]

                    .permissions =

                    permissions

            }

        }

    }

}



// MARK: - Location

private struct LocationPermissionView: View {

    @Environment(PermissionStore.self) private var permissionStore
    @Binding var location: InviteLocation

    let otherLocations: [InviteLocation]

    let onCopyTo: (UUID) -> Void

    let onCopyToAll: () -> Void

    @State private var isEditorPresented = false

    var body: some View {

        locationHeader
            .sheet(isPresented: $isEditorPresented) {
            LocationPermissionEditor(location: $location, isPresented: $isEditorPresented)
        }

    }

    private var locationHeader: some View {

        HStack(spacing: 10) {

            VStack(alignment: .leading, spacing: 3) {

                Text(location.name)

                    .font(.subheadline.weight(.semibold))

                Text(location.grantedFeatureSummary)

                    .font(.caption)

                    .foregroundStyle(.secondary)

            }

            Spacer()

            Button {
                isEditorPresented = true
            } label: {
                LocationAccessPill(

                    summary:

                        location.accessSummary

                )

            }

            .buttonStyle(.plain)

            locationMenu

        }

        .padding(.horizontal, 16)

        .frame(minHeight: 70)

    }

    private var locationMenu: some View {

        Menu {

            if !otherLocations.isEmpty {

                Menu {

                    ForEach(

                        otherLocations

                    ) { destination in

                        Button(

                            destination.name

                        ) {

                            onCopyTo(

                                destination.id

                            )

                        }

                    }

                    if otherLocations.count > 1 {

                        Divider()

                        Button {

                            onCopyToAll()

                        } label: {

                            Label(

                                "All other locations",

                                systemImage:

                                    "square.on.square"

                            )

                        }

                    }

                } label: {

                    Label(

                        "Copy access to",

                        systemImage:

                            "doc.on.doc"

                    )

                }

            }

            Divider()

            Button {

                setAll(

                    .noAccess

                )

            } label: {

                Label(

                    "Remove all access",

                    systemImage:

                        "nosign"

                )

            }

        } label: {

            Image(

                systemName: "ellipsis"

            )

            .font(

                .body.weight(.semibold)

            )

            .foregroundStyle(.secondary)

            .frame(

                width: 34,

                height: 34

            )

            .contentShape(

                Rectangle()

            )

        }

        .tint(.secondary)

    }

    private var featureList: some View {

        VStack(spacing: 0) {

            ForEach(

                $location.permissions

            ) { $permission in

                FeaturePermissionRow(

                    permission: $permission

                )

            }

        }

        .background(

            Color(

                .tertiarySystemGroupedBackground

            ),

            in: RoundedRectangle(

                cornerRadius: 8,

                style: .continuous

            )

        )

        .clipShape(

            RoundedRectangle(

                cornerRadius: 8,

                style: .continuous

            )

        )

    }

    private func setAll(

        _ level: AccessLevel

    ) {

        withAnimation(

            .easeInOut(duration: 0.18)

        ) {

            for index in location.permissions.indices {
                location.permissions[index].access = level

                if let appPermission = AppPermission(
                    rawValue: location.permissions[index].feature.rawValue
                ) {
                    permissionStore.setAccess(
                        AppAccessLevel(rawValue: level.rawValue) ?? .full,
                        for: appPermission
                    )
                }
            }

        }

    }

}



// MARK: - Feature

private struct FeaturePermissionRow: View {

    @Environment(PermissionStore.self) private var permissionStore
    @Binding var permission: FeaturePermission

    var body: some View {

        HStack(spacing: 12) {

            VStack(

                alignment: .leading,

                spacing: 3

            ) {

                Text(

                    permission.feature.title

                )

                .font(

                    .subheadline.weight(.medium)

                )

                if let description =

                    permission.feature.description {

                    Text(description)

                        .font(.caption)

                        .foregroundStyle(

                            .secondary

                        )

                        .fixedSize(

                            horizontal: false,

                            vertical: true

                        )

                }

            }

            Spacer(minLength: 8)

            Menu {

                ForEach(

                    AccessLevel.allCases

                ) { level in

                    Button {

                        permission.access =

                            level

                        if let appPermission = AppPermission(rawValue: permission.feature.rawValue) {
                            permissionStore.setAccess(
                                AppAccessLevel(rawValue: level.rawValue) ?? .full,
                                for: appPermission
                            )
                        }

                    } label: {

                        Label(

                            level.title,

                            systemImage:

                                level ==

                                permission.access

                                ? "checkmark"

                                : level.systemImage

                        )

                    }

                }

            } label: {

                AccessLevelPill(

                    level:

                        permission.access,

                    includesChevron: true

                )

            }

        }

        .padding(.horizontal, 14)

        .padding(.vertical, 8)

        .frame(minHeight: 52)

    }

}



// MARK: - Access pills

private struct AccessLevelPill: View {

    let level: AccessLevel

    var includesChevron = false

    var body: some View {

        HStack(spacing: 6) {

            Text(level.title)

                .font(

                    .subheadline

                        .weight(.semibold)

                )

            if includesChevron {

                Image(

                    systemName:

                        "chevron.up.chevron.down"

                )

                .font(

                    .system(

                        size: 9,

                        weight: .bold

                    )

                )

            }

        }

        .foregroundStyle(

            level.color

        )

        .padding(

            .horizontal,

            12

        )

        .frame(height: 36)

        .background(

            level.color.opacity(0.12),

            in: Capsule()

        )

    }

}

private struct LocationAccessPill: View {

    let summary: LocationAccessSummary

    var body: some View {

        HStack(spacing: 6) {

            Image(systemName: summary.systemImage)

                .font(.caption.weight(.semibold))

            Text(summary.title)

                .lineLimit(1)

            Image(systemName: "chevron.up.chevron.down")

                .font(.caption2.weight(.bold))

        }

        .font(.subheadline.weight(.semibold))

        .foregroundStyle(summary.color)

        .padding(.horizontal, 12)

        .frame(height: 36)

        .background(

            summary.color.opacity(0.12),

            in: Capsule()

        )

        .accessibilityLabel("\(summary.title), select access")

    }

}



// MARK: - Text field

private struct InviteTextField: View {

    let title: String

    let placeholder: String

    @Binding var text: String

    let keyboardType: UIKeyboardType

    let textContentType: UITextContentType?

    var body: some View {

        VStack(

            alignment: .leading,

            spacing: 8

        ) {

            HStack(spacing: 3) {

                Text(title)

                    .font(

                        .subheadline

                            .weight(.semibold)

                    )

                Text("*")

                    .foregroundStyle(.red)

            }

            TextField(

                placeholder,

                text: $text

            )

            .keyboardType(

                keyboardType

            )

            .textContentType(

                textContentType

            )

            .textInputAutocapitalization(

                keyboardType == .emailAddress

                ? .never

                : .words

            )

            .autocorrectionDisabled(

                keyboardType == .emailAddress

            )

            .padding(

                .horizontal,

                14

            )

            .frame(height: 52)

            .background(

                Color(

                    .secondarySystemGroupedBackground

                ),

                in: RoundedRectangle(

                    cornerRadius: 12,

                    style: .continuous

                )

            )

        }

    }

}



// MARK: - Team member row

struct TeamMemberRow: View {

    let member: TeamMember

    let avatarDiameter: CGFloat

    init(member: TeamMember, avatarDiameter: CGFloat = 38) {

        self.member = member

        self.avatarDiameter = avatarDiameter

    }

    var body: some View {

        HStack(spacing: 14) {

            Text(member.email.prefix(1).uppercased())

                .font(

                    avatarDiameter > 38

                    ? .headline.weight(.bold)

                    : .subheadline.weight(.bold)

                )

                .foregroundStyle(.blue)

                .frame(

                    width: avatarDiameter,

                    height: avatarDiameter

                )

                .background(

                    .blue.opacity(0.12),

                    in: Circle()

                )

            VStack(

                alignment: .leading,

                spacing: 3

            ) {

                Text(member.email)

                    .font(.subheadline)

                    .lineLimit(1)

                    .truncationMode(.tail)

                    .foregroundStyle(

                        .primary

                    )

                Text("\(member.locationCount) locations")

                    .font(.subheadline)

                    .foregroundStyle(

                        .secondary

                    )

            }

            Spacer()

            TeamMemberStatusChip(status: member.status)

            Image(

                systemName: "chevron.right"

            )

            .font(

                .caption.weight(.semibold)

            )

            .foregroundStyle(

                .tertiary

            )

        }

        .padding(

            .horizontal,

            16

        )

        .frame(minHeight: 62)

        .contentShape(

            Rectangle()

        )

    }

}



// MARK: - Existing member

struct TeamMemberView: View {

    @Environment(\.dismiss) private var dismiss

    @Binding var member: TeamMember

    let onRemoveInvite: (() -> Void)?

    @State private var organizations: [InviteOrganization] = [.northstar]

    @State private var availableOrganizations: [InviteOrganization] = [

        .atlas,

        .summit

    ]

    init(

        member: Binding<TeamMember>,

        onRemoveInvite: (() -> Void)? = nil

    ) {

        _member = member

        self.onRemoveInvite = onRemoveInvite

    }

    var body: some View {

        ScrollView {

            VStack(alignment: .leading, spacing: 28) {

                TeamMemberDetailsSection(

                    email: $member.email

                )

                TeamMemberStatusSection(

                    status: $member.status,

                    onRemoveInvite: removeInvite

                )

                Divider()

                TeamMemberPermissionsSection(

                    organizations: $organizations,

                    availableOrganizations: availableOrganizations,

                    onAddOrganization: addOrganization,

                    onDeleteOrganization: removeOrganization

                )
                .disabled(member.status == .inactive)
                .opacity(member.status == .inactive ? 0.45 : 1)
                .animation(
                    .easeInOut(duration: 0.2),
                    value: member.status
                )

            }

            .padding(.horizontal, 20)

            .padding(.top, 20)

            .padding(.bottom, 70)

        }

        .background(Color(.systemGroupedBackground))

        .navigationTitle(

            member.email

        )

        .navigationBarTitleDisplayMode(.inline)

    }

    private func addOrganization(_ organization: InviteOrganization) {

        withAnimation(.easeInOut(duration: 0.2)) {

            organizations.append(organization)

            availableOrganizations.removeAll { $0.id == organization.id }

        }

    }

    private func removeOrganization(_ id: UUID) {

        guard let index = organizations.firstIndex(where: { $0.id == id }) else {

            return

        }

        let organization = organizations[index]

        withAnimation(.easeInOut(duration: 0.2)) {

            organizations.remove(at: index)

            availableOrganizations.append(organization)

        }

    }

    private func removeInvite() {

        onRemoveInvite?()

        dismiss()

    }

}



private struct TeamMemberDetailsSection: View {

    @Binding var email: String

    var body: some View {

        VStack(alignment: .leading, spacing: 8) {

            InviteTextField(

                title: "Email",

                placeholder: "name@company.com",

                text: $email,

                keyboardType: .emailAddress,

                textContentType: .emailAddress

            )

            Text("They’ll receive an email to set their password and use this email to sign in.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }

    }

}

private struct TeamMemberStatusSection: View {

    @Binding var status: TeamMemberStatus

    let onRemoveInvite: () -> Void

    private var isActive: Binding<Bool> {

        Binding(

            get: {

                status == .active

            },

            set: { newValue in

                status = newValue ? .active : .inactive

            }

        )

    }

    var body: some View {

        VStack(alignment: .leading, spacing: 8) {

            HStack {

                Text("Status")

                    .font(.subheadline.weight(.semibold))

                Spacer()

                if status == .invited {

                    Text("Invited")

                        .foregroundStyle(.secondary)

                } else {

                    HStack(spacing: 10) {

                        Text(status == .active ? "Active" : "Inactive")

                            .foregroundStyle(.secondary)

                        Toggle("", isOn: isActive)

                            .labelsHidden()

                    }

                }

            }

            Text(status.description)

                .font(.footnote)

                .foregroundStyle(.secondary)

            if status == .invited {

                Button(role: .destructive) {

                    HapticFeedback.criticalAction()

                    onRemoveInvite()

                } label: {

                    Label(
                        "Remove invite",
                        systemImage: "person.crop.circle.badge.xmark"
                    )
                    .font(.subheadline.weight(.semibold))
                    .padding(.horizontal, 4)
                    .frame(minHeight: 34)

                }
                .buttonStyle(.glass)
                .buttonBorderShape(.capsule)
                .tint(.red)

            }

        }

    }

}

private struct TeamMemberStatusChip: View {

    let status: TeamMemberStatus

    var body: some View {

        Text(status.title)

            .font(.caption.weight(.semibold))

            .foregroundStyle(status.foregroundColor)

            .padding(.horizontal, 9)

            .padding(.vertical, 5)

            .background(status.backgroundColor, in: Capsule())

    }

}



private struct TeamMemberPermissionsSection: View {

    @Binding var organizations: [InviteOrganization]

    let availableOrganizations: [InviteOrganization]

    let onAddOrganization: (InviteOrganization) -> Void

    let onDeleteOrganization: (UUID) -> Void

    @State private var isPermissionCopyPresented = false

    var body: some View {

        VStack(alignment: .leading, spacing: 16) {

            HStack {

                Text("Permissions")

                    .font(.title3.weight(.bold))

                Spacer()

                if !availableOrganizations.isEmpty {

                    Menu {

                        ForEach(availableOrganizations) { organization in

                            Button {

                                onAddOrganization(organization)

                            } label: {

                                Label(

                                    organization.name,

                                    systemImage: "building.2"

                                )

                            }

                        }

                    } label: {

                        Label(

                            "Add org",

                            systemImage: "plus"

                        )

                    }

                    .buttonStyle(.glass)

                    .buttonBorderShape(.capsule)

                }

                Menu {

                    Button {

                        isPermissionCopyPresented = true

                    } label: {

                        Label(

                            "Copy another user's permissions",

                            systemImage: "person.2"

                        )

                    }

                } label: {

                    Image(systemName: "ellipsis")

                        .frame(width: 24, height: 24)

                }

                .buttonStyle(.glass)

                .buttonBorderShape(.circle)

            }

            if organizations.isEmpty {

                ContentUnavailableView(

                    "No organizations",

                    systemImage: "building.2",

                    description: Text(

                        "Add an organization to configure access."

                    )

                )

                .frame(maxWidth: .infinity)

                .padding(.vertical, 32)

            } else {

                VStack(spacing: 12) {

                    ForEach($organizations) { $organization in

                        OrganizationPermissionCard(

                            organization: $organization,

                            onDelete: {

                                onDeleteOrganization(organization.id)

                            }

                        )

                    }

                }

            }

        }

        .sheet(isPresented: $isPermissionCopyPresented) {

            PermissionCopyUserDrawer { source in

                organizations = source.organizations

                isPermissionCopyPresented = false

            }

        }

    }

}



private struct PermissionCopyUserDrawer: View {

    @Environment(\.dismiss) private var dismiss

    @State private var searchText = ""

    let onCopy: (PermissionCopySource) -> Void

    private var matchingUsers: [PermissionCopySource] {

        guard !searchText.isEmpty else {

            return PermissionCopySource.examples

        }

        return PermissionCopySource.examples.filter {

            $0.email.localizedCaseInsensitiveContains(searchText)

        }

    }

    var body: some View {

        NavigationStack {

            List(matchingUsers) { user in

                Button {

                    onCopy(user)

                    dismiss()

                } label: {

                    HStack(spacing: 12) {

                        Text(user.email.prefix(1).uppercased())

                            .font(.subheadline.weight(.bold))

                            .foregroundStyle(.blue)

                            .frame(width: 38, height: 38)

                            .background(.blue.opacity(0.12), in: Circle())

                        VStack(alignment: .leading, spacing: 3) {

                            Text(user.email)

                                .foregroundStyle(.primary)

                            Text("\(user.locationCount) locations")

                                .font(.subheadline)

                                .foregroundStyle(.secondary)

                        }

                    }

                }

                .buttonStyle(.plain)

            }

            .navigationTitle("Copy permissions")

            .navigationBarTitleDisplayMode(.inline)

            .searchable(text: $searchText, prompt: "Search users")

            .toolbar {

                ToolbarItem(placement: .cancellationAction) {

                    Button("Cancel") {

                        dismiss()

                    }

                }

            }

        }

    }

}



// MARK: - Models

struct TeamMember: Identifiable {

    let id: UUID

    var email: String

    var locationCount: Int

    var status: TeamMemberStatus

    init(

        id: UUID = UUID(),

        email: String,

        locationCount: Int,

        status: TeamMemberStatus

    ) {

        self.id = id

        self.email = email

        self.locationCount = locationCount

        self.status = status

    }

    static let unavailable = TeamMember(

        email: "",

        locationCount: 0,

        status: .inactive

    )

}



enum TeamMemberStatus: Hashable {

    case invited

    case active

    case inactive

    var title: LocalizedStringResource {

        switch self {

        case .invited:

            "Invited"

        case .active:

            "Active"

        case .inactive:

            "Inactive"

        }

    }

    var foregroundColor: Color {

        switch self {

        case .invited:

            .orange

        case .active:

            .blue

        case .inactive:

            .gray

        }

    }

    var backgroundColor: Color {

        switch self {

        case .invited:

            .orange.opacity(0.18)

        case .active:

            .blue.opacity(0.14)

        case .inactive:

            .gray.opacity(0.16)

        }

    }

    var sortOrder: Int {

        switch self {

        case .invited:

            0

        case .active:

            1

        case .inactive:

            2

        }

    }

    var description: LocalizedStringResource {

        switch self {

        case .invited:

            "This invitation must be removed before the user's status can change."

        case .active:

            "Active users can log in to the system."

        case .inactive:

            "Inactive users cannot log in to the system."

        }

    }

}



private struct PermissionCopySource: Identifiable {

    let id = UUID()

    let email: String

    let organizations: [InviteOrganization]

    var locationCount: Int {

        organizations.reduce(0) { count, organization in

            count + organization.locations.filter(\.hasGrantedAccess).count

        }

    }

    static let examples = [

        PermissionCopySource(

            email: "maya.chen@northstar.com",

            organizations: [.northstar, .atlas]

        ),

        PermissionCopySource(

            email: "daniel.brooks@northstar.com",

            organizations: [.northstar]

        ),

        PermissionCopySource(

            email: "james.wilson@northstar.com",

            organizations: [.summit]

        )

    ]

}



private struct InviteOrganization: Identifiable {

    let id: UUID

    let name: String

    var locations: [InviteLocation]

    init(

        id: UUID = UUID(),

        name: String,

        locations: [InviteLocation]

    ) {

        self.id = id

        self.name = name

        self.locations = locations

    }

}

struct InviteLocation: Identifiable {

    let id: UUID

    let name: String

    var permissions: [FeaturePermission]
    var selectedPreset: PermissionPreset
    var tenantOrganizations = ["Atlas Distribution", "Fenix Freight"]

    init(

        id: UUID = UUID(),

        name: String,

        preset: PermissionPreset = .employee

    ) {

        self.id = id

        self.name = name
        self.selectedPreset = preset

        self.permissions =

            PermissionFeature.allCases.map {

                FeaturePermission(

                    feature: $0,

                    access:

                        preset.access(

                            for: $0

                        )

                )

            }

    }

    var grantedFeatureCount: Int {

        permissions.filter { $0.access != .noAccess }.count

    }

    var hasGrantedAccess: Bool {

        grantedFeatureCount > 0

    }

    var grantedFeatureSummary: String {

        grantedFeatureCount == 1

            ? "1 feature"

            : "\(grantedFeatureCount) features"

    }

    var accessSummary: LocationAccessSummary {
        switch selectedPreset {
        case .admin:
            .admin
        case .edit, .manager:
            .edit
        case .view:
            .view
        case .noAccess:
            .noAccess
        case .tenant:
            .tenant
        case .custom, .employee:
            .custom
        }
    }

    mutating func applyPreset(

        _ preset: PermissionPreset

    ) {

        selectedPreset = preset

        guard preset != .custom else {
            return
        }

        for index in

            permissions.indices

        {

            let feature =

                permissions[index]

                    .feature

            permissions[index]

                .access =

                preset.access(

                    for: feature

                )

        }

    }

}

struct FeaturePermission: Identifiable {

    let id: PermissionFeature

    let feature: PermissionFeature

    var access: AccessLevel

    init(

        feature: PermissionFeature,

        access: AccessLevel

    ) {

        self.id = feature

        self.feature = feature

        self.access = access

    }

}



// MARK: - Access level

enum AccessLevel:

    String,

    CaseIterable,

    Identifiable {

    case noAccess

    case view

    case full

    var id: String {

        rawValue

    }

    var title: String {

        switch self {

        case .noAccess:

            "No access"

        case .view:

            "View access"

        case .full:

            "Full access"

        }

    }

    var systemImage: String {

        switch self {

        case .noAccess:

            "nosign"

        case .view:

            "eye"

        case .full:

            "checkmark.circle.fill"

        }

    }

    var color: Color {

        switch self {

        case .noAccess:

            .secondary

        case .view:

            .cyan

        case .full:

            .blue

        }

    }

}

enum LocationAccessSummary {

    case noAccess

    case view

    case full

    case admin

    case edit

    case tenant

    case custom

    var title: String {

        switch self {

        case .noAccess:

            "No access"

        case .view:

            "View access"

        case .full:

            "Full access"

        case .admin:

            "Admin access"

        case .edit:

            "Edit access"

        case .tenant:

            "Tenant access"

        case .custom:

            "Custom access"

        }

    }

    var systemImage: String {

        switch self {

        case .noAccess:

            "nosign"

        case .view:

            "eye"

        case .full:

            "checkmark.circle.fill"

        case .admin:

            "person.badge.key"

        case .edit:

            "pencil"

        case .tenant:

            "building.2"

        case .custom:

            "slider.horizontal.3"

        }

    }

    var color: Color {

        switch self {

        case .noAccess:

            .secondary

        case .view:

            .cyan

        case .full:

            .blue

        case .admin:

            .blue

        case .edit:

            .blue

        case .tenant:

            .indigo

        case .custom:

            .brown

        }

    }

}



// MARK: - Features

enum PermissionFeature:

    String,

    CaseIterable,

    Identifiable {

    case accessPointRecords

    case appointments

    case authorizedPeople

    case authorizedOrganizations

    case authorizedEquipment

    case inventoryList

    case inventoryCheck

    case requestTickets

    case usersAndPermissions

    case equipment

    case accessPointRecordsMedia

    var id: String {

        rawValue

    }

    var title: String {

        switch self {

        case .accessPointRecords:

            "Activity"

        case .appointments:

            "Appointments"

        case .authorizedPeople:

            "Authorized People"

        case .authorizedOrganizations:

            "Authorized Organizations"

        case .authorizedEquipment:

            "Authorized Equipment"

        case .inventoryList:

            "Inventory List"

        case .inventoryCheck:

            "Inventory Check"

        case .requestTickets:

            "Request Tickets"

        case .usersAndPermissions:

            "Users and Permissions"

        case .equipment:

            "Equipment"

        case .accessPointRecordsMedia:

            "Activity Media"

        }

    }

    var description: String? {

        switch self {

        case .usersAndPermissions:

            "Add and remove users and manage their permissions."

        default:

            nil

        }

    }

}



// MARK: - Presets

enum PermissionPreset: CaseIterable, Identifiable {

    case admin

    case manager

    case employee
    case edit
    case view
    case noAccess
    case tenant
    case custom

    var id: Self { self }

    func access(

        for feature: PermissionFeature

    ) -> AccessLevel {

        switch self {

        case .noAccess, .custom:
            return .noAccess

        case .view:
            return .view

        case .edit:
            return feature == .usersAndPermissions ? .noAccess : .full

        case .tenant:
            switch feature {
            case .authorizedPeople, .authorizedOrganizations, .authorizedEquipment, .appointments:
                return .view
            case .accessPointRecords, .accessPointRecordsMedia:
                return .view
            default:
                return .noAccess
            }

        case .admin:

            return .full

        case .manager:

            switch feature {

            case .usersAndPermissions:

                return .view

            default:

                return .full

            }

        case .employee:

            switch feature {

            case .accessPointRecords,

                 .appointments,

                 .authorizedPeople,

                 .authorizedOrganizations,

                 .authorizedEquipment,

                 .inventoryList,

                 .equipment:

                return .view

            case .inventoryCheck,

                 .requestTickets:

                return .full

            case .usersAndPermissions,

                 .accessPointRecordsMedia:

                return .noAccess

            }

        }

    }

}



// MARK: - Mock organizations

private extension InviteOrganization {

    static let northstar =

        InviteOrganization(

            name:

                "Northstar Logistics",

            locations: [

                InviteLocation(

                    name:

                        "Northstar (Oshawa)",

                    preset:

                        .manager

                ),

                InviteLocation(

                    name:

                        "Northstar (Dallas)",

                    preset:

                        .admin

                ),

                InviteLocation(

                    name:

                        "Northstar (Toronto)",

                    preset:

                        .noAccess

                )

            ]

        )

    static let atlas =

        InviteOrganization(

            name:

                "Atlas Distribution",

            locations: [

                InviteLocation(

                    name:

                        "Atlas (Chicago)",

                    preset:

                        .employee

                ),

                InviteLocation(

                    name:

                        "Atlas (Detroit)",

                    preset:

                        .employee

                )

            ]

        )

    static let summit =

        InviteOrganization(

            name:

                "Summit Transport",

            locations: [

                InviteLocation(

                    name:

                        "Summit (Buffalo)",

                    preset:

                        .employee

                ),

                InviteLocation(

                    name:

                        "Summit (Cleveland)",

                    preset:

                        .employee

                ),

                InviteLocation(

                    name:

                        "Summit (Columbus)",

                    preset:

                        .employee

                )

            ]

        )

}



#Preview {

    TeamView()

}
