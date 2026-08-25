import Observation
import SwiftUI

@MainActor
@Observable
final class SearchActivity {
    var isSearching = false
}

private struct SearchActivityReporter: View {
    @Environment(\.isSearching) private var isSearching
    @Environment(SearchActivity.self) private var searchActivity: SearchActivity?

    var body: some View {
        Color.clear
            .onChange(of: isSearching, initial: true) { _, isSearching in
                searchActivity?.isSearching = isSearching
            }
            .onDisappear {
                if isSearching {
                    searchActivity?.isSearching = false
                }
            }
    }
}

extension View {
    func reportingSearchActivity() -> some View {
        background {
            SearchActivityReporter()
        }
    }
}
