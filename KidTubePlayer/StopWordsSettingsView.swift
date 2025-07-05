import SwiftUI

struct StopWordsSettingsView: View {
    @State private var stopWords: [String] = UserSettings.stopWords
    @State private var newStopWord: String = ""
    
    var body: some View {
        VStack {
            List {
                Section(header: Text("Current Stop Words")) {
                    ForEach(stopWords, id: \.self) { word in
                        Text(word)
                    }
                    .onDelete(perform: deleteStopWord)
                }
                
                Section(header: Text("Add New Stop Word")) {
                    HStack {
                        TextField("New word", text: $newStopWord)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                        Button("Add") {
                            addStopWord()
                        }
                        .disabled(newStopWord.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                }
            }
            
            Button("Save Stop Words") {
                UserSettings.stopWords = stopWords
                // Optionally add a confirmation message or haptic feedback
            }
            .padding()
        }
        .navigationTitle("Stop Words Settings")
        .toolbar {
            EditButton()
        }
    }
    
    private func addStopWord() {
        let word = newStopWord.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if !word.isEmpty && !stopWords.contains(word) {
            stopWords.append(word)
            newStopWord = ""
            stopWords.sort()
        }
    }
    
    private func deleteStopWord(at offsets: IndexSet) {
        stopWords.remove(atOffsets: offsets)
    }
}

struct StopWordsSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            StopWordsSettingsView()
        }
    }
}
