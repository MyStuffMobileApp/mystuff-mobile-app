import SwiftUI

struct ItemPriceListView: View {
    @ObservedObject var itemStore: ItemPriceStore
    @State private var newItemName = ""
    @State private var isAddingNewItem = false
    @State private var editingItem: ItemPrice?
    @State private var tempPrice: String = ""
    @State private var pdfURL: URL?
    @State private var isShareSheetPresented = false
    let saveHandler: (() -> Void)?
    @Environment(\.presentationMode) var presentationMode
    
    // Update initializer to include optional save handler
    init(itemStore: ItemPriceStore, saveHandler: (() -> Void)? = nil) {
        self.itemStore = itemStore
        self.saveHandler = saveHandler
    }
    
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
            
            // Action buttons
            HStack {
                Button(action: exportToPDF) {
                    HStack {
                        Image(systemName: "doc.text")
                        Text("Export to PDF")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .foregroundColor(.blue)
                    .cornerRadius(8)
                }
                .disabled(itemStore.items.isEmpty)
                
                Button(action: saveList) {
                    HStack {
                        Image(systemName: "square.and.arrow.down")
                        Text("Save")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green.opacity(0.1))
                    .foregroundColor(.green)
                    .cornerRadius(8)
                }
                .disabled(itemStore.items.isEmpty)
            }
            .padding()
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
        .sheet(isPresented: $isShareSheetPresented) {
            if let pdfURL = pdfURL {
                ShareSheet(items: [pdfURL])
            }
        }
    }
    
    private func deleteItems(at offsets: IndexSet) {
        itemStore.deleteItem(at: offsets)
    }
    
    private func saveList() {
        // Call the save handler if provided
        saveHandler?()
        
        // Provide user feedback
        let alert = UIAlertController(
            title: "Saved",
            message: "Item list has been saved",
            preferredStyle: .alert
        )
        UIApplication.shared.windows.first?.rootViewController?.present(
            alert,
            animated: true
        ) {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                alert.dismiss(animated: true, completion: nil)
            }
        }
    }
    
    private func exportToPDF() {
        // Create PDF with items and their prices
        let pdfData = createItemListPDF()
        
        // Create a temporary file URL
        let temporaryDirectoryURL = FileManager.default.temporaryDirectory
        let temporaryFileURL = temporaryDirectoryURL.appendingPathComponent("ItemPriceList_\(Date().timeIntervalSince1970).pdf")
        
        // Write the PDF data to the file
        do {
            try pdfData.write(to: temporaryFileURL)
            pdfURL = temporaryFileURL
            isShareSheetPresented = true
        } catch {
            print("Error saving PDF: \(error)")
            
            // Show error alert
            let alert = UIAlertController(
                title: "Export Failed",
                message: "Could not export the item list to PDF",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            UIApplication.shared.windows.first?.rootViewController?.present(alert, animated: true)
        }
    }
    
    private func createItemListPDF() -> Data {
        let pdfMetaData = [
            kCGPDFContextCreator: "MyStuff App",
            kCGPDFContextAuthor: "MyStuff User",
            kCGPDFContextTitle: "Item Price List"
        ]
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMetaData as [String: Any]
        
        // Use A4 page size
        let pageWidth = 8.27 * 72.0
        let pageHeight = 11.69 * 72.0
        let pageRect = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)
        
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)
        
        let data = renderer.pdfData { (context) in
            context.beginPage()
            
            // Page title
            let titleFont = UIFont.systemFont(ofSize: 24, weight: .bold)
            let titleAttributes: [NSAttributedString.Key: Any] = [
                .font: titleFont,
                .foregroundColor: UIColor.black
            ]
            let attributedTitle = NSAttributedString(string: "Item Price List", attributes: titleAttributes)
            let titleSize = attributedTitle.size()
            let titleRect = CGRect(
                x: (pageRect.width - titleSize.width) / 2.0,
                y: 50,
                width: titleSize.width,
                height: titleSize.height
            )
            attributedTitle.draw(in: titleRect)
            
            // Date
            let dateFont = UIFont.systemFont(ofSize: 12, weight: .regular)
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .medium
            dateFormatter.timeStyle = .short
            let dateString = dateFormatter.string(from: Date())
            
            let dateAttributes: [NSAttributedString.Key: Any] = [
                .font: dateFont,
                .foregroundColor: UIColor.darkGray
            ]
            let attributedDate = NSAttributedString(string: "Generated on \(dateString)", attributes: dateAttributes)
            let dateSize = attributedDate.size()
            let dateRect = CGRect(
                x: (pageRect.width - dateSize.width) / 2.0,
                y: titleRect.maxY + 10,
                width: dateSize.width,
                height: dateSize.height
            )
            attributedDate.draw(in: dateRect)
            
            // Table headers
            let headerFont = UIFont.boldSystemFont(ofSize: 14)
            let cellFont = UIFont.systemFont(ofSize: 12)
            
            let itemHeaderRect = CGRect(x: 50, y: dateRect.maxY + 30, width: 300, height: 20)
            let priceHeaderRect = CGRect(x: pageRect.width - 200, y: dateRect.maxY + 30, width: 150, height: 20)
            
            let itemHeaderString = NSAttributedString(
                string: "Item",
                attributes: [
                    .font: headerFont,
                    .foregroundColor: UIColor.black
                ]
            )
            let priceHeaderString = NSAttributedString(
                string: "Price ($)",
                attributes: [
                    .font: headerFont,
                    .foregroundColor: UIColor.black
                ]
            )
            
            itemHeaderString.draw(in: itemHeaderRect)
            priceHeaderString.draw(in: priceHeaderRect)
            
            // Items
            var yOffset = itemHeaderRect.maxY + 10
            var total: Double = 0
            
            for (index, item) in itemStore.items.enumerated() {
                let itemRect = CGRect(x: 50, y: yOffset, width: 300, height: 20)
                let priceRect = CGRect(x: pageRect.width - 200, y: yOffset, width: 150, height: 20)
                
                let itemString = NSAttributedString(
                    string: "\(index + 1). \(item.name)",
                    attributes: [
                        .font: cellFont,
                        .foregroundColor: UIColor.black
                    ]
                )
                let priceString = NSAttributedString(
                    string: String(format: "%.2f", item.price),
                    attributes: [
                        .font: cellFont,
                        .foregroundColor: UIColor.black
                    ]
                )
                
                itemString.draw(in: itemRect)
                priceString.draw(in: priceRect)
                
                total += item.price
                yOffset += 25
            }
            
            // Total
            let totalLabelRect = CGRect(x: 50, y: yOffset + 20, width: 300, height: 20)
            let totalValueRect = CGRect(x: pageRect.width - 200, y: yOffset + 20, width: 150, height: 20)
            
            let totalLabelString = NSAttributedString(
                string: "Total:",
                attributes: [
                    .font: headerFont,
                    .foregroundColor: UIColor.black
                ]
            )
            let totalValueString = NSAttributedString(
                string: String(format: "%.2f", total),
                attributes: [
                    .font: headerFont,
                    .foregroundColor: UIColor.black
                ]
            )
            
            totalLabelString.draw(in: totalLabelRect)
            totalValueString.draw(in: totalValueRect)
        }
        
        return data
    }
}

struct ItemPriceListView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            ItemPriceListView(itemStore: ItemPriceStore())
        }
    }
}
