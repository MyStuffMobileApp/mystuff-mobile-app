import SwiftUI

struct PhotoDetailView: View {
    @ObservedObject var photoStore: PhotoStore
    let entry: PhotoEntry
    let entryIndex: Int
    
    @State private var isShowingChatGPTInstructions = false
    @State private var newCaption: String = ""
    @State private var isEditingCaption = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Display image
                photoImageView
                
                // Caption section
                captionView
                
                // Analyze with ChatGPT button
                Button(action: analyzeWithChatGPT) {
                    HStack {
                        Image(systemName: "sparkles.rectangle.stack")
                        Text("Identify Objects with ChatGPT")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .foregroundColor(.primary)
                    .cornerRadius(8)
                }
                
                // Date section
                dateView
                
                Spacer()
            }
            .padding()
        }
        .navigationTitle("Photo Details")
        .alert("Use ChatGPT to Identify Objects", isPresented: $isShowingChatGPTInstructions) {
            Button("Continue") {
                openChatGPT()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("The photo will be saved to your camera roll. ChatGPT will open with a prompt copied to your clipboard. Upload the photo to ChatGPT, paste the prompt, and get object identification.")
        }
        .alert("Update Caption", isPresented: $isEditingCaption) {
            TextField("Caption", text: $newCaption)
            
            Button("Save") {
                updateCaption()
            }
            
            Button("Cancel", role: .cancel) { }
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
                
                Button(action: {
                    newCaption = entry.caption
                    isEditingCaption = true
                }) {
                    Image(systemName: "pencil")
                        .font(.subheadline)
                }
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
    
    func analyzeWithChatGPT() {
        // First show instructions
        isShowingChatGPTInstructions = true
    }
    
    func openChatGPT() {
        // Save image to Photos album
        if let image = entry.thumbnailImage {
            UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
            
            // Create prompt for ChatGPT and copy to clipboard
            let prompt = "What objects can you see in the most recent photo I've uploaded? Please list the main objects you can identify and suggest a brief caption that describes what's in the image."
            UIPasteboard.general.string = prompt
            
            // Open ChatGPT app or website
            if let chatGPTAppURL = URL(string: "chatgpt://") {
                if UIApplication.shared.canOpenURL(chatGPTAppURL) {
                    UIApplication.shared.open(chatGPTAppURL)
                } else {
                    // Fallback to the website if the app is not installed
                    if let chatGPTWebURL = URL(string: "https://chat.openai.com") {
                        UIApplication.shared.open(chatGPTWebURL)
                    }
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
    
    // Helper to format date
    func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
