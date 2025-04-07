import SwiftUI

struct PhotoDetailView: View {
    @ObservedObject var photoStore: PhotoStore
    @StateObject private var itemPriceStore: ItemPriceStore
    @EnvironmentObject var appSettings: AppSettings
    let entry: PhotoEntry
    let entryIndex: Int
    
    @State private var newCaption: String = ""
    @State private var isEditingCaption = false
    @State private var isAnalyzing = false
    @State private var analysisResult: String = ""
    @State private var showAnalysisResult = false
    @State private var analysisError: String? = nil
    @State private var isShowingAPIKeySettings = false
    @State private var isShowingItemPriceList = false
    
    // Initialize with potential existing item list
    init(photoStore: PhotoStore, entry: PhotoEntry, entryIndex: Int) {
        self.photoStore = photoStore
        self.entry = entry
        self.entryIndex = entryIndex
        
        // Create ItemPriceStore with existing items if available
        let existingItems = entry.loadItemList()
        let store = ItemPriceStore()
        store.items = existingItems
        
        // Use StateObject to manage the store
        _itemPriceStore = StateObject(wrappedValue: store)
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Display image
                photoImageView
                
                // Caption section
                captionView
                
                // Analyze with OpenAI API button
                Button(action: analyzeWithOpenAI) {
                    HStack {
                        if isAnalyzing {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                                .frame(width: 16, height: 16)
                        } else {
                            Image(systemName: "wand.and.stars")
                        }
                        Text("Analyze Image")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green.opacity(0.1))
                    .foregroundColor(.primary)
                    .cornerRadius(8)
                }
                .disabled(isAnalyzing)
                
                // Analysis results section (only shown when there are results)
                if !analysisResult.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Objects Identified")
                            .font(.headline)
                        
                        Text(analysisResult)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.green.opacity(0.1))
                            .cornerRadius(8)
                        
                        HStack {
                            Button("Use as Caption") {
                                newCaption = analysisResult
                                isEditingCaption = true
                            }
                            
                            Button(entry.hasItemList ? "View Item List" : "Create Item List") {
                                if entry.hasItemList {
                                    // Restore existing item list
                                    itemPriceStore.items = entry.loadItemList()
                                } else {
                                    // Create new item list
                                    createItemListFromAnalysis()
                                }
                                isShowingItemPriceList = true
                            }
                            .background(
                                NavigationLink(
                                    destination: ItemPriceListView(
                                        itemStore: itemPriceStore,
                                        saveHandler: { saveItemListToPhoto() }
                                    ),
                                    isActive: $isShowingItemPriceList
                                ) {
                                    EmptyView()
                                }
                            )
                        }
                        .padding(.top, 4)
                        .disabled(analysisResult.isEmpty)
                    }
                }
                
                // If there's an existing item list, show a "View Item List" button
                if entry.hasItemList {
                    Button(action: {
                        itemPriceStore.items = entry.loadItemList()
                        isShowingItemPriceList = true
                    }) {
                        HStack {
                            Image(systemName: "list.bullet")
                            Text("View Saved Item List")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue.opacity(0.1))
                        .foregroundColor(.blue)
                        .cornerRadius(8)
                    }
                }
                
                // Date section
                dateView
                
                Spacer()
            }
            .padding()
        }
        .navigationTitle("Photo Details")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack {
                    Button(action: {
                        isEditingCaption = true
                        newCaption = entry.caption
                    }) {
                        Image(systemName: "pencil")
                    }
                    
                    Button(action: {
                        isShowingAPIKeySettings = true
                    }) {
                        Image(systemName: "key")
                    }
                }
            }
        }
        .sheet(isPresented: $isShowingAPIKeySettings) {
            APIKeySettingsView(appSettings: appSettings)
        }
        .alert("Update Caption", isPresented: $isEditingCaption) {
            TextField("Caption", text: $newCaption)
            
            Button("Save") {
                updateCaption()
            }
            
            Button("Cancel", role: .cancel) { }
        }
        .alert(isPresented: Binding<Bool>(
            get: { analysisError != nil },
            set: { if !$0 { analysisError = nil } }
        )) {
            Alert(
                title: Text("Analysis Error"),
                message: Text(analysisError ?? "Unknown error occurred"),
                dismissButton: .default(Text("OK")) {
                    analysisError = nil
                }
            )
        }
    }
    
    // MARK: - Subviews
    
    private var photoImageView: some View {
        Group {
            if let image = entry.thumbnailImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity)
                    .cornerRadius(12)
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 300)
                    .cornerRadius(12)
                    .overlay(
                        Text("Image unavailable")
                            .foregroundColor(.secondary)
                    )
            }
        }
    }
    
    private var captionView: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Caption")
                    .font(.headline)
                
                Spacer()
            }
            
            Text(entry.caption)
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
        }
    }
    
    private var dateView: some View {
        HStack {
            Text("Date:")
                .font(.subheadline)
                .bold()
            
            Text(formattedDate(entry.dateCreated))
                .font(.subheadline)
        }
    }
    
    // MARK: - Helper Methods
    
    func analyzeWithOpenAI() {
        guard let image = entry.thumbnailImage else {
            analysisError = "Could not load image"
            return
        }
        
        guard appSettings.isAPIKeyConfigured, let openAIService = appSettings.getOpenAIService() else {
            isShowingAPIKeySettings = true
            return
        }
        
        // Start analysis
        isAnalyzing = true
        analysisResult = ""
        
        openAIService.analyzeImage(image) { result in
            DispatchQueue.main.async {
                isAnalyzing = false
                
                switch result {
                case .success(let content):
                    analysisResult = content
                case .failure(let error):
                    analysisError = "Error analyzing image: \(error.localizedDescription)"
                }
            }
        }
    }
    
    func updateCaption() {
        var updatedEntry = entry
        updatedEntry.caption = newCaption
        
        photoStore.photoEntries[entryIndex] = updatedEntry
        photoStore.saveData()
    }
    
    // New method to save item list to photo
    private func saveItemListToPhoto() {
        // Create a copy of the entry to modify
        var updatedEntry = entry
        
        // Save the current item list to the photo entry
        updatedEntry.saveItemList(itemPriceStore)
        
        // Update the photo store
        photoStore.photoEntries[entryIndex] = updatedEntry
        photoStore.saveData()
    }
    
    // New method to create item list from OpenAI analysis
    private func createItemListFromAnalysis() {
        // Clear existing items
        itemPriceStore.deleteAll()
        
        // Split the analysis result into individual items
        let items = analysisResult
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        
        // Add each item to the store
        for item in items {
            itemPriceStore.addItem(item)
        }
    }
    
    // Helper to format date
    func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
