//
//  PhotoEntry.swift
//  PhotoNote
//
//  Created by Ryan Cabeen on 3/6/25.
//


import Foundation
import SwiftUI

struct PhotoEntry: Identifiable, Codable {
    var id = UUID()
    var imageFilename: String
    var caption: String
    var dateCreated: Date
    
    // This won't be encoded/decoded but computed on demand
    var thumbnailImage: UIImage? {
        let path = FileManager.documentsDirectory.appendingPathComponent(imageFilename)
        return UIImage(contentsOfFile: path.path)
    }
}

// Extension to help with file operations
extension FileManager {
    static var documentsDirectory: URL {
        return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
}
