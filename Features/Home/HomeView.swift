import SwiftUI
import Charts
import TipKit

struct HomeView: View {

    @Environment(SnackbarCenter.self) private var snackbarCenter

    let onAIAction: (String) -> Void
    let onOpenSettings: () -> Void

    private let locations = [
        LocationSummary(
            name: "Northstar (Oshawa)",
            subtitle: "Oshawa, Ontario",
            people: "128",
            organizations: "14",
            equipment: "46",
            appointments: "4",
            traffic: "18% lower",
            insight: "Entry traffic is lower today, concentrated at North Gate."
        ),
        LocationSummary(
            name: "Northstar (Dallas)",
            subtitle: "Dallas, Texas",
            people: "96",
            organizations: "9",
            equipment: "31",
            appointments: "7",
            traffic: "8% higher",
            insight: "Traffic is trending up this morning across the main entrance."
        ),
        LocationSummary(
            name: "Northstar (Toronto)",
            subtitle: "Toronto, Ontario",
            people: "154",
            organizations: "18",
            equipment: "52",
            appointments: "11",
            traffic: "12% lower",
            insight: "Most activity is centered around the south visitor entrance."
        )
    ]

    @AppStorage("defaultLocation") private var defaultLocation = "Northstar (Oshawa)"
    @AppStorage("hasDismissedDefaultLocationTip") private var hasDismissedDefaultLocationTip = false
    @State private var selectedLocationIndex = 0
    @State private var activeCreateSheet: HomeCreateSheet?
    @State private var hasLoadedDefaultLocation = false
    @State private var isLocationTipPresented = false
    @State private var isPersonTutorialActive = false
    @State private var activeLearnBasicsStory: LearnBasicsStory?
    @AppStorage("onboardingAuthorizedPersonComplete") private var isAuthorizeFirstDriverTutorialComplete = false
    @AppStorage("learnBasicsExploreComplete") private var isLearnBasicsExploreComplete = false
    @AppStorage("learnBasicsTeamComplete") private var isLearnBasicsTeamComplete = false
    @AppStorage("learnBasicsAccessComplete") private var isLearnBasicsAccessComplete = false

    private var selectedLocation: LocationSummary {
        locations[selectedLocationIndex]
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {

                    VStack(alignment: .leading, spacing: 10) {
                        HStack(alignment: .center, spacing: 12) {
                            Text("Now")
                                .font(.largeTitle.weight(.bold))
                                .foregroundStyle(.primary)

                        }

                        LocationSwitcher(
                            location: selectedLocation,
                            locations: locations,
                            selectedLocationIndex: $selectedLocationIndex,
                            canGoBack: selectedLocationIndex > 0,
                            canGoForward: selectedLocationIndex < locations.count - 1,
                            onPrevious: selectPreviousLocation,
                            onNext: selectNextLocation
                        )

                        if isLocationTipPresented {
                            LocationDefaultTip(
                                locationName: selectedLocation.name,
                                onDismiss: {
                                    hasDismissedDefaultLocationTip = true
                                    isLocationTipPresented = false
                                },
                                onOpenSettings: {
                                    isLocationTipPresented = false
                                    onOpenSettings()
                                }
                            )
                        }
                    }

                    LocationDashboardContent(
                        location: selectedLocation,
                        isPersonTutorialActive: isPersonTutorialActive,
                        onAbandonPersonTutorial: {
                            isPersonTutorialActive = false
                        },
                        onAdd: openCreateSheet,
                        onAIAction: onAIAction
                    )
                    .id(selectedLocation.id)
                    .transition(.opacity)
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 28)
            }
            .birdseyeRefreshable()
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Now")
            .navigationBarTitleDisplayMode(.inline)
            .birdseyeMainTabPage()
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Color.clear
                        .frame(width: 1, height: 1)
                        .accessibilityHidden(true)
                }
            }
            .sheet(item: $activeCreateSheet) { sheet in
                switch sheet {
                case .person:
                    PersonAuthorizationTutorialFlow(
                        isPersonTutorialActive: isPersonTutorialActive,
                        onCancelTutorial: {
                            isPersonTutorialActive = false
                        },
                        onCompleteTutorial: {
                            isPersonTutorialActive = false
                            snackbarCenter.show("You're all set — your driver is authorized.")
                        },
                        showsDriverTutorial: !isAuthorizeFirstDriverTutorialComplete,
                        onDriverTutorialComplete: {
                            isAuthorizeFirstDriverTutorialComplete = true
                            isPersonTutorialActive = true
                        }
                    )
                case .organization:
                    OrganizationEditorView()
                case .equipment:
                    EquipmentEditorView()
                case .appointment:
                    AppointmentEditorView()
                }
            }
            .fullScreenCover(item: $activeLearnBasicsStory) { story in
                LearnBasicsStoryExperience(
                    story: story,
                    onDismiss: {
                        activeLearnBasicsStory = nil
                    },
                    onTryItYourself: {
                        completeLearnBasicsStory(story)
                        activeLearnBasicsStory = nil
                    }
                )
            }
            .animation(
                .easeInOut(duration: 0.25),
                value: selectedLocation.id
            )
            .onAppear {
                guard !hasLoadedDefaultLocation else {
                    return
                }

                hasLoadedDefaultLocation = true
                selectedLocationIndex = locations.firstIndex {
                    $0.name == defaultLocation
                } ?? 0
            }
            .onChange(of: selectedLocationIndex) { _, newIndex in
                guard
                    hasLoadedDefaultLocation,
                    locations[newIndex].name != defaultLocation,
                    !hasDismissedDefaultLocationTip
                else {
                    return
                }

                isLocationTipPresented = true
            }
        }
    }

    private func selectPreviousLocation() {
        guard selectedLocationIndex > 0 else {
            return
        }

        withAnimation {
            selectedLocationIndex -= 1
        }

    }

    private func selectNextLocation() {
        guard selectedLocationIndex < locations.count - 1 else {
            return
        }

        withAnimation {

            selectedLocationIndex += 1
        }
    }

    private var learnBasicsCompletionStates: [Bool] {
        [
            isLearnBasicsExploreComplete,
            isLearnBasicsTeamComplete,
            isLearnBasicsAccessComplete
        ]
    }

    private func openCreateSheet(_ sheet: HomeCreateSheet) {
        activeCreateSheet = sheet
    }

    private func completeLearnBasicsStory(_ story: LearnBasicsStory) {
        switch story {
        case .start:
            isLearnBasicsExploreComplete = true
        case .details:
            isLearnBasicsTeamComplete = true
        case .review:
            isLearnBasicsAccessComplete = true
        }

        Task {
            await HomeAddRegularDriverTip().resetEligibility()
        }
        isPersonTutorialActive = true

        if case .start = story {
            snackbarCenter.show("Got it — tap the highlighted + to add your first driver.")
        }
    }

}

private enum LearnBasicsStory: CaseIterable, Identifiable {
    case start
    case details
    case review

    var id: Self { self }

    var title: String {
        switch self {
        case .start: "Start authorization"
        case .details: "Add person details"
        case .review: "Review access"
        }
    }

    var symbol: String {
        switch self {
        case .start: "person.badge.plus"
        case .details: "person.text.rectangle.fill"
        case .review: "checkmark.shield.fill"
        }
    }

    var slides: [LearnBasicsSlide] {
        switch self {
        case .start:
            [
                LearnBasicsSlide(title: "Authorize a person", message: "Start by opening People and selecting Add person.", symbol: "person.badge.plus"),
                LearnBasicsSlide(title: "Choose the right person", message: "Search for an existing person or create a new authorization record.", symbol: "person.crop.circle.badge.plus"),
                LearnBasicsSlide(title: "Ready to begin", message: "Birdseye will guide you through each part of the authorization.", symbol: "hand.tap.fill")
            ]
        case .details:
            [
                LearnBasicsSlide(title: "Add their details", message: "Capture the information your team needs to identify the person.", symbol: "person.text.rectangle.fill"),
                LearnBasicsSlide(title: "Set their permissions", message: "Choose which locations, doors, and times they can access.", symbol: "key.fill"),
                LearnBasicsSlide(title: "Keep it current", message: "You can review or update an authorization whenever details change.", symbol: "arrow.triangle.2.circlepath" )
            ]
        case .review:
            [
                LearnBasicsSlide(title: "Review the authorization", message: "Check the person, access rules, and any required approval details.", symbol: "checklist"),
                LearnBasicsSlide(title: "Confirm with confidence", message: "Birdseye highlights anything that still needs your attention.", symbol: "checkmark.seal.fill"),
                LearnBasicsSlide(title: "Authorize the person", message: "Finish the guided flow to save their authorization securely.", symbol: "checkmark.shield.fill")
            ]
        }
    }
}

private struct LearnBasicsSlide: Identifiable {
    let title: String
    let message: String
    let symbol: String

    var id: String { title }
}

private struct LearnBasicsSection: View {

    let completedStories: [Bool]
    let onSelectStory: (LearnBasicsStory) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Learn basics")
                        .font(.headline.weight(.semibold))
                    Text("Quick stories to help you get started.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: 0)

                Text("\(completedStories.filter { $0 }.count)/\(LearnBasicsStory.allCases.count)")
                    .font(.caption.weight(.semibold).monospacedDigit())
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color(.tertiarySystemFill), in: Capsule())
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .top, spacing: 18) {
                    ForEach(Array(LearnBasicsStory.allCases.enumerated()), id: \.element) { index, story in
                        LearnBasicsStoryButton(
                            story: story,
                            isComplete: completedStories[index],
                            action: { onSelectStory(story) }
                        )
                    }
                }
                .padding(.horizontal, 2)
                .padding(.vertical, 5)
            }
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color(.separator).opacity(0.45), lineWidth: 1)
        }
        .accessibilityElement(children: .contain)
    }
}

private struct LearnBasicsStoryButton: View {

    let story: LearnBasicsStory
    let isComplete: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack(alignment: .bottomTrailing) {
                    ZStack {
                        Circle()
                            .fill(Color.accentColor.opacity(0.12))
                            .frame(width: 72, height: 72)
                            .overlay {
                                Circle()
                                    .stroke(Color.accentColor, lineWidth: 3)
                            }

                        Image(systemName: story.symbol)
                            .font(.title2.weight(.semibold))
                            .foregroundStyle(Color.accentColor)
                    }

                    if isComplete {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title3)
                            .foregroundStyle(.white, .green)
                            .background(Color.white, in: Circle())
                            .offset(x: 3, y: 3)
                            .accessibilityHidden(true)
                    }
                }

                Text(story.title)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .frame(width: 88)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(isComplete ? "\(story.title), completed" : story.title)
        .accessibilityHint("Opens a three-slide tutorial")
    }
}

private struct LearnBasicsStoryExperience: View {

    let story: LearnBasicsStory
    let onDismiss: () -> Void
    let onTryItYourself: () -> Void

    @State private var slideIndex = 0

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.03, green: 0.16, blue: 0.34), Color(red: 0.06, green: 0.43, blue: 0.78)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                HStack(spacing: 5) {
                    ForEach(story.slides.indices, id: \.self) { index in
                        Capsule()
                            .fill(index <= slideIndex ? Color.white : Color.white.opacity(0.3))
                            .frame(height: 4)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)

                HStack {
                    Button(action: onDismiss) {
                        Image(systemName: "xmark")
                            .font(.body.weight(.bold))
                            .frame(width: 42, height: 42)
                            .background(.white.opacity(0.16), in: Circle())
                    }
                    .accessibilityLabel("Close tutorial")

                    Spacer()

                    Text("\(slideIndex + 1) of \(story.slides.count)")
                        .font(.subheadline.weight(.semibold).monospacedDigit())
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 20)
                .padding(.top, 16)

                TabView(selection: $slideIndex) {
                    ForEach(Array(story.slides.enumerated()), id: \.element.id) { index, slide in
                        LearnBasicsStorySlide(
                            slide: slide,
                            isActive: slideIndex == index
                        )
                        .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .overlay {
                    GeometryReader { proxy in
                        HStack(spacing: 0) {
                            Color.clear
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    moveToPreviousSlide()
                                }
                                .frame(width: proxy.size.width / 2)

                            Color.clear
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    moveToNextSlide()
                                }
                                .frame(width: proxy.size.width / 2)
                        }
                    }
                }

                HStack(spacing: 12) {
                    Button("Previous", action: moveToPreviousSlide)
                    .buttonStyle(.bordered)
                    .tint(.white)
                    .disabled(slideIndex == 0)
                    .opacity(slideIndex == 0 ? 0.4 : 1)

                    Spacer()

                    if slideIndex == story.slides.count - 1 {
                        Button("Try it yourself", action: onTryItYourself)
                            .buttonStyle(.borderedProminent)
                            .tint(.white)
                            .foregroundStyle(Color.accentColor)
                    } else {
                        Button("Next", action: moveToNextSlide)
                        .buttonStyle(.borderedProminent)
                        .tint(.white)
                        .foregroundStyle(Color.accentColor)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 28)
            }
        }
        .interactiveDismissDisabled()
    }

    private func moveToPreviousSlide() {
        guard slideIndex > 0 else {
            return
        }

        withAnimation(.easeInOut) {
            slideIndex -= 1
        }
    }

    private func moveToNextSlide() {
        guard slideIndex < story.slides.count - 1 else {
            return
        }

        withAnimation(.easeInOut) {
            slideIndex += 1
        }
    }
}

private struct LearnBasicsStorySlide: View {

    let slide: LearnBasicsSlide
    let isActive: Bool

    var body: some View {
        VStack(spacing: 28) {
            Image(systemName: slide.symbol)
                .font(.system(size: 74, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 156, height: 156)
                .background(.white.opacity(0.16), in: Circle())

            VStack(spacing: 12) {
                Text(slide.title)
                    .font(.largeTitle.weight(.bold))
                    .multilineTextAlignment(.center)

                Text(slide.message)
                    .font(.title3)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.white.opacity(0.82))
                    .fixedSize(horizontal: false, vertical: true)
            }
            .opacity(isActive ? 1 : 0)
            .animation(.easeIn(duration: 0.3), value: isActive)
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 32)
    }
}

private struct LocationDefaultTip: View {

    let locationName: String
    let onDismiss: () -> Void
    let onOpenSettings: () -> Void

    var body: some View {
        HStack(alignment: .center, spacing: 8) {
            Text("Set \(locationName) as default in")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            Button("Settings", action: onOpenSettings)
                .font(.footnote.weight(.semibold))
                .buttonStyle(.borderless)
                .foregroundStyle(.blue)
                .fixedSize()

            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.footnote.weight(.medium))
                    .foregroundStyle(.tertiary)
                    .frame(width: 32, height: 32)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Dismiss default location tip")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .contain)
    }
}

private enum HomeCreateSheet: Identifiable {
    case person
    case organization
    case equipment
    case appointment

    var id: Self { self }
}

// MARK: - Location Summary

private struct LocationSummary: Identifiable {
    let id = UUID()

    let name: String
    let subtitle: String

    let people: String
    let organizations: String
    let equipment: String
    let appointments: String

    let traffic: String
    let insight: String
}


// MARK: - Location Switcher

private struct LocationSwitcher: View {

    let location: LocationSummary
    let locations: [LocationSummary]

    @Binding var selectedLocationIndex: Int

    let canGoBack: Bool
    let canGoForward: Bool

    let onPrevious: () -> Void
    let onNext: () -> Void

    private let controlHeight: CGFloat = 24
    private let arrowButtonSize: CGFloat = 36

    var body: some View {
        HStack(spacing: 4) {

            arrowButton(
                systemName: "chevron.left",
                isEnabled: canGoBack,
                accessibilityLabel: "Previous location",
                action: onPrevious
            )

            Menu {
                ForEach(
                    Array(locations.enumerated()),
                    id: \.offset
                ) { index, item in

                    Button {
                        withAnimation {
                            selectedLocationIndex = index
                        }
                    } label: {
                        if index == selectedLocationIndex {
                            Label(
                                item.name,
                                systemImage: "checkmark"
                            )
                        } else {
                            Text(item.name)
                        }
                    }
                }

            } label: {
                HStack(spacing: 2) {

                    Text(location.name)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.primary)
                        .lineLimit(2)
                        .truncationMode(.tail)
                        .multilineTextAlignment(.leading)
                        .frame(
                            maxWidth: .infinity,
                            alignment: .leading
                        )

                    Image(systemName: "chevron.up.chevron.down")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.primary)
                        .fixedSize()
                }
                .padding(.horizontal, 1)
                .frame(
                    maxWidth: .infinity,
                    alignment: .leading
                )
                .frame(height: controlHeight)
                .contentShape(Rectangle())

            }
            .tint(.primary)
            .buttonStyle(.glass)
            .buttonBorderShape(.capsule)
            .frame(maxWidth: .infinity)
            .frame(height: controlHeight)
            .layoutPriority(1)
            .accessibilityLabel("Choose location")
            .accessibilityValue(location.name)

            arrowButton(
                systemName: "chevron.right",
                isEnabled: canGoForward,
                accessibilityLabel: "Next location",
                action: onNext
            )
        }
    }

    private func arrowButton(
        systemName: String,
        isEnabled: Bool,
        accessibilityLabel: String,
        action: @escaping () -> Void
    ) -> some View {

        Button(action: action) {
            Image(systemName: systemName)
                .font(.caption.weight(.semibold))
                .frame(
                    maxWidth: .infinity,
                    maxHeight: .infinity
                )
        }
        .buttonStyle(.glass)
        .buttonBorderShape(.circle)
        .frame(
            width: arrowButtonSize,
            height: arrowButtonSize
        )
        .foregroundStyle(isEnabled ? .primary : .tertiary)
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1 : 0.45)
        .accessibilityLabel(accessibilityLabel)
    }
}


// MARK: - Dashboard Content

private struct LocationDashboardContent: View {

    let location: LocationSummary
    let isPersonTutorialActive: Bool
    let onAbandonPersonTutorial: () -> Void
    let onAdd: (HomeCreateSheet) -> Void
    let onAIAction: (String) -> Void

    private var personTutorialTipPresentation: Binding<Bool> {
        Binding(
            get: { isPersonTutorialActive },
            set: { isPresented in
                if !isPresented {
                    onAbandonPersonTutorial()
                }
            }
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {

            if isPersonTutorialActive {
                TipView(
                    HomeAddRegularDriverTip(),
                    isPresented: personTutorialTipPresentation,
                    arrowEdge: .bottom
                ) { action in
                    guard action.id == "next-step" else { return }
                    onAdd(.person)
                }
                .tint(.blue)
                .tipViewStyle(OnboardingTipViewStyle())
            }

            MetricGrid(
                location: location,
                onAdd: onAdd
            )

            AccessRecordsSummaryCard()

            InventorySummaryCard()


            DashboardSection(title: "Do it faster with AI") {
                VStack(
                    alignment: .leading,
                    spacing: 10
                ) {

                    AIActionButton(
                        title: "Authorize this person to all locations",
                        action: onAIAction
                    )

                    AIActionButton(
                        title: "How many people entered yesterday?",
                        action: onAIAction
                    )

                    AIActionButton(
                        title: "Show events that need review",
                        action: onAIAction
                    )
                }
            }

           
        }
    }
}


// MARK: - Metric Grid

private struct MetricGrid: View {

    let location: LocationSummary
    let onAdd: (HomeCreateSheet) -> Void

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        LazyVGrid(
            columns: columns,
            spacing: 12
        ) {

            MetricCard(
                title: "Authorized people",
                value: location.people,
                newValue: Int.random(in: 1...5),
                systemImage: "person.fill",
                tint: .blue,
                destination: AuthorizedPeopleOperationsView()
                    .permissionProtected(.authorizedPeople),
                onAdd: { onAdd(.person) }
            )

            MetricCard(
                title: "Authorized organizations",
                value: location.organizations,
                newValue: Int.random(in: 1...5),
                systemImage: "building.2.fill",
                tint: .blue,
                destination: AuthorizedOrganizationsOperationsView()
                    .permissionProtected(.authorizedOrganizations),
                onAdd: { onAdd(.organization) }
            )

            MetricCard(
                title: "Authorized equipment",
                value: location.equipment,
                newValue: Int.random(in: 1...5),
                systemImage: "truck.box.fill",
                tint: .blue,
                destination: EquipmentOperationsView()
                    .permissionProtected(.authorizedEquipment),
                onAdd: { onAdd(.equipment) }
            )

            MetricCard(
                title: "Appointments",
                value: location.appointments,
                newValue: Int.random(in: 1...5),
                systemImage: "calendar",
                tint: .blue,
                destination: AppointmentsOperationsView()
                    .permissionProtected(.appointments),
                onAdd: { onAdd(.appointment) }
            )
        }
    }
}


// MARK: - Metric Card

private struct HomeAddRegularDriverTip: Tip {
    var title: Text {
        Text("1. Add a regular driver")
    }

    var message: Text? {
        Text("Start here to add someone you authorize often.")
    }

    var image: Image? {
        Image(systemName: "person.badge.plus")
    }

    var actions: [Action] {
        Action(id: "next-step", title: "Next step")
    }
}

private struct MetricCard<Destination: View>: View {

    let title: String
    let value: String
    let newValue: Int
    let systemImage: String
    let tint: Color
    let destination: Destination
    let onAdd: () -> Void

    var body: some View {
        ZStack(alignment: .topTrailing) {

            NavigationLink {
                destination
            } label: {

                VStack(
                    alignment: .leading,
                    spacing: 0
                ) {

                    VStack(
                        alignment: .leading,
                        spacing: 3
                    ) {

                        Image(systemName: systemImage)
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(tint)
                            .frame(
                                width: 34,
                                height: 34
                            )

                        Text(title)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }

                    Spacer()

                    HStack( spacing: 6) {
                        Text(value)
                            .font(
                                .system(
                                    .title,
                                    design: .rounded
                                )
                                .weight(.bold)
                            )
                            .foregroundStyle(.primary)
                        
                        Text("\(newValue) new")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(tint)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(
                                tint.opacity(0.08),
                                in: Capsule()
                            )
                    }
                }
                .frame(
                    maxWidth: .infinity,
                    minHeight: 132,
                    alignment: .leading
                )
                .padding(16)
                .background(
                    Color(.secondarySystemGroupedBackground),
                    in: RoundedRectangle(
                        cornerRadius: 20,
                        style: .continuous
                    )
                )
                .contentShape(
                    RoundedRectangle(
                        cornerRadius: 20,
                        style: .continuous
                    )
                )
            }
            .buttonStyle(.plain)
            .accessibilityLabel(title)
            .accessibilityValue("\(value), \(newValue) new")

            Button(action: onAdd) {
                Image(systemName: "plus")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Color.primary)
                    .frame(width: 30, height: 30)
                    .background(Color.primary.opacity(0.12), in: Circle())
            }
            .buttonStyle(.plain)
            .padding(12)
            .contentShape(Circle())
            .accessibilityLabel("Add \(title)")
        }
    }
}


// MARK: - Access Records Summary

private struct AccessRecordsSummaryCard: View {

    private let points = [
        AccessActivityPoint(day: "Jan 27", entries: 15, exits: 9),
        AccessActivityPoint(day: "28", entries: 18, exits: 11),
        AccessActivityPoint(day: "29", entries: 20, exits: 13),
        AccessActivityPoint(day: "30", entries: 19, exits: 14),
        AccessActivityPoint(day: "31", entries: 20, exits: 15),
        AccessActivityPoint(day: "Feb 1", entries: 6, exits: 2),
        AccessActivityPoint(day: "2", entries: 17, exits: 10)
    ]

    private var totalEntries: Int {
        points.reduce(0) { $0 + $1.entries }
    }

    private var totalExits: Int {
        points.reduce(0) { $0 + $1.exits }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(alignment: .top, spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Activity")
                        .font(.headline.weight(.semibold))

                    Text("Inbound and outbound activity over the last 7 days.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 8)

                NavigationLink {
                    AccessRecordsView()
                        .permissionProtected(.activity)
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.foreground)

                }
                .accessibilityLabel("View activity")
            }

            HStack(spacing: 28) {
                AccessMetric(label: "Entries", value: totalEntries, tint: .blue)
                AccessMetric(label: "Exits", value: totalExits, tint: .birdseyeAmber)
                AccessMetric(label: "Total", value: 765, tint: .primary)
            }

            Chart(points) { point in
                BarMark(
                    x: .value("Day", point.day),
                    y: .value("Activity", point.entries)
                )
                .foregroundStyle(by: .value("Direction", "Entries"))
                .cornerRadius(2)

                BarMark(
                    x: .value("Day", point.day),
                    y: .value("Activity", point.exits)
                )
                .foregroundStyle(by: .value("Direction", "Exits"))
                .cornerRadius(2)
            }
            .chartForegroundStyleScale([
                "Entries": Color.blue,
                "Exits": Color.birdseyeAmber
            ])
            .chartLegend(.hidden)
            .chartXAxis {
                AxisMarks { value in
                    AxisValueLabel(anchor: .top) {
                        if let day = value.as(String.self) {
                            Text(day)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .chartYAxis(.hidden)
            .chartPlotStyle { plotArea in
                plotArea
                    .frame(height: 142)
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Seven day access activity chart")
            .accessibilityValue("\(totalEntries) entries and \(totalExits) exits")
        }
        .padding(20)
        .background(
            Color(.secondarySystemGroupedBackground),
            in: RoundedRectangle(cornerRadius: 22, style: .continuous)
        )
    }
}

// MARK: - Inventory Summary

private struct InventorySummaryCard: View {

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(alignment: .top, spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Inventory")
                        .font(.headline.weight(.semibold))

                    Text("Current trucks, trailers, and facility inventory for this location.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 8)


                NavigationLink {
                    InventoryOperationsView()
                        .permissionProtected(.inventoryList)
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.foreground)
                }
                .accessibilityLabel("View inventory")
            }

            HStack(spacing: 28) {
                AccessMetric(label: "Trucks", value: 15, tint: .primary)
                AccessMetric(label: "Trailers", value: 23, tint: .primary)
                AccessMetric(label: "Total", value: 765, tint: .primary)
            }
        }
        .padding(20)
        .background(
            Color(.secondarySystemGroupedBackground),
            in: RoundedRectangle(cornerRadius: 22, style: .continuous)
        )
    }
}


private struct AccessActivityPoint: Identifiable {

    let id = UUID()
    let day: String
    let entries: Int
    let exits: Int
}

private struct AccessMetric: View {

    let label: String
    let value: Int
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Text(value, format: .number)
                .font(.system(.title, design: .rounded).weight(.bold))
                .foregroundStyle(tint)
        }
        .accessibilityElement(children: .combine)
    }
}


// MARK: - Dashboard Section

private struct DashboardSection<Content: View>: View {

    let title: LocalizedStringKey

    @ViewBuilder

    let content: () -> Content

    var body: some View {
        VStack(
            alignment: .leading,
            spacing: 10
        ) {

            Text(title)
                .font(.title3.weight(.bold))
                .foregroundStyle(.primary)
                .padding(.horizontal, 4)

            content()
                .padding(16)
                .background(
                    Color(.secondarySystemGroupedBackground),
                    in: RoundedRectangle(
                        cornerRadius: 20,
                        style: .continuous
                    )
                )
        }
    }
}


// MARK: - Dashboard Link Row

private struct DashboardLinkRow<Destination: View>: View {

    let title: LocalizedStringKey
    let systemImage: String
    let destination: Destination

    var body: some View {
        NavigationLink {
            destination
        } label: {

            Label(
                title,
                systemImage: systemImage
            )
            .frame(
                maxWidth: .infinity,
                alignment: .leading
            )
            .padding(.vertical, 10)
        }
        .foregroundStyle(.primary)
        .tint(.primary)
    }
}


// MARK: - AI Action

private struct AIActionButton: View {

    let title: String
    let action: (String) -> Void

    var body: some View {
        Button {
            action(title)
        } label: {

            Label(
                title,
                systemImage: "sparkles"
            )
            .frame(
                maxWidth: .infinity,
                alignment: .leading
            )
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
        .foregroundStyle(.blue)
    }
}


#Preview {
    HomeView(
        onAIAction: { _ in },
        onOpenSettings: {}
    )
}
