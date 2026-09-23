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
            .padding(.horizontal, 16)
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
                .presentationDragIndicator(.visible)
        }
    }
}

private struct OrganizationSelectionDrawer: View {
    @Environment(\.dismiss) private var dismiss

    @Binding var selection: String

    @State private var searchText = ""
    @State private var isShowingAddOrganization = false

    @FocusState private var isSearchFieldFocused: Bool

    private var filteredOrganizations: [OrganizationRecord] {
        let trimmedSearch = searchText.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        return OrganizationDirectory.records
            .filter {
                trimmedSearch.isEmpty
                    || $0.name.localizedCaseInsensitiveContains(trimmedSearch)
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

                    Button("Add new organization", systemImage: "plus") {
                        isShowingAddOrganization = true
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.blue)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 16)

                    if filteredOrganizations.isEmpty {
                        ContentUnavailableView.search(
                            text: searchText
                        )
                        .padding(.top, 48)
                    } else {
                        AuthorizedOrganizationsCard(
                            organizations: filteredOrganizations
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

private struct OrganizationPickerSearchField: View {
    @Binding var text: String
    @FocusState.Binding var isFocused: Bool

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)

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
                        .foregroundStyle(.secondary)
                }
                .accessibilityLabel("Clear search")
            }
        }
        .padding(.horizontal, 14)
        .frame(minHeight: 44)
        .background(
            Color(.secondarySystemGroupedBackground),
            in: RoundedRectangle(cornerRadius: 14, style: .continuous)
        )
        .padding(.horizontal, 16)
    }
}
