import Foundation

struct ItemPrice: Identifiable, Codable, Equatable {
    var id = UUID()
    var name: String
    var price: Double
    
    static func ==(lhs: ItemPrice, rhs: ItemPrice) -> Bool {
        return lhs.id == rhs.id
    }
}

class ItemPriceStore: ObservableObject {
    @Published var items: [ItemPrice] = []
    private let saveKey = "SavedItemPrices"
    
    init() {
        loadData()
    }
    
    func saveData() {
        if let encoded = try? JSONEncoder().encode(items) {
            UserDefaults.standard.set(encoded, forKey: saveKey)
        }
    }
    
    func loadData() {
        if let data = UserDefaults.standard.data(forKey: saveKey) {
            if let decoded = try? JSONDecoder().decode([ItemPrice].self, from: data) {
                items = decoded
                return
            }
        }
        // If no saved data, start with empty array
        items = []
    }
    
    func addItem(_ name: String, price: Double = 0.0) {
        let newItem = ItemPrice(name: name, price: price)
        items.append(newItem)
        saveData()
    }
    
    func updateItem(_ item: ItemPrice) {
        if let index = items.firstIndex(where: { $0.id == item.id }) {
            items[index] = item
            saveData()
        }
    }
    
    func deleteItem(at indexSet: IndexSet) {
        items.remove(atOffsets: indexSet)
        saveData()
    }
    
    func deleteAll() {
        items.removeAll()
        saveData()
    }
    
    // Generate items from comma-separated string
    func generateItemsFromString(_ itemsString: String) {
        // Clear existing items
        items.removeAll()
        
        // Parse the comma-separated string
        let itemNames = itemsString
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        
        // Add each item with default price
        for name in itemNames {
            addItem(name)
        }
    }
    
    func totalPrice() -> Double {
        return items.reduce(0) { $0 + $1.price }
    }
}
