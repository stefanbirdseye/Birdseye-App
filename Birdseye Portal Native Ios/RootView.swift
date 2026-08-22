import SwiftUI

enum AppFlow {
    case splash
    case login
    case main
}

struct RootView: View {
    @State private var flow: AppFlow = .splash

    var body: some View {
        Group {
            switch flow {
            case .splash:
                SplashView()
            case .login:
                LoginView(flow: $flow)
            case .main:
                MainTabView(flow: $flow)
            }
        }
        .task {
            guard flow == .splash else {
                return
            }

            try? await Task.sleep(for: .seconds(1.2))

            if !Task.isCancelled, flow == .splash {
                flow = .login
            }
        }
    }
}
