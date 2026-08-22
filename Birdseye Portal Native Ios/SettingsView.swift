import SwiftUI

struct SettingsView: View {
    @Binding var flow: AppFlow

    var body: some View {
        NavigationStack {
            Form {
                Section("Account") {
                    Label("Profile", systemImage: "person.crop.circle")
                    Label("Organization", systemImage: "building.2")
                }

                Section("Preferences") {
                    Label("Notifications", systemImage: "bell")
                    Label("Appearance", systemImage: "circle.lefthalf.filled")
                    Label("Default location", systemImage: "mappin.and.ellipse")
                }

                Section("Security") {
                    Label("Security", systemImage: "lock")
                    Label("Privacy", systemImage: "hand.raised")
                }

                Section("Support") {
                    Label("Help", systemImage: "questionmark.circle")
                    Label("About", systemImage: "info.circle")
                }

                Section {
                    Button("Sign Out", role: .destructive) {
                        flow = .login
                    }
                }
            }
            .navigationTitle("Settings")
        }
        .safeAreaInset(edge: .top, spacing: 0) {
            BirdseyeHeader()
        }
    }
}

#Preview {
    SettingsView(flow: .constant(.main))
}
