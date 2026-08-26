import SwiftUI

struct EquipmentCategoryIcon: View {
    let category: String
    var tint: Color = .primary

    private var systemImage: String {
        switch category {
        case "Car":
            return "car.side"
        case "Bobtail", "Straight truck", "Truck":
            return "truck.box"
        default:
            return "shippingbox"
        }
    }

    var body: some View {
        Image(systemName: systemImage)
            .symbolRenderingMode(.monochrome)
            .foregroundStyle(tint)
            .accessibilityHidden(true)
    }
}
