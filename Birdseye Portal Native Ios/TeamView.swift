import SwiftUI

struct TeamView: View {
    private let members = [
        TeamMember(name: "Maya Chen", role: "Administrator", initials: "MC"),
        TeamMember(name: "Daniel Brooks", role: "Yard Manager", initials: "DB"),
        TeamMember(name: "Sarah Patel", role: "Security", initials: "SP"),
        TeamMember(name: "James Wilson", role: "Operator", initials: "JW")
    ]

    var body: some View {
        NavigationStack {
            List(members) { member in
                HStack(spacing: 12) {
                    Text(member.initials)
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.white)
                        .frame(width: 40, height: 40)
                        .background(Color.birdseyeNavy, in: Circle())

                    VStack(alignment: .leading, spacing: 3) {
                        Text(member.name)
                        Text(member.role)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.tertiary)
                }
                .frame(minHeight: 44)
            }
            .navigationTitle("Team")
        }
        .safeAreaInset(edge: .top, spacing: 0) {
            BirdseyeHeader()
        }
    }
}

private struct TeamMember: Identifiable {
    let id = UUID()
    let name: String
    let role: String
    let initials: String
}

#Preview {
    TeamView()
}
