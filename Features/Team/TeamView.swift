import SwiftUI

import UIKit

struct TeamView: View {

    @Environment(SnackbarCenter.self) private var snackbarCenter

    @State private var isInvitePresented = false

    @State private var members = [

        TeamMember(

            username: "maya.chen",

            email: "maya.chen@northstar.com",

            locationCount: 12,

            status: .active

        ),

        TeamMember(

            username: "daniel.brooks",

            email: "daniel.brooks@northstar.com",

            locationCount: 8,

            status: .active

        ),

        TeamMember(

            username: "sarah.patel",

            email: "sarah.patel@northstar.com",

            locationCount: 4,

            status: .inactive

        ),

        TeamMember(

            username: "james.wilson",

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

                    Button {

                        isInvitePresented = true

                    } label: {

                        Label(

                            "Invite member",

                            systemImage: "person.badge.plus"

                        )

                        .frame(

                            maxWidth: .infinity,

                            minHeight: 40

                        )

                    }

                    .buttonStyle(.glassProminent)

                    .buttonBorderShape(.capsule)

                    .tint(.blue)

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

                InviteTeamMemberView { email, username, locationCount in

                    members.append(

                        TeamMember(

                            username: username,

                            email: email,

                            locationCount: locationCount,

                            status: .invited

                        )

                    )

                    snackbarCenter.show("Invitation sent to \(email).")

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



// MARK: - Invite member

private struct InviteTeamMemberView: View {

    @Environment(\.dismiss) private var dismiss

    let onInvite: (String, String, Int) -> Void

    @State private var email = ""

    @State private var username = ""

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

        &&

        !username

            .trimmingCharacters(

                in: .whitespacesAndNewlines

            )

            .isEmpty

    }

    private var locationCount: Int {

        organizations.reduce(0) { count, organization in

            count + organization.locations.count

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

        TeamMemberDetailsSection(email: $email, username: $username)

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

        onInvite(email, username, locationCount)

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

                Text(locationNames)

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

    private var locationNames: String {

        organization.locations

            .map(\.name)

            .joined(separator: ", ")

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

    @Binding var location: InviteLocation

    let otherLocations: [InviteLocation]

    let onCopyTo: (UUID) -> Void

    let onCopyToAll: () -> Void

    @State private var isExpanded = false

    var body: some View {

        VStack(spacing: 0) {

            locationHeader

            if isExpanded {

                featureList

                    .padding(.horizontal, 12)

                    .padding(.bottom, 12)

                    .transition(.opacity)

            }

        }

    }

    private var locationHeader: some View {

        HStack(spacing: 10) {

            Button {

                withAnimation(

                    .easeInOut(duration: 0.2)

                ) {

                    isExpanded.toggle()

                }

            } label: {

                HStack(spacing: 12) {

                    VStack(

                        alignment: .leading,

                        spacing: 3

                    ) {

                        Text(location.name)

                            .font(

                                .subheadline

                                    .weight(.semibold)

                            )

                            .foregroundStyle(

                                .primary

                            )

                        Text(

                            "\(location.permissions.count) features"

                        )

                        .font(.caption)

                        .foregroundStyle(

                            .secondary

                        )

                    }

                    Spacer()

                    Image(

                        systemName:

                            isExpanded

                            ? "chevron.up"

                            : "chevron.down"

                    )

                    .font(

                        .caption.weight(.semibold)

                    )

                    .foregroundStyle(

                        .secondary

                    )

                }

                .contentShape(

                    Rectangle()

                )

            }

            .buttonStyle(.plain)

            LocationAccessPill(

                summary:

                    location.accessSummary

            )

            locationMenu

        }

        .padding(.horizontal, 16)

        .frame(minHeight: 70)

    }

    private var locationMenu: some View {

        Menu {

            Menu {

                Button {

                    applyPreset(.admin)

                } label: {

                    Label(

                        "Admin",

                        systemImage:

                            "person.badge.key"

                    )

                }

                Button {

                    applyPreset(.manager)

                } label: {

                    Label(

                        "Manager",

                        systemImage:

                            "person.crop.circle.badge.checkmark"

                    )

                }

                Button {

                    applyPreset(.employee)

                } label: {

                    Label(

                        "Employee",

                        systemImage: "person"

                    )

                }

            } label: {

                Label(

                    "Apply preset",

                    systemImage:

                        "slider.horizontal.3"

                )

            }

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

    private func applyPreset(

        _ preset: PermissionPreset

    ) {

        withAnimation(

            .easeInOut(duration: 0.18)

        ) {

            location.applyPreset(

                preset

            )

        }

    }

    private func setAll(

        _ level: AccessLevel

    ) {

        withAnimation(

            .easeInOut(duration: 0.18)

        ) {

            for index in

                location.permissions.indices

            {

                location

                    .permissions[index]

                    .access =

                    level

            }

        }

    }

}



// MARK: - Feature

private struct FeaturePermissionRow: View {

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

        Text(summary.title)

            .font(

                .subheadline

                    .weight(.semibold)

            )

            .foregroundStyle(

                summary.color

            )

            .padding(

                .horizontal,

                12

            )

            .frame(height: 36)

            .background(

                summary.color.opacity(0.12),

                in: Capsule()

            )

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

            Text(member.username.prefix(1).uppercased())

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

                Text(member.username)

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

                    email: $member.email,

                    username: $member.username

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

            member.username

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

    @Binding var username: String

    var body: some View {

        VStack(spacing: 18) {

            InviteTextField(

                title: "Email",

                placeholder: "name@company.com",

                text: $email,

                keyboardType: .emailAddress,

                textContentType: .emailAddress

            )

            InviteTextField(

                title: "Username",

                placeholder: "username",

                text: $username,

                keyboardType: .default,

                textContentType: .username

            )

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

            $0.username.localizedCaseInsensitiveContains(searchText)

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

                        Text(user.username.prefix(1).uppercased())

                            .font(.subheadline.weight(.bold))

                            .foregroundStyle(.blue)

                            .frame(width: 38, height: 38)

                            .background(.blue.opacity(0.12), in: Circle())

                        VStack(alignment: .leading, spacing: 3) {

                            Text(user.username)

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

    var username: String

    var email: String

    var locationCount: Int

    var status: TeamMemberStatus

    init(

        id: UUID = UUID(),

        username: String,

        email: String,

        locationCount: Int,

        status: TeamMemberStatus

    ) {

        self.id = id

        self.username = username

        self.email = email

        self.locationCount = locationCount

        self.status = status

    }

    static let unavailable = TeamMember(

        username: "Unavailable",

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

    let username: String

    let organizations: [InviteOrganization]

    var locationCount: Int {

        organizations.reduce(0) { count, organization in

            count + organization.locations.count

        }

    }

    static let examples = [

        PermissionCopySource(

            username: "maya.chen",

            organizations: [.northstar, .atlas]

        ),

        PermissionCopySource(

            username: "daniel.brooks",

            organizations: [.northstar]

        ),

        PermissionCopySource(

            username: "james.wilson",

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

private struct InviteLocation: Identifiable {

    let id: UUID

    let name: String

    var permissions: [FeaturePermission]

    init(

        id: UUID = UUID(),

        name: String,

        preset: PermissionPreset = .employee

    ) {

        self.id = id

        self.name = name

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

    var accessSummary: LocationAccessSummary {

        let values =

            permissions.map(

                \.access

            )

        guard !values.isEmpty else {

            return .noAccess

        }

        if values.allSatisfy({

            $0 == .full

        }) {

            return .full

        }

        if values.allSatisfy({

            $0 == .view

        }) {

            return .view

        }

        if values.allSatisfy({

            $0 == .noAccess

        }) {

            return .noAccess

        }

        return .custom

    }

    mutating func applyPreset(

        _ preset: PermissionPreset

    ) {

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

private struct FeaturePermission: Identifiable {

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

private enum AccessLevel:

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

private enum LocationAccessSummary {

    case noAccess

    case view

    case full

    case custom

    var title: String {

        switch self {

        case .noAccess:

            "No access"

        case .view:

            "View access"

        case .full:

            "Full access"

        case .custom:

            "Custom access"

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

        case .custom:

            .brown

        }

    }

}



// MARK: - Features

private enum PermissionFeature:

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

private enum PermissionPreset {

    case admin

    case manager

    case employee

    func access(

        for feature: PermissionFeature

    ) -> AccessLevel {

        switch self {

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

                        .employee

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
