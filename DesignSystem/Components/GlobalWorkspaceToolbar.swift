import SwiftUI

struct GlobalWorkspaceToolbar: ToolbarContent {
    var body: some ToolbarContent {
        ToolbarItemGroup(placement: .topBarTrailing) {
            NavigationLink {
                RequestsView()
            } label: {
                Label("Requests", systemImage: "envelope")
                    .overlay(alignment: .topTrailing) {
                        Circle()
                            .fill(.blue)
                            .frame(width: 8, height: 8)
                            .overlay {
                                Circle()
                                    .stroke(Color(.systemBackground), lineWidth: 1.5)
                            }
                            .offset(x: 3, y: -3)
                    }
            }
            .foregroundStyle(Color.controlForeground)
            .tint(Color.controlForeground)
            .accessibilityLabel("Requests")
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
