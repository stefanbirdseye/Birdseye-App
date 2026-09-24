import SwiftUI

struct ProfileView: View {

    @Binding var flow: AppFlow
    @Binding var showSettings: Bool
    let onRestartOnboarding: () -> Void
    @State private var currentMember = TeamMember(
        username: "maya.chen",
        email: "maya.chen@northstar.com",
        locationCount: 12,
        status: .active
    )

    var body: some View {
        NavigationStack {

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {

                    BirdseyePageTitle(title: "Profile")
                        .padding(.top, 16)

                    NavigationLink {
                        TeamMemberView(member: $currentMember)
                    } label: {
                        TeamMemberRow(
                            member: currentMember,
                            avatarDiameter: 48
                        )
                    }
                    .buttonStyle(.plain)
                    .background(
                        Color(.secondarySystemGroupedBackground),
                        in: RoundedRectangle(
                            cornerRadius: 20,
                            style: .continuous
                        )
                    )

                    // Your workspace
                    ProfileSection(title: "Your workspace") {

                        NavigationLink {
                            SettingsView(
                                flow: $flow,
                                onRestartOnboarding: onRestartOnboarding
                            )
                        } label: {
                            ProfileRow(
                                title: "Settings",
                                systemImage: "gearshape"
                            )
                        }

                        Divider()
                            .padding(.leading, 48)

                        NavigationLink {
                            HelpView()
                        } label: {
                            ProfileRow(
                                title: "Help Center",
                                systemImage: "questionmark.circle"
                            )
                        }

                        Divider()
                            .padding(.leading, 48)

                        NavigationLink {
                            FeedbackView()
                        } label: {
                            ProfileRow(
                                title: "Send feedback",
                                systemImage: "exclamationmark.bubble"
                            )
                        }
                    }

                    // Logout
                    Button(role: .destructive) {
                        HapticFeedback.criticalAction()
                        flow = .login
                    } label: {
                        HStack {
                            Text("Log out")
                                .font(.body)

                            Spacer()
                        }
                        .padding(.horizontal, 16)
                        .frame(minHeight: 52)
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.red)
                    .background(
                        Color(.secondarySystemGroupedBackground),
                        in: RoundedRectangle(
                            cornerRadius: 20,
                            style: .continuous
                        )
                    )
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 70)
            }
            .birdseyeRefreshable()
            .background(Color(.systemGroupedBackground))
            .birdseyeMainTabPage()
            .navigationDestination(isPresented: $showSettings) {
                SettingsView(
                    flow: $flow,
                    onRestartOnboarding: onRestartOnboarding
                )
            }
        }
    }
}

private struct ProfileSection<Content: View>: View {

    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {

            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 4)

            VStack(spacing: 0) {
                content
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
}

private struct ProfileRow: View {

    let title: String
    let systemImage: String

    var body: some View {
        HStack(spacing: 12) {

            Image(systemName: systemImage)
                .frame(width: 24)

            Text(title)
                .foregroundStyle(.primary)

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.tertiary)
        }
        .padding(.horizontal, 16)
        .frame(minHeight: 52)
        .contentShape(Rectangle())
    }
}

struct SettingsView: View {

    @Binding var flow: AppFlow
    let onRestartOnboarding: () -> Void
    @AppStorage("defaultLocation") private var defaultLocation = "Northstar (Oshawa)"

    var body: some View {
        Form {

            Section("Account") {
                LabeledContent("Name", value: "Maya Chen")
                LabeledContent("Email", value: "maya@northstar.com")
                LabeledContent("Role", value: "Administrator")

                LabeledContent(
                    "Organization",
                    value: "Northstar Operations"
                )
            }

            Section("Preferences") {

                Toggle(
                    "Operational notifications",
                    isOn: .constant(true)
                )

                Toggle(
                    "Daily activity summary",
                    isOn: .constant(true)
                )

                Picker(
                    "Default location",
                    selection: $defaultLocation
                ) {
                    Text("Northstar (Oshawa)")
                        .tag("Northstar (Oshawa)")

                    Text("Northstar (Dallas)")
                        .tag("Northstar (Dallas)")

                    Text("Northstar (Toronto)")
                        .tag("Northstar (Toronto)")
                }
            }

            Section("Onboarding") {
                Button("Restart onboarding steps") {
                    restartOnboarding()
                }
            }

            Section("Support") {

                NavigationLink {
                    HelpView()
                } label: {
                    Label(
                        "Help Center",
                        systemImage: "questionmark.circle"
                    )
                }

                LabeledContent("Version", value: "1.0")
            }
        }
        .navigationTitle("Settings")
        .toolbar {
            GlobalWorkspaceToolbar()
        }
    }

    private func restartOnboarding() {
        UserDefaults.standard.set(false, forKey: "onboardingAuthorizedPersonComplete")
        UserDefaults.standard.set(false, forKey: "onboardingOrganizationComplete")
        UserDefaults.standard.set(false, forKey: "onboardingEquipmentComplete")
        UserDefaults.standard.set(false, forKey: "onboardingAppointmentComplete")
        UserDefaults.standard.set(false, forKey: "onboardingCrewComplete")
        UserDefaults.standard.set(false, forKey: "onboardingAIComplete")
        UserDefaults.standard.set(false, forKey: "hasDismissedOnboardingChecklist")
        onRestartOnboarding()
    }
}

struct FeedbackView: View {

    var body: some View {
        Text("Work in progress")
            .navigationTitle("Send feedback")
    }
}


#Preview {
    ProfileView(
        flow: .constant(.main),
        showSettings: .constant(false),
        onRestartOnboarding: {}
    )
}
