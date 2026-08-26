import SwiftUI

struct GlobalWorkspaceToolbar: ToolbarContent {
    var body: some ToolbarContent {
        ToolbarItemGroup(placement: .topBarTrailing) {
            NavigationLink {
                NotificationsView()
            } label: {
                Label("Notifications", systemImage: "bell")
            }
            .foregroundStyle(Color.controlForeground)
            .tint(Color.controlForeground)
            .accessibilityLabel("Notifications")
            .simultaneousGesture(TapGesture().onEnded {
                HapticFeedback.lightImpact()
            })

            NavigationLink {
                HelpView()
            } label: {
                Label("Help", systemImage: "questionmark.circle")
            }
            .foregroundStyle(Color.controlForeground)
            .tint(Color.controlForeground)
            .accessibilityLabel("Help")
            .simultaneousGesture(TapGesture().onEnded {
                HapticFeedback.lightImpact()
            })
        }
    }
}
