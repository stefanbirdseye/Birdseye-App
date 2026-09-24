import SwiftUI
import UIKit

struct HelpView: View {
    @Environment(AIComposerStore.self) private var aiComposerStore

    private let featuredGuides = HelpFeaturedGuide.all
    private let aiExamples = HelpAIExample.all
    private let topics = HelpTopic.all
    private let helpCenterLink = "https://birdseye.app/help"
    @State private var isLinkCopied = false
    @State private var isSearchPresented = false
    @State private var searchText = ""

    private var searchableTopics: [HelpTopic] {
        [HelpTopic.discoverMore] + topics
    }

    private var filteredTopics: [HelpTopic] {
        guard !searchText.isEmpty else {
            return topics
        }

        return searchableTopics.compactMap { topic in
            let matchingArticles = topic.articles.filter {
                $0.localizedCaseInsensitiveContains(searchText)
            }

            guard topic.title.localizedCaseInsensitiveContains(searchText) || !matchingArticles.isEmpty else {
                return nil
            }

            return HelpTopic(
                id: topic.id,
                title: topic.title,
                summary: topic.summary,
                systemImage: topic.systemImage,
                tint: topic.tint,
                articles: matchingArticles.isEmpty ? topic.articles : matchingArticles
            )
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 32) {
                if searchText.isEmpty {
                    HelpFeaturedSection(guides: featuredGuides)
                    HelpAISection(
                        examples: aiExamples,
                        onPromptSelected: { aiComposerStore.prompt = $0 }
                    )
                }

                if searchText.isEmpty {
                    HelpTopicsSection(topics: topics)
                    HelpContactSection()
                } else if filteredTopics.isEmpty {
                    HelpNoSearchResultsSection(
                        searchText: searchText,
                        onAskAI: { aiComposerStore.prompt = "Help me find information about \(searchText)." }
                    )
                } else {
                    HelpTopicsSection(topics: filteredTopics)
                }
            }
            .padding(.vertical, 20)
        }
        .safeAreaPadding(.bottom, 112)
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Help Center")
        .navigationBarTitleDisplayMode(.inline)
        .searchable(
            text: $searchText,
            isPresented: $isSearchPresented,
            prompt: "Search Help Center"
        )
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button {
                    isSearchPresented = true
                } label: {
                    Image(systemName: "magnifyingglass")
                }
                .accessibilityLabel("Search Help Center")

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
                    Image(systemName: "ellipsis")
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
                systemImage: "lightbulb.max"
            )
            .padding(.horizontal, 16)

            ScrollView(.horizontal) {
                HStack(spacing: 16) {
                    ForEach(guides) { guide in
                        NavigationLink {
                            HelpArticleView(article: HelpArticle(guide: guide))
                        } label: {
                            HelpFeaturedCard(guide: guide)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 16)
            }
            .contentMargins(.horizontal, 0)
            .scrollClipDisabled()
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
    let onPromptSelected: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HelpSectionHeader(
                title: "Do it faster with AI",
                systemImage: "sparkles"
            )
            .padding(.horizontal, 16)

            VStack(spacing: 10) {
                ForEach(examples) { example in
                    HelpAIPromptRow(
                        example: example,
                        onSelect: { onPromptSelected(example.prompt) }
                    )
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
    let onSelect: () -> Void

    var body: some View {
        Button {
            onSelect()
        } label: {
            Label(example.prompt, systemImage: "sparkles")
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 4)
                .multilineTextAlignment(.leading)
                .foregroundStyle(.blue)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(example.prompt)
        .accessibilityHint("Adds this prompt to the AI composer")
    }
}

private struct HelpNoSearchResultsSection: View {
    let searchText: String
    let onAskAI: () -> Void

    var body: some View {
        ContentUnavailableView {
            Label("No results found", systemImage: "magnifyingglass")
        } description: {
            Text("Try a different search, or ask AI to help with \(searchText).")
        } actions: {
            Button("Ask AI") {
                onAskAI()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
    }
}

private struct HelpTopicsSection: View {
    let topics: [HelpTopic]

    var body: some View {
        VStack(spacing: 16) {
            ForEach(topics) { topic in
                HelpTopicCategory(topic: topic)
            }
        }
    }
}

private struct HelpTopicCategory: View {
    let topic: HelpTopic

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HelpSectionHeader(
                title: topic.title,
                systemImage: topic.systemImage,
                iconColor: topic.tint
            )
            .padding(.horizontal, 16)

            HelpTopicArticleList(topic: topic)
                .padding(.horizontal, 16)
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
                HStack(spacing: 12) {
                    Image(systemName: "envelope")
                        .foregroundStyle(Color.accentColor)

                    Text("Contact Us")
                        .foregroundStyle(Color.accentColor)

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.tertiary)
                }
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
    var iconColor: Color = .primary
    var includesHorizontalPadding = true

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.system(size: 18, weight: .semibold))
                .frame(width: 24, height: 24, alignment: .leading)
                .foregroundStyle(iconColor)

            Text(title)
        }
        .font(.title3.weight(.semibold))
        .foregroundStyle(.primary)
        .padding(.horizontal, includesHorizontalPadding ? 16 : 0)
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
    let topic: HelpTopic

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {

            VStack(spacing: 0) {
                ForEach(topic.articles, id: \.self) { title in
                    let article = HelpArticle(topic: topic, title: title)

                    NavigationLink {
                        HelpArticleView(article: article)
                    } label: {
                        HelpArticleRow(title: article.title)
                    }
                    .buttonStyle(.plain)

                    if title != topic.articles.last {
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

private struct HelpArticleRow: View {
    let title: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "doc.text")
                .frame(width: 24, height: 24)
                .foregroundStyle(.secondary)

            Text(title)
                .foregroundStyle(.primary)

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.tertiary)
        }
        .padding(16)
        .contentShape(Rectangle())
    }
}

private struct HelpRelatedArticlesSection: View {
    let articles: [HelpArticle]

    var body: some View {
        if !articles.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                HelpSectionHeader(
                    title: "Related articles",
                    systemImage: "doc.on.doc",
                    iconColor: .secondary,
                    includesHorizontalPadding: false
                )

                VStack(spacing: 0) {
                    ForEach(articles) { article in
                        NavigationLink {
                            HelpArticleView(article: article)
                        } label: {
                            HelpArticleRow(title: article.title)
                        }
                        .buttonStyle(.plain)

                        if article.id != articles.last?.id {
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
            .accessibilityElement(children: .contain)
        }
    }
}

private struct HelpArticleView: View {
    let article: HelpArticle
    @Environment(AIComposerStore.self) private var aiComposerStore
    @State private var isLinkCopied = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                HelpArticleImage(article: article)
                    .frame(height: 210)

                Text(article.title)
                    .font(.title.bold())

                Text(article.body)
                    .font(.body)
                    .foregroundStyle(.secondary)

                Button {
                    aiComposerStore.prompt = "Help me with \(article.title)."
                } label: {
                    Label("Ask AI about this", systemImage: "sparkles")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(Color.accentColor)
                .accessibilityHint("Adds a question about this article to the AI composer")

                HelpRelatedArticlesSection(articles: article.relatedArticles)
            }
            .padding(16)
            .padding(.bottom, 112)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(article.topicTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button {
                        UIPasteboard.general.url = article.link
                        isLinkCopied = true
                    } label: {
                        Label(
                            isLinkCopied ? "Link copied" : "Copy link",
                            systemImage: isLinkCopied ? "checkmark" : "link"
                        )
                    }

                    ShareLink(item: article.link) {
                        Label("Share article", systemImage: "square.and.arrow.up")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                }
                .accessibilityLabel("Article options")
            }
        }
    }
}

private struct HelpArticleImage: View {
    let article: HelpArticle

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [article.tint.opacity(0.9), article.tint],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Circle()
                .fill(.white.opacity(0.16))
                .frame(width: 220, height: 220)
                .offset(x: 110, y: -70)

            Image(systemName: article.systemImage)
                .font(.system(size: 62, weight: .semibold))
                .foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .accessibilityHidden(true)
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

private struct HelpArticle: Identifiable {
    let topicTitle: String
    let topicID: String
    let title: String
    let systemImage: String
    let tint: Color

    init(topic: HelpTopic, title: String) {
        topicTitle = topic.title
        topicID = topic.id
        self.title = title
        systemImage = topic.systemImage
        tint = topic.tint
    }

    init(guide: HelpFeaturedGuide) {
        topicTitle = HelpTopic.discoverMore.title
        topicID = HelpTopic.discoverMore.id
        title = guide.title
        systemImage = guide.systemImage
        tint = guide.colors.first ?? .indigo
    }

    var id: String {
        title
            .lowercased()
            .replacingOccurrences(of: "'", with: "")
            .replacingOccurrences(of: " ", with: "-")
    }

    var link: URL {
        URL(string: "https://birdseye.app/help/\(topicID)/\(id)")!
    }

    var body: String {
        if let guide = HelpFeaturedGuide.all.first(where: { $0.title == title }) {
            return guide.subtitle
        }

        return "Learn how to \(title.lowercased()) in Birdseye. Follow the guided steps to complete this task for your workspace."
    }

    var relatedArticles: [HelpArticle] {
        if topicID == HelpTopic.discoverMore.id {
            return HelpFeaturedGuide.all
                .filter { $0.title != title }
                .map(HelpArticle.init(guide:))
        }

        return HelpTopic.all
            .first(where: { $0.id == topicID })?
            .articles
            .filter { $0 != title }
            .map { HelpArticle(topicID: topicID, topicTitle: topicTitle, title: $0, systemImage: systemImage, tint: tint) } ?? []
    }

    private init(topicID: String, topicTitle: String, title: String, systemImage: String, tint: Color) {
        self.topicID = topicID
        self.topicTitle = topicTitle
        self.title = title
        self.systemImage = systemImage
        self.tint = tint
    }
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

    static let discoverMore = HelpTopic(
        id: "discover-more",
        title: "Discover more",
        summary: "Guides for getting more from Birdseye.",
        systemImage: "gift",
        tint: .indigo,
        articles: HelpFeaturedGuide.all.map(\.title)
    )

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
