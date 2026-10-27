import SwiftUI
import AVKit
import UIKit
import Combine

struct AIView: View {

    @Binding var query: String
    @Binding var messages: [AIMessage]
    @Binding var conversations: [AIConversation]
    @Binding var activeConversationID: UUID?
    @Binding var isThreadPresented: Bool
    @Binding var currentConversationTitle: String
    @Binding var restoredTutorial: AITutorial?

    let onThreadDismiss: () -> Void
    let onAuthorizationExampleSelected: () -> Void
    let onOpenNow: () -> Void
    let onMinimizeTutorial: (AITutorial) -> Void

    @State private var exampleScrollID: String?
    @State private var isDraggingExamples = false
    @State private var selectedTutorial: AITutorial?
    @State private var tutorialDestination: AITutorial?
    @State private var isStartHereExpanded = true
    @State private var isCloseOnboardingConfirmationPresented = false
    @State private var teamInvitationEmail = ""
    @State private var isTeamInvitePresented = false
    @State private var onboardingCardScrollID: String? = "learnBasics"

    @Environment(\.colorScheme) private var colorScheme

    @AppStorage("onboardingStartHereDismissed") private var isStartHereDismissed = false
    @AppStorage("onboardingAuthorizedPersonComplete") private var isAuthorizedPersonComplete = false
    @AppStorage("onboardingCrewComplete") private var isCrewComplete = false
    @AppStorage("onboardingAIComplete") private var isAIComplete = false

    private let exampleAutoScroll = Timer
        .publish(
            every: 4.8,
            on: .main,
            in: .common
        )
        .autoconnect()

    private let examples: [AIExample] = [
        AIExample(
            id: "people",
            category: "People",
            title: "Authorize a person",
            systemImage: "person.badge.plus",
            tint: .blue
        ),
        AIExample(
            id: "find",
            category: "Search",
            title: "Find anything in seconds",
            systemImage: "magnifyingglass",
            tint: .blue
        ),
        AIExample(
            id: "activity",
            category: "Activity",
            title: "Ask about today's yard activity",
            systemImage: "sparkles",
            tint: .blue
        ),
        AIExample(
            id: "appointments",
            category: "Appointments",
            title: "What appointments are scheduled today?",
            systemImage: "calendar",
            tint: .orange
        ),
        AIExample(
            id: "activity",
            category: "Activity",
            title: "How many people entered yesterday?",
            systemImage: "arrow.right.arrow.left",
            tint: .blue
        ),
        AIExample(
            id: "review",
            category: "Review",
            title: "Show events that need review",
            systemImage: "exclamationmark.bubble.fill",
            tint: .purple
        )
    ]

    init(
        query: Binding<String> = .constant(""),
        messages: Binding<[AIMessage]> = .constant([]),
        conversations: Binding<[AIConversation]> = .constant([]),
        activeConversationID: Binding<UUID?> = .constant(nil),
        isThreadPresented: Binding<Bool> = .constant(false),
        currentConversationTitle: Binding<String> = .constant("New conversation"),
        restoredTutorial: Binding<AITutorial?> = .constant(nil),
        onThreadDismiss: @escaping () -> Void = {},
        onAuthorizationExampleSelected: @escaping () -> Void = {},
        onOpenNow: @escaping () -> Void = {},
        onMinimizeTutorial: @escaping (AITutorial) -> Void = { _ in }
    ) {
        _query = query
        _messages = messages
        _conversations = conversations
        _activeConversationID = activeConversationID
        _isThreadPresented = isThreadPresented
        _currentConversationTitle = currentConversationTitle
        _restoredTutorial = restoredTutorial
        self.onThreadDismiss = onThreadDismiss
        self.onAuthorizationExampleSelected = onAuthorizationExampleSelected
        self.onOpenNow = onOpenNow
        self.onMinimizeTutorial = onMinimizeTutorial
    }

    var body: some View {
        ZStack {
            NavigationStack {
                landingContent
                    .navigationDestination(
                        isPresented: $isThreadPresented
                    ) {
                        AIThreadView(
                            title: $currentConversationTitle,
                            messages: $messages,
                            isPresented: $isThreadPresented,
                            onMessagesChanged: syncCurrentConversation,
                            onEdit: {
                                query = $0
                            },
                            onNewConversation: startNewConversation
                        )
                    }
                    .navigationDestination(item: $tutorialDestination) { destination in
                        tutorialDestinationView(for: destination)
                    }
            }

        }
        .fullScreenCover(item: $selectedTutorial) { tutorial in
            tutorialOverlay(for: tutorial)
                .presentationBackground(.clear)
        }
        .onChange(
            of: isThreadPresented
        ) { _, isPresented in
            if !isPresented {
                onThreadDismiss()
            }
        }
        .onChange(of: restoredTutorial) { _, tutorial in
            guard let tutorial else {
                return
            }

            selectedTutorial = tutorial
            restoredTutorial = nil
        }
    }
    private func tutorialOverlay(for tutorial: AITutorial) -> some View {
        ZStack {
            Color.black.opacity(0.18)
                .ignoresSafeArea()

            GeometryReader { proxy in
                let cardWidth = min(proxy.size.width - 32, 480)
                let cardHeight = min(proxy.size.height - 100, 760)

                AITutorialStoryExperience(
                    tutorial: tutorial,
                    isComplete: completionBinding(for: tutorial),
                    onDismiss: {
                        selectedTutorial = nil
                    },
                    onTryItYourself: {
                        openTutorialDestination(tutorial)
                    },
                    onNextTutorial: {
                        selectedTutorial = nil
                    },
                    isCardPresentation: true
                )
                .id(tutorial.id)
                .frame(width: cardWidth, height: cardHeight)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .ignoresSafeArea()
        .zIndex(10_000)
    }

    private var landingContent: some View {
        ScrollView {
            VStack(
                alignment: .leading,
                spacing: 16
            ) {
                BirdseyePageTitle(
                    title: "Ask Birdseye AI"
                )
                .padding(.top, 16)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Tell it what you need, just like typing an email.")
                        .font(.subheadline.weight(.semibold))

                    Text("Authorize people, update someone's access, or find records in seconds.")
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)

                Spacer(minLength: 4)

                exampleSection
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 120)
            .frame(maxWidth: .infinity, alignment: .top)
        }
        .birdseyeRefreshable()
        .background(
            Color(.systemGroupedBackground)
        )
        .birdseyeMainTabPage()
        .toolbarBackground(.visible, for: .navigationBar)
        .confirmationDialog(
            "Close onboarding?",
            isPresented: $isCloseOnboardingConfirmationPresented,
            titleVisibility: .visible
        ) {
            Button("Close onboarding", role: .destructive) {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isStartHereDismissed = true
                    onboardingCardScrollID = "inviteTeam"
                }
            }
        } message: {
            Text("All Start here steps will remain available in Help Center whenever you need them.")
        }
        .sheet(isPresented: $isTeamInvitePresented) {
            InviteTeamMemberView(email: $teamInvitationEmail) { _, _ in
                isCrewComplete = true
                teamInvitationEmail = ""
            }
        }
    }

    private func openTutorialDestination(_ tutorial: AITutorial) {
        selectedTutorial = nil

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            switch tutorial {
            case .authorizeDriver:
                onOpenNow()
            case .askAI:
                query = "Help me get started with Birdseye AI."
            case .inviteTeam:
                tutorialDestination = tutorial
            }
        }
    }

    @ViewBuilder
    private func tutorialDestinationView(for tutorial: AITutorial) -> some View {
        switch tutorial {
        case .authorizeDriver:
            AuthorizedPeopleOperationsView(startsPersonTutorial: true)
        case .inviteTeam:
            TeamView()
        case .askAI:
            EmptyView()
        }
    }

    // MARK: - Examples

    private var exampleSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            ScrollView(.horizontal) {
                LazyHStack(spacing: 16) {
                    if !isStartHereDismissed {
                VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 10) {
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            isStartHereExpanded.toggle()
                        }
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: "lightbulb.min")
                                .font(.title3.weight(.semibold))
                                .foregroundStyle(.primary)
                                .symbolRenderingMode(.hierarchical)
                                .tint(.blue)

                            Text("Start here")
                                .font(.title3.weight(.bold))
                                .foregroundStyle(.primary)

                            Text("\(completedTutorialCount)/\(AITutorial.allCases.count)")
                                .font(.subheadline.weight(.semibold).monospacedDigit())
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 9)
                                .padding(.vertical, 5)
                                .background(.secondary.opacity(0.12), in: Capsule())
                        }
                    }
                    .buttonStyle(.plain)

                    Spacer()

                    if completedTutorialCount == AITutorial.allCases.count {
                        Button {
                            isCloseOnboardingConfirmationPresented = true
                        } label: {
                            Label("Complete", systemImage: "checkmark")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 9)
                                .background(Color.green, in: Capsule())
                        }
                        .buttonStyle(.plain)
                    } else {
                        NavigationLink {
                            HelpView()
                        } label: {
                            Label("See all", systemImage: "arrow.right")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(Color.accentColor)
                        }
                        .buttonStyle(.plain)
                    }
                }

                if isStartHereExpanded {
                    HStack(alignment: .top, spacing: 0) {
                        ForEach(AITutorial.allCases) { tutorial in
                            AITutorialStoryCircle(
                                tutorial: tutorial,
                                isComplete: completionBinding(for: tutorial),
                                onOpen: { selectedTutorial = tutorial }
                            )
                            .frame(maxWidth: .infinity)
                        }
                    }
                    .padding(.vertical, 2)
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
                }
                .padding(20)
                .frame(height: 200, alignment: .top)
                .background(
                    colorScheme == .dark ? Color(.secondarySystemGroupedBackground) : .white,
                    in: RoundedRectangle(cornerRadius: 28, style: .continuous)
                )
                .containerRelativeFrame(.horizontal, count: 1, spacing: 16)
                .id("learnBasics")
                    }

                InviteTeamActionCard(
                    invitationEmail: $teamInvitationEmail,
                    isInvitePresented: $isTeamInvitePresented
                )
                .containerRelativeFrame(.horizontal, count: 1, spacing: 16)
                .id("inviteTeam")

                sendRequestCard
                    .containerRelativeFrame(.horizontal, count: 1, spacing: 16)
                    .id("sendRequest")
                }
                .scrollTargetLayout()
            }
            .scrollIndicators(.hidden)
            .scrollTargetBehavior(.viewAligned)
            .scrollPosition(id: $onboardingCardScrollID)

            HStack(spacing: 8) {
                ForEach(onboardingCardIDs, id: \.self) { cardID in
                    Capsule()
                        .fill(cardID == onboardingCardScrollID ? Color.accentColor : Color.secondary.opacity(0.28))
                        .frame(width: cardID == onboardingCardScrollID ? 18 : 6, height: 6)
                }
            }
            .frame(maxWidth: .infinity)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(onboardingCardAccessibilityLabel)

            VStack(alignment: .leading, spacing: 10) {
                Text("Try these examples")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)

                ForEach(examples.prefix(3)) { example in
                    Button {
                        query = example.title
                        if example.id == "people" {
                            onAuthorizationExampleSelected()
                        }
                    } label: {
                        AIExampleCard(example: example)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.top, 10)
        }
    }

    private var teamInvitationCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 16) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Invite users")
                        .font(.title3.weight(.bold))

                    Text("Manage access, view activity, and submit requests together in Birdseye.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(3)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)

                Image(systemName: "person.2.badge.plus")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(Color.accentColor)
                    .frame(width: 58, height: 58)
                    .background(Color.accentColor.opacity(0.16), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .accessibilityHidden(true)
            }

            Spacer(minLength: 0)

            HStack(spacing: 10) {
                Image(systemName: "envelope")
                    .font(.body.weight(.medium))
                    .foregroundStyle(.secondary)
                    .accessibilityHidden(true)

                TextField("Email address", text: $teamInvitationEmail)
                    .textContentType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .keyboardType(.emailAddress)
                    .submitLabel(.go)
                    .onSubmit {
                        isTeamInvitePresented = true
                    }

                Button {
                    isTeamInvitePresented = true
                } label: {
                    Image(systemName: "arrow.right")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(.white)
                        .frame(width: 40, height: 40)
                        .background(Color.accentColor, in: Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Invite user")
            }
            .padding(.leading, 16)
            .padding(.trailing, 8)
            .frame(minHeight: 54)
            .background(
                colorScheme == .dark ? Color(.secondarySystemGroupedBackground) : .white,
                in: RoundedRectangle(cornerRadius: 16, style: .continuous)
            )
        }
        .padding(20)
        .frame(height: 200, alignment: .top)
        .background(
            Color.accentColor.opacity(colorScheme == .dark ? 0.26 : 0.12),
            in: RoundedRectangle(cornerRadius: 28, style: .continuous)
        )
    }

    private var sendRequestCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 16) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Send us a request")
                        .font(.title3.weight(.bold))

                    Text("Request footage, a protocol change, or an update to service hours.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(3)
                }

                Spacer(minLength: 0)

                Image(systemName: "envelope")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(Color.accentColor)
                    .frame(width: 58, height: 58)
                    .background(Color.accentColor.opacity(0.16), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .accessibilityHidden(true)
            }

            Spacer(minLength: 0)

            NavigationLink {
                RequestsView()
            } label: {
                Label("Open requests", systemImage: "arrow.right")
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, minHeight: 54)
                    .background(
                        Color.accentColor,
                        in: RoundedRectangle(cornerRadius: 16, style: .continuous)
                    )
            }
            .buttonStyle(.plain)
        }
        .padding(20)
        .frame(height: 200, alignment: .top)
        .background(
            colorScheme == .dark ? Color(.secondarySystemGroupedBackground) : .white,
            in: RoundedRectangle(cornerRadius: 28, style: .continuous)
        )
    }

    private var onboardingCardIDs: [String] {
        isStartHereDismissed
            ? ["inviteTeam", "sendRequest"]
            : ["learnBasics", "inviteTeam", "sendRequest"]
    }

    private var onboardingCardAccessibilityLabel: String {
        let cardID = onboardingCardScrollID ?? onboardingCardIDs[0]
        let position = (onboardingCardIDs.firstIndex(of: cardID) ?? 0) + 1
        let title: String

        switch cardID {
        case "inviteTeam":
            title = "Invite users"
        case "sendRequest":
            title = "Send us a request"
        default:
            title = "Learn basics"
        }

        return "\(title) card, \(position) of \(onboardingCardIDs.count)"
    }

    private var completedTutorialCount: Int {
        [
            isAuthorizedPersonComplete,
            isCrewComplete,
            isAIComplete
        ].filter { $0 }.count
    }

    private var firstIncompleteTutorial: AITutorial? {
        AITutorial.allCases.first { tutorial in
            !completionBinding(for: tutorial).wrappedValue
        }
    }

    private func scrollTutorials(to proxy: ScrollViewProxy) {
        guard let tutorial = firstIncompleteTutorial else {
            return
        }

        DispatchQueue.main.async {
            withAnimation(.easeInOut(duration: 0.7)) {
                proxy.scrollTo(tutorial, anchor: .leading)
            }
        }
    }

    private func completionBinding(for tutorial: AITutorial) -> Binding<Bool> {
        switch tutorial {
        case .authorizeDriver:
            return $isAuthorizedPersonComplete
        case .inviteTeam:
            return $isCrewComplete
        case .askAI:
            return $isAIComplete
        }
    }
    
    private func exampleEdgeFade(
        isLeading: Bool
    ) -> some View {
        Rectangle()
            .fill(.ultraThinMaterial)
            .frame(width: 22)
            .mask {
                LinearGradient(
                    colors: isLeading
                        ? [
                            .black,
                            .black.opacity(0.65),
                            .clear
                        ]
                        : [
                            .clear,
                            .black.opacity(0.65),
                            .black
                        ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            }
            .allowsHitTesting(false)
    }
    
    private func advanceExamples() {
        guard
            !isDraggingExamples,
            !examples.isEmpty
        else {
            return
        }

        let currentIndex = examples.firstIndex {
            $0.id == exampleScrollID
        } ?? -1

        let nextIndex = (
            currentIndex + 1
        ) % examples.count

        withAnimation(
            .easeInOut(
                duration: 1.15
            )
        ) {
            exampleScrollID =
                examples[nextIndex].id
        }
    }

    // MARK: - History

    private var historySection: some View {
        VStack(
            alignment: .leading,
            spacing: 10
        ) {
            HStack {
                Text("Conversation history")
                    .font(
                        .subheadline.weight(.semibold)
                    )
                    .foregroundStyle(.secondary)

                Spacer()

                if !conversations.isEmpty {
                    Text(
                        "\(conversations.count)"
                    )
                    .font(
                        .caption.weight(.semibold)
                    )
                    .foregroundStyle(.secondary)
                }
            }

            if conversations.isEmpty {
                ContentUnavailableView(
                    "No conversations yet",
                    systemImage:
                        "bubble.left.and.bubble.right",
                    description: Text(
                        "Your AI conversations will appear here."
                    )
                )
                .frame(
                    maxWidth: .infinity
                )
                .padding(.vertical, 18)

            } else {
                VStack(spacing: 0) {
                    ForEach(
                        conversations
                    ) { conversation in

                        Button {
                            open(conversation)
                        } label: {
                            VStack(
                                alignment: .leading,
                                spacing: 6
                            ) {
                                HStack {
                                    Text(
                                        conversation.title
                                    )
                                    .font(
                                        .body.weight(
                                            .semibold
                                        )
                                    )
                                    .lineLimit(1)

                                    Spacer()

                                    Text(
                                        conversation.updatedAt,
                                        format: .dateTime
                                            .hour()
                                            .minute()
                                    )
                                    .font(.caption)
                                    .foregroundStyle(
                                        .secondary
                                    )
                                }

                                Text(
                                    conversation.preview
                                )
                                .font(.subheadline)
                                .foregroundStyle(
                                    .secondary
                                )
                                .lineLimit(2)

                                Text(
                                    "\(conversation.messages.count) messages"
                                )
                                .font(.caption)
                                .foregroundStyle(
                                    .tertiary
                                )
                            }
                            .padding(16)
                            .frame(
                                maxWidth: .infinity,
                                alignment: .leading
                            )
                            .contentShape(
                                Rectangle()
                            )
                        }
                        .buttonStyle(.plain)
                        .contextMenu {
                            Button(
                                role: .destructive
                            ) {
                                HapticFeedback.criticalAction()
                                delete(
                                    conversation
                                )
                            } label: {
                                Label(
                                    "Delete conversation",
                                    systemImage: "trash"
                                )
                            }
                        }

                        if conversation.id !=
                            conversations.last?.id {
                            Divider()
                        }
                    }
                }
                .background(
                    Color(
                        .secondarySystemGroupedBackground
                    ),
                    in: RoundedRectangle(
                        cornerRadius: 24,
                        style: .continuous
                    )
                )
            }
        }
    }

    // MARK: - Conversation Actions

    private func startNewConversation() {
        messages = []
        currentConversationTitle =
            "New conversation"

        let id = UUID()

        activeConversationID = id
        isThreadPresented = true
    }

    private func open(
        _ conversation: AIConversation
    ) {
        messages = conversation.messages
        currentConversationTitle =
            conversation.title
        activeConversationID =
            conversation.id
        isThreadPresented = true
    }

    private func delete(
        _ conversation: AIConversation
    ) {
        conversations.removeAll {
            $0.id == conversation.id
        }

        if activeConversationID ==
            conversation.id {

            messages = []
            activeConversationID = nil
            isThreadPresented = false
        }
    }

    private func syncCurrentConversation() {
        guard let activeConversationID else {
            return
        }

        if let index =
            conversations.firstIndex(
                where: {
                    $0.id ==
                        activeConversationID
                }
            ) {

            if messages.isEmpty {
                conversations.remove(
                    at: index
                )
            } else {
                conversations[index]
                    .messages = messages

                conversations[index]
                    .updatedAt = Date()

                conversations[index]
                    .title =
                    currentConversationTitle
            }

        } else if !messages.isEmpty {

            conversations.insert(
                AIConversation(
                    id: activeConversationID,
                    title:
                        currentConversationTitle,
                    messages: messages
                ),
                at: 0
            )
        }
    }
}


struct InviteTeamActionCard: View {
    @Binding var invitationEmail: String
    @Binding var isInvitePresented: Bool
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 16) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Invite users")
                        .font(.title3.weight(.bold))
                        .foregroundStyle(.primary)

                    Text("Manage access, view activity, and submit requests together in Birdseye.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(3)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)

                Image(systemName: "person.2.badge.plus")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(Color.accentColor)
                    .frame(width: 58, height: 58)
                    .background(Color.accentColor.opacity(0.16), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .accessibilityHidden(true)
            }

            Spacer(minLength: 0)

            HStack(spacing: 10) {
                Image(systemName: "envelope")
                    .font(.body.weight(.medium))
                    .foregroundStyle(.secondary)
                    .accessibilityHidden(true)

                TextField("Email address", text: $invitationEmail)
                    .textContentType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .keyboardType(.emailAddress)
                    .submitLabel(.go)
                    .onSubmit {
                        isInvitePresented = true
                    }

                Button {
                    isInvitePresented = true
                } label: {
                        Image(systemName: "arrow.right")
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(.white)
                            .frame(width: 40, height: 40)
                            .background(Color.accentColor, in: Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Invite user")
            }
            .padding(.leading, 16)
            .padding(.trailing, 8)
            .frame(minHeight: 54)
            .background(
                colorScheme == .dark ? Color(.secondarySystemGroupedBackground) : .white,
                in: RoundedRectangle(cornerRadius: 16, style: .continuous)
            )
        }
        .padding(20)
        .frame(height: 200, alignment: .top)
        .background(
            Color.accentColor.opacity(colorScheme == .dark ? 0.26 : 0.12),
            in: RoundedRectangle(cornerRadius: 28, style: .continuous)
        )
    }
}

// MARK: - AI Tutorials

struct AITutorialStep {
    let title: String
    let detail: String
}

enum AITutorial: String, CaseIterable, Identifiable {
    case authorizeDriver
    case inviteTeam
    case askAI

    var id: String { rawValue }

    var title: String {
        switch self {
        case .authorizeDriver: "Authorize a regular driver"
        case .inviteTeam: "Invite users"
        case .askAI: "Ask AI to do anything"
        }
    }

    var duration: String { "10 sec" }

    var thumbnailSymbol: String {
        switch self {
        case .authorizeDriver: "person.badge.plus"
        case .inviteTeam: "person.2.badge.plus"
        case .askAI: "sparkles"
        }
    }

    var steps: [AITutorialStep] {
        switch self {
        case .authorizeDriver:
            [
                AITutorialStep(
                    title: "Open the People page",
                    detail: "Tap Add (+) to add a new person."
                ),
                AITutorialStep(
                    title: "Enter driver's full name",
                    detail: "The full name is the only required field."
                ),
                AITutorialStep(
                    title: "Review their access",
                    detail: "Choose which locations the driver can access, then tap Save."
                )
            ]
        case .inviteTeam:
            [
                AITutorialStep(title: "Open Users", detail: "Go to the Users page."),
                AITutorialStep(title: "Invite a user", detail: "Select Invite user."),
                AITutorialStep(title: "Choose a role", detail: "Send their invitation.")
            ]
        case .askAI:
            [
                AITutorialStep(title: "Open Birdseye AI", detail: "Start a new request."),
                AITutorialStep(title: "Describe your task", detail: "Use everyday language."),
                AITutorialStep(title: "Review the result", detail: "Continue the conversation if needed.")
            ]
        }
    }

    func stepImageAssetName(at index: Int) -> String? {
        let assetNames = [
            "AuthorizePersonTutorialSlide1",
            "AuthorizePersonTutorialSlide2",
            "AuthorizePersonTutorialSlide3"
        ]

        guard self == .authorizeDriver, assetNames.indices.contains(index) else {
            return nil
        }

        return assetNames[index]
    }

    func stepVideoResourceName(at index: Int) -> String? {
        let resourceNames = [
            "AuthorizeDriverTutorialSlide1",
            "AuthorizeDriverTutorialSlide2",
            "AuthorizeDriverTutorialSlide3"
        ]

        guard self == .authorizeDriver, resourceNames.indices.contains(index) else {
            return nil
        }

        return resourceNames[index]
    }

    var article: String {
        switch self {
        case .authorizeDriver:
            "Add a driver to the list of people authorized to enter your locations."
        case .inviteTeam:
            "Bring the people who run your operation into Birdseye. Invite users so they can manage people, view yard activity, and keep daily work moving."
        case .askAI:
            "Tell Birdseye AI what you need in plain language. It can help you find records, review activity, and start common tasks without digging through screens."
        }
    }

    var completionTitle: String {
        switch self {
        case .authorizeDriver: "Ready to give it a try?"
        case .inviteTeam: "Invite a user"
        case .askAI: "Ask Birdseye AI"
        }
    }

    var completionDetail: String {
        switch self {
        case .authorizeDriver:
            "You now know how to authorize a driver. You can revisit this tutorial anytime in Help."
        case .inviteTeam:
            "Try inviting a user so you can manage access and work together in Birdseye."
        case .askAI:
            "Try asking Birdseye AI a question in your own words to find what you need."
        }
    }

    var completionActionTitle: String {
        switch self {
        case .authorizeDriver: "Try it now"
        case .inviteTeam: "Invite a user"
        case .askAI: "Ask Birdseye AI"
        }
    }
}

private struct AITutorialStoryCircle: View {
    let tutorial: AITutorial
    @Binding var isComplete: Bool
    let onOpen: () -> Void

    var body: some View {
        Button {
            HapticFeedback.lightImpact()
            onOpen()
        } label: {
            VStack(spacing: 8) {
                ZStack(alignment: .bottomTrailing) {
                    ZStack {
                        Circle()
                            .fill(Color.accentColor.opacity(0.12))
                            .frame(width: 72, height: 72)
                            .overlay {
                                Circle()
                                    .stroke(
                                        isComplete
                                            ? Color.gray.opacity(0.55)
                                            : Color.accentColor,
                                        lineWidth: 3
                                    )
                            }

                        Image(
                            systemName: tutorial == .authorizeDriver
                                ? "person.text.rectangle"
                                : tutorial.thumbnailSymbol
                        )
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(Color.accentColor)
                    }

                    if isComplete {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title3)
                            .foregroundStyle(.white, .green)
                            .background(Color.white, in: Circle())
                            .offset(x: 3, y: 3)
                            .accessibilityHidden(true)
                    }
                }

                Text(tutorial.title)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(width: 104)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(isComplete ? "\(tutorial.title), completed" : tutorial.title)
        .accessibilityHint("Opens a three-slide tutorial")
    }
}

struct AITutorialStoryExperience: View {
    let tutorial: AITutorial
    @Binding var isComplete: Bool
    let onDismiss: () -> Void
    let onTryItYourself: () -> Void
    let onNextTutorial: () -> Void
    let completionTitle: String?
    let completionDetail: String?
    let completionActionTitle: String?
    let showsNextTutorialButton: Bool
    let isCardPresentation: Bool

    init(
        tutorial: AITutorial,
        isComplete: Binding<Bool>,
        onDismiss: @escaping () -> Void,
        onTryItYourself: @escaping () -> Void,
        onNextTutorial: @escaping () -> Void,
        completionTitle: String? = nil,
        completionDetail: String? = nil,
        completionActionTitle: String? = nil,
        showsNextTutorialButton: Bool = true,
        isCardPresentation: Bool = false
    ) {
        self.tutorial = tutorial
        _isComplete = isComplete
        self.onDismiss = onDismiss
        self.onTryItYourself = onTryItYourself
        self.onNextTutorial = onNextTutorial
        self.completionTitle = completionTitle
        self.completionDetail = completionDetail
        self.completionActionTitle = completionActionTitle
        self.showsNextTutorialButton = showsNextTutorialButton
        self.isCardPresentation = isCardPresentation
    }

    @State private var selectedStep = 0
    @State private var activeVideoProgress = 0.0
    @State private var player = AVPlayer()
    @State private var timeObserver: Any?
    @State private var endObserver: NSObjectProtocol?
    @State private var tapFeedbackEdge: HorizontalEdge?
    @State private var isMuted = false

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.03, green: 0.16, blue: 0.34), Color(red: 0.06, green: 0.43, blue: 0.78)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea(edges: isCardPresentation ? [] : .all)

            VStack(spacing: 0) {
                HStack(spacing: 5) {
                    ForEach(tutorial.steps.indices, id: \.self) { index in
                        Capsule()
                            .fill(Color.white.opacity(0.3))
                            .overlay(alignment: .leading) {
                                Capsule()
                                    .fill(Color.white)
                                    .scaleEffect(
                                        x: progress(for: index),
                                        anchor: .leading
                                    )
                            }
                            .frame(height: 4)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)

                HStack(spacing: 12) {
                    HStack(spacing: 8) {
                        Image(systemName: tutorial.thumbnailSymbol)
                            .font(.subheadline.weight(.semibold))
                            .frame(width: 32, height: 32)
                            .background(.white.opacity(0.16), in: Circle())
                            .accessibilityHidden(true)

                        Text(tutorial.title)
                            .font(.subheadline.weight(.semibold))
                            .lineLimit(1)
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel(tutorial.title)

                    Spacer()

                    Button {
                        isMuted.toggle()
                        player.isMuted = isMuted
                    } label: {
                        Image(systemName: isMuted ? "speaker.slash" : "speaker.wave.2")
                            .font(.body.weight(.bold))
                            .frame(width: 42, height: 42)
                    }
                    .accessibilityLabel(isMuted ? "Unmute tutorial" : "Mute tutorial")

                    Button(action: onDismiss) {
                        Image(systemName: "xmark")
                            .font(.body.weight(.bold))
                            .frame(width: 42, height: 42)
                    }
                    .accessibilityLabel("Close tutorial")
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 20)
                .padding(.top, 16)

                TabView(selection: $selectedStep) {
                    ForEach(Array(tutorial.steps.enumerated()), id: \.offset) { index, step in
                        AITutorialStorySlide(
                            tutorial: tutorial,
                            step: step,
                            stepIndex: index,
                            isActive: selectedStep == index,
                            player: player
                        )
                        .tag(index)
                    }

                    AITutorialStoryCompletionSlide(
                        tutorial: tutorial,
                        completionTitle: completionTitle,
                        completionDetail: completionDetail,
                        completionActionTitle: completionActionTitle,
                        showsNextTutorialButton: showsNextTutorialButton,
                        onTryItYourself: {
                            isComplete = true
                            onTryItYourself()
                        },
                        onNextTutorial: onNextTutorial,
                        onPrevious: moveToPreviousStep
                    )
                    .tag(tutorial.steps.count)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .overlay {
                    GeometryReader { proxy in
                        HStack(spacing: 0) {
                            Color.clear
                                .contentShape(Rectangle())
                                .onTapGesture { moveToPreviousStep(showingFeedbackAt: .leading) }
                                .frame(width: proxy.size.width / 2, height: proxy.size.height)

                            Color.clear
                                .contentShape(Rectangle())
                                .onTapGesture { moveToNextStep(showingFeedbackAt: .trailing) }
                                .frame(width: proxy.size.width / 2, height: proxy.size.height)
                        }
                    }
                    .allowsHitTesting(selectedStep < tutorial.steps.count)
                }
            }

            LinearGradient(
                colors: [.white.opacity(tapFeedbackEdge == .leading ? 0.32 : 0), .clear],
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(width: 112)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            .ignoresSafeArea(edges: isCardPresentation ? [] : .all)
            .allowsHitTesting(false)

            LinearGradient(
                colors: [.clear, .white.opacity(tapFeedbackEdge == .trailing ? 0.32 : 0)],
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(width: 112)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)
            .ignoresSafeArea(edges: isCardPresentation ? [] : .all)
            .allowsHitTesting(false)
        }
        .frame(
            maxWidth: isCardPresentation ? 520 : .infinity,
            maxHeight: isCardPresentation ? 760 : .infinity
        )
        .clipShape(
            RoundedRectangle(
                cornerRadius: isCardPresentation ? 28 : 0,
                style: .continuous
            )
        )
        .shadow(
            color: .black.opacity(isCardPresentation ? 0.28 : 0),
            radius: isCardPresentation ? 24 : 0,
            y: isCardPresentation ? 12 : 0
        )
        .interactiveDismissDisabled()
        .onAppear {
            addProgressObserver()
            playVideo(for: selectedStep)
        }
        .onChange(of: selectedStep) { _, _ in
            activeVideoProgress = 0
            playVideo(for: selectedStep)
        }
        .onDisappear {
            player.pause()
            player.replaceCurrentItem(with: nil)
            removePlaybackObservers()
        }
    }

    private func progress(for index: Int) -> Double {
        if index < selectedStep {
            return 1
        }

        if index == selectedStep {
            return activeVideoProgress
        }

        return 0
    }

    private func playVideo(for stepIndex: Int) {
        guard let resourceName = tutorial.stepVideoResourceName(at: stepIndex),
              let url = Bundle.main.url(forResource: resourceName, withExtension: "mp4") else {
            player.pause()
            player.replaceCurrentItem(with: nil)
            removeEndObserver()
            return
        }

        player.pause()
        let item = AVPlayerItem(url: url)
        player.replaceCurrentItem(with: item)
        observeEnd(of: item)
        player.seek(
            to: .zero,
            toleranceBefore: .zero,
            toleranceAfter: .zero
        ) { finished in
            guard finished, player.currentItem === item else {
                return
            }

            player.play()
        }
    }

    private func addProgressObserver() {
        if let timeObserver {
            player.removeTimeObserver(timeObserver)
        }

        let interval = CMTime(value: 1, timescale: 30)
        timeObserver = player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { time in
            let duration = player.currentItem?.duration.seconds ?? 0
            guard player.rate > 0, duration.isFinite, duration > 0 else {
                return
            }

            activeVideoProgress = min(max(time.seconds / duration, 0), 1)
        }
    }

    private func observeEnd(of item: AVPlayerItem) {
        removeEndObserver()
        endObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: item,
            queue: .main
        ) { _ in
            activeVideoProgress = 1
            moveToNextStep()
        }
    }

    private func removePlaybackObservers() {
        if let timeObserver {
            player.removeTimeObserver(timeObserver)
            self.timeObserver = nil
        }

        removeEndObserver()
    }

    private func removeEndObserver() {
        if let endObserver {
            NotificationCenter.default.removeObserver(endObserver)
            self.endObserver = nil
        }
    }

    private func moveToPreviousStep() {
        guard selectedStep > 0 else {
            return
        }

        withAnimation(.easeInOut) {
            selectedStep -= 1
        }
    }

    private func moveToPreviousStep(showingFeedbackAt edge: HorizontalEdge) {
        showTapFeedback(at: edge)
        moveToPreviousStep()
    }

    private func moveToNextStep() {
        guard selectedStep < tutorial.steps.count else {
            return
        }

        withAnimation(.easeInOut) {
            selectedStep += 1
        }
    }

    private func moveToNextStep(showingFeedbackAt edge: HorizontalEdge) {
        showTapFeedback(at: edge)
        moveToNextStep()
    }

    private func showTapFeedback(at edge: HorizontalEdge) {
        withAnimation(.easeOut(duration: 0.12)) {
            tapFeedbackEdge = edge
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            guard tapFeedbackEdge == edge else {
                return
            }

            withAnimation(.easeOut(duration: 0.22)) {
                tapFeedbackEdge = nil
            }
        }
    }
}

private struct AITutorialStoryCompletionSlide: View {
    let tutorial: AITutorial
    let completionTitle: String?
    let completionDetail: String?
    let completionActionTitle: String?
    let showsNextTutorialButton: Bool
    let onTryItYourself: () -> Void
    let onNextTutorial: () -> Void
    let onPrevious: () -> Void

    var body: some View {
        ZStack {
            GeometryReader { proxy in
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture(perform: onPrevious)
                    .frame(width: proxy.size.width / 2)
            }

            VStack(spacing: 0) {
                Spacer(minLength: 24)

                VStack(spacing: 24) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 76))
                        .foregroundStyle(.green)

                    VStack(spacing: 12) {
                        Text(completionTitle ?? tutorial.completionTitle)
                            .font(.largeTitle.weight(.bold))
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity, alignment: .center)

                        Text(completionDetail ?? tutorial.completionDetail)
                            .font(.title3)
                            .multilineTextAlignment(.center)
                            .foregroundStyle(.white.opacity(0.82))
                            .frame(maxWidth: .infinity, alignment: .center)
                    }

                    Button(completionActionTitle ?? "Try it now", action: onTryItYourself)
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                        .tint(.white)
                        .foregroundStyle(Color.accentColor)
                        .frame(maxWidth: 280, minHeight: 56)
                }

                Spacer(minLength: 24)

                if showsNextTutorialButton {
                    Button("Close", action: onNextTutorial)
                        .buttonStyle(.bordered)
                        .tint(.white)
                        .padding(.bottom, 28)
                }
            }
            .padding(.horizontal, 32)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        }
        .foregroundStyle(.white)
    }
}

private struct AITutorialStorySlide: View {
    let tutorial: AITutorial
    let step: AITutorialStep
    let stepIndex: Int
    let isActive: Bool
    let player: AVPlayer

    var body: some View {
        VStack(spacing: 28) {
            if tutorial.stepVideoResourceName(at: stepIndex) != nil {
                AITutorialStoryVideo(player: player)
                .frame(maxWidth: 260)
            } else {
                AITutorialStepArtwork(
                    assetName: tutorial.stepImageAssetName(at: stepIndex),
                    symbol: tutorial.thumbnailSymbol,
                    stepNumber: stepIndex + 1
                )
                .frame(maxWidth: 260)
            }

            VStack(spacing: 12) {
                Text(step.title)
                    .font(.largeTitle.weight(.bold))
                    .multilineTextAlignment(.center)

                Text(step.detail)
                    .font(.title3)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.white.opacity(0.82))
                    .fixedSize(horizontal: false, vertical: true)
            }
            .opacity(isActive ? 1 : 0)
            .animation(.easeIn(duration: 0.3), value: isActive)
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 32)
    }
}

private struct AITutorialStoryVideo: View {
    let player: AVPlayer

    var body: some View {
        VideoPlayer(player: player)
            .aspectRatio(9.0 / 16.0, contentMode: .fit)
            .background(.black, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .accessibilityLabel("Tutorial video")
    }
}

private struct AITutorialDrawer: View {
    @Binding var isAuthorizedPersonComplete: Bool
    @Binding var isCrewComplete: Bool
    @Binding var isAIComplete: Bool
    let tutorial: AITutorial
    let onOpenDestination: (AITutorial) -> Void

    @State private var selectedStep = 0
    @Environment(\.dismiss) private var dismiss

    init(
        tutorial: AITutorial,
        isAuthorizedPersonComplete: Binding<Bool>,
        isCrewComplete: Binding<Bool>,
        isAIComplete: Binding<Bool>,
        onOpenDestination: @escaping (AITutorial) -> Void
    ) {
        self.tutorial = tutorial
        _isAuthorizedPersonComplete = isAuthorizedPersonComplete
        _isCrewComplete = isCrewComplete
        _isAIComplete = isAIComplete
        self.onOpenDestination = onOpenDestination
    }

    var body: some View {
        NavigationStack {
            TabView(selection: $selectedStep) {
                ForEach(Array(tutorial.steps.enumerated()), id: \.offset) { index, step in
                    AITutorialStepPage(
                        tutorial: tutorial,
                        step: step,
                        stepNumber: index + 1,
                        totalSteps: tutorial.steps.count,
                        selectedStep: $selectedStep,
                        isFinalStep: index == tutorial.steps.indices.last,
                        onOpenDestination: onOpenDestination
                    )
                    .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .onChange(of: selectedStep) { _, step in
                if step == tutorial.steps.indices.last {
                    isComplete.wrappedValue = true
                }
            }
            .navigationTitle(tutorial.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }

    private var isComplete: Binding<Bool> {
        switch tutorial {
        case .authorizeDriver:
            return $isAuthorizedPersonComplete
        case .inviteTeam:
            return $isCrewComplete
        case .askAI:
            return $isAIComplete
        }
    }

}

private struct AITutorialStepPage: View {
    let tutorial: AITutorial
    let step: AITutorialStep
    let stepNumber: Int
    let totalSteps: Int
    @Binding var selectedStep: Int
    let isFinalStep: Bool
    let onOpenDestination: (AITutorial) -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                AITutorialStepArtwork(
                    assetName: tutorial.stepImageAssetName(at: stepNumber - 1),
                    symbol: tutorial.thumbnailSymbol,
                    stepNumber: stepNumber
                )

                VStack(alignment: .leading, spacing: 12) {
                    Text("Step \(stepNumber) of \(totalSteps)")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.blue)

                    Text(step.title)
                        .font(.title.bold())

                    Text(step.detail)
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                AITutorialStepPagination(
                    selectedStep: $selectedStep,
                    stepCount: totalSteps
                )

                if isFinalStep {
                    Button {
                        onOpenDestination(tutorial)
                    } label: {
                        Label(destinationTitle, systemImage: destinationImage)
                            .frame(maxWidth: .infinity, minHeight: 40)
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding(20)
            .padding(.bottom, 24)
        }
        .accessibilityLabel("\(tutorial.title), step \(stepNumber) of \(totalSteps). \(step.title). \(step.detail)")
    }

    private var destinationTitle: String {
        switch tutorial {
        case .authorizeDriver: "Open People"
        case .inviteTeam: "Open Users"
        case .askAI: "Open Birdseye AI"
        }
    }

    private var destinationImage: String {
        switch tutorial {
        case .authorizeDriver, .inviteTeam: "person.2"
        case .askAI: "sparkles"
        }
    }
}

private struct AITutorialStepArtwork: View {
    let assetName: String?
    let symbol: String
    let stepNumber: Int

    var body: some View {
        Group {
            if let assetName {
                Image(assetName)
                    .resizable()
                    .scaledToFit()
                    .background(Color(.secondarySystemBackground))
            } else {
                ZStack {
                    LinearGradient(
                        colors: [.blue.opacity(0.9), .indigo.opacity(0.75)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )

                    Image(systemName: symbol)
                        .font(.system(size: 72, weight: .semibold))
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(.white)

                    Text("\(stepNumber)")
                        .font(.headline.weight(.bold))
                        .foregroundStyle(.blue)
                        .frame(width: 36, height: 36)
                        .background(.white, in: Circle())
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                        .padding(16)
                }
                .aspectRatio(1, contentMode: .fit)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .accessibilityHidden(true)
    }
}

private struct AITutorialStepPagination: View {
    @Binding var selectedStep: Int
    let stepCount: Int

    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<stepCount, id: \.self) { index in
                Button {
                    selectedStep = index
                } label: {
                    Capsule()
                        .fill(index == selectedStep ? Color.blue : Color.secondary.opacity(0.3))
                        .frame(width: index == selectedStep ? 18 : 6, height: 6)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Show step \(index + 1)")
                .accessibilityAddTraits(index == selectedStep ? .isSelected : [])
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 4)
    }
}

private struct AITutorialVideoPlayer: View {
    let tutorial: AITutorial
    let isSelected: Bool
    let onPlaybackStarted: () -> Void
    @State private var player: AVPlayer?

    init(tutorial: AITutorial, isSelected: Bool, onPlaybackStarted: @escaping () -> Void) {
        self.tutorial = tutorial
        self.isSelected = isSelected
        self.onPlaybackStarted = onPlaybackStarted
        let videoURL = Bundle.main.url(
            forResource: "TutorialPlaceholder",
            withExtension: "mp4"
        )
        let player = videoURL.map { AVPlayer(url: $0) }
        player?.isMuted = false
        _player = State(initialValue: player)
    }

    var body: some View {
        Group {
            if let player {
                VideoPlayer(player: player)
                    .onAppear {
                        updatePlayback(for: player)
                    }
                    .onChange(of: isSelected) { _, _ in
                        updatePlayback(for: player)
                    }
                    .onDisappear {
                        player.pause()
                    }
            } else {
                LinearGradient(
                    colors: [.blue.opacity(0.9), .cyan.opacity(0.62), .indigo.opacity(0.82)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .overlay {
                    Text("10-second tutorial video coming soon")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.9))
                }
            }
        }
        .aspectRatio(16.0 / 9.0, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .accessibilityLabel("Video for \(tutorial.title)")
    }

    private func updatePlayback(for player: AVPlayer) {
        if isSelected {
            player.play()
            onPlaybackStarted()
        } else {
            player.pause()
        }
    }
}

// MARK: - AI Example

private struct AIExample: Identifiable {

    let id: String
    let category: String
    let title: String
    let systemImage: String
    let tint: Color
}


// MARK: - AI Example Card

private struct AIExampleCard: View {

    let example: AIExample

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(example.title)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.blue)

                Text(example.category == "People"
                    ? "Add a driver, employee, contractor, or visitor to the access list."
                    : example.category == "Search"
                    ? "Search drivers, carriers, trailers, or any records."
                    : "How many bobtail trucks entered the yard today?")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.leading)
            }

            Spacer(minLength: 8)

            Image(systemName: "sparkles")
                .font(.body.weight(.semibold))
                .foregroundStyle(.blue)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}


private struct AIConversationHistoryView: View {
    @Binding var conversations: [AIConversation]
    let onOpen: (AIConversation) -> Void
    let onDelete: (AIConversation) -> Void
    let onNewConversation: () -> Void

    @State private var searchText = ""
    @State private var isSearchPresented = false

    private var matchingConversations: [AIConversation] {
        let term = searchText.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !term.isEmpty else {
            return conversations
        }

        return conversations.filter {
            $0.title.localizedCaseInsensitiveContains(term)
                || $0.preview.localizedCaseInsensitiveContains(term)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            if conversations.isEmpty {
                ContentUnavailableView(
                    "No conversations yet",
                    systemImage: "clock.arrow.circlepath",
                    description: Text("Your AI conversations will appear here.")
                )
            } else if matchingConversations.isEmpty {
                ContentUnavailableView.search(text: searchText)
            } else {
                List {
                    ForEach(matchingConversations) { conversation in
                        Button {
                            onOpen(conversation)
                        } label: {
                            Text(conversation.title)
                                .font(.body.weight(.semibold))
                                .lineLimit(1)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(.primary)
                        .swipeActions {
                            Button(role: .destructive) {
                                onDelete(conversation)
                            } label: {
                                Label("Delete conversation", systemImage: "trash")
                            }
                        }
                    }
                }
            }
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Conversation history")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button {
                    HapticFeedback.lightImpact()
                    isSearchPresented = true
                } label: {
                    Image(systemName: "magnifyingglass")
                }
                .tint(.primary)
                .accessibilityLabel("Search conversations")

                Button {
                    HapticFeedback.lightImpact()
                    onNewConversation()
                } label: {
                    Image(systemName: "square.and.pencil")
                }
                .tint(.primary)
                .accessibilityLabel("New conversation")
            }
        }
        .conversationHistorySearch(
            isPresented: $isSearchPresented,
            text: $searchText
        )
    }
}


struct AIConversationHistoryDrawer: View {
    @Binding var conversations: [AIConversation]
    let onOpen: (AIConversation) -> Void
    let onDelete: (AIConversation) -> Void
    let onNewConversation: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        NavigationStack {
            AIConversationHistoryView(
                conversations: $conversations,
                onOpen: onOpen,
                onDelete: onDelete,
                onNewConversation: onNewConversation
            )
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: onDismiss) {
                        Image(systemName: "xmark")
                    }
                    .tint(.primary)
                    .accessibilityLabel("Close conversation history")
                }
            }
        }
        .background(Color(.systemGroupedBackground))
        .ignoresSafeArea()
    }
}


private extension View {
    @ViewBuilder
    func conversationHistorySearch(
        isPresented: Binding<Bool>,
        text: Binding<String>
    ) -> some View {
        if isPresented.wrappedValue {
            self
                .reportingSearchActivity()
                .searchable(
                    text: text,
                    isPresented: isPresented,
                    placement: .navigationBarDrawer(displayMode: .always),
                    prompt: "Search conversations"
                )
        } else {
            self
        }
    }
}


// MARK: - AI Thread

struct AIThreadView: View {

    @Binding var title: String
    @Binding var messages: [AIMessage]
    @Binding var isPresented: Bool

    let onMessagesChanged: () -> Void
    let onEdit: (String) -> Void
    let onNewConversation: () -> Void

    @State private var messageToDelete:
        AIMessage?

    @State private var isSearchPresented =
        false

    @State private var selectedAuthorizationCandidate: AuthorizationCandidate?
    @State private var selectedAuthorizationMessageID: UUID?

    @Environment(\.dismiss)
    private var dismiss

    var body: some View {
        VStack(spacing: 0) {

            if messages.isEmpty {
                emptyState

            } else {
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(
                            spacing: 18
                        ) {
                            ForEach(
                                messages
                            ) { message in

                                AIMessageRow(
                                    message:
                                        message,
                                    onCopy: {
                                        copy(
                                            message.text
                                        )
                                    },
                                    onEdit: {
                                        onEdit(
                                            message.text
                                        )
                                    },
                                    onDelete: {
                                        messageToDelete =
                                            message
                                    },
                                    onSelectAuthorizationPerson: { candidate in
                                        selectedAuthorizationCandidate = candidate
                                        selectedAuthorizationMessageID = message.id
                                    },
                                    onSaveAllAuthorizationPeople: {
                                        saveAllAuthorizationPeople(
                                            in: message.id
                                        )
                                    }
                                )
                                .id(
                                    message.id
                                )
                            }
                        }
                        .padding(
                            .horizontal,
                            16
                        )
                        .padding(.top, 20)
                        .padding(.bottom, 70)
                    }
                    .scrollDismissesKeyboard(
                        .interactively
                    )
                    .onChange(
                        of: messages.count
                    ) {
                        if let lastID =
                            messages.last?.id {

                            withAnimation(
                                .snappy
                            ) {
                                proxy.scrollTo(
                                    lastID,
                                    anchor: .bottom
                                )
                            }
                        }
                    }
                }
            }
        }
        .background(
            Color(.systemGroupedBackground)
        )
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(
            .inline
        )
        .toolbar {
            ToolbarItemGroup(
                placement:
                    .topBarTrailing
            ) {

                Button(
                    action:
                        onNewConversation
                ) {
                    Image(
                        systemName: "square.and.pencil"
                    )
                    .font(
                        .headline.weight(
                            .semibold
                        )
                    )
                }
                .accessibilityLabel(
                    "New conversation"
                )

                Menu {
                    Button {
                        isSearchPresented =
                            true
                    } label: {
                        Label(
                            "Search messages",
                            systemImage:
                                "magnifyingglass"
                        )
                    }

                    Button {
                        closeThread()
                    } label: {
                        Label(
                            "Conversation history",
                            systemImage:
                                "clock.arrow.circlepath"
                        )
                    }

                    Button(
                        role: .destructive
                    ) {
                        HapticFeedback.criticalAction()
                        messages.removeAll()
                        onMessagesChanged()
                        closeThread()
                    } label: {
                        Label(
                            "Delete conversation",
                            systemImage:
                                "trash"
                        )
                        .foregroundStyle(
                            .red
                        )
                    }

                } label: {
                    Image(
                        systemName:
                            "ellipsis"
                    )
                    .font(
                        .title3.weight(
                            .semibold
                        )
                    )
                }
                .accessibilityLabel(
                    "Conversation actions"
                )
            }
        }
        .sheet(
            isPresented:
                $isSearchPresented
        ) {
            AIMessageSearchView(
                messages: messages
            )
        }
        .sheet(item: $selectedAuthorizationCandidate) { candidate in
            EditPersonAuthorizationView(person: candidate.person) {
                if let selectedAuthorizationMessageID {
                    saveAuthorizationPerson(
                        candidate.id,
                        in: selectedAuthorizationMessageID
                    )
                }
            }
        }
        .alert(
            "Delete message?",
            isPresented: Binding(
                get: {
                    messageToDelete != nil
                },
                set: {
                    if !$0 {
                        messageToDelete =
                            nil
                    }
                }
            )
        ) {
            Button(
                "Delete",
                role: .destructive
            ) {
                HapticFeedback.criticalAction()
                if let messageToDelete {
                    messages.removeAll {
                        $0.id ==
                            messageToDelete.id
                    }

                    onMessagesChanged()
                }

                self.messageToDelete =
                    nil
            }

            Button(
                "Cancel",
                role: .cancel
            ) {}

        } message: {
            Text(
                "This message will be removed from the conversation."
            )
        }
        .simultaneousGesture(
            DragGesture(
                minimumDistance: 24
            )
            .onEnded { value in

                guard
                    value.startLocation.x <
                        36,
                    value.translation.width >
                        100,
                    abs(
                        value.translation
                            .height
                    ) < 80
                else {
                    return
                }

                closeThread()
            }
        )
    }

    private func closeThread() {
        isPresented = false
        dismiss()
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label(
                "Start a new conversation",
                systemImage: "sparkles"
            )
        } description: {
            Text(
                "Ask a question or attach a file from the composer below."
            )
        }
        .frame(
            maxHeight: .infinity
        )
    }

    private func copy(
        _ text: String
    ) {
        UIPasteboard.general.string =
            text
    }

    private func saveAuthorizationPerson(_ candidateID: UUID, in messageID: UUID) {
        guard let messageIndex = messages.firstIndex(where: { $0.id == messageID }),
              var review = messages[messageIndex].authorizationReview else {
            return
        }

        review.markSaved(candidateID)
        messages[messageIndex].authorizationReview = review
        onMessagesChanged()
    }

    private func saveAllAuthorizationPeople(in messageID: UUID) {
        guard let messageIndex = messages.firstIndex(where: { $0.id == messageID }),
              var review = messages[messageIndex].authorizationReview else {
            return
        }

        review.markAllSaved()
        messages[messageIndex].authorizationReview = review
        onMessagesChanged()
    }
}


// MARK: - Message Search

private struct AIMessageSearchView: View {

    let messages: [AIMessage]

    @Environment(\.dismiss)
    private var dismiss

    @State private var query = ""

    private var results: [AIMessage] {
        let term = query
            .trimmingCharacters(
                in:
                    .whitespacesAndNewlines
            )

        guard !term.isEmpty else {
            return messages
        }

        return messages.filter {
            $0.text
                .localizedCaseInsensitiveContains(
                    term
                )
        }
    }

    var body: some View {
        NavigationStack {
            List(
                results
            ) { message in

                VStack(
                    alignment: .leading,
                    spacing: 6
                ) {
                    Text(
                        message.isUser
                        ? "You"
                        : "Birdseye AI"
                    )
                    .font(
                        .caption.weight(
                            .semibold
                        )
                    )
                    .foregroundStyle(
                        .secondary
                    )

                    Text(
                        message.text
                    )
                    .textSelection(
                        .enabled
                    )
                }
                .padding(
                    .vertical,
                    4
                )
            }
            .navigationTitle(
                "Search messages"
            )
            .navigationBarTitleDisplayMode(
                .inline
            )
            .reportingSearchActivity()
            .searchable(
                text: $query,
                prompt:
                    "Search messages"
            )
            .toolbar {
                ToolbarItem(
                    placement:
                        .topBarTrailing
                ) {
                    Button(
                        "Done"
                    ) {
                        dismiss()
                    }
                }
            }
        }
    }
}


// MARK: - Message Row

private struct AIMessageRow: View {

    let message: AIMessage

    let onCopy: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void
    let onSelectAuthorizationPerson: (AuthorizationCandidate) -> Void
    let onSaveAllAuthorizationPeople: () -> Void

    var body: some View {
        HStack(
            alignment: .bottom,
            spacing: 8
        ) {

            if message.isUser {
                Spacer(
                    minLength: 28
                )
            }

            VStack(
                alignment:
                    message.isUser
                    ? .trailing
                    : .leading,
                spacing: 5
            ) {
                VStack(
                    alignment:
                        message.isUser
                        ? .trailing
                        : .leading,
                    spacing: 8
                ) {

                    if message.isLoading {
                        AIThinkingIndicator()

                    } else {

                        if let pageContext = message.pageContext {
                            Label(
                                pageContext,
                                systemImage: "doc.text"
                            )
                            .font(.caption.weight(.medium))
                            .lineLimit(1)
                        }

                        if !message.attachments.isEmpty {
                            AIMessageAttachmentGrid(
                                attachments: message.attachments
                            )
                        }

                        Text(
                            message.text
                        )
                        .textSelection(
                            .enabled
                        )
                        .fixedSize(
                            horizontal:
                                false,
                            vertical:
                                true
                        )

                        if let review = message.authorizationReview {
                            AuthorizationReviewView(
                                review: review,
                                onSelectPerson: onSelectAuthorizationPerson,
                                onSaveAll: onSaveAllAuthorizationPeople
                            )
                            .padding(.top, 4)
                        }
                    }
                }
                .padding(
                    .horizontal,
                    message.isUser ? 15 : 0
                )
                .padding(
                    .vertical,
                    message.isUser ? 12 : 0
                )
                .foregroundStyle(
                    message.isUser
                    ? .white
                    : .primary
                )
                .background(
                    message.isUser
                    ? AnyShapeStyle(Color.accentColor)
                    : AnyShapeStyle(Color.clear),
                    in: RoundedRectangle(
                        cornerRadius: 20,
                        style:
                            .continuous
                    )
                )
                .contextMenu {

                    Button(
                        action: onCopy
                    ) {
                        Label(
                            "Copy",
                            systemImage:
                                "doc.on.doc"
                        )
                    }

                    if message.isUser {
                        Button(
                            action:
                                onEdit
                        ) {
                            Label(
                                "Edit",
                                systemImage:
                                    "pencil"
                            )
                        }
                    }

                    Button(
                        role:
                            .destructive,
                        action:
                            onDelete
                    ) {
                        Label(
                            "Delete",
                            systemImage:
                                "trash"
                        )
                        .foregroundStyle(
                            .red
                        )
                    }
                }

                HStack(
                    spacing: 6
                ) {
                    Text(
                        message.isUser
                        ? "You"
                        : "Birdseye AI"
                    )

                    Text("•")

                    Text(
                        message.date,
                        format: .dateTime
                            .hour()
                            .minute()
                    )
                }
                .font(.caption2)
                .foregroundStyle(
                    .secondary
                )
            }

            if !message.isUser {
                Spacer(
                    minLength: 28
                )
            }
        }
    }
}


private struct AIMessageAttachmentGrid: View {
    let attachments: [AIMessageAttachment]

    private let columns = Array(
        repeating: GridItem(.fixed(72), spacing: 8),
        count: 3
    )

    var body: some View {
        LazyVGrid(columns: columns, alignment: .leading, spacing: 8) {
            ForEach(attachments) { attachment in
                VStack(alignment: .leading, spacing: 4) {
                    Group {
                        if let thumbnail = attachment.thumbnail {
                            Image(uiImage: thumbnail)
                                .resizable()
                                .scaledToFill()
                        } else {
                            Image(systemName: attachment.systemImage)
                                .font(.title3)
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .background(Color(.tertiarySystemFill))
                        }
                    }
                    .frame(width: 72, height: 58)
                    .clipShape(
                        RoundedRectangle(
                            cornerRadius: 10,
                            style: .continuous
                        )
                    )

                    Text(attachment.name)
                        .font(.caption2.weight(.medium))
                        .lineLimit(1)
                        .frame(width: 72, alignment: .leading)
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Attachment: \(attachment.name)")
            }
        }
    }
}

private struct AIThinkingIndicator: View {

    @Environment(\.accessibilityReduceMotion)
    private var accessibilityReduceMotion

    @State private var startedAt = Date()

    var body: some View {
        TimelineView(
            .animation(
                minimumInterval: 1.0 / 30.0,
                paused: accessibilityReduceMotion
            )
        ) { context in
            let elapsed = context.date.timeIntervalSince(startedAt)

            HStack(spacing: 10) {
                pulsingOrb

                ShimmeringThinkingText(
                    text: status(for: elapsed),
                    elapsed: elapsed,
                    isPaused: accessibilityReduceMotion
                )
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel(status(for: elapsed))
        }
    }

    private var pulsingOrb: some View {
        ZStack {
            Circle()
                .fill(Color.blue.opacity(0.18))
                .frame(width: 30, height: 30)
                .phaseAnimator([false, true]) { content, isExpanded in
                    content
                        .scaleEffect(isExpanded ? 1.2 : 0.82)
                        .opacity(isExpanded ? 0.28 : 0.82)
                } animation: { _ in
                    accessibilityReduceMotion
                        ? nil
                        : .easeInOut(duration: 0.9)
                }

            Circle()
                .fill(Color.blue)
                .frame(width: 12, height: 12)
        }
        .accessibilityHidden(true)
    }

    private func status(for elapsed: TimeInterval) -> String {
        switch Int(elapsed / 1.4) {
        case 0:
            "Looking into authorizations..."
        case 1:
            "Thinking..."
        default:
            "Preparing response..."
        }
    }
}

private struct ShimmeringThinkingText: View {

    let text: String
    let elapsed: TimeInterval
    let isPaused: Bool

    var body: some View {

        Text(text)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.secondary.opacity(0.82))
            .overlay {

                GeometryReader { proxy in

                    let progress = isPaused
                        ? 0.5
                        : elapsed
                            .truncatingRemainder(dividingBy: 1.8) / 1.8

                    LinearGradient(
                        colors: [
                            .clear,
                            Color.primary.opacity(0.75),
                            .clear
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(
                        width: proxy.size.width * 0.65
                    )
                    .offset(
                        x: proxy.size.width
                            * (progress * 1.8 - 0.7)
                    )
                }
            }
            .mask {
                Text(text)
                    .font(.subheadline.weight(.semibold))
            }
            .fixedSize(
                horizontal: true,
                vertical: false
            )
    }
}
// MARK: - Authorization review

struct AuthorizationCandidate: Identifiable {
    let id: UUID
    let person: ExistingPerson
    var isSaved: Bool
}

struct AuthorizationReview {
    var candidates: [AuthorizationCandidate]

    mutating func markSaved(_ candidateID: UUID) {
        guard let index = candidates.firstIndex(where: { $0.id == candidateID }) else {
            return
        }

        candidates[index].isSaved = true
    }

    mutating func markAllSaved() {
        for index in candidates.indices {
            candidates[index].isSaved = true
        }
    }

    static let sample = AuthorizationReview(
        candidates: [
            AuthorizationCandidate(
                id: UUID(),
                person: ExistingPerson(
                    fullName: "Avery Johnson",
                    organization: "Northstar Logistics",
                    title: "Delivery Driver",
                    cdlNumber: "CDL-48291",
                    phoneNumber: "(416) 555-0182",
                    emailAddress: "avery.johnson@example.com",
                    dateOfBirth: nil,
                    idCountry: "Canada",
                    dlNumber: "ON-J482-910-228",
                    companyCardNumber: "NS-10482"
                ),
                isSaved: false
            ),
            AuthorizationCandidate(
                id: UUID(),
                person: ExistingPerson(
                    fullName: "Morgan Lee",
                    organization: "Northstar Logistics",
                    title: "Site Contractor",
                    cdlNumber: "CDL-59310",
                    phoneNumber: "(416) 555-0124",
                    emailAddress: "morgan.lee@example.com",
                    dateOfBirth: nil,
                    idCountry: "Canada",
                    dlNumber: "ON-L593-104-765",
                    companyCardNumber: "NS-10483"
                ),
                isSaved: false
            )
        ]
    )
}

private struct AuthorizationReviewView: View {
    let review: AuthorizationReview
    let onSelectPerson: (AuthorizationCandidate) -> Void
    let onSaveAll: () -> Void

    private var hasUnsavedPeople: Bool {
        review.candidates.contains { !$0.isSaved }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach(review.candidates) { candidate in
                AuthorizationCandidateRow(
                    candidate: candidate,
                    onSelect: { onSelectPerson(candidate) }
                )
            }

            if hasUnsavedPeople {
                if #available(iOS 26.0, *) {
                    confirmAllButton
                        .glassEffect(.regular.tint(.blue), in: Capsule())
                } else {
                    confirmAllButton
                        .background(.blue.opacity(0.85), in: Capsule())
                }
            } else {
                confirmAllButton
                    .background(Color(.tertiarySystemFill), in: Capsule())
            }
        }
        .padding(.top, 2)
    }

    private var confirmAllButton: some View {
        Button(action: onSaveAll) {
            Label(
                hasUnsavedPeople ? "Confirm all" : "All authorizations saved",
                systemImage: hasUnsavedPeople
                    ? "checkmark.circle.fill"
                    : "checkmark.seal.fill"
            )
            .font(.body.weight(.semibold))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
        }
        .foregroundStyle(hasUnsavedPeople ? Color.white : Color.primary.opacity(0.45))
        .disabled(!hasUnsavedPeople)
        .buttonStyle(.plain)
        .accessibilityHint("Saves authorization for every listed person")
    }
}

private struct AuthorizationCandidateRow: View {
    let candidate: AuthorizationCandidate
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "person.fill")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .frame(width: 34, height: 34)
                    .background(Color.secondary.opacity(0.10), in: RoundedRectangle(cornerRadius: 10, style: .continuous))

                VStack(alignment: .leading, spacing: 6) {
                    Text(candidate.person.fullName)
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(1)

                    Text(candidate.person.subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)

                    HStack(spacing: 8) {
                        Label("All locations", systemImage: "mappin.and.ellipse")
                            .font(.caption.weight(.medium))
                            .foregroundStyle(.secondary)

                        AccessTypeChip(
                            accessType: "Default Access",
                            periodAccess: "Ongoing",
                            hasNote: false,
                            isLimitedTime: false
                        )
                    }

                    Label(
                        candidate.isSaved ? "Saved" : "Not saved yet, open to confirm",
                        systemImage: candidate.isSaved ? "checkmark.circle.fill" : "exclamationmark.circle.fill"
                    )
                    .font(.caption.weight(.medium))
                    .foregroundStyle(candidate.isSaved ? .green : .secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.tertiary)
                    .padding(.top, 5)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .accessibilityHint(candidate.isSaved ? "Authorization has been saved" : "Opens this person's authorization details to confirm and save")
    }
}

// MARK: - Message Model

struct AIMessageAttachment: Identifiable {
    let id: UUID
    let name: String
    let systemImage: String
    let thumbnail: UIImage?

    init(
        id: UUID = UUID(),
        name: String,
        systemImage: String,
        thumbnail: UIImage? = nil
    ) {
        self.id = id
        self.name = name
        self.systemImage = systemImage
        self.thumbnail = thumbnail
    }

    static let authorizationSamples = [
        AIMessageAttachment(
            name: "Avery Johnson ID.jpg",
            systemImage: "photo",
            thumbnail: UIImage(systemName: "person.crop.square.fill")
        ),
        AIMessageAttachment(
            name: "Morgan Lee ID.jpg",
            systemImage: "photo",
            thumbnail: UIImage(systemName: "person.crop.square.fill")
        )
    ]
}

struct AIMessage: Identifiable {

    let id: UUID
    var text: String
    let isUser: Bool
    var date: Date
    let attachments: [AIMessageAttachment]
    let pageContext: String?
    var isLoading: Bool
    var authorizationReview: AuthorizationReview?

    init(
        id: UUID = UUID(),
        text: String,
        isUser: Bool,
        date: Date = Date(),
        attachments: [AIMessageAttachment] = [],
        pageContext: String? = nil,
        isLoading: Bool = false,
        authorizationReview: AuthorizationReview? = nil
    ) {
        self.id = id
        self.text = text
        self.isUser = isUser
        self.date = date
        self.attachments = attachments
        self.pageContext = pageContext
        self.isLoading =
            isLoading
        self.authorizationReview = authorizationReview
    }
}


// MARK: - Conversation Model

struct AIConversation: Identifiable {

    let id: UUID
    var title: String
    var messages: [AIMessage]
    let createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        title: String,
        messages: [AIMessage],
        createdAt:
            Date = Date(),
        updatedAt:
            Date = Date()
    ) {
        self.id = id
        self.title = title
        self.messages = messages
        self.createdAt =
            createdAt
        self.updatedAt =
            updatedAt
    }

    var preview: String {
        messages.last?.text
            ?? "No messages yet"
    }
}


#Preview {
    AIView()
}
