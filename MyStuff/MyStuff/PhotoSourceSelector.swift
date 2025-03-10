//
//  PhotoSourceSelector.swift
//  MyStuff
//
//  Created by Laura on 3/6/25.
//


import SwiftUI

struct PhotoSourceSelector: View {
    @Binding var isShowingImagePicker: Bool
    @Binding var sourceType: UIImagePickerController.SourceType
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    Button(action: {
                        // Set camera source type first
                        sourceType = .camera
                        // Dismiss this sheet
                        presentationMode.wrappedValue.dismiss()
                        // Small delay before showing image picker to ensure state updates properly
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            isShowingImagePicker = true
                        }
                    }) {
                        HStack {
                            Image(systemName: "camera")
                                .frame(width: 30, height: 30)
                                .foregroundColor(.blue)
                            Text("Take Photo")
                        }
                    }
                    .disabled(!UIImagePickerController.isSourceTypeAvailable(.camera))
                    
                    Button(action: {
                        // Set photo library source type first
                        sourceType = .photoLibrary
                        // Dismiss this sheet
                        presentationMode.wrappedValue.dismiss()
                        // Small delay before showing image picker to ensure state updates properly
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            isShowingImagePicker = true
                        }
                    }) {
                        HStack {
                            Image(systemName: "photo.on.rectangle")
                                .frame(width: 30, height: 30)
                                .foregroundColor(.blue)
                            Text("Choose from Library")
                        }
                    }
                }
                
                Section {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Text("Cancel")
                            .foregroundColor(.red)
                    }
                }
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle("Add Photo")
        }
    }
}
