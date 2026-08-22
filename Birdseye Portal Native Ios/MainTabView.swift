import SwiftUI

enum MainTab: Hashable {
    case home
    case ai
    case new
    case team
    case settings
}

struct MainTabView: View {
    @Binding var flow: AppFlow

    @State private var selectedTab: MainTab = .home
    @State private var isShowingNewSheet = false

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab("Home", systemImage: "house", value: .home) {
                HomeView()
            }

            Tab("AI", systemImage: "sparkles", value: .ai) {
                AIView()
            }

            Tab("New", systemImage: "plus", value: .new) {
                Color.clear
                    .accessibilityHidden(true)
            }

            Tab("Team", systemImage: "person.2", value: .team) {
                TeamView()
            }

            Tab("Settings", systemImage: "gearshape", value: .settings) {
                SettingsView(flow: $flow)
            }
        }
        .tabViewStyle(.sidebarAdaptable)
        .onChange(of: selectedTab) { _, newValue in
            guard newValue == .new else {
                return
            }

            isShowingNewSheet = true
            selectedTab = .home
        }
        .sheet(isPresented: $isShowingNewSheet) {
            NewSheet()
        }
    }
}
