import SwiftUI

struct BirdseyeMainTabHeaderModifier: ViewModifier {

    func body(content: Content) -> some View {
        content
            .toolbarBackground(
                Color.birdseyeNavy,
                for: .navigationBar
            )
            .toolbarBackground(
                .visible,
                for: .navigationBar
            )
            .toolbarColorScheme(
                .dark,
                for: .navigationBar
            )
            .toolbar {

                // MARK: - Logo
                // Plain logo. No Liquid Glass background.

                ToolbarItem(
                    placement: .topBarLeading
                ) {
                    BrandLogoView(
                        foregroundStyle: .white
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
                        NotificationsView()
                    } label: {
                        Image(systemName: "bell")
                            .font(
                                .system(
                                    size: 17,
                                    weight: .semibold
                                )
                            )
                    }
                    .tint(.white)
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
                    }
                    .tint(.white)
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
