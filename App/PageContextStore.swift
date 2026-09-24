import Observation
import SwiftUI

@MainActor
@Observable
final class PageContextStore {
    var title: String?
    var hidesWorkspaceComposer = false
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
