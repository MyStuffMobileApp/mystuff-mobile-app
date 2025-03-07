//
//  PDFGenerator.swift
//  PhotoNote
//
//  Created by Ryan Cabeen on 3/6/25.
//


import UIKit
import PDFKit

class PDFGenerator {
    
    static func generatePDF(from photoEntries: [PhotoEntry], appName: String = "MyStuff") -> Data? {
        // Create a new PDF document
        let pdfMetaData = [
            kCGPDFContextCreator: "MyStuff App",
            kCGPDFContextAuthor: "MyStuff User",
            kCGPDFContextTitle: "\(appName) Photos"
        ]
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMetaData as [String: Any]
        
        // Use A4 page size
        let pageWidth = 8.27 * 72.0
        let pageHeight = 11.69 * 72.0
        let pageRect = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)
        
        // Create the PDF renderer
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)
        
        // Generate PDF data
        let data = renderer.pdfData { (context) in
            // Add title page
            context.beginPage()
            addTitlePage(to: context, in: pageRect, appName: appName)
            
            // Add a page for each photo
            for entry in photoEntries {
                context.beginPage()
                addPhotoPage(for: entry, to: context, in: pageRect)
            }
        }
        
        return data
    }
    
    private static func addTitlePage(to context: UIGraphicsPDFRendererContext, in pageRect: CGRect, appName: String) {
        // Set up title page formatting
        let titleFont = UIFont.systemFont(ofSize: 36, weight: .bold)
        let subtitleFont = UIFont.systemFont(ofSize: 18, weight: .regular)
        
        // Format current date
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .long
        dateFormatter.timeStyle = .medium
        let dateString = dateFormatter.string(from: Date())
        
        // Draw title
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: titleFont,
            .foregroundColor: UIColor.black
        ]
        
        let attributedTitle = NSAttributedString(string: appName, attributes: titleAttributes)
        
        let titleStringSize = attributedTitle.size()
        let titleStringRect = CGRect(
            x: (pageRect.width - titleStringSize.width) / 2.0,
            y: pageRect.height / 3.0,
            width: titleStringSize.width,
            height: titleStringSize.height
        )
        attributedTitle.draw(in: titleStringRect)
        
        // Draw subtitle (Photo Collection)
        let subtitleAttributes: [NSAttributedString.Key: Any] = [
            .font: subtitleFont,
            .foregroundColor: UIColor.darkGray
        ]
        
        let attributedSubtitle = NSAttributedString(string: "Photo Collection", attributes: subtitleAttributes)
        
        let subtitleStringSize = attributedSubtitle.size()
        let subtitleStringRect = CGRect(
            x: (pageRect.width - subtitleStringSize.width) / 2.0,
            y: titleStringRect.maxY + 20,
            width: subtitleStringSize.width,
            height: subtitleStringSize.height
        )
        attributedSubtitle.draw(in: subtitleStringRect)
        
        // Draw date
        let dateAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 14, weight: .light),
            .foregroundColor: UIColor.darkGray
        ]
        
        let attributedDate = NSAttributedString(string: "Generated on \(dateString)", attributes: dateAttributes)
        
        let dateStringSize = attributedDate.size()
        let dateStringRect = CGRect(
            x: (pageRect.width - dateStringSize.width) / 2.0,
            y: pageRect.height - 100,
            width: dateStringSize.width,
            height: dateStringSize.height
        )
        attributedDate.draw(in: dateStringRect)
    }
    
    private static func addPhotoPage(for entry: PhotoEntry, to context: UIGraphicsPDFRendererContext, in pageRect: CGRect) {
        // Get image from file
        let photoPath = FileManager.documentsDirectory.appendingPathComponent(entry.imageFilename)
        guard let image = UIImage(contentsOfFile: photoPath.path) else {
            return
        }
        
        // Calculate image size to fit the page with margins
        let maxWidth = pageRect.width - 100  // 50pt margins on each side
        let maxHeight = pageRect.height - 200  // More space for caption and margins
        
        let originalSize = image.size
        var drawSize = originalSize
        
        // Scale down if the image is too large
        if originalSize.width > maxWidth || originalSize.height > maxHeight {
            let widthRatio = maxWidth / originalSize.width
            let heightRatio = maxHeight / originalSize.height
            let scaleFactor = min(widthRatio, heightRatio)
            
            drawSize = CGSize(
                width: originalSize.width * scaleFactor,
                height: originalSize.height * scaleFactor
            )
        }
        
        // Center the image on the page
        let imageRect = CGRect(
            x: (pageRect.width - drawSize.width) / 2.0,
            y: 100,  // Start 100pt from the top
            width: drawSize.width,
            height: drawSize.height
        )
        
        // Draw the image
        image.draw(in: imageRect)
        
        // Draw the caption below the image
        let captionFont = UIFont.systemFont(ofSize: 14, weight: .regular)
        let captionAttributes: [NSAttributedString.Key: Any] = [
            .font: captionFont,
            .foregroundColor: UIColor.black
        ]
        
        let attributedCaption = NSAttributedString(string: entry.caption, attributes: captionAttributes)
        
        let captionSize = attributedCaption.size()
        let captionRect = CGRect(
            x: (pageRect.width - captionSize.width) / 2.0,
            y: imageRect.maxY + 20,  // 20pt below the image
            width: captionSize.width,
            height: captionSize.height
        )
        
        attributedCaption.draw(in: captionRect)
        
        // Draw the date below the caption
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        let dateString = dateFormatter.string(from: entry.dateCreated)
        
        let dateAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 12, weight: .light),
            .foregroundColor: UIColor.darkGray
        ]
        
        let attributedDate = NSAttributedString(string: dateString, attributes: dateAttributes)
        
        let dateSize = attributedDate.size()
        let dateRect = CGRect(
            x: (pageRect.width - dateSize.width) / 2.0,
            y: captionRect.maxY + 10,  // 10pt below the caption
            width: dateSize.width,
            height: dateSize.height
        )
        
        attributedDate.draw(in: dateRect)
    }
}
