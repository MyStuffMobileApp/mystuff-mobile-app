import Foundation
import SwiftUI

struct PhotoEntry: Identifiable, Codable {
    var id = UUID()
    var imageFilename: String
    var caption: String
    var dateCreated: Date
    
    // New property to store serialized item list
    var serializedItemList: Data?
    
    // This won't be encoded/decoded but computed on demand
    var thumbnailImage: UIImage? {
        let path = FileManager.documentsDirectory.appendingPathComponent(imageFilename)
        return UIImage(contentsOfFile: path.path)
    }
    
    // Method to save item list
    mutating func saveItemList(_ itemStore: ItemPriceStore) {
        self.serializedItemList = try? JSONEncoder().encode(itemStore.items)
    }
    
    // Method to load item list
    func loadItemList() -> [ItemPrice] {
        guard let data = serializedItemList,
              let items = try? JSONDecoder().decode([ItemPrice].self, from: data) else {
            return []
        }
        return items
    }
    
    // Check if item list exists
    var hasItemList: Bool {
        return serializedItemList != nil
    }
}

// Extension to help with file operations
extension FileManager {
    static var documentsDirectory: URL {
        return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
}
