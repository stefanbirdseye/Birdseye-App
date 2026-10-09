import SwiftUI
import TipKit

struct OnboardingTipViewStyle: TipViewStyle {

    @Environment(\.colorScheme) private var colorScheme

    func makeBody(configuration: Configuration) -> some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top, spacing: 16) {
                configuration.image?
                    .resizable()
                    .scaledToFit()
                    .frame(width: 44, height: 44)
                    .foregroundStyle(Color.accentColor)

                VStack(alignment: .leading, spacing: 6) {
                    configuration.title?
                        .font(.headline.weight(.semibold))

                    configuration.message?
                        .font(.body)
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: 0)

                Button {
                    configuration.tip.invalidate(reason: .tipClosed)
                } label: {
                    Image(systemName: "xmark")
                        .font(.body.weight(.bold))
                        .foregroundStyle(.secondary)
                        .frame(width: 32, height: 32)
                        .background(Color(.tertiarySystemFill), in: Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Dismiss tip")
            }

            ForEach(configuration.actions) { action in
                Button(action: action.handler) {
                    action.label()
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.accentColor, in: Capsule())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(24)
        .background(tipBackground, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(Color(.separator).opacity(0.25), lineWidth: 1)
        }
    }

    private var tipBackground: Color {
        colorScheme == .light
            ? Color(.systemBackground)
            : Color(.secondarySystemGroupedBackground)
    }
}
