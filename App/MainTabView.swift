import SwiftUI
import UIKit
import PhotosUI
import UniformTypeIdentifiers

enum MainTab: Hashable {
    case home
    case ai
    case team
    case profile

    var pageTitle: String {
        switch self {
        case .home:
            "Now"
        case .ai:
            "Birdseye AI"
        case .team:
            "Team"
        case .profile:
            "Profile"
        }
    }
}

struct MainTabView: View {

    @Binding var flow: AppFlow

    @Environment(\.horizontalSizeClass)
    private var actualHorizontalSizeClass

    @State private var selectedTab: MainTab = .ai
    @State private var shouldShowSettings = false

    @State private var composerText = ""
    @State private var composerAttachments: [AIMessageAttachment] = []

    @State private var messages: [AIMessage] = []
    @State private var conversations: [AIConversation] = []
    @State private var activeConversationID: UUID?

    @State private var isThreadPresented = false
    @State private var isAIResponding = false
    @State private var isConversationHistoryPresented = false

    @State private var currentConversationTitle = "New conversation"

    @State private var searchActivity = SearchActivity()
    @State private var pageContextStore = PageContextStore()
    @State private var aiComposerStore = AIComposerStore()

    @FocusState private var isComposerFocused: Bool

    // MARK: - Keyboard

    @State private var dockedKeyboardOverlap: CGFloat = 0

    // MARK: - Composer

    private var composerPrompt: String {
        selectedTab == .ai && isThreadPresented
            ? "Continue in this thread"
            : "Ask AI, type it like an email..."
    }

    private var composerPageContext: String? {
        guard selectedTab != .ai else {
            return nil
        }

        return pageContextStore.title
            ?? selectedTab.pageTitle
    }

    /*
     Closed keyboard:
     58pt native tab bar allowance + 8pt gap.

     Floating keyboard:
     stays exactly in the same place.

     Docked keyboard:
     keyboard height + exactly 8pt.
    */
    private var composerBottomPadding: CGFloat {
        if dockedKeyboardOverlap > 0 {
            return dockedKeyboardOverlap + 8
        }

        return 66
    }

    // MARK: - Body

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .bottom) {
                nativeTabView

                if isComposerFocused {
                    Color.clear
                        .contentShape(Rectangle())
                        .ignoresSafeArea()
                        .onTapGesture {
                            dismissKeyboard()
                        }
                        .zIndex(1)
                }

                if !searchActivity.isSearching
                    && !isConversationHistoryPresented
                    && !pageContextStore.hidesWorkspaceComposer
                {
                    WorkspaceAIComposer(
                        text: $composerText,
                        attachedFiles: $composerAttachments,
                        isFocused: $isComposerFocused,
                        prompt: composerPrompt,
                        pageContext: composerPageContext,
                        isLoading: isAIResponding,
                        onSubmit: sendQuery
                    )
                    .frame(
                        width: min(
                            max(0, proxy.size.width - 48),
                            480
                        )
                    )
                    .frame(
                        maxWidth: .infinity,
                        alignment: .center
                    )
                    .padding(
                        .bottom,
                        dockedKeyboardOverlap > 0
                            ? (
                                UIDevice.current.userInterfaceIdiom == .phone
                                    ? max(
                                        8,
                                        dockedKeyboardOverlap
                                            - proxy.safeAreaInsets.bottom
                                            + 8
                                    )
                                    : dockedKeyboardOverlap + 8
                            )
                            : 58 + 8
                    )
                    .offset(
                        y: UIDevice.current.userInterfaceIdiom == .phone
                            && dockedKeyboardOverlap == 0
                            ? 6
                            : 0
                    )
                    .zIndex(2)
                }

                if isConversationHistoryPresented {
                    AIConversationHistoryDrawer(
                        conversations: $conversations,
                        onOpen: { conversation in
                            isConversationHistoryPresented = false
                            selectedTab = .ai
                            messages = conversation.messages
                            currentConversationTitle = conversation.title
                            activeConversationID = conversation.id
                            isThreadPresented = true
                        },
                        onDelete: { conversation in
                            conversations.removeAll { $0.id == conversation.id }
                        },
                        onNewConversation: {
                            isConversationHistoryPresented = false
                            selectedTab = .ai
                            messages = []
                            currentConversationTitle = "New conversation"
                            activeConversationID = UUID()
                            isThreadPresented = true
                        },
                        onDismiss: {
                            isConversationHistoryPresented = false
                        }
                    )
                    .transition(.move(edge: .leading))
                    .zIndex(3)
                }
            }
        }
        .animation(.easeInOut(duration: 0.25), value: isConversationHistoryPresented)
        .ignoresSafeArea(
            .keyboard,
            edges: .bottom
        )
        .onReceive(
            NotificationCenter.default.publisher(
                for: UIResponder.keyboardWillChangeFrameNotification
            )
        ) { notification in
            handleKeyboardFrameChange(
                notification
            )
        }
        .onReceive(
            NotificationCenter.default.publisher(
                for: UIResponder.keyboardWillHideNotification
            )
        ) { notification in
            updateKeyboardOverlap(
                0,
                notification: notification
            )
        }
        .environment(searchActivity)
        .environment(pageContextStore)
        .environment(aiComposerStore)
        .onReceive(
            NotificationCenter.default.publisher(
                for: .birdseyeOpenConversationHistory
            )
        ) { _ in
            isConversationHistoryPresented = true
        }
        .onChange(of: aiComposerStore.prompt) { _, prompt in
            guard let prompt else {
                return
            }

            composerText = prompt
            isComposerFocused = true
            aiComposerStore.prompt = nil
        }
        .onChange(of: selectedTab) { _, _ in
            HapticFeedback.selectionChanged()
        }
    }

    // MARK: - Native tab navigation

    private var nativeTabView: some View {
        TabView(selection: $selectedTab) {

            Tab(
                "Birdseye AI",
                systemImage: "sparkles",
                value: MainTab.ai
            ) {
                AIView(
                    query: $composerText,
                    messages: $messages,
                    conversations: $conversations,
                    activeConversationID: $activeConversationID,
                    isThreadPresented: $isThreadPresented,
                    currentConversationTitle: $currentConversationTitle,
                    onThreadDismiss: returnFromThread,
                    onAuthorizationExampleSelected: {
                        composerAttachments =
                            AIMessageAttachment
                                .authorizationSamples

                        isComposerFocused = true
                    }
                )
                .environment(
                    \.horizontalSizeClass,
                    actualHorizontalSizeClass
                )
                .bottomReadabilityBlur()
            }

            Tab(
                "Now",
                systemImage: "waveform.path.ecg",
                value: MainTab.home
            ) {
                HomeView(
                    onAIAction: { prompt in
                        composerText = prompt
                        isComposerFocused = true
                    },
                    onOpenSettings: openSettings,
                    onOpenTeam: {
                        selectedTab = .team
                    }
                )
                .environment(
                    \.horizontalSizeClass,
                    actualHorizontalSizeClass
                )
                .bottomReadabilityBlur()
            }

            Tab(
                "Team",
                systemImage: "person.2",
                value: MainTab.team
            ) {
                TeamView()
                    .environment(
                        \.horizontalSizeClass,
                        actualHorizontalSizeClass
                    )
                    .bottomReadabilityBlur()
            }

            Tab(
                "Profile",
                systemImage: "person.crop.circle",
                value: MainTab.profile
            ) {
                ProfileView(
                    flow: $flow,
                    showSettings: $shouldShowSettings,
                    onRestartOnboarding: returnToHomeAfterRestartingOnboarding
                )
                .environment(
                    \.horizontalSizeClass,
                    actualHorizontalSizeClass
                )
                .bottomReadabilityBlur()
            }
        }

        // Force native bottom tab bar on iPad
        .environment(
            \.horizontalSizeClass,
            .compact
        )
        .tabViewStyle(.tabBarOnly)
    }

    private func openSettings() {
        selectedTab = .profile
        shouldShowSettings = true
    }

    private func returnToHomeAfterRestartingOnboarding() {
        shouldShowSettings = false
        selectedTab = .home
    }

    // MARK: - Active window

    private var activeWindow: UIWindow? {
        UIApplication.shared.connectedScenes
            .compactMap {
                $0 as? UIWindowScene
            }
            .filter {
                $0.activationState == .foregroundActive
            }
            .flatMap {
                $0.windows
            }
            .first {
                $0.isKeyWindow
            }
    }

    // MARK: - Keyboard handling

    private func handleKeyboardFrameChange(
        _ notification: Notification
    ) {
        guard
            let keyboardFrame =
                notification.userInfo?[
                    UIResponder
                        .keyboardFrameEndUserInfoKey
                ] as? CGRect
        else {
            return
        }

        guard let window = activeWindow else {
            return
        }

        /*
         Keyboard notification frame is in screen coordinates.

         Convert it to this app window's coordinate space.
         This is especially important with iPad Stage Manager.
        */
        let keyboardFrameInWindow =
            window.convert(
                keyboardFrame,
                from: window.screen.coordinateSpace
            )

        let windowBounds =
            window.bounds

        let intersection =
            windowBounds.intersection(
                keyboardFrameInWindow
            )

        /*
         Keyboard completely outside the current window.
        */
        guard
            !intersection.isNull,
            !intersection.isEmpty
        else {
            updateKeyboardOverlap(
                0,
                notification: notification
            )

            return
        }

        /*
         Docked keyboard reaches the bottom of
         the current application window.
        */
        let touchesBottom =
            intersection.maxY
            >= windowBounds.maxY - 2

        /*
         Docked keyboard is almost as wide
         as the app window.

         Floating iPad keyboard is much narrower.
        */
        let coversMostOfWindowWidth =
            intersection.width
            >= windowBounds.width * 0.85

        /*
         Ignore tiny accessory / transient frames.
        */
        let hasRealKeyboardHeight =
            intersection.height > 100

        let isDockedKeyboard =
            touchesBottom
            && coversMostOfWindowWidth
            && hasRealKeyboardHeight

        /*
         Floating keyboard ALWAYS produces zero.

         This is the important part that fixes:

         floating
         -> docked
         -> floating

         The composer returns to its original position.
        */
        let overlap: CGFloat =
            isDockedKeyboard
                ? intersection.height
                : 0

        updateKeyboardOverlap(
            overlap,
            notification: notification
        )
    }

    // MARK: - Keyboard animation

    private func updateKeyboardOverlap(
        _ overlap: CGFloat,
        notification: Notification
    ) {
        let duration =
            notification.userInfo?[
                UIResponder
                    .keyboardAnimationDurationUserInfoKey
            ] as? Double
            ?? 0.25

        /*
         Use the system keyboard duration so
         the composer follows the full keyboard smoothly.
        */
        withAnimation(
            .easeOut(
                duration: duration
            )
        ) {
            dockedKeyboardOverlap =
                overlap
        }
    }

    // MARK: - Dismiss keyboard

    private func dismissKeyboard() {
        isComposerFocused = false

        UIApplication.shared.sendAction(
            #selector(
                UIResponder.resignFirstResponder
            ),
            to: nil,
            from: nil,
            for: nil
        )
    }

    // MARK: - Send query

    private func sendQuery(
        attachments: [AIMessageAttachment] = [],
        pageContext: String? = nil
    ) {
        let trimmed =
            composerText
                .trimmingCharacters(
                    in: .whitespacesAndNewlines
                )

        guard
            (
                !trimmed.isEmpty
                || !attachments.isEmpty
            ),
            !isAIResponding
        else {
            return
        }

        HapticFeedback.lightImpact()

        let prompt =
            trimmed.isEmpty
                ? "Please review the attached item(s)."
                : trimmed

        let userMessage =
            AIMessage(
                text: prompt,
                isUser: true,
                attachments: attachments,
                pageContext: pageContext
            )

        let thinkingMessage =
            AIMessage(
                text: "",
                isUser: false,
                isLoading: true
            )

        let conversationID: UUID

        if
            isThreadPresented,
            let activeConversationID
        {
            conversationID =
                activeConversationID

            messages.append(
                userMessage
            )

            messages.append(
                thinkingMessage
            )

            if let index =
                conversations.firstIndex(
                    where: {
                        $0.id
                            == activeConversationID
                    }
                )
            {
                conversations[index]
                    .messages =
                    messages

                conversations[index]
                    .updatedAt =
                    Date()
            }

        } else {

            conversationID =
                UUID()

            messages = [
                userMessage,
                thinkingMessage
            ]

            currentConversationTitle =
                String(
                    prompt.prefix(42)
                )

            activeConversationID =
                conversationID

            conversations.insert(
                AIConversation(
                    id: conversationID,
                    title:
                        currentConversationTitle,
                    messages:
                        messages
                ),
                at: 0
            )

            isThreadPresented =
                true
        }

        composerText = ""

        selectedTab =
            .ai

        isThreadPresented =
            true

        isAIResponding =
            true

        dismissKeyboard()

        scheduleResponse(
            for: conversationID,
            isAuthorizationRequest:
                isAuthorizationRequest(
                    prompt
                )
        )
    }

    // MARK: - Response

    private func scheduleResponse(
        for conversationID: UUID,
        isAuthorizationRequest: Bool
    ) {
        Task {
            try? await Task.sleep(
                nanoseconds:
                    8_400_000_000
            )

            guard !Task.isCancelled else {
                return
            }

            await MainActor.run {
                guard
                    activeConversationID
                        == conversationID
                else {
                    isAIResponding =
                        false

                    return
                }

                let response =
                    AIMessage(
                        text:
                            isAuthorizationRequest
                                ? "Please review the proposed authorizations and confirm each person individually, or confirm all at once."
                                : "I reviewed the current workspace context. I can break this down by location, event status, time window, people, or equipment.",
                        isUser: false,
                        authorizationReview:
                            isAuthorizationRequest
                                ? AuthorizationReview.sample
                                : nil
                    )

                if let index =
                    messages.lastIndex(
                        where: {
                            $0.isLoading
                        }
                    )
                {
                    messages[index] =
                        response
                }

                if let historyIndex =
                    conversations.firstIndex(
                        where: {
                            $0.id
                                == conversationID
                        }
                    )
                {
                    conversations[
                        historyIndex
                    ]
                    .messages =
                        messages

                    conversations[
                        historyIndex
                    ]
                    .updatedAt =
                        Date()
                }

                isAIResponding =
                    false

                HapticFeedback.success()
            }
        }
    }

    // MARK: - Authorization request

    private func isAuthorizationRequest(
        _ prompt: String
    ) -> Bool {
        let normalizedPrompt =
            prompt.localizedLowercase

        return
            normalizedPrompt
                .contains("authoriz")
            && (
                normalizedPrompt
                    .contains("person")
                || normalizedPrompt
                    .contains("people")
            )
    }

    // MARK: - Return from thread

    private func returnFromThread() {
        isThreadPresented =
            false

        selectedTab =
            .ai

        composerText =
            ""

        dismissKeyboard()
    }
}

// MARK: - Bottom readability blur

private struct BottomReadabilityModifier:
    ViewModifier {

    func body(
        content: Content
    ) -> some View {
        content
            .overlay(
                alignment: .bottom
            ) {
                BottomReadabilityBlur()
                    .frame(
                        height: 190
                    )
                    .ignoresSafeArea(
                        edges: .bottom
                    )
                    .allowsHitTesting(
                        false
                    )
            }
    }
}

private extension View {

    func bottomReadabilityBlur()
        -> some View
    {
        modifier(
            BottomReadabilityModifier()
        )
    }
}

// MARK: - Progressive material

private struct BottomReadabilityBlur:
    View {

    var body: some View {
        ZStack {
            Rectangle()
                .fill(
                    .thickMaterial
                )

            Rectangle()
                .fill(
                    Color(
                        .systemBackground
                    )
                    .opacity(
                        0.35
                    )
                )
        }
        .mask(
            LinearGradient(
                stops: [
                    .init(
                        color: .clear,
                        location: 0
                    ),

                    .init(
                        color:
                            .black
                            .opacity(
                                0.15
                            ),
                        location:
                            0.18
                    ),

                    .init(
                        color:
                            .black
                            .opacity(
                                0.30
                            ),
                        location:
                            0.35
                    ),

                    .init(
                        color:
                            .black
                            .opacity(
                                0.75
                            ),
                        location:
                            0.58
                    ),

                    .init(
                        color:
                            .black
                            .opacity(
                                0.99
                            ),
                        location:
                            0.80
                    ),

                    .init(
                        color: .black,
                        location: 1
                    )
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .allowsHitTesting(
            false
        )
    }
}
