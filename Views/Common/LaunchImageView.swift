import SwiftUI

// MARK: - LaunchImageViewStyle
enum LaunchImageViewStyle {
    case launchCard
    case detailView
    case rocketCard
    case mediaThumbnail
    case custom(height: CGFloat, width: CGFloat?)
}

// MARK: - LaunchImageView Component
struct LaunchImageView: View {
    let launchId: String
    let url: URL?
    var style: LaunchImageViewStyle = .launchCard
    var fallbackMessage: String = "Image Unavailable"
    var contentMode: ContentMode = .fill
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottom) {
                // Image or placeholder
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        loadingView
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: contentMode)
                            .transition(.opacity)
                    case .failure:
                        fallbackView
                    @unknown default:
                        fallbackView
                    }
                }
                .frame(width: geometry.size.width, height: geometry.size.height)
                .clipped()
                
                // Use the existing gradient from Styles
                Styles.imageOverlayGradient
                    .frame(height: overlayHeightForStyle)
                    .allowsHitTesting(false)
            }
        }
        .frame(width: widthForStyle, height: heightForStyle)
        .grokImage(cornerRadius: cornerRadiusForStyle) // Use the new modifier
    }
    
    // MARK: - Loading View
    private var loadingView: some View {
        ZStack {
            Color.gray.opacity(0.1)
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: Styles.textSecondary))
        }
    }
    
    // MARK: - Fallback Image View
    private var fallbackView: some View {
        ZStack {
            RoundedRectangle(cornerRadius: cornerRadiusForStyle)
                .fill(Color.gray.opacity(0.1))
            VStack(spacing: Styles.paddingSmall) {
                Image(systemName: "photo.on.rectangle.angled")
                    .font(.largeTitle)
                    .foregroundColor(Styles.textTertiary)
                Text(fallbackMessage)
                    .font(.caption)
                    .foregroundColor(Styles.textTertiary)
            }
            .padding()
        }
    }
    
    // MARK: - Style Definitions
    private var heightForStyle: CGFloat {
        switch style {
        case .launchCard: return Styles.launchCardImageHeight
        case .detailView: return Styles.detailImageHeight
        case .rocketCard: return Styles.rocketCardHeight
        case .mediaThumbnail: return 120
        case .custom(let height, _): return height
        }
    }
    
    private var overlayHeightForStyle: CGFloat {
        switch style {
        case .launchCard: return heightForStyle * 0.5  // 50% of image height
        case .detailView: return heightForStyle * 0.4  // 40% of image height
        case .rocketCard: return heightForStyle * 0.6  // 60% of image height for better readability
        case .mediaThumbnail: return heightForStyle * 0.4  // 40% of image height
        case .custom: return 80  // Fixed size for custom images
        }
    }
    
    private var widthForStyle: CGFloat? {
        switch style {
        case .rocketCard: return Styles.rocketCardWidth
        case .mediaThumbnail: return 120
        case .custom(_, let width): return width
        default: return nil
        }
    }
    
    private var cornerRadiusForStyle: CGFloat {
        switch style {
        case .launchCard: return Styles.cornerRadiusMedium
        case .detailView: return Styles.cornerRadiusLarge
        case .rocketCard: return Styles.cornerRadiusMedium
        case .mediaThumbnail: return Styles.cornerRadiusSmall
        default: return Styles.cornerRadiusMedium
        }
    }
    
    // MARK: - Shadow & Overlay Styles
    private var shadowColor: Color {
        Styles.cardShadow
    }
    
    private var shadowRadius: CGFloat {
        switch style {
        case .detailView: return Styles.shadowRadiusMedium
        default: return Styles.shadowRadiusSmall
        }
    }
    
    private var shadowOffset: CGFloat {
        Styles.shadowOffset.height
    }
}

#Preview {
    VStack(spacing: 20) {
        LaunchImageView(
            launchId: "123",
            url: URL(string: "https://example.com/image.jpg"),
            style: .launchCard
        )
        
        LaunchImageView(
            launchId: "456",
            url: URL(string: "https://example.com/image2.jpg"),
            style: .detailView
        )
        
        LaunchImageView(
            launchId: "789",
            url: URL(string: "https://example.com/image3.jpg"),
            style: .rocketCard
        )
    }
    .padding()
    .background(Color.black)
}
