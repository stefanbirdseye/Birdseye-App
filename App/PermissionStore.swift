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
    func permissionProtected(_ permission: AppPermission) -> some View {
        modifier(PermissionProtectionModifier(permission: permission))
    }
}

private struct PermissionProtectionModifier: ViewModifier {
    @Environment(PermissionStore.self) private var permissionStore

    let permission: AppPermission

    func body(content: Content) -> some View {
        switch permissionStore.access(for: permission) {
        case .full:
            content
        case .view:
            content
                .disabled(true)
                .safeAreaInset(edge: .bottom) {
                    ViewOnlyPermissionNotice(
                        onRestoreAccess: permissionStore.restoreFullAccess
                    )
                    .padding(.horizontal, 16)
                    .padding(.bottom, 8)
                }
        case .noAccess:
            PermissionDeniedView(
                onRestoreAccess: permissionStore.restoreFullAccess
            )
        }
    }
}

private struct PermissionDeniedView: View {
    let onRestoreAccess: () -> Void

    var body: some View {
        ContentUnavailableView {
            Label("You don’t have permission to view this page", systemImage: "lock.fill")
        } description: {
            Text("Contact your organization administrator if you need access to this feature.")
        } actions: {
            Button("Restore demo access", action: onRestoreAccess)
                .buttonStyle(.borderedProminent)
        }
    }
}

private struct ViewOnlyPermissionNotice: View {
    let onRestoreAccess: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("View-only access", systemImage: "eye.fill")
                .font(.subheadline.weight(.semibold))

            Text("You can review this page, but you don’t have permission to make changes. Contact your organization administrator if you need edit access.")

            Button("Restore demo access", action: onRestoreAccess)
                .font(.subheadline.weight(.semibold))
        }
        .font(.footnote)
        .foregroundStyle(.primary)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.blue.opacity(0.25), lineWidth: 1)
        }
    }
}
