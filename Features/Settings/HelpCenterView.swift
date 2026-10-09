import SwiftUI
import UIKit
struct HelpView: View {
    @Environment(AIComposerStore.self) private var aiComposerStore
    @State private var searchText = ""
    @State private var isSearchPresented = false
    @State private var isLinkCopied = false
    private let topics = HelpTopic.all
    private let helpCenterLink = "https://birdseye.app/help"
    private var filteredTopics: [HelpTopic] {
        guard !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return topics
        }
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        return topics.compactMap { topic in
            let articles = topic.articles.filter { article in
                article.matches(query)
            }
            guard topic.matches(query) || !articles.isEmpty else {
                return nil
            }
            return HelpTopic(
                id: topic.id,
                title: topic.title,
                summary: topic.summary,
                systemImage: topic.systemImage,
                tint: topic.tint,
                articles: articles.isEmpty ? topic.articles : articles
            )
        }
    }
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                if searchText.isEmpty {
                    HelpQuickStartSection()
                    HelpAISection()
                }
                if filteredTopics.isEmpty {
                    HelpNoSearchResultsSection(
                        searchText: searchText,
                        onAskAI: {
                            aiComposerStore.prompt = "Help me find information about \(searchText)."
                        }
                    )
                } else {
                    HelpTopicsSection(topics: filteredTopics)
                }
                if searchText.isEmpty {
                    HelpContactSection()
                }
            }
            .padding(.vertical, 20)
            .padding(.bottom, 92)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Help Center")
        .navigationBarTitleDisplayMode(.inline)
        .searchable(
            text: $searchText,
            isPresented: $isSearchPresented,
            prompt: "Search guides and tasks"
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
                .accessibilityLabel("More Help Center options")
            }
        }
    }
}
private struct HelpWelcomeSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Birdseye, explained", systemImage: "questionmark.circle.fill")
                .font(.title2.weight(.bold))
                .foregroundStyle(.primary)
            Text("Find clear, step-by-step help for managing people, access, operations, and your workspace.")
                .font(.body)
                .foregroundStyle(.secondary)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(
                colors: [Color.blue.opacity(0.18), Color.indigo.opacity(0.10)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 20, style: .continuous)
        )
        .padding(.horizontal, 16)
    }
}
private struct HelpQuickStartSection: View {
    private let guideIDs = [
        "add-authorized-person",
        "ban-person",
        "find-activity-event",
        "invite-team-member"
    ]
    private var guides: [HelpArticle] {
        let articles = HelpTopic.all.flatMap(\.articles)
        return guideIDs.compactMap { identifier in
            articles.first { $0.id == identifier }
        }
    }
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HelpSectionHeader(title: "Learn basics", systemImage: "lightbulb.min")
                .padding(.horizontal, 16)
            ScrollView(.horizontal) {
                HStack(spacing: 12) {
                    ForEach(guides) { article in
                        NavigationLink {
                            HelpArticlePager(selectedArticle: article, articles: HelpTopic.all.flatMap(\.articles))
                        } label: {
                            HelpQuickStartCard(article: article)
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
private struct HelpQuickStartCard: View {
    let article: HelpArticle
    var body: some View {
        HStack(spacing: 12) {
            HelpQuickStartThumbnail(systemImage: article.systemImage)
            VStack(alignment: .leading, spacing: 6) {
                Text(article.title)
                    .font(.headline)
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.leading)
                    .lineLimit(3)
                Spacer(minLength: 0)
                Text("Quick guide")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(10)
        .frame(width: 250, height: 104, alignment: .leading)
        .background(
            Color(.secondarySystemGroupedBackground),
            in: RoundedRectangle(cornerRadius: 18, style: .continuous)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color(.separator).opacity(0.45), lineWidth: 1)
        }
        .accessibilityElement(children: .combine)
        .accessibilityHint("Opens this guide")
    }
}
private struct HelpQuickStartThumbnail: View {
    let systemImage: String
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color.blue.opacity(0.92), Color.cyan.opacity(0.76)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            Circle()
                .fill(.white.opacity(0.14))
                .frame(width: 72, height: 72)
                .offset(x: 26, y: -24)
            Image(systemName: systemImage)
                .font(.title2.weight(.semibold))
                .foregroundStyle(.white)
        }
        .frame(width: 82, height: 82)
        .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
        .accessibilityHidden(true)
    }
}
private struct HelpAISection: View {
    @Environment(AIComposerStore.self) private var aiComposerStore
    private let prompts = [
        "How to give someone access?",
        "How to find a banned driver?",
        "How to find recent arrivals?"
    ]
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HelpSectionHeader(title: "Do it faster with AI", systemImage: "sparkles")
                .padding(.horizontal, 16)
            VStack(spacing: 0) {
                ForEach(prompts, id: \.self) { prompt in
                    Button {
                        aiComposerStore.prompt = prompt
                    } label: {
                        Label(prompt, systemImage: "sparkles")
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .foregroundStyle(Color.accentColor)
                            .multilineTextAlignment(.leading)
                            .padding(16)
                    }
                    .buttonStyle(.plain)
                    if prompt != prompts.last {
                        Divider()
                            .padding(.leading, 48)
                    }
                }
            }
            .background(
                Color(.secondarySystemGroupedBackground),
                in: RoundedRectangle(cornerRadius: 16, style: .continuous)
            )
            .padding(.horizontal, 16)
        }
    }
}
private struct HelpTopicsSection: View {
    let topics: [HelpTopic]
    var body: some View {
        VStack(spacing: 24) {
            ForEach(topics) { topic in
                HelpTopicSection(topic: topic)
            }
        }
    }
}
private struct HelpTopicSection: View {
    let topic: HelpTopic
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HelpSectionHeader(
                title: topic.title,
                systemImage: topic.systemImage,
                iconColor: topic.tint
            )
            .padding(.horizontal, 16)
            VStack(spacing: 0) {
                ForEach(topic.articles) { article in
                    NavigationLink {
                        HelpArticlePager(selectedArticle: article, articles: HelpTopic.all.flatMap(\.articles))
                    } label: {
                        HelpArticleRow(article: article)
                    }
                    .buttonStyle(.plain)
                    if article.id != topic.articles.last?.id {
                        Divider()
                            .padding(.leading, 52)
                    }
                }
            }
            .background(
                Color(.secondarySystemGroupedBackground),
                in: RoundedRectangle(cornerRadius: 16, style: .continuous)
            )
            .padding(.horizontal, 16)
        }
    }
}
private struct HelpArticleRow: View {
    let article: HelpArticle
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: article.systemImage)
                .foregroundStyle(Color.accentColor)
                .frame(width: 24)
            Text(article.title)
                .foregroundStyle(.primary)
            Spacer(minLength: 0)
            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.tertiary)
        }
        .padding(16)
        .contentShape(Rectangle())
    }
}
private struct HelpArticlePager: View {
    let articles: [HelpArticle]
    @State private var selectedArticleID: String
    @State private var isLinkCopied = false
    init(selectedArticle: HelpArticle, articles: [HelpArticle]) {
        self.articles = articles
        _selectedArticleID = State(initialValue: selectedArticle.id)
    }
    private var currentIndex: Int {
        articles.firstIndex { $0.id == selectedArticleID } ?? 0
    }
    private var currentArticle: HelpArticle {
        articles[currentIndex]
    }
    var body: some View {
        TabView(selection: $selectedArticleID) {
            ForEach(Array(articles.enumerated()), id: \.element.id) { index, article in
                HelpArticlePage(
                    article: article,
                    currentIndex: index,
                    topicCount: articles.count,
                    onPrevious: {
                        withAnimation {
                            selectedArticleID = articles[index - 1].id
                        }
                    },
                    onNext: {
                        withAnimation {
                            selectedArticleID = articles[index + 1].id
                        }
                    }
                )
                .tag(article.id)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .background(Color(.systemGroupedBackground))
        .navigationTitle(currentArticle.topicTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button {
                        UIPasteboard.general.url = currentArticle.link
                        isLinkCopied = true
                    } label: {
                        Label(
                            isLinkCopied ? "Link copied" : "Copy link",
                            systemImage: isLinkCopied ? "checkmark" : "link"
                        )
                    }
                    ShareLink(item: currentArticle.link) {
                        Label("Share topic", systemImage: "square.and.arrow.up")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                }
                .accessibilityLabel("Topic options")
            }
        }
    }
}
private struct HelpTopicPagerControls: View {
    let currentIndex: Int
    let topicCount: Int
    let onPrevious: () -> Void
    let onNext: () -> Void
    var body: some View {
        HStack {
            if currentIndex > 0 {
                Button(action: onPrevious) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                        Text("Read previous")
                    }
                }
                .buttonStyle(.plain)
                .foregroundStyle(Color.accentColor)
                .accessibilityHint("Opens topic \(currentIndex) of \(topicCount).")
            }
            Spacer(minLength: 16)
            if currentIndex < topicCount - 1 {
                Button(action: onNext) {
                    HStack(spacing: 4) {
                        Text("Read next")
                        Image(systemName: "chevron.right")
                    }
                }
                .buttonStyle(.plain)
                .foregroundStyle(Color.accentColor)
                .accessibilityHint("Opens topic \(currentIndex + 2) of \(topicCount).")
            }
        }
        .font(.body.weight(.medium))
        .frame(maxWidth: .infinity)
        .padding(.top, 12)
    }
}
private struct HelpArticlePage: View {
    let article: HelpArticle
    let currentIndex: Int
    let topicCount: Int
    let onPrevious: () -> Void
    let onNext: () -> Void
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                HelpArticleIntroduction(
                    title: article.title,
                    summary: article.summary
                )
                ForEach(Array(article.displaySections.enumerated()), id: \.element.id) { index, section in
                    HelpArticleSection(
                        section: section,
                        presentsSummary: index == 0
                    )
                }
                HelpTopicPagerControls(
                    currentIndex: currentIndex,
                    topicCount: topicCount,
                    onPrevious: onPrevious,
                    onNext: onNext
                )
                .padding(.top, 12)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .padding(.bottom, 132)
        }
        .accessibilityLabel(article.title)
    }
}
private struct HelpArticleIntroduction: View {
    let title: String
    let summary: String
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.title.bold())
            Text(summary)
                .font(.body)
                .foregroundStyle(.secondary)
        }
    }
}
private struct HelpArticleHero: View {
    let article: HelpArticle
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [article.tint.opacity(0.88), article.tint.opacity(0.62)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            Circle()
                .fill(.white.opacity(0.16))
                .frame(width: 190, height: 190)
                .offset(x: 112, y: -54)
            Image(systemName: article.systemImage)
                .font(.system(size: 54, weight: .semibold))
                .foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 180)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .accessibilityHidden(true)
    }
}
private struct HelpArticleSection: View {
    let section: HelpContentSection
    let presentsSummary: Bool
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            if section.kind == .ai, let prompt = section.prompt {
                HelpAIInstruction(prompt: prompt)
            } else if section.kind == .faq {
                Text(section.title).font(.title3.weight(.semibold))
                VStack(alignment: .leading, spacing: 16) {
                    ForEach(section.steps) { item in
                        VStack(alignment: .leading, spacing: 5) {
                            Text(item.title).font(.body.weight(.semibold))
                            Text(item.detail).font(.body).foregroundStyle(.secondary)
                        }
                    }
                }
            } else {
                Text(section.title).font(.title3.weight(.semibold))
                if let introduction = section.introduction {
                    Text(introduction).font(.body).foregroundStyle(.secondary)
                }
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(Array(section.steps.enumerated()), id: \.element.id) { index, step in
                        HelpNumberedStep(number: index + 1, detail: step.detail)
                    }
                }
            }
        }
        .padding(.top, 8)
    }
}
private struct HelpAIInstruction: View {
    @Environment(AIComposerStore.self) private var aiComposerStore
    let prompt: String
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Ask AI", systemImage: "sparkles")
                .font(.title3.weight(.semibold))
                .foregroundStyle(Color.accentColor)
            Text("“\(prompt)”")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Button {
                aiComposerStore.prompt = prompt
            } label: {
                Label("Try it", systemImage: "sparkles")
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
    }
}
private struct HelpNumberedStep: View {
    let number: Int
    let detail: String
    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Text("\(number).").font(.body.weight(.semibold))
            Text(detail).font(.body)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
private struct HelpNoSearchResultsSection: View {
    let searchText: String
    let onAskAI: () -> Void
    var body: some View {
        ContentUnavailableView {
            Label("No guides found", systemImage: "magnifyingglass")
        } description: {
            Text("Try a broader search, or ask Birdseye AI for help with \(searchText).")
        } actions: {
            Button("Ask AI", action: onAskAI)
                .buttonStyle(.borderedProminent)
        }
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity)
    }
}
private struct HelpContactSection: View {
    @Environment(\.openURL) private var openURL
    private let supportEmailURL = URL(string: "mailto:cs@birdseye.ca")
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HelpSectionHeader(title: "Need more help?", systemImage: "questionmark.circle")
            Button {
                guard let supportEmailURL else {
                    return
                }
                openURL(supportEmailURL)
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "envelope")
                        .foregroundStyle(Color.accentColor)
                    Text("Contact us")
                        .foregroundStyle(.primary)
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
            .buttonStyle(.plain)
            .accessibilityHint("Opens your email app to contact Birdseye support.")
        }
        .padding(.horizontal, 16)
    }
}
private struct HelpSectionHeader: View {
    let title: String
    let systemImage: String
    var iconColor: Color = .primary
    var body: some View {
        Label {
            Text(title)
                .font(.title3.weight(.semibold))
        } icon: {
            Image(systemName: systemImage)
                .foregroundStyle(Color.accentColor)
        }
        .foregroundStyle(.primary)
    }
}
private struct HelpQuickStartGuide: Identifiable {
    let id = UUID()
    let title: String
    let detail: String
    let systemImage: String
    let prompt: String
}
private struct HelpTopic: Identifiable {
    let id: String
    let title: String
    let summary: String
    let systemImage: String
    let tint: Color
    let articles: [HelpArticle]
    func matches(_ query: String) -> Bool {
        title.localizedCaseInsensitiveContains(query) || summary.localizedCaseInsensitiveContains(query)
    }
    static let all: [HelpTopic] = [
        HelpTopic(id: "authorizations", title: "Authorized People", summary: "Add people and manage where and when they can enter.", systemImage: "person.crop.circle.badge.checkmark", tint: .green, articles: [
            article("add-authorized-person", "How to add an authorized person", "Add drivers, employees, contractors, or visitors.", "person.badge.plus", "authorizations", "Authorized People", [
                .ai("Add John Smith as a driver and authorize him for Northstar Oshawa."),
                .manual("Do it manually", ["Open People and tap +.", "Enter the full name and any additional details.", "Review Access policy and tap Save."]),
                .faq([("Can I scan a driver's license?", "Yes. Use Quick scan to fill in available information, then review it."), ("Is an organization required?", "No. Only the full name is required by default.")])
            ]),
            article("find-person", "How to find a person", "Find people and check their authorization details.", "magnifyingglass", "authorizations", "Authorized People", [
                .ai("Find all drivers from FedEx authorized at Northstar Oshawa."),
                .manual("Search manually", ["Open People and tap Search.", "Enter a name and select the matching result."]),
                .faq([("Can't find someone?", "Check the selected location and active filters.")])
            ]),
            article("edit-person", "How to edit a person", "Keep personal details and authorizations up to date.", "pencil", "authorizations", "Authorized People", [
                .ai("Change John Smith's organization to FedEx."),
                .manual("Do it manually", ["Open People and select the person.", "Edit their details or access policy.", "Tap Save."])
            ]),
            article("manage-person-access", "How to manage access permissions", "Control which locations a person can access.", "checkmark.shield", "authorizations", "Authorized People", [
                .ai("Give John Smith access to all locations."),
                .manual("Do it manually", ["Open the person's Access policy.", "Select locations, access type, and access period.", "Tap Save."]),
                .faq([("What is Default Access?", "The standard location access policy."), ("What is Specialized Access?", "An access policy with additional conditions.")])
            ]),
            article("temporary-person-access", "How to set temporary access", "Restrict authorization to selected periods.", "clock", "authorizations", "Authorized People", [
                .ai("Give John Smith temporary access to Northstar Oshawa."),
                .manual("Do it manually", ["Open the person's Access policy.", "Change Period access or enable Limited time access.", "Set the period and tap Save."]),
                .faq([("What does Ongoing mean?", "The authorization has no predefined end date.")])
            ]),
            article("sort-filter-people", "How to sort and filter people", "Organize the People list to find records faster.", "line.3.horizontal.decrease.circle", "authorizations", "Authorized People", [
                .manual("Sort and filter", ["Open People and tap the three-dot menu.", "Choose a sort option, such as Name A-Z or Recently added.", "Select Active only to limit results."]),
                .faq([("How do I restore the original list?", "Use Reset view to clear custom sorting and filters.")])
            ]),
            article("ban-person", "How to ban or unban a person", "Block or restore a person's access to your locations.", "person.crop.circle.badge.xmark", "authorizations", "Authorized People", [
                .manual("Do it manually", ["Open People and select the person.", "Open Access policy and set Access type to Banned Access.", "Tap Save. To unban them, select the appropriate access type and save again."]),
                .ai("Ban Olivia Martin from all locations."),
                .faq([("Does banning delete the person?", "No. Their record remains available to manage."), ("How do I restore access?", "Change Banned Access to the appropriate access type and save.")])
            ]),
            article("people-faq", "Frequently asked questions about people", "Quick answers about people and authorizations.", "questionmark.circle", "authorizations", "Authorized People", [
                .faq([("Can someone access multiple locations?", "Yes. Select multiple locations or All locations."), ("Do I have to use AI?", "No. You can also manage records manually."), ("Can I edit someone added through AI?", "Yes. AI and manual changes use the same records."), ("Does adding a person guarantee entry?", "No. Entry still depends on their access policy and required checks.")])
            ])
        ]),
        HelpTopic(id: "organizations", title: "Authorized Organizations", summary: "Manage companies, carriers, and vendors.", systemImage: "building.2", tint: .indigo, articles: [
            article("create-organization", "How to add an organization", "Create a company record for authorization.", "building.2.crop.circle", "organizations", "Organizations", [
                .ai("Authorize ABC Logistics for Northstar Oshawa."),
                .manual("Do it manually", ["Open Organizations and tap +.", "Enter the organization name and available details.", "Review the access policy and tap Save."]),
                .faq([("Can an organization cover multiple locations?", "Yes. Set the appropriate locations in its access policy.")])
            ]),
            article("find-organization", "How to find an organization", "Find an existing company before adding a duplicate.", "magnifyingglass", "organizations", "Organizations", [
                .ai("Find ABC Logistics and show its authorized locations."),
                .manual("Search manually", ["Open Organizations and tap Search.", "Enter the company name and select a match."])
            ]),
            article("ban-organization", "How to ban or unban an organization", "Block or restore authorization for a company or carrier.", "building.2.crop.circle", "organizations", "Authorized Organizations", [
                .manual("Do it manually", ["Open Organizations and select the organization.", "Open Access policy and choose Banned Access.", "Tap Save. To unban it, choose the appropriate access type and save."]),
                .ai("Ban ABC Logistics from Northstar Oshawa."),
                .faq([("Does banning remove the organization?", "No. The organization record stays in the directory.")])
            ]),
            article("edit-organization", "How to update an organization", "Change company information or access.", "pencil", "organizations", "Organizations", [
                .ai("Give ABC Logistics access to all locations."),
                .manual("Do it manually", ["Open Organizations and select the company.", "Edit its details or access policy.", "Tap Save."])
            ])
        ]),
        HelpTopic(id: "equipment", title: "Authorized Equipment", summary: "Authorize trucks, trailers, cars, and service vehicles.", systemImage: "truck.box", tint: .brown, articles: [
            article("manage-equipment", "How to add authorized equipment", "Create a record for a truck, trailer, car, or service vehicle.", "plus.circle", "equipment", "Equipment", [
                .ai("Authorize truck unit 204 from ABC Logistics for Northstar Oshawa."),
                .manual("Do it manually", ["Open Equipment and tap +.", "Select the equipment type and enter its identifiers.", "Review access settings and tap Save."]),
                .faq([("Can equipment be linked to a person or organization?", "Yes. Add those relationships when available.")])
            ]),
            article("ban-equipment", "How to ban or unban equipment", "Block or restore authorization for a truck, trailer, car, or service vehicle.", "hand.raised", "equipment", "Authorized Equipment", [
                .manual("Do it manually", ["Open Equipment and select the vehicle or trailer.", "Open Access policy and choose Banned Access.", "Tap Save. To unban it, choose the appropriate access type and save."]),
                .ai("Ban truck unit 204 from all locations."),
                .faq([("Does banning delete equipment?", "No. You can find its record and update the access policy later.")])
            ]),
            article("find-edit-equipment", "How to find or update equipment", "Find equipment by its identifying information.", "magnifyingglass", "equipment", "Equipment", [
                .ai("Find truck unit 204 and show its authorization."),
                .manual("Do it manually", ["Open Equipment and search by unit or license plate.", "Select the record, make changes, and tap Save."])
            ])
        ]),
        HelpTopic(id: "appointments", title: "Appointments", summary: "Create and manage scheduled visits.", systemImage: "calendar", tint: .pink, articles: [
            article("schedule-appointment", "How to schedule an appointment", "Record who is arriving and when.", "calendar.badge.plus", "appointments", "Appointments", [
                .ai("Schedule an inbound appointment for John Smith at Northstar Oshawa tomorrow at 10 AM."),
                .manual("Do it manually", ["Open Appointments and tap +.", "Select the date, time, and direction.", "Add available person or vehicle details and tap Save."]),
                .faq([("Which fields are required?", "Date, time, and direction.")])
            ]),
            article("edit-appointment", "How to update an appointment", "Keep visit information accurate.", "calendar", "appointments", "Appointments", [
                .ai("Find John Smith's appointment and change the arrival time to 11 AM."),
                .manual("Do it manually", ["Open Appointments and find the visit.", "Edit the required details.", "Tap Save."])
            ])
        ]),
        HelpTopic(id: "team", title: "Team", summary: "Invite members and manage workspace access.", systemImage: "person.2.fill", tint: .blue, articles: [
            article("invite-team-member", "How to invite a team member", "Invite someone to your Birdseye workspace.", "person.badge.plus", "team", "Team", [
                .manual("Do it manually", ["Open Team and tap Invite member.", "Enter the member's email address and username.", "Assign organizations, locations, and feature permissions.", "Send the invitation."]),
                .ai("Invite alex.morgan@northstar.com to the team with access to Northstar Dallas."),
                .faq([("Can I assign multiple locations?", "Yes. Members can have access to multiple locations and organizations."), ("Can I change permissions later?", "Yes. Open their profile and edit Permissions.")])
            ]),
            article("find-team-member", "How to find a team member", "Review members and their current status.", "person.crop.circle", "team", "Team", [
                .manual("Do it manually", ["Open Team to view workspace members.", "Find the member by username.", "Tap their name to see account details and permissions."]),
                .ai("Show team members who can access Northstar Dallas.")
            ]),
            article("edit-team-member", "How to edit a team member", "Update a member's email or username.", "pencil", "team", "Team", [
                .manual("Do it manually", ["Open Team and select the member.", "Edit their email address or username.", "Save the changes." ]),
                .ai("Update Sarah Patel's username to sarah.patel.")
            ]),
            article("change-member-status", "How to activate or deactivate a member", "Choose whether someone can sign in.", "person.crop.circle.badge.xmark", "team", "Team", [
                .manual("Do it manually", ["Open Team and select a member.", "Use the Status switch to activate or deactivate the account.", "Save if prompted."]),
                .ai("Deactivate Sarah Patel's account."),
                .faq([("What happens when a member is inactive?", "Inactive users cannot log in to the system."), ("Can I reactivate them?", "Yes. Turn Status back on.")])
            ]),
            article("assign-member-organization", "How to assign organizations", "Give a member access to one or more organizations.", "building.2", "team", "Team", [
                .manual("Do it manually", ["Open Team and select the member.", "In Permissions, tap Add org.", "Choose the organization and its locations.", "Set access for each location and save."]),
                .ai("Give Sarah Patel access to Atlas Distribution in Chicago and Detroit."),
                .faq([("Can I remove an organization?", "Yes. Use the delete icon beside the organization in Permissions.")])
            ]),
            article("manage-member-locations", "How to manage location access", "Control which sites a member can access.", "mappin.and.ellipse", "team", "Team", [
                .manual("Do it manually", ["Open Team and select the member.", "Expand the organization under Permissions.", "Review the assigned locations and update the selection.", "Save the changes."]),
                .ai("Remove Sarah Patel's access to Northstar Toronto but keep Dallas and Oshawa."),
                .faq([("Can locations have different permissions?", "Yes. Configure permissions independently for each location.")])
            ]),
            article("configure-member-permissions", "How to configure permissions", "Choose which features someone can view or manage.", "slider.horizontal.3", "team", "Team", [
                .manual("Do it manually", ["Open Team and select a member.", "Expand an organization and one of its locations.", "Select a feature and choose No access, View access, or Full access.", "Repeat for other features and save."]),
                .ai("Give Sarah Patel View access to Equipment at Northstar Dallas."),
                .faq([("What is No access?", "The feature is unavailable to that member."), ("What is View access?", "The member can see the feature but cannot make changes."), ("What is Full access?", "The member can view and manage the feature."), ("What is Custom access?", "The location uses individually configured feature permissions.")])
            ]),
            article("revoke-member-access", "How to revoke member access", "Restrict a feature or remove an organization.", "lock.shield", "team", "Team", [
                .manual("Do it manually", ["Open Team and select the member.", "Expand the organization and location under Permissions.", "Choose No access for features that should be restricted, or remove the organization using the delete icon.", "Save the changes."]),
                .ai("Remove Sarah Patel's access to Atlas Distribution."),
                .faq([("Do I need to deactivate the user?", "No. You can revoke specific permissions while keeping their account active.")])
            ])
        ]),
        HelpTopic(id: "activity", title: "Activity", summary: "Find events, review outcomes, and investigate access issues.", systemImage: "waveform.path.ecg", tint: .red, articles: [
            article("review-events", "How to review access activity", "See recent access events and their outcomes.", "list.bullet.rectangle", "activity", "Activity", [
                .manual("Do it manually", ["Open Activity.", "Select the location and date range.", "Open an event to review its details and outcome."]),
                .ai("Show me recent access activity at Northstar Oshawa."),
                .faq([("What information can I review?", "Check the recorded location, time, and outcome of an event.")])
            ]),
            article("find-activity-event", "How to find a specific event", "Locate an event without scrolling through the entire list.", "magnifyingglass", "activity", "Activity", [
                .manual("Do it manually", ["Open Activity and select the relevant location.", "Set the date range and use available search or filters.", "Open the matching event to confirm its details."]),
                .ai("Find access events involving John Smith at Northstar Oshawa today."),
                .faq([("Can't find an event?", "Check the date range, selected location, and any active filters.")])
            ]),
            article("filter-access-activity", "How to filter access activity", "Narrow events by date, location, or other available filters.", "line.3.horizontal.decrease.circle", "activity", "Activity", [
                .manual("Do it manually", ["Open Activity.", "Select a location and date range.", "Apply any additional available filters to narrow the results."]),
                .ai("Show access activity at Northstar Oshawa from the past 7 days."),
                .faq([("Why am I missing some events?", "Check your selected location, date range, and active filters.")])
            ]),
            article("report-activity-issue", "How to report incorrect activity", "Review a questionable event and share the details with support.", "exclamationmark.bubble", "activity", "Activity", [
                .manual("Do it manually", ["Open the event that looks incorrect.", "Check the person or equipment, location, time, and recorded outcome.", "Contact support with the event details and explain what seems wrong."]),
                .ai("Help me investigate an incorrect access event at Northstar Oshawa."),
                .faq([("Can I edit the event itself?", "Activity events are records of what happened. Report inaccuracies rather than changing the recorded event.")])
            ])
        ])
    ]
}
private func article(_ id: String, _ title: String, _ summary: String, _ image: String,
                     _ topicID: String, _ topicTitle: String, _ sections: [HelpContentSection]) -> HelpArticle {
    HelpArticle(id: id, topicID: topicID, topicTitle: topicTitle, title: title,
                summary: summary, systemImage: image, tint: .accentColor, sections: sections)
}
private struct HelpArticle: Identifiable {
    let id: String
    let topicID: String
    let topicTitle: String
    let title: String
    let summary: String
    let systemImage: String
    let tint: Color
    let sections: [HelpContentSection]
    var displaySections: [HelpContentSection] {
        // Manual instructions first, AI prompt second, FAQs last.
        sections.filter { $0.kind == .manual }
        + sections.filter { $0.kind == .ai }
        + sections.filter { $0.kind == .faq }
    }
    var link: URL {
        URL(string: "https://birdseye.app/help/\(topicID)/\(id)")!
    }
    func matches(_ query: String) -> Bool {
        title.localizedCaseInsensitiveContains(query)
        || summary.localizedCaseInsensitiveContains(query)
        || sections.contains { $0.matches(query) }
    }
}
private enum HelpSectionKind: Equatable { case ai, manual, faq }
private struct HelpContentSection: Identifiable {
    let id: String
    let title: String
    let kind: HelpSectionKind
    let prompt: String?
    let introduction: String?
    let steps: [HelpContentStep]
    static func ai(_ prompt: String) -> HelpContentSection {
        HelpContentSection(id: "ai", title: "Ask AI", kind: .ai,
                           prompt: prompt, introduction: nil, steps: [])
    }
    static func manual(_ title: String, _ steps: [String]) -> HelpContentSection {
        HelpContentSection(id: "manual", title: title, kind: .manual, prompt: nil,
                           introduction: nil,
                           steps: steps.enumerated().map { HelpContentStep(title: "Step \($0.offset + 1)", detail: $0.element) })
    }
    static func faq(_ questions: [(String, String)]) -> HelpContentSection {
        HelpContentSection(id: "faq", title: "Frequently asked questions", kind: .faq,
                           prompt: nil, introduction: nil,
                           steps: questions.map { HelpContentStep(title: $0.0, detail: $0.1) })
    }
    func matches(_ query: String) -> Bool {
        title.localizedCaseInsensitiveContains(query)
        || prompt?.localizedCaseInsensitiveContains(query) == true
        || steps.contains { $0.matches(query) }
    }
}
private struct HelpContentStep: Identifiable {
    let title: String
    let detail: String
    var id: String { title }
    func matches(_ query: String) -> Bool {
        title.localizedCaseInsensitiveContains(query) || detail.localizedCaseInsensitiveContains(query)
    }
}
