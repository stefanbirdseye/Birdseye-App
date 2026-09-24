import SwiftUI

struct AccessTypeChip: View {
    let accessType: String
    let periodAccess: String
    let hasNote: Bool
    let isLimitedTime: Bool

    private var foregroundColor: Color {
        switch accessType {
        case "Banned Access":
            return .red
        case "Priority Access":
            return .blue
        case "Specialized Access":
            return .orange
        default:
            return .secondary
        }
    }

    private var backgroundColor: Color {
        switch accessType {
        case "Banned Access":
            return .red.opacity(0.12)
        case "Priority Access":
            return .blue.opacity(0.12)
        case "Specialized Access":
            return .orange.opacity(0.14)
        default:
            return Color(.tertiarySystemFill)
        }
    }

    var body: some View {
        HStack(spacing: 6) {
            Text(accessType)

            if periodAccess == "One-time" {
                Image(systemName: "1.circle.fill")
                    .accessibilityLabel(periodAccess)
            }

            if hasNote {
                Image(systemName: "note.text")
                    .accessibilityLabel("Has note")
            }

            if isLimitedTime {
                Image(systemName: "clock.fill")
                    .accessibilityLabel("Limited time access")
            }
        }
        .font(.subheadline.weight(.medium))
        .foregroundStyle(foregroundColor)
        .lineLimit(1)
        .padding(.horizontal, 9)
        .padding(.vertical, 5)
        .background(backgroundColor, in: Capsule())
    }
}

struct MoreDetailsChips: View {
    let title: String
    let phoneNumber: String
    let emailAddress: String
    let dateOfBirth: Date?
    let idCountry: String
    let dlNumber: String
    let companyCardNumber: String

    var body: some View {
        WrappingDetailFlowLayout(spacing: 6) {
            if !title.isEmpty {
                AccessPolicyDetailChip(label: "Title", value: title)
            }

            if !phoneNumber.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                AccessPolicyDetailChip(label: "Phone", value: phoneNumber)
            }

            if !emailAddress.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                AccessPolicyDetailChip(label: "Email", value: emailAddress)
            }

            if let dateOfBirth {
                AccessPolicyDetailChip(
                    label: "DOB",
                    value: dateOfBirth.formatted(date: .abbreviated, time: .omitted)
                )
            }

            if !idCountry.isEmpty {
                AccessPolicyDetailChip(label: "Country", value: idCountry)
            }

            if !dlNumber.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                AccessPolicyDetailChip(label: "DL", value: dlNumber)
            }

            if !companyCardNumber.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                AccessPolicyDetailChip(label: "Card", value: companyCardNumber)
            }
        }
    }
}

private struct AccessPolicyDetailChip: View {
    let label: String
    let value: String

    var body: some View {
        HStack(spacing: 3) {
            Text("\(label):")
                .fontWeight(.semibold)
            Text(value)
                .multilineTextAlignment(.leading)
        }
        .font(.caption)
        .foregroundStyle(.primary)
        .padding(.horizontal, 9)
        .padding(.vertical, 5)
        .background(
            Color(.tertiarySystemFill),
            in: RoundedRectangle(cornerRadius: 9, style: .continuous)
        )
    }
}

struct WrappingDetailFlowLayout: Layout {
    let spacing: CGFloat

    init(spacing: CGFloat = 8) {
        self.spacing = spacing
    }

    func sizeThatFits(
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(
                ProposedViewSize(width: maxWidth, height: nil)
            )
            if currentX + size.width > maxWidth, currentX > 0 {
                currentX = 0
                currentY += rowHeight + spacing
                rowHeight = 0
            }

            currentX += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }

        return CGSize(width: maxWidth, height: currentY + rowHeight)
    }

    func placeSubviews(
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) {
        var currentX = bounds.minX
        var currentY = bounds.minY
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(
                ProposedViewSize(width: bounds.width, height: nil)
            )
            if currentX + size.width > bounds.maxX, currentX > bounds.minX {
                currentX = bounds.minX
                currentY += rowHeight + spacing
                rowHeight = 0
            }

            subview.place(
                at: CGPoint(x: currentX, y: currentY),
                proposal: ProposedViewSize(
                    width: min(size.width, bounds.maxX - currentX),
                    height: size.height
                )
            )
            currentX += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}
