import SwiftUI
import Charts
import TipKit

struct HomeView: View {

    @Environment(SnackbarCenter.self) private var snackbarCenter

    let onAIAction: (String) -> Void
    let onOpenSettings: () -> Void
    let onOpenTeam: () -> Void

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
    @State private var isOnboardingExpanded = true
    @State private var isPersonTutorialActive = false
    @AppStorage("hasDismissedOnboardingChecklist") private var hasDismissedOnboardingChecklist = false
    @AppStorage("onboardingAuthorizedPersonComplete") private var isAuthorizedPersonComplete = false
    @AppStorage("hasResetPersonTutorialCompletion") private var hasResetPersonTutorialCompletion = false
    @AppStorage("onboardingOrganizationComplete") private var isOrganizationComplete = false
    @AppStorage("onboardingEquipmentComplete") private var isEquipmentComplete = false
    @AppStorage("onboardingAppointmentComplete") private var isAppointmentComplete = false
    @AppStorage("onboardingCrewComplete") private var isCrewComplete = false
    @AppStorage("onboardingAIComplete") private var isAIComplete = false

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

                            Spacer(minLength: 0)

                            if hasDismissedOnboardingChecklist || !isOnboardingExpanded {
                                OnboardingToggleButton(
                                    isExpanded: $isOnboardingExpanded,
                                    onShow: {
                                        hasDismissedOnboardingChecklist = false
                                    }
                                )
                                .transition(.opacity.combined(with: .scale(scale: 0.92)))
                            }
                        }

                        if !hasDismissedOnboardingChecklist && isOnboardingExpanded {
                            OnboardingChecklist(
                                completedTasks: onboardingCompletionStates,
                                isExpanded: $isOnboardingExpanded,
                                onShowMe: showOnboardingTask,
                                onRestart: restartOnboardingSteps,
                                onHide: hideOnboardingSteps
                            )
                            .transition(.opacity.combined(with: .move(edge: .top)))
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
                        onAdd: { sheet in
                            activeCreateSheet = sheet
                        },
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
                    AddPersonAuthorizationView(
                        isPersonTutorialActive: isPersonTutorialActive,
                        onCancelTutorial: {
                            isPersonTutorialActive = false
                        },
                        onCompleteTutorial: {
                            isPersonTutorialActive = false
                            isAuthorizedPersonComplete = true
                            snackbarCenter.show("Completed a tutorial: Authorized a driver.")
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
            .animation(
                .easeInOut(duration: 0.25),
                value: selectedLocation.id
            )
            .onAppear {
                if !hasResetPersonTutorialCompletion {
                    isAuthorizedPersonComplete = false
                    hasResetPersonTutorialCompletion = true
                }

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

    private var onboardingCompletionStates: [Bool] {
        [
            true,
            isAuthorizedPersonComplete,
            isAppointmentComplete,
            isCrewComplete,
            isAIComplete
        ]
    }

    private func restartOnboardingSteps() {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.78)) {
            isAuthorizedPersonComplete = false
            isAppointmentComplete = false
            isCrewComplete = false
            isAIComplete = false
        }
    }

    private func hideOnboardingSteps() {
        withAnimation(.easeInOut(duration: 0.25)) {
            hasDismissedOnboardingChecklist = true
            isOnboardingExpanded = false
        }
    }

    private func showOnboardingTask(_ task: OnboardingTask) {
        switch task {
        case .workspace:
            break
        case .authorizedPerson:
            Task {
                await HomeAddRegularDriverTip().resetEligibility()
            }
            withAnimation(.spring(response: 0.35, dampingFraction: 0.78)) {
                isPersonTutorialActive = true
            }
        case .appointment:
            withAnimation(.spring(response: 0.35, dampingFraction: 0.78)) {
                isAppointmentComplete = true
            }
            activeCreateSheet = .appointment
        case .crew:
            withAnimation(.spring(response: 0.35, dampingFraction: 0.78)) {
                isCrewComplete = true
            }
            onOpenTeam()
        case .ai:
            withAnimation(.spring(response: 0.35, dampingFraction: 0.78)) {
                isAIComplete = true
            }
            onAIAction("Help me get started with Birdseye AI.")
        }
    }
}

private enum OnboardingTask: CaseIterable, Identifiable, Hashable {
    case workspace
    case authorizedPerson
    case appointment
    case crew
    case ai

    var id: Self { self }

    var title: String {
        switch self {
        case .workspace: "Join your workspace"
        case .authorizedPerson: "Authorize a driver"
        case .appointment: "Schedule an appointment"
        case .crew: "Invite your team"
        case .ai: "Ask AI to do anything."
        }
    }

    var subtitle: String {
        switch self {
        case .workspace: "Workspace"
        case .authorizedPerson: "People"
        case .appointment: "Appointments"
        case .crew: "Team"
        case .ai: "Birdseye AI"
        }
    }

    var description: String {
        switch self {
        case .workspace: "Your workspace is ready."
        case .authorizedPerson: "Add a regular driver to your list."
        case .appointment: "Know who’s arriving and when."
        case .crew: "Bring teammates in and set their access."
        case .ai: "Try Birdseye AI"
        }
    }

    var thumbnailSymbol: String {
        switch self {
        case .workspace: "checkmark.circle.fill"
        case .authorizedPerson: "person.badge.plus"
        case .appointment: "calendar.badge.clock"
        case .crew: "person.3.fill"
        case .ai: "sparkles"
        }
    }

    var iconColor: Color {
        switch self {
        case .workspace: .green
        case .authorizedPerson: .blue
        case .appointment: .purple
        case .crew: .teal
        case .ai: .pink
        }
    }

}

private struct OnboardingToggleButton: View {

    @Binding var isExpanded: Bool
    let onShow: () -> Void

    var body: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.25)) {
                onShow()
                isExpanded = true
            }
        } label: {
            HStack(spacing: 6) {
                Text("Learn basics")
                    .font(.caption.weight(.semibold))

                Image(systemName: "chevron.down")
                    .font(.caption2.weight(.bold))
                    .contentTransition(.symbolEffect(.replace))
                    .symbolEffect(.bounce, value: isExpanded)
            }
            .foregroundStyle(Color(.secondaryLabel))
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(.secondarySystemBackground), in: Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Learn basics")
        .accessibilityHint("Show onboarding steps")
    }
}

private struct OnboardingChecklist: View {

    let completedTasks: [Bool]
    @Binding var isExpanded: Bool
    let onShowMe: (OnboardingTask) -> Void
    let onRestart: () -> Void
    let onHide: () -> Void

    private var completedCount: Int {
        completedTasks.filter { $0 }.count
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            OnboardingChecklistHeader(
                completedCount: completedCount,
                totalCount: OnboardingTask.allCases.count,
                isExpanded: $isExpanded
            )
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            ForEach(Array(OnboardingTask.allCases.enumerated()), id: \.element) { index, task in
                OnboardingTaskRow(
                    task: task,
                    stepNumber: index + 1,
                    isComplete: completedTasks[index],
                    isCurrent: !completedTasks[index] && !completedTasks.prefix(index).contains(false),
                    onShowMe: { onShowMe(task) }
                )
                .padding(.horizontal, 12)
            }

            if completedCount == OnboardingTask.allCases.count {
                OnboardingCompletionActions(
                    onRestart: onRestart,
                    onHide: onHide
                )
                .padding(.horizontal, 12)
                .padding(.top, 8)
                .padding(.bottom, 12)
            }
        }
        .padding(0)
        .background(
            Color(.secondarySystemGroupedBackground),
            in: RoundedRectangle(cornerRadius: 20, style: .continuous)
        )
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color(.separator).opacity(0.45), lineWidth: 1)
        }
        .accessibilityElement(children: .contain)
    }
}

private struct OnboardingChecklistHeader: View {

    let completedCount: Int
    let totalCount: Int
    @Binding var isExpanded: Bool

    private var isComplete: Bool {
        completedCount == totalCount
    }

    var body: some View {
        HStack(spacing: 20) {
            OnboardingProgressRing(completedCount: completedCount, totalCount: totalCount)

            VStack(alignment: .leading, spacing: 1) {
                if isComplete {
                    Text("You're all set!")
                        .font(.headline.weight(.semibold))

                    Text("Find more tips in Help.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    Text("Get started")
                        .font(.headline.weight(.semibold))

                    Text("Learn the basics in 2 minutes.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer(minLength: 0)

            Button {
                withAnimation(.easeInOut(duration: 0.25)) {
                    isExpanded = false
                }
            } label: {
                Image(systemName: "chevron.up")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(Color(.secondaryLabel))
                    .frame(width: 36, height: 36)
                    .background(.thinMaterial, in: Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Collapse onboarding")
            .accessibilityHint("Shows the Learn basics button")
        }
    }
}

private struct OnboardingCompletionActions: View {

    let onRestart: () -> Void
    let onHide: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Spacer(minLength: 0)

            Button("Restart", systemImage: "arrow.counterclockwise", action: onRestart)
                .font(.subheadline.weight(.semibold))
                .buttonStyle(.bordered)

            Button(action: onHide) {
                Label("Complete", systemImage: "checkmark")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 9)
                    .background(Color.green, in: Capsule())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Complete onboarding")
            .accessibilityHint("Collapses onboarding to the Learn basics button")
        }
    }
}

private struct OnboardingProgressRing: View {

    let completedCount: Int
    let totalCount: Int

    private var isComplete: Bool {
        completedCount == totalCount
    }

    var body: some View {
        Gauge(value: Double(completedCount), in: 0...Double(totalCount)) {
            Text("Onboarding progress")
        } currentValueLabel: {
            Text("\(completedCount)/\(totalCount)")
                .font(.subheadline.weight(.semibold).monospacedDigit())
                .contentTransition(.numericText(value: Double(completedCount)))
        }
        .gaugeStyle(.accessoryCircularCapacity)
        .tint(isComplete ? .green : .accentColor)
        .frame(width: 48, height: 48)
        .animation(.spring(response: 0.35, dampingFraction: 0.78), value: completedCount)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(completedCount) of \(totalCount) steps complete")
    }
}

private struct OnboardingTaskRow: View {

    let task: OnboardingTask
    let stepNumber: Int
    let isComplete: Bool
    let isCurrent: Bool
    let onShowMe: () -> Void

    var body: some View {
        Button(action: onShowMe) {
            HStack(spacing: 10) {
                Image(systemName: isComplete ? "checkmark.circle.fill" : (isCurrent ? "circle.inset.filled" : "circle"))
                    .font(.title3)
                    .foregroundStyle(isComplete ? Color.green : (isCurrent ? Color.accentColor : Color.secondary))
                    .frame(width: 28, height: 28)
                    .contentTransition(.symbolEffect(.replace))
                    .symbolEffect(.bounce, value: isComplete)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 2) {
                    Text(task.title)
                        .font(.subheadline.weight(.medium))
                        .strikethrough(isComplete, color: .secondary)
                        .foregroundStyle(isComplete ? .secondary : .primary)

                    if isCurrent {
                        Text(task.description)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                            .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                }

                Spacer(minLength: 0)

                if isCurrent {
                    HStack(spacing: 6) {
                        Text("Start")
                        Image(systemName: "chevron.right")
                    }
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Color.accentColor, in: Capsule())
                    .transition(.opacity.combined(with: .scale(scale: 0.9)))
                } else if !isComplete {
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(Color(.tertiaryLabel))
                        .accessibilityHidden(true)
                }
            }
            .padding(.vertical, 8)

        }
        .buttonStyle(.plain)
        .contentShape(Rectangle())
        .hoverEffect(.highlight)
        .sensoryFeedback(.success, trigger: isComplete)
        .animation(.spring(response: 0.35, dampingFraction: 0.78), value: isComplete)
        .animation(.spring(response: 0.35, dampingFraction: 0.78), value: isCurrent)
        .accessibilityLabel(isComplete ? "\(task.title), completed" : task.title)
        .accessibilityHint(isComplete ? "" : "Opens this getting started action")
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
                .backgroundStyle(Color.white)
            }

            MetricGrid(
                location: location,
                isPersonTutorialActive: isPersonTutorialActive,
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
    let isPersonTutorialActive: Bool
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
                destination: AuthorizedPeopleOperationsView(),
                isHighlighted: isPersonTutorialActive,
                onAdd: { onAdd(.person) }
            )

            MetricCard(
                title: "Authorized organizations",
                value: location.organizations,
                newValue: Int.random(in: 1...5),
                systemImage: "building.2.fill",
                tint: .blue,
                destination: AuthorizedOrganizationsOperationsView(),
                isHighlighted: false,
                onAdd: { onAdd(.organization) }
            )

            MetricCard(
                title: "Authorized equipment",
                value: location.equipment,
                newValue: Int.random(in: 1...5),
                systemImage: "truck.box.fill",
                tint: .blue,
                destination: EquipmentOperationsView(),
                isHighlighted: false,
                onAdd: { onAdd(.equipment) }
            )

            MetricCard(
                title: "Appointments",
                value: location.appointments,
                newValue: Int.random(in: 1...5),
                systemImage: "calendar",
                tint: .blue,
                destination: AppointmentsOperationsView(),
                isHighlighted: false,
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
    let isHighlighted: Bool
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
                    .foregroundStyle(.primary)
                    .frame(width: 30, height: 30)
                    .background(
                        .primary.opacity(0.12),
                        in: Circle()
                    )
                    .overlay {
                        if isHighlighted {
                            Circle()
                                .stroke(.blue, lineWidth: 3)
                                .padding(-6)
                        }
                    }
                    .symbolEffect(.pulse, isActive: isHighlighted)
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
        onOpenSettings: {},
        onOpenTeam: {}
    )
}
