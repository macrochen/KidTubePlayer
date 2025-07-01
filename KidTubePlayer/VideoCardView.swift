import SwiftUI

struct VideoCardView: View {
    let video: Video
    var isSelected: Bool = false
    
    var body: some View {
        VStack(alignment: .leading) {
            ZStack(alignment: .topTrailing) {
                AsyncImage(url: video.thumbnailURL) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Rectangle()
                        .fill(.gray.opacity(0.3))
                        .overlay(
                            ProgressView()
                        )
                }
                .aspectRatio(16/9, contentMode: .fit)
                .cornerRadius(16)
                .shadow(radius: 8)
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.largeTitle)
                        .foregroundColor(.blue)
                        .padding(8)
                }
            }
            
            Text(video.title)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.primary)
                .padding(.top, 8)
            
            Spacer()
        }
        .padding()
    }
}

struct VideoCardView_Previews: PreviewProvider {
    static var previews: some View {
        VideoCardView(video: VideoProvider.allVideos.first!)
            .previewLayout(.fixed(width: 300, height: 300))
    }
}
