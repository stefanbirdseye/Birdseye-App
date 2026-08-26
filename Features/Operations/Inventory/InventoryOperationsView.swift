import SwiftUI

struct InventoryOperationsView: View {
    private let inventory: [InventoryRecord] = (1...100).map {
        InventoryRecord(id: $0, name: ["Loaded trailer", "Empty trailer", "Pallet", "Container"][ $0 % 4], category: ["Trailer", "Equipment", "Materials"][ $0 % 3], quantity: 1 + ($0 % 40))
    }

    @State private var searchText = ""
    @State private var isSearchPresented = false
    @State private var showLowStockOnly = false
    @State private var page = 0
    @State private var showingEditor = false
    @State private var selectedItem: InventoryRecord?

    private var filteredInventory: [InventoryRecord] {
        inventory.filter {
            (searchText.isEmpty || $0.name.localizedCaseInsensitiveContains(searchText) || $0.category.localizedCaseInsensitiveContains(searchText))
                && (!showLowStockOnly || $0.quantity < 10)
        }
    }

    var body: some View {
        Text("Inventory")
            .navigationTitle("Inventory")
    }
}

private struct InventoryRecord: Identifiable {
    let id: Int
    let name: String
    let category: String
    let quantity: Int
}

private struct InventoryEditorView: View {
    @Environment(\.dismiss) private var dismiss
    let item: InventoryRecord?
    @State private var name: String
    @State private var quantity: String

    init(item: InventoryRecord? = nil) {
        self.item = item
        _name = State(initialValue: item?.name ?? "")
        _quantity = State(initialValue: item.map { String($0.quantity) } ?? "")
    }

    var body: some View {
        NavigationStack {
            Form {
                TextField("Item name", text: $name)
                TextField("Quantity", text: $quantity).keyboardType(.numberPad)
                LabeledContent("Location", value: "All locations")
            }
            .navigationTitle(item == nil ? "Add inventory item" : "Edit inventory item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button(item == nil ? "Add" : "Save") { dismiss() }.tint(.blue) }
            }
        }
        .presentationDetents([.medium])
    }
}
