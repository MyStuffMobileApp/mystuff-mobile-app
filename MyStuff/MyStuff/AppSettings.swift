import Foundation
import SwiftUI

class AppSettings: ObservableObject {
    @Published var openAIApiKey: String {
        didSet {
            UserDefaults.standard.set(openAIApiKey, forKey: "openAIApiKey")
        }
    }
    
    init() {
        self.openAIApiKey = UserDefaults.standard.string(forKey: "openAIApiKey") ?? ""
    }
    
    var isAPIKeyConfigured: Bool {
        return !openAIApiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    func getOpenAIService() -> OpenAIService? {
        guard isAPIKeyConfigured else { return nil }
        return OpenAIService(apiKey: openAIApiKey)
    }
}

struct APIKeySettingsView: View {
    @ObservedObject var appSettings: AppSettings
    @Environment(\.presentationMode) var presentationMode
    @State private var tempApiKey: String = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("OpenAI API Configuration")) {
                    SecureField("API Key", text: $tempApiKey)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .onAppear {
                            tempApiKey = appSettings.openAIApiKey
                        }
                    
                    Button("Save API Key") {
                        appSettings.openAIApiKey = tempApiKey
                        presentationMode.wrappedValue.dismiss()
                    }
                    .disabled(tempApiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                
                Section(header: Text("Information")) {
                    Text("You need an OpenAI API key to use the image analysis feature. Get one from openai.com.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("API Settings")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
}
