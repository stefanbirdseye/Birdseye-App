import Observation
import SwiftUI

enum AppPermission: String, CaseIterable, Hashable {
    case activity = "accessPointRecords"
    case appointments
    case authorizedPeople
    case authorizedOrganizations
    case authorizedEquipment
    case inventoryList
    case inventoryCheck
    case requestTickets
    case usersAndPermissions
    case equipment
    case activityMedia = "accessPointRecordsMedia"

    var pageTitle: String {
        switch self {
        case .activity:
            "Activity"
        case .appointments:
            "Appointments"
        case .authorizedPeople:
            "Authorized people"
        case .authorizedOrganizations:
            "Authorized organizations"
        case .authorizedEquipment:
            "Authorized equipment"
        case .inventoryList:
            "Inventory"
        case .inventoryCheck:
            "Inventory check"
        case .requestTickets:
            "Requests"
        case .usersAndPermissions:
            "Team"
        case .equipment:
            "Equipment"
        case .activityMedia:
            "Activity media"
        }
    }
}

enum AppAccessLevel: String, Equatable {
    case noAccess
    case view
    case full
}

@MainActor
@Observable
final class PermissionStore {
    private var accessByPermission: [AppPermission: AppAccessLevel] = [:]

    func access(for permission: AppPermission) -> AppAccessLevel {
        accessByPermission[permission] ?? .full
    }

    func setAccess(_ access: AppAccessLevel, for permission: AppPermission) {
        accessByPermission[permission] = access
    }

    func restoreFullAccess() {
        accessByPermission = [:]
    }
}

extension View {
    func permissionProtected(
        _ permission: AppPermission,
        pageTitle: String? = nil,
        onGoToBirdseyeAI: (() -> Void)? = nil
    ) -> some View {
        modifier(
            PermissionProtectionModifier(
                permission: permission,
                pageTitle: pageTitle,
                onGoToBirdseyeAI: onGoToBirdseyeAI
            )
        )
    }

    func permissionReadOnlyEditor(_ permission: AppPermission) -> some View {
        modifier(PermissionReadOnlyEditorModifier(permission: permission))
    }
}

private struct PermissionProtectionModifier: ViewModifier {
    @Environment(PermissionStore.self) private var permissionStore

    let permission: AppPermission
    let pageTitle: String?
    let onGoToBirdseyeAI: (() -> Void)?

    func body(content: Content) -> some View {
        switch permissionStore.access(for: permission) {
        case .full, .view:
            content
        case .noAccess:
            PermissionDeniedView(
                pageTitle: pageTitle,
                permissionTitle: permission.pageTitle,
                onGoToBirdseyeAI: onGoToBirdseyeAI,
                onRestoreAccess: permissionStore.restoreFullAccess
            )
        }
    }
}

private struct PermissionDeniedView: View {
    let pageTitle: String?
    let permissionTitle: String
    let onGoToBirdseyeAI: (() -> Void)?
    let onRestoreAccess: () -> Void

    var body: some View {
        if let pageTitle {
            NavigationStack {
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        BirdseyePageTitle(title: pageTitle)
                            .padding(.top, 16)

                        unavailableContent
                            .frame(maxWidth: .infinity, minHeight: 440)
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 70)
                }
                .background(Color(.systemGroupedBackground))
                .birdseyeMainTabPage()
            }
        } else {
            unavailableContent
        }
    }

    @ViewBuilder
    private var unavailableContent: some View {
        ContentUnavailableView {
            Label(
                "You don’t have permission to see \"\(permissionTitle)\" page",
                systemImage: "lock.fill"
            )
        } description: {
            Text("Contact your organization administrator if you need access to this feature.")
        } actions: {
            if let onGoToBirdseyeAI {
                Button("Go to home", action: onGoToBirdseyeAI)
                    .buttonStyle(.glassProminent)
                    .tint(.blue)
                    .controlSize(.large)
            }

            Button("Restore demo access", action: onRestoreAccess)
                .buttonStyle(.plain)
                .foregroundStyle(.blue)
        }
    }
}

private struct PermissionReadOnlyEditorModifier: ViewModifier {
    @Environment(PermissionStore.self) private var permissionStore

    let permission: AppPermission

    func body(content: Content) -> some View {
        let isReadOnly = permissionStore.access(for: permission) == .view

        content
            .disabled(isReadOnly)
            .safeAreaInset(edge: .top, spacing: 0) {
                if isReadOnly {
                    Label(
                        "View-only access — contact your organization administrator to make changes.",
                        systemImage: "eye.fill"
                    )
                    .font(.footnote.weight(.medium))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color(.secondarySystemBackground))
                }
            }
    }
}
