import SwiftUI

struct PersonAuthorizationTutorialFlow: View {

    let isPersonTutorialActive: Bool
    let onCancelTutorial: () -> Void
    let onCompleteTutorial: () -> Void
    let showsDriverTutorial: Bool
    let onDriverTutorialComplete: () -> Void

    @Environment(SnackbarCenter.self) private var snackbarCenter

    @State private var isDriverTutorialPresented = false
    @State private var isDriverTutorialVisible = false
    @State private var hasCompletedDriverTutorial = false
    @State private var tutorialPresentationTask: Task<Void, Never>?
    @State private var tutorialDismissalTask: Task<Void, Never>?

    init(
        isPersonTutorialActive: Bool,
        onCancelTutorial: @escaping () -> Void,
        onCompleteTutorial: @escaping () -> Void,
        showsDriverTutorial: Bool = false,
        onDriverTutorialComplete: @escaping () -> Void = {}
    ) {
        self.isPersonTutorialActive = isPersonTutorialActive
        self.onCancelTutorial = onCancelTutorial
        self.onCompleteTutorial = onCompleteTutorial
        self.showsDriverTutorial = showsDriverTutorial
        self.onDriverTutorialComplete = onDriverTutorialComplete
    }

    var body: some View {
        ZStack {
            AddPersonAuthorizationView(
                isPersonTutorialActive: isPersonTutorialActive,
                onCancelTutorial: onCancelTutorial,
                onCompleteTutorial: onCompleteTutorial,
                showsTutorialShortcut: true,
                onWatchTutorial: {
                    presentDriverTutorial()
                }
            )

            if isDriverTutorialPresented {
                Color.black
                    .opacity(isDriverTutorialVisible ? 0.18 : 0)
                    .ignoresSafeArea()

                GeometryReader { proxy in
                    let cardWidth = min(proxy.size.width - 32, 480)
                    // The add-person sheet is shorter than the full-screen Start Here overlay.
                    // This keeps the tutorial card visually aligned with that standard presentation.
                    let cardHeight = min(proxy.size.height - 32, 760)

                    AITutorialStoryExperience(
                        tutorial: .authorizeDriver,
                        isComplete: $hasCompletedDriverTutorial,
                        onDismiss: {
                            dismissDriverTutorial()
                        },
                        onTryItYourself: {
                            onDriverTutorialComplete()
                            dismissDriverTutorial()
                        },
                        onNextTutorial: {},
                        completionTitle: "Ready to give it a try?",
                        completionDetail: "You now know how to authorize a driver. You can revisit this tutorial anytime in Help.",
                        completionActionTitle: "Try it now",
                        showsNextTutorialButton: false,
                        isCardPresentation: true
                    )
                    .frame(width: cardWidth, height: cardHeight)
                    .scaleEffect(isDriverTutorialVisible ? 1 : 0.92)
                    .opacity(isDriverTutorialVisible ? 1 : 0)
                    .offset(y: isDriverTutorialVisible ? 0 : 28)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
        }
        .onAppear {
            tutorialPresentationTask?.cancel()

            guard showsDriverTutorial else {
                return
            }

            presentDriverTutorial(after: .milliseconds(350))
        }
        .onDisappear {
            tutorialPresentationTask?.cancel()
            tutorialDismissalTask?.cancel()
        }
    }

    private func presentDriverTutorial(after delay: Duration = .zero) {
        tutorialPresentationTask?.cancel()
        tutorialDismissalTask?.cancel()
        hasCompletedDriverTutorial = false
        isDriverTutorialVisible = false

        tutorialPresentationTask = Task { @MainActor in
            try? await Task.sleep(for: delay)

            guard !Task.isCancelled else {
                return
            }

            isDriverTutorialPresented = true

            try? await Task.sleep(for: .milliseconds(50))

            guard !Task.isCancelled else {
                return
            }

            withAnimation(.easeOut(duration: 0.45)) {
                isDriverTutorialVisible = true
            }
        }
    }

    private func dismissDriverTutorial() {
        guard isDriverTutorialPresented else {
            return
        }

        tutorialPresentationTask?.cancel()
        tutorialDismissalTask?.cancel()

        withAnimation(.easeInOut(duration: 0.38)) {
            isDriverTutorialVisible = false
        }

        tutorialDismissalTask = Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(400))

            guard !Task.isCancelled else {
                return
            }

            isDriverTutorialPresented = false
            snackbarCenter.show("Find more tutorials in Help Center.")
        }
    }
}
