import SwiftUI

struct AccessPolicyEditorView: View {

    @Environment(\.dismiss)
    private var dismiss

    @State private var policy: AccessPolicy

    let onSave: (AccessPolicy) -> Void

    private let locations = [
        "All locations",
        "Northstar(Oshawa)",
        "Northstar(Dallas)",
        "Northstar(Toronto)"
    ]

    private let accessTypes = [
        "Default Access",
        "Banned Access",
        "Priority Access",
        "Specialized Access"
    ]

    private let periods = [
        "Ongoing",
        "One-time"
    ]


    init(
        policy: AccessPolicy,
        onSave: @escaping (AccessPolicy) -> Void
    ) {

        _policy = State(
            initialValue: policy
        )

        self.onSave = onSave
    }


    var body: some View {

        NavigationStack {

            Form {

                VStack(
                    alignment: .leading,
                    spacing: 14
                ) {

                    policyMenuField(
                        title: "Locations",
                        value: policy.locations,
                        icon: "mappin"
                    ) {

                        ForEach(
                            locations,
                            id: \.self
                        ) { location in

                            Button {

                                policy.locations =
                                    location

                            } label: {

                                if policy.locations
                                    == location {

                                    Label(
                                        location,
                                        systemImage:
                                            "checkmark"
                                    )

                                } else {

                                    Text(location)
                                }
                            }
                        }
                    }


                    policyMenuField(
                        title: "Access type",
                        value: policy.accessType,
                        icon: nil
                    ) {

                        ForEach(
                            accessTypes,
                            id: \.self
                        ) { type in

                            Button {

                                policy.accessType =
                                    type

                            } label: {

                                if policy.accessType
                                    == type {

                                    Label(
                                        type,
                                        systemImage:
                                            "checkmark"
                                    )

                                } else {

                                    Text(type)
                                }
                            }
                        }
                    }


                    policyMenuField(
                        title: "Period access",
                        value: policy.periodAccess,
                        icon:
                            policy.periodAccess == "One-time"
                            ? "1.circle.fill"
                            : "infinity.circle.fill"
                    ) {
                        Button {
                            policy.periodAccess = "Ongoing"
                        } label: {
                            if policy.periodAccess == "Ongoing" {
                                Label(
                                    "Ongoing",
                                    systemImage: "checkmark"
                                )
                            } else {
                                Label(
                                    "Ongoing",
                                    systemImage: "infinity.circle.fill"
                                )
                            }
                        }

                        Button {
                            policy.periodAccess = "One-time"
                        } label: {
                            if policy.periodAccess == "One-time" {
                                Label(
                                    "One-time",
                                    systemImage: "checkmark"
                                )
                            } else {
                                Label(
                                    "One-time",
                                    systemImage: "1.circle.fill"
                                )
                            }
                        }
                    }

                    noteField


                    limitedTimeArea
                }
                .listRowInsets(
                    EdgeInsets(
                        top: 4,
                        leading: 0,
                        bottom: 4,
                        trailing: 0
                    )
                )
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
            }
            .contentMargins(
                .top,
                8,
                for: .scrollContent
            )
            .navigationTitle(
                "Access policy"
            )
            .navigationBarTitleDisplayMode(
                .inline
            )
            .toolbar {

                ToolbarItem(
                    placement: .cancellationAction
                ) {

                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(
                    placement: .confirmationAction
                ) {

                    Button("Save") {

                        onSave(policy)

                        dismiss()
                    }
                    .buttonStyle(.glassProminent)
                    .tint(.blue)
                }
            }
        }
    }


    // MARK: Menu Field

    @ViewBuilder
    private func policyMenuField<MenuContent: View>(
        title: String,
        value: String,
        icon: String?,
        @ViewBuilder menuContent:
            () -> MenuContent
    ) -> some View {

        VStack(
            alignment: .leading,
            spacing: 6
        ) {

            Text(title)
                .font(
                    .subheadline.weight(.semibold)
                )
                .foregroundStyle(.secondary)
                .padding(.horizontal, 16)

            Menu {

                menuContent()

            } label: {

                HStack(spacing: 10) {

                    if let icon {

                        Image(
                            systemName: icon
                        )
                        .foregroundStyle(.secondary)
                        .frame(width: 20)
                    }

                    Text(value)
                        .foregroundStyle(.primary)

                    Spacer()

                    Image(
                        systemName: "chevron.down"
                    )
                    .font(
                        .caption.weight(.semibold)
                    )
                    .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 16)
                .frame(
                    maxWidth: .infinity,
                    minHeight: 52
                )
                .background(
                    Color(
                        .secondarySystemGroupedBackground
                    ),
                    in: RoundedRectangle(
                        cornerRadius: 20,
                        style: .continuous
                    )
                )
            }
            .buttonStyle(.plain)
        }
    }


    // MARK: Note

    private var noteField: some View {

        VStack(
            alignment: .leading,
            spacing: 6
        ) {

            Text("Note")
                .font(
                    .subheadline.weight(.semibold)
                )
                .foregroundStyle(.secondary)
                .padding(.horizontal, 16)

            HStack(spacing: 10) {

                Image(
                    systemName:
                        "note.text"
                )
                .foregroundStyle(.secondary)

                TextField(
                    "Specific information about this person's access",
                    text: $policy.note
                )
            }
            .padding(.horizontal, 16)
            .frame(
                maxWidth: .infinity,
                minHeight: 52
            )
            .background(
                Color(
                    .secondarySystemGroupedBackground
                ),
                in: RoundedRectangle(
                    cornerRadius: 20,
                    style: .continuous
                )
            )
        }
    }


    // MARK: Limited Time

    private var limitedTimeArea: some View {

        VStack(
            alignment: .leading,
            spacing: 14
        ) {

            Toggle(
                isOn: $policy.limitedTimeAccess
            ) {
                HStack(
                    alignment: .top,
                    spacing: 10
                ) {
                    Image(systemName: "clock.fill")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .frame(width: 20, height: 20)
                        .padding(.top, 2)

                    VStack(
                        alignment: .leading,
                        spacing: 2
                    ) {
                        Text("Limited time access")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.primary)

                        Text("Enable access only during selected periods.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(.horizontal, 16)


            if policy.limitedTimeAccess {

                dateField(
                    title: "Start date",
                    selection:
                        $policy.startDate
                )

                optionalEndDateField

                scheduleArea
            }
        }
    }


    // MARK: Date

    private func dateField(
        title: String,
        selection: Binding<Date>
    ) -> some View {

        VStack(
            alignment: .leading,
            spacing: 6
        ) {

            Text(title)
                .font(
                    .subheadline.weight(.semibold)
                )
                .foregroundStyle(.secondary)
                .padding(.horizontal, 16)

            HStack {

                DatePicker(
                    "",
                    selection: selection,
                    displayedComponents:
                        .date
                )
                .labelsHidden()

                Spacer()
            }
            .padding(.horizontal, 16)
            .frame(
                maxWidth: .infinity,
                minHeight: 52
            )
            .background(
                Color(
                    .secondarySystemGroupedBackground
                ),
                in: RoundedRectangle(
                    cornerRadius: 20,
                    style: .continuous
                )
            )
        }
    }


    private var optionalEndDateField: some View {

        VStack(
            alignment: .leading,
            spacing: 6
        ) {

            HStack {

                Text("End date")
                    .font(
                        .subheadline.weight(
                            .semibold
                        )
                    )
                    .foregroundStyle(.secondary)

                Spacer()

                if policy.endDate != nil {

                    Button("Clear") {
                        policy.endDate = nil
                    }
                    .font(.subheadline)
                }
            }
            .padding(.horizontal, 16)

            if policy.endDate != nil {

                HStack {

                    DatePicker(
                        "",
                        selection: Binding(
                            get: {
                                policy.endDate
                                ?? Date()
                            },
                            set: {
                                policy.endDate = $0
                            }
                        ),
                        displayedComponents:
                            .date
                    )
                    .labelsHidden()

                    Spacer()
                }
                .padding(.horizontal, 16)
                .frame(
                    maxWidth: .infinity,
                    minHeight: 52
                )
                .background(
                    Color(
                        .secondarySystemGroupedBackground
                    ),
                    in: RoundedRectangle(
                        cornerRadius: 20,
                        style: .continuous
                    )
                )

            } else {

                Button {

                    policy.endDate = Date()

                } label: {

                    HStack {

                        Text("No end date")
                            .foregroundStyle(
                                .secondary
                            )

                        Spacer()

                        Image(
                            systemName:
                                "calendar.badge.plus"
                        )
                        .foregroundStyle(.blue)
                    }
                    .padding(.horizontal, 16)
                    .frame(
                        maxWidth: .infinity,
                        minHeight: 52
                    )
                    .background(
                        Color(
                            .secondarySystemGroupedBackground
                        ),
                        in: RoundedRectangle(
                            cornerRadius: 20,
                            style: .continuous
                        )
                    )
                }
                .buttonStyle(.plain)
            }

            Text(
                "Leave empty if there is no end date"
            )
            .font(.caption)
            .foregroundStyle(.secondary)
            .padding(.horizontal, 16)
        }
    }


    // MARK: Schedule

    private var scheduleArea: some View {

        VStack(
            alignment: .leading,
            spacing: 8
        ) {

            Text("Weekly schedule")
                .font(
                    .subheadline.weight(.semibold)
                )
                .foregroundStyle(.secondary)
                .padding(.horizontal, 16)

            VStack(spacing: 0) {

                dayRow(
                    day:
                        $policy.monday
                )

                Divider()
                    .padding(.leading, 16)

                dayRow(
                    day:
                        $policy.tuesday
                )

                Divider()
                    .padding(.leading, 16)

                dayRow(
                    day:
                        $policy.wednesday
                )

                Divider()
                    .padding(.leading, 16)

                dayRow(
                    day:
                        $policy.thursday
                )

                Divider()
                    .padding(.leading, 16)

                dayRow(
                    day:
                        $policy.friday
                )

                Divider()
                    .padding(.leading, 16)

                dayRow(
                    day:
                        $policy.saturday
                )

                Divider()
                    .padding(.leading, 16)

                dayRow(
                    day:
                        $policy.sunday
                )
            }
            .background(
                Color(
                    .secondarySystemGroupedBackground
                ),
                in: RoundedRectangle(
                    cornerRadius: 20,
                    style: .continuous
                )
            )
        }
    }


    private func dayRow(
        day: Binding<DayAccess>
    ) -> some View {

        VStack(
            alignment: .leading,
            spacing: 10
        ) {

            Toggle(
                day.wrappedValue.title,
                isOn: day.enabled
            )
            .font(
                .body.weight(.medium)
            )

            if day.wrappedValue.enabled {

                HStack(spacing: 12) {

                    VStack(
                        alignment: .leading,
                        spacing: 4
                    ) {

                        Text("Start time")
                            .font(.caption)
                            .foregroundStyle(
                                .secondary
                            )

                        DatePicker(
                            "",
                            selection:
                                day.startTime,
                            displayedComponents:
                                .hourAndMinute
                        )
                        .labelsHidden()
                    }

                    VStack(
                        alignment: .leading,
                        spacing: 4
                    ) {

                        Text("End time")
                            .font(.caption)
                            .foregroundStyle(
                                .secondary
                            )

                        DatePicker(
                            "",
                            selection:
                                day.endTime,
                            displayedComponents:
                                .hourAndMinute
                        )
                        .labelsHidden()
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}


// MARK: - Access Policy Summary Chip

