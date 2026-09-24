import SwiftUI

struct OrganizationPickerControl: View {
    @Binding var selection: String

    @State private var isShowingOrganizationPicker = false

    var body: some View {
        Button {
            isShowingOrganizationPicker = true
        } label: {
            HStack(spacing: 12) {
                Text(
                    selection.isEmpty
                        ? "Select organization"
                        : selection
                )
                .foregroundStyle(selection.isEmpty ? .tertiary : .primary)
                .frame(maxWidth: .infinity, alignment: .leading)

                Image(systemName: "chevron.up.chevron.down")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, minHeight: 52)
            .background(
                Color(.secondarySystemGroupedBackground),
                in: RoundedRectangle(cornerRadius: 20, style: .continuous)
            )
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $isShowingOrganizationPicker) {
            OrganizationSelectionDrawer(selection: $selection)
                .presentationDetents([.large])
                .presentationDragIndicator(.hidden)
        }
    }
}

private struct OrganizationSelectionDrawer: View {
    @Environment(\.dismiss) private var dismiss

    @Binding var selection: String

    @State private var searchText = ""
    @State private var isShowingAddOrganization = false

    @FocusState private var isSearchFieldFocused: Bool

    private let locationName = "Northstar (Oshawa)"

    private var filteredOrganizations: [OrganizationRecord] {
        let trimmedSearch = searchText.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        return OrganizationDirectory.records
            .filter {
                ($0.locations.contains(locationName)
                    || $0.locations.contains("All locations"))
                    && (
                        trimmedSearch.isEmpty
                        || $0.name.localizedCaseInsensitiveContains(trimmedSearch)
                    )
            }
            .sorted {
                $0.addedOrder > $1.addedOrder
            }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    OrganizationPickerSearchField(
                        text: $searchText,
                        isFocused: $isSearchFieldFocused
                    )

                    OrganizationPickerResultsHeader(
                        resultCount: filteredOrganizations.count,
                        locationName: locationName
                    )

                    if filteredOrganizations.isEmpty {
                        ContentUnavailableView.search(
                            text: searchText
                        )
                        .padding(.top, 48)
                    } else {
                        AuthorizedOrganizationsCard(
                            organizations: filteredOrganizations,
                            selectedOrganizationName: selection,
                            showsNewBadge: false
                        ) { organization in
                            selection = organization.name
                            dismiss()
                        }
                    }
                }
                .padding(.top, 16)
                .padding(.bottom, 32)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Select organization")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("Add new") {
                        isShowingAddOrganization = true
                    }
                    .tint(.primary)
                }
            }
            .sheet(isPresented: $isShowingAddOrganization) {
                OrganizationEditorView { newOrganizationName in
                    selection = newOrganizationName
                    dismiss()
                }
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
            }
        }
        .task {
            isSearchFieldFocused = true
        }
    }
}

private struct OrganizationPickerResultsHeader: View {
    let resultCount: Int
    let locationName: String

    var body: some View {
        HStack {
            Text("\(resultCount) results")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)

            Spacer()

            Text(locationName)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 16)
    }
}

private struct OrganizationPickerSearchField: View {
    @Binding var text: String
    @FocusState.Binding var isFocused: Bool

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.primary)

            TextField("Search organizations", text: $text)
                .focused($isFocused)
                .textInputAutocapitalization(.words)
                .autocorrectionDisabled()
                .submitLabel(.search)

            if !text.isEmpty {
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.primary)
                }
                .accessibilityLabel("Clear search")
            }
        }
        .padding(.horizontal, 14)
        .frame(minHeight: 38)
        .background(
            Color(.systemGray5),
            in: RoundedRectangle(cornerRadius: 20, style: .continuous)
        )
        .padding(.horizontal, 16)
    }
}
