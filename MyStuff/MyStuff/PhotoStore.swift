import Foundation
import SwiftUI
import PDFKit

class PhotoStore: ObservableObject {
    @Published var photoEntries: [PhotoEntry] = []
    private let saveKey = "SavedPhotoEntries"
    
    init() {
        loadData()
    }
    
    // Save data to UserDefaults and local file system
    func saveData() {
        if let encoded = try? JSONEncoder().encode(photoEntries) {
            UserDefaults.standard.set(encoded, forKey: saveKey)
        }
    }
    
    // Load data from UserDefaults
    func loadData() {
        if let data = UserDefaults.standard.data(forKey: saveKey) {
            if let decoded = try? JSONDecoder().decode([PhotoEntry].self, from: data) {
                photoEntries = decoded
                return
            }
        }
        // If no saved data, start with empty array
        photoEntries = []
    }
    
    // Add a new photo entry
    func addPhoto(imageData: Data, caption: String) {
        // Create a unique filename
        let filename = "\(UUID().uuidString).jpg"
        let path = FileManager.documentsDirectory.appendingPathComponent(filename)
        
        // Save the image file
        try? imageData.write(to: path)
        
        // Create and add the new entry
        let newEntry = PhotoEntry(
            imageFilename: filename,
            caption: caption,
            dateCreated: Date()
        )
        
        photoEntries.append(newEntry)
        saveData()
    }
    
    // Delete a photo entry
    func deletePhoto(at indexSet: IndexSet) {
        // Delete the image files
        for index in indexSet {
            let entry = photoEntries[index]
            let path = FileManager.documentsDirectory.appendingPathComponent(entry.imageFilename)
            try? FileManager.default.removeItem(at: path)
        }
        
        // Remove from the array
        photoEntries.remove(atOffsets: indexSet)
        saveData()
    }
    
    // Generate PDF from photo entries
    func exportToPDF() -> URL? {
        guard !photoEntries.isEmpty else { return nil }
        
        // Generate the PDF data
        guard let pdfData = PDFGenerator.generatePDF(from: photoEntries) else { return nil }
        
        // Create a temporary file URL
        let temporaryDirectoryURL = FileManager.default.temporaryDirectory
        let temporaryFileURL = temporaryDirectoryURL.appendingPathComponent("MyStuff_\(Date().timeIntervalSince1970).pdf")
        
        // Write the PDF data to the file
        do {
            try pdfData.write(to: temporaryFileURL)
            return temporaryFileURL
        } catch {
            print("Error saving PDF: \(error)")
            return nil
        }
    }
}
