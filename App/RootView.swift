import SwiftUI

enum AppFlow {
    case splash
    case login
    case main
}

struct RootView: View {
    @State private var flow: AppFlow = .splash
    @State private var snackbarCenter = SnackbarCenter()

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
        .transition(.opacity)
        .animation(.easeInOut(duration: 0.2), value: flow)
    }
}
