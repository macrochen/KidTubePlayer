import SwiftUI

struct VideoListView: View {
    @StateObject private var videoImporter = VideoImporter()
    @State private var isImporting = false
    @State private var editMode: EditMode = .inactive
    @State private var selectedVideoIds: Set<String> = []
    @State private var isShowingDeleteConfirmation = false

    private let columns = [
        GridItem(.flexible(), spacing: 20),
        GridItem(.flexible(), spacing: 20),
        GridItem(.flexible(), spacing: 20),
        GridItem(.flexible(), spacing: 20)
    ]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 30) {
                    HeaderView()
                    
                    if videoImporter.videos.isEmpty {
                        EmptyStateView()
                    } else {
                        VideoGridView(
                            videoImporter: videoImporter,
                            selectedVideoIds: $selectedVideoIds,
                            editMode: $editMode
                        )
                    }
                }
                .padding(40)
            }
            .navigationDestination(for: Video.self) { video in
                PlayerView(video: video)
            }
            .background(Color(white: 0.97))
            .ignoresSafeArea()
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    EditButton()
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    if editMode.isEditing {
                        Button("Delete") {
                            isShowingDeleteConfirmation = true
                        }
                        .disabled(selectedVideoIds.isEmpty)
                    } else {
                        Button("Import") {
                            isImporting = true
                        }
                    }
                }
            }
            .sheet(isPresented: $isImporting) {
                DocumentPicker { url in
                    videoImporter.importVideos(from: url)
                }
            }
            .alert(isPresented: $isShowingDeleteConfirmation) {
                Alert(
                    title: Text("Delete Videos"),
                    message: Text("Are you sure you want to delete the selected videos?"),
                    primaryButton: .destructive(Text("Delete")) {
                        deleteSelectedVideos()
                    },
                    secondaryButton: .cancel()
                )
            }
            .environment(\.editMode, $editMode)
        }
    }

    private func toggleSelection(for video: Video) {
        if selectedVideoIds.contains(video.id) {
            selectedVideoIds.remove(video.id)
        } else {
            selectedVideoIds.insert(video.id)
        }
    }

    private func deleteSelectedVideos() {
        videoImporter.deleteVideos(with: selectedVideoIds)
        selectedVideoIds.removeAll()
        editMode = .inactive
    }
}

struct EmptyStateView: View {
    var body: some View {
        VStack {
            Spacer()
            Image(systemName: "film.stack")
                .font(.system(size: 80))
                .foregroundColor(.gray.opacity(0.5))
            Text("No Videos")
                .font(.title)
                .fontWeight(.bold)
                .padding(.top)
            Text("Tap 'Import' to add your first video list.")
                .font(.headline)
                .foregroundColor(.secondary)
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 100)
    }
}

struct VideoGridView: View {
    @ObservedObject var videoImporter: VideoImporter
    @Binding var selectedVideoIds: Set<String>
    @Binding var editMode: EditMode

    private let columns = [
        GridItem(.flexible(), spacing: 20),
        GridItem(.flexible(), spacing: 20),
        GridItem(.flexible(), spacing: 20),
        GridItem(.flexible(), spacing: 20)
    ]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 40) {
            ForEach(videoImporter.videos) { video in
                if editMode.isEditing {
                    VideoCardView(video: video, isSelected: selectedVideoIds.contains(video.id))
                        .onTapGesture {
                            toggleSelection(for: video)
                        }
                } else {
                    NavigationLink(value: video) {
                        VideoCardView(video: video)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
    }

    private func toggleSelection(for video: Video) {
        if selectedVideoIds.contains(video.id) {
            selectedVideoIds.remove(video.id)
        } else {
            selectedVideoIds.insert(video.id)
        }
    }
}

struct HeaderView: View {
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text("Welcome to KidTube!")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                Text("Your favorite Minecraft videos for learning English.")
                    .font(.title2)
                    .foregroundColor(.secondary)
            }
            Spacer()
        }
    }
}

struct FooterView: View {
    var body: some View {
        Text("Powered by YouTube")
            .font(.caption)
            .foregroundColor(.gray)
    }
}

struct VideoListView_Previews: PreviewProvider {
    static var previews: some View {
        VideoListView()
            .previewDevice("iPad Pro (11-inch) (4th generation)")
            .previewInterfaceOrientation(.landscapeLeft)
    }
}