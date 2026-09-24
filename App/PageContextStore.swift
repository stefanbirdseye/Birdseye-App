import Observation
import SwiftUI

@MainActor
@Observable
final class PageContextStore {
    var title: String?

    private var workspaceComposerHiders = Set<UUID>()

    var hidesWorkspaceComposer: Bool {
        !workspaceComposerHiders.isEmpty
    }

    func hideWorkspaceComposer(for sourceID: UUID) {
        workspaceComposerHiders.insert(sourceID)
    }

    func showWorkspaceComposer(for sourceID: UUID) {
        workspaceComposerHiders.remove(sourceID)
    }
}

@MainActor
@Observable
final class AIComposerStore {
    var prompt: String?
}

private struct PageContextReporter: ViewModifier {
    @Environment(PageContextStore.self) private var pageContextStore

    let title: String

    func body(content: Content) -> some View {
        content
            .onAppear {
                pageContextStore.title = title
            }
            .onDisappear {
                if pageContextStore.title == title {
                    pageContextStore.title = nil
                }
            }
    }
}

extension View {
    func reportingPageContext(_ title: String) -> some View {
        modifier(PageContextReporter(title: title))
    }
}
