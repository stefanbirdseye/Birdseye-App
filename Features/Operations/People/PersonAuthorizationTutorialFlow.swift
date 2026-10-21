import SwiftUI

struct PersonAuthorizationTutorialFlow: View {

    let isPersonTutorialActive: Bool
    let onCancelTutorial: () -> Void
    let onCompleteTutorial: () -> Void

    var body: some View {
        AddPersonAuthorizationView(
            isPersonTutorialActive: isPersonTutorialActive,
            onCancelTutorial: onCancelTutorial,
            onCompleteTutorial: onCompleteTutorial
        )
    }
}
