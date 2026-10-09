import SwiftUI

enum AppFlow {
    case splash
    case login
    case main
}

enum AppTheme: String, CaseIterable {
    case system
    case light
    case dark

    var title: LocalizedStringResource {
        switch self {
        case .system:
            "System (Default)"
        case .light:
            "Light"
        case .dark:
            "Dark"
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .system:
            nil
        case .light:
            .light
        case .dark:
            .dark
        }
    }
}

struct RootView: View {
    @State private var flow: AppFlow = .splash
    @State private var snackbarCenter = SnackbarCenter()
    @AppStorage("appTheme") private var appTheme = AppTheme.system

    var body: some View {
        ZStack {
            switch flow {
            case .splash:
                SplashView {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        flow = .login
                    }
                }
            case .login:
                LoginView(flow: $flow)
            case .main:
                MainTabView(flow: $flow)
            }
        }
        .id(flow)
        .presentingSnackbars()
        .environment(snackbarCenter)
        .preferredColorScheme(appTheme.colorScheme)
        .transition(.opacity)
        .animation(.easeInOut(duration: 0.2), value: flow)
    }
}
