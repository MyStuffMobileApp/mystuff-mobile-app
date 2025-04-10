import SwiftUI

struct ContentView: View {
    @StateObject private var photoStore = PhotoStore()
    @EnvironmentObject var appSettings: AppSettings
    
    // State for image selection
    @State private var inputImage: UIImage?
    @State private var sourceType: UIImagePickerController.SourceType = .camera
    
    // Sheet control states
    @State private var isShowingImagePicker = false
    @State private var isShowingSourcePicker = false
    @State private var isShowingCaptionDialog = false
    @State private var isShowingShareSheet = false
    @State private var isShowingDeleteConfirmation = false
    @State private var isShowingAPIKeySettings = false
    
    // Other state
    @State private var caption = ""
    @State private var pdfURL: URL?
    @State private var indexSetToDelete: IndexSet?
    
    var body: some View {
        NavigationView {
            List {
                ForEach(Array(photoStore.photoEntries.enumerated()), id: \.element.id) { index, entry in
                    NavigationLink(destination: PhotoDetailView(photoStore: photoStore, entry: entry, entryIndex: index)) {
                        photoRowView(for: entry)
                    }
                }
                .onDelete(perform: confirmDelete)
            }
            .toolbar {
                ToolbarItem(placement: .principal) {
                    HStack {
                        AppIconImage(size: 30)
                        Text("MyStuff")
                            .font(.headline)
                            .fontWeight(.bold)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack {
                        Button(action: showSourcePicker) {
                            Image(systemName: "plus")
                        }
                        
                        EditButton()
                        
                        Button(action: exportPhotos) {
                            Image(systemName: "square.and.arrow.up")
                        }
                        .disabled(photoStore.photoEntries.isEmpty)
                        
                        Button(action: { isShowingAPIKeySettings = true }) {
                            Image(systemName: "key")
                        }
                    }
                }
            }
            .sheet(isPresented: $isShowingAPIKeySettings) {
                APIKeySettingsView(appSettings: appSettings)
            }
            // Actions sheet to choose source
            .actionSheet(isPresented: $isShowingSourcePicker) {
                ActionSheet(
                    title: Text("Add Photo"),
                    message: Text("Choose a source"),
                    buttons: [
                        .default(Text("Take Photo")) {
                            if UIImagePickerController.isSourceTypeAvailable(.camera) {
                                sourceType = .camera
                                isShowingImagePicker = true
                            }
                        },
                        .default(Text("Choose from Library")) {
                            sourceType = .photoLibrary
                            isShowingImagePicker = true
                        },
                        .cancel()
                    ]
                )
            }
            // Image picker sheet
            .sheet(isPresented: $isShowingImagePicker, onDismiss: handleSelectedImage) {
                ImagePicker(image: $inputImage, sourceType: sourceType)
            }
            // Share sheet
            .sheet(isPresented: $isShowingShareSheet) {
                if let pdfURL = pdfURL {
                    ShareSheet(items: [pdfURL])
                }
            }
            // Delete confirmation alert
            .alert("Delete Photo", isPresented: $isShowingDeleteConfirmation) {
                Button("Cancel", role: .cancel) {
                    indexSetToDelete = nil
                }
                Button("Delete", role: .destructive) {
                    if let indexSet = indexSetToDelete {
                        photoStore.deletePhoto(at: indexSet)
                        indexSetToDelete = nil
                    }
                }
            } message: {
                Text("Are you sure you want to delete this photo? This action cannot be undone.")
            }
            // Caption dialog
            .alert("Add Caption", isPresented: $isShowingCaptionDialog) {
                TextField("Caption", text: $caption)
                Button("Save") {
                    saveNewPhoto()
                }
                Button("Cancel", role: .cancel) {
                    caption = ""
                    inputImage = nil
                }
            }
        }
    }
    
    // MARK: - Row View
    
    private func photoRowView(for entry: PhotoEntry) -> some View {
        HStack {
            // Thumbnail image
            Group {
                if let thumbnail = entry.thumbnailImage {
                    Image(uiImage: thumbnail)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 60, height: 60)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                } else {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gray)
                        .frame(width: 60, height: 60)
                }
            }
            
            // Caption
            Text(entry.caption)
                .lineLimit(2)
                .padding(.leading, 8)
        }
        .padding(.vertical, 4)
    }
    
    // MARK: - Helper Methods
    
    private func showSourcePicker() {
        isShowingSourcePicker = true
    }
    
    private func handleSelectedImage() {
        if inputImage != nil {
            isShowingCaptionDialog = true
        }
    }
    
    private func saveNewPhoto() {
        if let image = inputImage, let imageData = image.jpegData(compressionQuality: 0.8) {
            photoStore.addPhoto(imageData: imageData, caption: caption)
            caption = ""
            inputImage = nil
        }
    }
    
    private func exportPhotos() {
        pdfURL = photoStore.exportToPDF()
        if pdfURL != nil {
            isShowingShareSheet = true
        }
    }
    
    private func confirmDelete(at indexSet: IndexSet) {
        indexSetToDelete = indexSet
        isShowingDeleteConfirmation = true
    }
}
