import SwiftUI

struct APISettingsView: View {
    @State private var youtubeAPIKey: String = UserSettings.youtubeAPIKey ?? ""
    @State private var geminiAPIKey: String = UserSettings.geminiAPIKey ?? ""
    
    var body: some View {
        Form {
            Section(header: Text("YouTube Data API Key")) {
                TextField("Enter YouTube API Key", text: $youtubeAPIKey)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
            }
            
            Section(header: Text("Gemini API Key")) {
                TextField("Enter Gemini API Key", text: $geminiAPIKey)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
            }
            
            Button("Save API Keys") {
                UserSettings.youtubeAPIKey = youtubeAPIKey
                UserSettings.geminiAPIKey = geminiAPIKey
                // Optionally add a confirmation message or haptic feedback
            }
        }
        .navigationTitle("API Settings")
    }
}

struct APISettingsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            APISettingsView()
        }
    }
}
