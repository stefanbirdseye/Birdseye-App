import SwiftUI
import UIKit
import Combine

struct AIView: View {

    @Binding var query: String
    @Binding var messages: [AIMessage]
    @Binding var conversations: [AIConversation]
    @Binding var activeConversationID: UUID?
    @Binding var isThreadPresented: Bool
    @Binding var currentConversationTitle: String

    let onThreadDismiss: () -> Void
    let onAuthorizationExampleSelected: () -> Void

    @State private var exampleScrollID: String?
    @State private var isDraggingExamples = false

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
            title: "Authorize these persons to all locations",
            systemImage: "person.fill",
            tint: .cyan
        ),
        AIExample(
            id: "organizations",
            category: "Organizations",
            title: "Show organizations with active access",
            systemImage: "building.2.fill",
            tint: .green
        ),
        AIExample(
            id: "equipment",
            category: "Equipment",
            title: "Show authorized equipment at this location",
            systemImage: "truck.box.fill",
            tint: .indigo
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
        onThreadDismiss: @escaping () -> Void = {},
        onAuthorizationExampleSelected: @escaping () -> Void = {}
    ) {
        _query = query
        _messages = messages
        _conversations = conversations
        _activeConversationID = activeConversationID
        _isThreadPresented = isThreadPresented
        _currentConversationTitle = currentConversationTitle
        self.onThreadDismiss = onThreadDismiss
        self.onAuthorizationExampleSelected = onAuthorizationExampleSelected
    }

    var body: some View {
        NavigationStack {
            landingContent
                .toolbar {

                    ToolbarItem(
                        placement: .topBarTrailing
                    ) {
                        Button {
                            startNewConversation()
                        } label: {
                            Image(
                                systemName: "square.and.pencil"
                            )
                        }
                        .accessibilityLabel(
                            "New conversation"
                        )
                    }
                }
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
        }
        .onChange(
            of: isThreadPresented
        ) { _, isPresented in
            if !isPresented {
                onThreadDismiss()
            }
        }
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

                Text(
                    "Ask about people, equipment, organizations, locations, or access events."
                )
                .foregroundStyle(.secondary)

                exampleSection

                historySection
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 120)
        }
        .birdseyeRefreshable()
        .background(
            Color(.systemGroupedBackground)
        )
        .birdseyeMainTabPage()
    }

    // MARK: - Examples

    private var exampleSection: some View {
        VStack(
            alignment: .leading,
            spacing: 10
        ) {
            HStack {
                Text("Try these examples")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)

            }

            ScrollView(.horizontal) {
                LazyHStack(spacing: 12) {
                    ForEach(examples) { example in
                        Button {
                            query = example.title
                            if example.id == "people" {
                                onAuthorizationExampleSelected()
                            }
                        } label: {
                            AIExampleCard(
                                example: example
                            )
                        }
                        .buttonStyle(.plain)
                        .id(example.id)
                    }
                }
                .scrollTargetLayout()
                .padding(.horizontal, 16)
            }
            .scrollIndicators(.hidden)
            .scrollTargetBehavior(
                .viewAligned(
                    limitBehavior: .alwaysByOne
                )
            )
            .scrollPosition(
                id: $exampleScrollID,
                anchor: .leading
            )
            .padding(.horizontal, -16)
            .simultaneousGesture(
                DragGesture(minimumDistance: 4)
                    .onChanged { _ in
                        isDraggingExamples = true
                    }
                    .onEnded { _ in
                        isDraggingExamples = false
                    }
            )
            .onReceive(exampleAutoScroll) { _ in
                advanceExamples()
            }
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
        VStack(
            alignment: .leading,
            spacing: 0
        ) {
            HStack {
                Image(
                    systemName:
                        example.systemImage
                )
                .font(
                    .system(
                        size: 20,
                        weight: .semibold
                    )
                )
                .foregroundStyle(.white)
                .frame(
                    width: 42,
                    height: 42
                )
                .background(
                    .white.opacity(0.16),
                    in: Circle()
                )

                Spacer()

                Image(
                    systemName:
                        "arrow.down.right"
                )
                .font(
                    .subheadline.weight(
                        .semibold
                    )
                )
                .foregroundStyle(
                    .white.opacity(0.8)
                )
            }

            Spacer()

            Text(
                example.category
                    .uppercased()
            )
            .font(
                .caption2.weight(.bold)
            )
            .tracking(0.8)
            .foregroundStyle(
                .white.opacity(0.72)
            )

            Text(example.title)
                .font(
                    .headline.weight(
                        .semibold
                    )
                )
                .foregroundStyle(.white)
                .multilineTextAlignment(
                    .leading
                )
                .lineLimit(3)
                .padding(.top, 5)
        }
        .padding(16)
        .frame(
            width: 224,
            height: 154,
            alignment: .leading
        )
        .background {
            RoundedRectangle(
                cornerRadius: 20,
                style: .continuous
            )
            .fill(
                LinearGradient(
                    colors: [
                        example.tint,
                        example.tint
                            .opacity(0.72)
                    ],
                    startPoint:
                        .topLeading,
                    endPoint:
                        .bottomTrailing
                )
            )
        }
        .overlay {
            RoundedRectangle(
                cornerRadius: 20,
                style: .continuous
            )
            .stroke(
                .white.opacity(0.15),
                lineWidth: 1
            )
        }
        .shadow(
            color:
                example.tint.opacity(0.14),
            radius: 10,
            y: 5
        )
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
