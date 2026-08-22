import SwiftUI

struct BrandLogoView: View {
    var foregroundStyle: Color = .primary

    var body: some View {
        Image("BirdseyeLogoWhite")
            .renderingMode(.template)
            .resizable()
            .scaledToFit()
            .frame(width: 116, height: 19)
            .foregroundStyle(foregroundStyle)
            .accessibilityLabel("Birdseye")
    }
}
