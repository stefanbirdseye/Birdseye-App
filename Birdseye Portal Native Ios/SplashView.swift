import SwiftUI

struct SplashView: View {
    var body: some View {
        ZStack {
            Color.birdseyeNavy
                .ignoresSafeArea()

            BrandLogoView(foregroundStyle: .white)
                .scaleEffect(1.2)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Birdseye")
    }
}
