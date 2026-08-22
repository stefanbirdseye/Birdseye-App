import SwiftUI

struct NewSheet: View {
    @Environment(\.dismiss) private var dismiss

    private let options = [
        ("Person", "person"),
        ("Organization", "building.2"),
        ("Equipment", "wrench.and.screwdriver"),
        ("Appointment", "calendar"),
        ("Authorization", "checkmark.shield")
    ]

    var body: some View {
        NavigationStack {
            List {
                Section("Create new") {
                    ForEach(options, id: \.0) { option in
                        Button {
                            dismiss()
                        } label: {
                            Label(option.0, systemImage: option.1)
                                .frame(minHeight: 44)
                        }
                    }
                }
            }
            .navigationTitle("Create new")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}

#Preview {
    NewSheet()
}
