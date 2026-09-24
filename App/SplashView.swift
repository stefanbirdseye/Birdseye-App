import SwiftUI

struct SplashView: View {

    let onAnimationCompleted: () -> Void

    @State private var topTruckOffset: CGFloat = 0
    @State private var middleTruckOffset: CGFloat = 0
    @State private var bottomTruckOffset: CGFloat = 0

    @State private var topTruckOpacity = 0.0
    @State private var middleTruckOpacity = 0.0
    @State private var bottomTruckOpacity = 0.0

    var body: some View {

        GeometryReader { proxy in

            let screenWidth = proxy.size.width
            let screenHeight = proxy.size.height

            let bigTruckWidth = min(
                max(screenWidth * 0.62, 240),
                540
            )

            let smallTruckWidth = min(
                max(screenWidth * 0.34, 135),
                300
            )

            let extraPadding: CGFloat = 60

            let bigTruckTravel =
                (screenWidth / 2) +
                (bigTruckWidth / 2) +
                extraPadding

            let smallTruckTravel =
                (screenWidth / 2) +
                (smallTruckWidth / 2) +
                extraPadding

            ZStack {

                Color.blue
                    .ignoresSafeArea()

                // BIG TOP TRUCK
                truck(width: bigTruckWidth)
                    .offset(
                        x: topTruckOffset,
                        y: -min(screenHeight * 0.39, 340)
                    )
                    .opacity(topTruckOpacity)
                    .accessibilityHidden(true)

                // SMALL MIDDLE TRUCK
                truck(width: smallTruckWidth)
                    .scaleEffect(x: -1, y: 1)
                    .offset(
                        x: middleTruckOffset,
                        y: -min(screenHeight * 0.22, 190)
                    )
                    .opacity(middleTruckOpacity)
                    .accessibilityHidden(true)

                // BIG BOTTOM TRUCK
                truck(width: bigTruckWidth)
                    .offset(
                        x: bottomTruckOffset,
                        y: min(screenHeight * 0.39, 340)
                    )
                    .opacity(bottomTruckOpacity)
                    .accessibilityHidden(true)

                // LOGO
                BrandLogoView(
                    foregroundStyle: .white
                )
                .frame(
                    width: 170,
                    height: 34
                )
                .frame(
                    maxWidth: .infinity,
                    maxHeight: .infinity
                )
            }
            .clipped()
            .task {

                await prepareTrucks(
                    bigTravel: bigTruckTravel,
                    smallTravel: smallTruckTravel
                )

                await animateTrucks(
                    bigTravel: bigTruckTravel,
                    smallTravel: smallTruckTravel
                )

                guard !Task.isCancelled else {
                    return
                }

                // Leave splash immediately.
                onAnimationCompleted()
            }
        }
        .ignoresSafeArea()
        .preferredColorScheme(.dark)
    }

    private func truck(
        width: CGFloat
    ) -> some View {

        Image("TruckTop")
            .resizable()
            .scaledToFit()
            .frame(width: width)
    }

    private func prepareTrucks(
        bigTravel: CGFloat,
        smallTravel: CGFloat
    ) async {

        await MainActor.run {

            topTruckOffset = -bigTravel
            middleTruckOffset = smallTravel
            bottomTruckOffset = -bigTravel

            topTruckOpacity = 0
            middleTruckOpacity = 0
            bottomTruckOpacity = 0
        }

        await Task.yield()
    }

    private func animateTrucks(
        bigTravel: CGFloat,
        smallTravel: CGFloat
    ) async {

        await withTaskGroup(
            of: Void.self
        ) { group in

            // 1. BIG TOP TRUCK
            group.addTask {

                try? await Task.sleep(
                    for: .milliseconds(30)
                )

                guard !Task.isCancelled else {
                    return
                }

                await MainActor.run {

                    topTruckOpacity = 0.8

                    withAnimation(
                        .linear(duration: 1.20)
                    ) {
                        topTruckOffset = bigTravel
                    }
                }

                try? await Task.sleep(
                    for: .milliseconds(1200)
                )

                await MainActor.run {
                    topTruckOpacity = 0
                }
            }

            // 2. SMALL MIDDLE TRUCK
            group.addTask {

                try? await Task.sleep(
                    for: .milliseconds(140)
                )

                guard !Task.isCancelled else {
                    return
                }

                await MainActor.run {

                    middleTruckOpacity = 0.8

                    withAnimation(
                        .linear(duration: 1.05)
                    ) {
                        middleTruckOffset = -smallTravel
                    }
                }

                try? await Task.sleep(
                    for: .milliseconds(1050)
                )

                await MainActor.run {
                    middleTruckOpacity = 0
                }
            }

            // 3. BIG BOTTOM TRUCK
            group.addTask {

                try? await Task.sleep(
                    for: .milliseconds(260)
                )

                guard !Task.isCancelled else {
                    return
                }

                await MainActor.run {

                    bottomTruckOpacity = 0.8

                    withAnimation(
                        .linear(duration: 1.25)
                    ) {
                        bottomTruckOffset = bigTravel
                    }
                }

                try? await Task.sleep(
                    for: .milliseconds(1250)
                )

                await MainActor.run {
                    bottomTruckOpacity = 0
                }
            }
        }
    }
}
