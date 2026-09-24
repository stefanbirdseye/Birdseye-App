import SwiftUI

extension Notification.Name {
    static let birdseyeOpenConversationHistory = Notification.Name(
        "birdseyeOpenConversationHistory"
    )
}

struct BirdseyeMainTabHeaderModifier: ViewModifier {

    func body(content: Content) -> some View {
        content
            .toolbarBackground(
                .hidden,
                for: .navigationBar
            )
            .toolbar {

                // MARK: - Logo
                // Plain logo. No Liquid Glass background.

                ToolbarItemGroup(
                    placement: .topBarLeading
                ) {
                    Button {
                        HapticFeedback.lightImpact()
                        NotificationCenter.default.post(
                            name: .birdseyeOpenConversationHistory,
                            object: nil
                        )
                    } label: {
                        Image(systemName: "line.3.horizontal")
                            .font(
                                .system(
                                    size: 19,
                                    weight: .semibold
                                )
                            )
                            .frame(width: 28, height: 28)
                    }
                    .tint(.primary)
                    .buttonStyle(.glass)
                    .buttonBorderShape(.circle)
                    .accessibilityLabel("Conversation history")

                    BrandLogoView(
                        foregroundStyle: .blue
                    )
                    .frame(
                        width: 112,
                        height: 26
                    )
                    .accessibilityLabel("Birdseye")
                }
                .sharedBackgroundVisibility(.hidden)


                // MARK: - Actions
                // One native Liquid Glass group.

                ToolbarItemGroup(
                    placement: .topBarTrailing
                ) {

                    NavigationLink {
                        RequestsView()
                    } label: {
                        Image(systemName: "envelope")
                            .font(
                                .system(
                                    size: 17,
                                    weight: .semibold
                                )
                            )
                            .overlay(alignment: .topTrailing) {
                                Circle()
                                    .fill(.blue)
                                    .frame(width: 8, height: 8)
                                    .overlay {
                                        Circle()
                                            .stroke(Color(.systemBackground), lineWidth: 1.5)
                                    }
                                    .offset(x: 3, y: -3)
                            }
                    }
                    .tint(.primary)
                    .simultaneousGesture(TapGesture().onEnded {
                        HapticFeedback.lightImpact()
                    })

                    NavigationLink {
                        HelpView()
                    } label: {
                        Image(systemName: "questionmark.circle")
                            .font(
                                .system(
                                    size: 17,
                                    weight: .semibold
                                )
                            )
                            .overlay(alignment: .topTrailing) {
                                Circle()
                                    .fill(.blue)
                                    .frame(width: 8, height: 8)
                                    .overlay {
                                        Circle()
                                            .stroke(Color(.systemBackground), lineWidth: 1.5)
                                    }
                                    .offset(x: 3, y: -3)
                            }
                    }
                    .tint(.primary)
                    .simultaneousGesture(TapGesture().onEnded {
                        HapticFeedback.lightImpact()
                    })
                }
            }
    }
}


// MARK: - Page Modifier

extension View {

    func birdseyeMainTabPage() -> some View {
        modifier(
            BirdseyeMainTabHeaderModifier()
        )
        .safeAreaPadding(
            .bottom,
            72
        )
    }
}


// MARK: - Page Title

struct BirdseyePageTitle: View {

    let title: String

    var body: some View {
        Text(title)
            .font(
                .largeTitle
                .weight(.bold)
            )
            .frame(
                maxWidth: .infinity,
                alignment: .leading
            )
            .listRowInsets(
                EdgeInsets(
                    top: 0,
                    leading: 0,
                    bottom: 0,
                    trailing: 0
                )
            )
            .listRowBackground(
                Color.clear
            )
            .listRowSeparator(
                .hidden
            )
    }
}
