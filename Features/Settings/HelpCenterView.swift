import SwiftUI
import UIKit

struct HelpView: View {
    private let featuredGuides = HelpFeaturedGuide.all
    private let aiExamples = HelpAIExample.all
    private let topics = HelpTopic.all
    private let helpCenterLink = "https://birdseye.app/help"
    @State private var isLinkCopied = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 32) {
                HelpFeaturedSection(guides: featuredGuides)
                HelpAISection(examples: aiExamples)
                HelpTopicsSection(topics: topics)
                HelpContactSection()
            }
            .padding(.vertical, 20)
        }
        .safeAreaPadding(.bottom, 112)
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Help Center")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button {
                        UIPasteboard.general.string = helpCenterLink
                        isLinkCopied = true
                    } label: {
                        Label(
                            isLinkCopied ? "Link copied" : "Copy link",
                            systemImage: isLinkCopied ? "checkmark" : "link"
                        )
                    }

                    ShareLink(item: helpCenterLink) {
                        Label("Share Help Center", systemImage: "square.and.arrow.up")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
                .accessibilityLabel("More options")
            }
        }
    }
}

private struct HelpFeaturedSection: View {
    let guides: [HelpFeaturedGuide]

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HelpSectionHeader(
                title: "Discover more",
                systemImage: "gift"
            )

            ScrollView(.horizontal) {
                HStack(spacing: 16) {
                    ForEach(guides) { guide in
                        NavigationLink {
                            HelpMediaDetailView(guide: guide)
                        } label: {
                            HelpFeaturedCard(guide: guide)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 16)
            }
            .contentMargins(.horizontal, 0)
            .scrollIndicators(.hidden)
        }
    }
}

private struct HelpFeaturedCard: View {
    let guide: HelpFeaturedGuide

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HelpMediaThumbnail(
                title: guide.title,
                systemImage: guide.systemImage,
                colors: guide.colors,
                isVideo: guide.isVideo
            )
            .frame(height: 154)

            VStack(alignment: .leading, spacing: 6) {
                Text(guide.title)
                    .font(.headline)
                    .foregroundStyle(.primary)
                    .lineLimit(2)

                Text(guide.subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
            .padding(16)
        }
        .frame(width: 286, alignment: .leading)
        .background(
            Color(.secondarySystemGroupedBackground),
            in: RoundedRectangle(cornerRadius: 18, style: .continuous)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color(.separator).opacity(0.55), lineWidth: 1)
        }
        .accessibilityElement(children: .combine)
        .accessibilityHint("Opens this guide")
    }
}

private struct HelpMediaThumbnail: View {
    let title: String
    let systemImage: String
    let colors: [Color]
    let isVideo: Bool

    var body: some View {
        ZStack {
            LinearGradient(
                colors: colors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Circle()
                .fill(.white.opacity(0.14))
                .frame(width: 170, height: 170)
                .offset(x: 104, y: -42)

            Image(systemName: systemImage)
                .font(.system(size: 50, weight: .semibold))
                .foregroundStyle(.white)
                .symbolRenderingMode(.hierarchical)

            if isVideo {
                Image(systemName: "play.fill")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(.white)
                    .frame(width: 46, height: 46)
                    .background(.black.opacity(0.35), in: Circle())
                    .accessibilityLabel("Video")
                    .offset(x: 106, y: 52)
            }
        }
        .clipShape(
            UnevenRoundedRectangle(
                topLeadingRadius: 18,
                bottomLeadingRadius: 0,
                bottomTrailingRadius: 0,
                topTrailingRadius: 18,
                style: .continuous
            )
        )
        .accessibilityLabel(title)
    }
}

private struct HelpAISection: View {
    let examples: [HelpAIExample]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Do it faster with AI")
                .font(.title3.weight(.bold))
                .foregroundStyle(.primary)
                .padding(.horizontal, 20)

            VStack(spacing: 10) {
                ForEach(examples) { example in
                    HelpAIPromptRow(example: example)
                }
            }
            .padding(16)
            .background(
                Color(.secondarySystemGroupedBackground),
                in: RoundedRectangle(cornerRadius: 20, style: .continuous)
            )
            .padding(.horizontal, 16)
        }
    }
}

private struct HelpAIPromptRow: View {
    let example: HelpAIExample

    var body: some View {
        Button {
            UIPasteboard.general.string = example.prompt
        } label: {
            Label(example.prompt, systemImage: "sparkles")
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 4)
                .multilineTextAlignment(.leading)
                .foregroundStyle(.blue)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(example.prompt)
        .accessibilityHint("Copies this prompt to the clipboard")
    }
}

private struct HelpTopicsSection: View {
    let topics: [HelpTopic]

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HelpSectionHeader(
                title: "Explore help topics",
                systemImage: "lifepreserver"
            )

            VStack(spacing: 16) {
                ForEach(topics) { topic in
                    HelpTopicCategory(topic: topic)
                }
            }
            .padding(.horizontal, 16)
        }
    }
}

private struct HelpTopicCategory: View {
    let topic: HelpTopic

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 12) {
                Image(systemName: topic.systemImage)
                    .font(.title3)
                    .foregroundStyle(topic.tint)
                    .frame(width: 40, height: 40)
                    .background(topic.tint.opacity(0.12), in: RoundedRectangle(cornerRadius: 10, style: .continuous))

                VStack(alignment: .leading, spacing: 2) {
                    Text(topic.title)
                        .font(.headline)

                    Text(topic.summary)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            HelpTopicArticleList(articles: topic.articles)
        }
    }
}

private struct HelpContactSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HelpSectionHeader(
                title: "Need more help?",
                systemImage: "questionmark.circle"
            )

            Link(destination: URL(string: "mailto:support@birdseye.app")!) {
                HStack {
                    Label("Contact Us", systemImage: "arrow.up.right.square")
                        .font(.headline)

                    Spacer()

                    Image(systemName: "arrow.up.right")
                        .font(.subheadline.weight(.semibold))
                }
                .foregroundStyle(Color.accentColor)
                .padding(16)
                .background(
                    Color(.secondarySystemGroupedBackground),
                    in: RoundedRectangle(cornerRadius: 16, style: .continuous)
                )
            }
        }
        .padding(.horizontal, 16)
    }
}

private struct HelpSectionHeader: View {
    let title: String
    let systemImage: String

    var body: some View {
        Label(title, systemImage: systemImage)
            .font(.title3.weight(.semibold))
            .foregroundStyle(.primary)
            .padding(.horizontal, 16)
    }
}

private struct HelpMediaDetailView: View {
    let guide: HelpFeaturedGuide

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                HelpMediaThumbnail(
                    title: guide.title,
                    systemImage: guide.systemImage,
                    colors: guide.colors,
                    isVideo: guide.isVideo
                )
                .frame(height: 260)

                VStack(alignment: .leading, spacing: 10) {
                    Text(guide.title)
                        .font(.title.bold())

                    Text(guide.subtitle)
                        .font(.body)
                        .foregroundStyle(.secondary)

                    Text("This guide will include \(guide.isVideo ? "a video walkthrough" : "illustrated instructions") as content is added.")
                        .font(.body)
                }
                .padding(.horizontal, 16)
            }
            .padding(.vertical, 20)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Guide")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct HelpTopicArticleList: View {
    let articles: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("In this topic")
                .font(.headline)

            VStack(spacing: 0) {
                ForEach(articles, id: \.self) { article in
                    HStack(spacing: 12) {
                        Image(systemName: "doc.text")
                            .foregroundStyle(.secondary)

                        Text(article)
                            .foregroundStyle(.primary)

                        Spacer()
                    }
                    .padding(16)

                    if article != articles.last {
                        Divider()
                            .padding(.leading, 44)
                    }
                }
            }
            .background(
                Color(.secondarySystemGroupedBackground),
                in: RoundedRectangle(cornerRadius: 16, style: .continuous)
            )
        }
    }
}

private struct HelpFeaturedGuide: Identifiable {
    let id: String
    let title: String
    let subtitle: String
    let systemImage: String
    let colors: [Color]
    let isVideo: Bool

    static let all = [
        HelpFeaturedGuide(
            id: "authorization-basics",
            title: "Set up authorizations",
            subtitle: "Create access rules for the people and places that matter.",
            systemImage: "checkmark.shield",
            colors: [.indigo, .purple],
            isVideo: true
        ),
        HelpFeaturedGuide(
            id: "invite-users",
            title: "Invite and manage users",
            subtitle: "Bring your team into Birdseye and keep roles up to date.",
            systemImage: "person.2.badge.plus",
            colors: [.teal, .cyan],
            isVideo: false
        ),
        HelpFeaturedGuide(
            id: "review-activity",
            title: "Review access activity",
            subtitle: "Understand recent activity across your workspace.",
            systemImage: "chart.line.uptrend.xyaxis",
            colors: [.orange, .pink],
            isVideo: true
        )
    ]
}

private struct HelpAIExample: Identifiable {
    let id: String
    let prompt: String

    static let all = [
        HelpAIExample(
            id: "add-authorization",
            prompt: "Explain how to add an authorization for a new contractor."
        ),
        HelpAIExample(
            id: "review-access",
            prompt: "Show me how to review recent access activity."
        ),
        HelpAIExample(
            id: "manage-user",
            prompt: "How do I update a user's role and location access?"
        )
    ]
}

private struct HelpTopic: Identifiable {
    let id: String
    let title: String
    let summary: String
    let systemImage: String
    let tint: Color
    let articles: [String]

    var link: URL {
        URL(string: "https://birdseye.app/help/\(id)")!
    }

    static let all = [
        HelpTopic(
            id: "users",
            title: "Users",
            summary: "Invite, manage, and update team members.",
            systemImage: "person.2",
            tint: .blue,
            articles: [
                "Invite a user",
                "Change a user's role",
                "Deactivate or remove a user"
            ]
        ),
        HelpTopic(
            id: "authorizations",
            title: "Authorizations",
            summary: "Create and manage access permissions.",
            systemImage: "checkmark.shield",
            tint: .green,
            articles: [
                "Create an authorization",
                "Edit access dates and times",
                "Review authorization history"
            ]
        ),
        HelpTopic(
            id: "access-points",
            title: "Access points",
            summary: "Manage doors, gates, and other entry points.",
            systemImage: "door.left.hand.open",
            tint: .orange,
            articles: [
                "Add an access point",
                "Update an access point",
                "Troubleshoot an offline access point"
            ]
        ),
        HelpTopic(
            id: "organizations",
            title: "Organizations",
            summary: "Manage organizations and their access.",
            systemImage: "building.2",
            tint: .purple,
            articles: [
                "Create an organization",
                "Add people to an organization",
                "Manage organization access"
            ]
        ),
        HelpTopic(
            id: "appointments",
            title: "Appointments",
            summary: "Schedule and manage upcoming visits.",
            systemImage: "calendar",
            tint: .pink,
            articles: [
                "Schedule an appointment",
                "Update an appointment",
                "Check in a visitor"
            ]
        )
    ]
}
