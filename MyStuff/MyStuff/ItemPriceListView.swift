import SwiftUI

struct ItemPriceListView: View {
    @ObservedObject var itemStore: ItemPriceStore
    @State private var newItemName = ""
    @State private var isAddingNewItem = false
    @State private var editingItem: ItemPrice?
    @State private var tempPrice: String = ""
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        VStack {
            // Header section with total
            HStack {
                Text("Total Price:")
                    .font(.headline)
                
                Spacer()
                
                Text("$\(itemStore.totalPrice(), specifier: "%.2f")")
                    .font(.headline)
            }
            .padding()
            .background(Color.green.opacity(0.1))
            .cornerRadius(8)
            .padding(.horizontal)
            
            // Table header
            HStack {
                Text("Item")
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                Text("Price")
                    .font(.headline)
                    .frame(width: 120, alignment: .trailing)
            }
            .padding(.horizontal)
            .padding(.top)
            
            // Item list
            List {
                ForEach(itemStore.items) { item in
                    HStack {
                        Text(item.name)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        Button(action: {
                            editingItem = item
                            tempPrice = String(format: "%.2f", item.price)
                        }) {
                            Text("$\(item.price, specifier: "%.2f")")
                                .frame(width: 80, alignment: .trailing)
                                .foregroundColor(.primary)
                        }
                        .buttonStyle(BorderlessButtonStyle())
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        editingItem = item
                        tempPrice = String(format: "%.2f", item.price)
                    }
                }
                .onDelete(perform: deleteItems)
                
                // Add new item button
                Button(action: {
                    isAddingNewItem = true
                    newItemName = ""
                }) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(.green)
                        Text("Add Item")
                            .foregroundColor(.primary)
                    }
                }
                .buttonStyle(BorderlessButtonStyle())
            }
            .listStyle(InsetGroupedListStyle())
        }
        .navigationTitle("Price List")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                EditButton()
            }
        }
        .alert("Add New Item", isPresented: $isAddingNewItem) {
            TextField("Item Name", text: $newItemName)
            
            Button("Add") {
                if !newItemName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    itemStore.addItem(newItemName.trimmingCharacters(in: .whitespacesAndNewlines))
                }
            }
            
            Button("Cancel", role: .cancel) { }
        }
        .alert("Edit Price", isPresented: Binding<Bool>(
            get: { editingItem != nil },
            set: { if !$0 { editingItem = nil } }
        )) {
            TextField("Price", text: $tempPrice)
                .keyboardType(.decimalPad)
            
            Button("Save") {
                if var item = editingItem {
                    // Convert text field value to Double
                    if let price = Double(tempPrice.replacingOccurrences(of: ",", with: ".")) {
                        item.price = price
                        itemStore.updateItem(item)
                    }
                    editingItem = nil
                }
            }
            
            Button("Cancel", role: .cancel) {
                editingItem = nil
            }
        }
    }
    
    private func deleteItems(at offsets: IndexSet) {
        itemStore.deleteItem(at: offsets)
    }
}

struct ItemPriceListView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            ItemPriceListView(itemStore: ItemPriceStore())
        }
    }
}
