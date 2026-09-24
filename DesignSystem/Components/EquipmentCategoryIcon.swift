import SwiftUI

struct EquipmentCategoryIcon: View {
    let category: String
    var tint: Color = .primary

    private var systemImage: String {
        "tire"
    }

    var body: some View {
        Image(systemName: systemImage)
            .symbolRenderingMode(.monochrome)
            .foregroundStyle(tint)
            .accessibilityHidden(true)
    }
}
