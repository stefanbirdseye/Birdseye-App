import SwiftUI

struct HomeView: View {
    private let cards = [
        DashboardCardData(title: "People", value: "128", detail: "1 new", color: .blue),
        DashboardCardData(title: "Organizations", value: "14", detail: "1 new", color: .green),
        DashboardCardData(title: "Equipment", value: "46", detail: "1 new", color: .purple),
        DashboardCardData(title: "Appointments", value: "4", detail: "1 new", color: .orange)
    ]

    private let aiActions = [
        "Authorize this person at all locations",
        "How many people entered yesterday?",
        "Is this person banned across all locations?"
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Today summary")
                        .font(.largeTitle.weight(.semibold))
                    Text("Here’s what’s happening.")
                        .font(.body)
                        .foregroundStyle(.secondary)
                }

                LocationSelector()

                LazyVGrid(
                    columns: [GridItem(.adaptive(minimum: 160), spacing: 12)],
                    spacing: 12
                ) {
                    ForEach(cards) { card in
                        DashboardCard(data: card)
                    }
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text("Do it faster with AI")
                        .font(.title2.weight(.semibold))

                    ForEach(aiActions, id: \.self) { action in
                        Button {
                        } label: {
                            HStack {
                                Text(action)
                                    .multilineTextAlignment(.leading)
                                Spacer(minLength: 8)
                                Image(systemName: "arrow.up.right")
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .buttonStyle(.bordered)
                        .frame(minHeight: 44)
                    }
                }
            }
            .frame(maxWidth: 900, alignment: .leading)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 20)
            .padding(.vertical, 24)
        }
        .safeAreaInset(edge: .top, spacing: 0) {
            BirdseyeHeader()
        }
    }
}

private struct LocationSelector: View {
    var body: some View {
        HStack(spacing: 8) {
            Button {
            } label: {
                Image(systemName: "chevron.left")
            }
            .frame(minWidth: 44, minHeight: 44)
            .accessibilityLabel("Previous location")

            Button {
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "mappin.and.ellipse")
                    Text("Northstar (Oshawa)")
                        .lineLimit(1)
                    Image(systemName: "chevron.down")
                        .font(.caption.weight(.semibold))
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .controlSize(.large)
            .frame(minHeight: 44)
            .accessibilityLabel("Current location, Northstar Oshawa")

            Button {
            } label: {
                Image(systemName: "chevron.right")
            }
            .frame(minWidth: 44, minHeight: 44)
            .accessibilityLabel("Next location")
        }
    }
}

private struct DashboardCardData: Identifiable {
    let id = UUID()
    let title: String
    let value: String
    let detail: String
    let color: Color
}

private struct DashboardCard: View {
    let data: DashboardCardData

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(data.title)
                    .font(.headline)
                Spacer()
                Circle()
                    .fill(data.color)
                    .frame(width: 10, height: 10)
                    .accessibilityHidden(true)
            }

            Text(data.value)
                .font(.system(.largeTitle, design: .rounded).weight(.semibold))

            HStack {
                Text(data.detail)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
                Button("Add") {
                }
                .buttonStyle(.bordered)
                .tint(data.color)
                .frame(minHeight: 44)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
        .overlay {
            RoundedRectangle(cornerRadius: 16)
                .stroke(data.color.opacity(0.18), lineWidth: 1)
        }
    }
}

#Preview {
    HomeView()
}
