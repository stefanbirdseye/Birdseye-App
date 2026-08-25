import SwiftUI
import UIKit

struct BrandLogoView: View {

    var foregroundStyle: Color = .primary

    var body: some View {
        Group {
            if UIImage(named: "BirdseyeLogoWhite") != nil {
                Image("BirdseyeLogoWhite")
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
            } else {
                Text("BIRDSEYE")
                    .font(.headline.weight(.bold))
                    .tracking(0.6)
            }
        }
        .foregroundStyle(foregroundStyle)
        .accessibilityLabel("Birdseye")
    }
}
