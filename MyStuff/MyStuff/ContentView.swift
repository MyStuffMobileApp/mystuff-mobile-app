import SwiftUI

struct ContentView: View {
    @StateObject private var photoStore = PhotoStore()
    @State private var isShowingImagePicker = false
    @State private var inputImage: UIImage?
    @State private var isShowingCaptionDialog = false
    @State private var caption = ""
    @State private var isShowingShareSheet = false
    @State private var pdfURL: URL?
    @State private var indexSetToDelete: IndexSet?
    @State private var isShowingDeleteConfirmation = false
    
    var body: some View {
        NavigationView {
            List {
                ForEach(photoStore.photoEntries) { entry in
                    HStack {
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
                        
                        Text(entry.caption)
                            .padding(.leading, 8)
                    }
                    .padding(.vertical, 4)
                }
                .onDelete(perform: confirmDelete)
            }
            .navigationTitle("MyStuff")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack {
                        Button(action: {
                            isShowingImagePicker = true
                        }) {
                            Image(systemName: "plus")
                        }
                        
                        EditButton()
                        
                        Button(action: exportPhotos) {
                            Image(systemName: "square.and.arrow.up")
                        }
                        .disabled(photoStore.photoEntries.isEmpty)
                    }
                }
            }
            .sheet(isPresented: $isShowingImagePicker, onDismiss: loadImage) {
                ImagePicker(image: $inputImage)
            }
            .alert("Add Caption", isPresented: $isShowingCaptionDialog) {
                TextField("Caption", text: $caption)
                Button("Save") {
                    if let image = inputImage, let imageData = image.jpegData(compressionQuality: 0.8) {
                        photoStore.addPhoto(imageData: imageData, caption: caption)
                        caption = ""
                    }
                }
                Button("Cancel", role: .cancel) {
                    caption = ""
                }
            }
            .sheet(isPresented: $isShowingShareSheet) {
                if let pdfURL = pdfURL {
                    ShareSheet(items: [pdfURL])
                }
            }
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
        }
    }
    
    func loadImage() {
        if inputImage != nil {
            isShowingCaptionDialog = true
        }
    }
    
    func exportPhotos() {
        pdfURL = photoStore.exportToPDF()
        if pdfURL != nil {
            isShowingShareSheet = true
        }
    }
    
    func confirmDelete(at indexSet: IndexSet) {
        indexSetToDelete = indexSet
        isShowingDeleteConfirmation = true
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
