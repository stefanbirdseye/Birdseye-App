import SwiftUI

extension View {

    func birdseyeRefreshable() -> some View {
        scrollBounceBehavior(.always)
            .refreshable {
                await BirdseyeRefresh.perform()
            }
    }
}

@MainActor
private enum BirdseyeRefresh {

    static func perform() async {
        HapticFeedback.lightImpact()

        try? await Task.sleep(
            for: .milliseconds(650)
        )

        HapticFeedback.success()
    }
}
