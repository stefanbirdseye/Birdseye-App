import SwiftUI

struct BirdseyeHeader: View {
    var body: some View {
        HStack(spacing: 12) {
            BrandLogoView(foregroundStyle: .white)

            Spacer()

            HeaderButton(symbol: "bell", label: "Notifications")
            HeaderButton(symbol: "questionmark.circle", label: "Help")

            Button {
            } label: {
                Text("SB")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(Color.birdseyeNavy)
                    .frame(width: 36, height: 36)
                    .background(.white, in: Circle())
            }
            .frame(minWidth: 44, minHeight: 44)
            .accessibilityLabel("Profile")
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color.birdseyeNavy)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(.white.opacity(0.18))
                .frame(height: 1)
        }
    }
}

private struct HeaderButton: View {
    let symbol: String
    let label: String

    var body: some View {
        Button {
        } label: {
            Image(systemName: symbol)
                .font(.body.weight(.medium))
                .frame(minWidth: 44, minHeight: 44)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }
}
