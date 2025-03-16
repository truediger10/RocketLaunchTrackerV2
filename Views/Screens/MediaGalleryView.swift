import SwiftUI
import Foundation

// MARK: - MediaGalleryView
struct MediaGalleryView: View {
    let launches: [Launch]
    
    // MARK: - Grouping and Filtering Launches by Rocket
    /// Group launches by rocket name, select a valid image for each rocket type.
    /// Only include entries that have an image, then sort them by rocket name.
    private var rocketTypes: [RocketType] {
        let groupedLaunches = Dictionary(grouping: launches) { $0.rocketName }
        
        return groupedLaunches.compactMap { rocketName, launchesForRocket in
            guard let rocketImage = launchesForRocket.first(where: { $0.image != nil })?.image else { return nil }
            return RocketType(rocket: rocketName, image: rocketImage, launches: launchesForRocket)
        }
        .sorted { $0.rocket < $1.rocket }
    }
    
    // MARK: - Preview Subset
    /// A small subset of rocket types for the initial horizontal preview.
    var previewRocketTypes: [RocketType] {
        Array(rocketTypes.prefix(6))
    }
    
    var title: String = "ROCKET VEHICLES"
    @State private var showFullGallery = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: Styles.paddingMedium) {
            // MARK: - Header
            HStack {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Styles.textSecondary)
                    .tracking(1.2)
                
                Spacer()
                
                // If there are more rockets than shown in the preview, enable a 'See All' button
                if rocketTypes.count > previewRocketTypes.count {
                    Button(action: {
                        showFullGallery = true
                    }) {
                        HStack(spacing: 4) {
                            Text("See All")
                                .font(Font.system(size: 14, weight: .medium))
                                .foregroundColor(Styles.primaryAccent)
                            Image(systemName: "chevron.right")
                                .font(.system(size: 12))
                                .foregroundColor(Styles.primaryAccent)
                        }
                    }
                    .buttonStyle(ScaleButtonStyle())
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: showFullGallery)
                }
            }
            
            // MARK: - Preview Gallery
            if previewRocketTypes.isEmpty {
                Text("No images available")
                    .font(.system(size: 14))
                    .foregroundColor(Styles.textTertiary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 20)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: Styles.paddingMedium) {
                        ForEach(previewRocketTypes, id: \.rocket) { rocketInfo in
                            NavigationLink(
                                destination: RocketDetailView(
                                    rocketName: rocketInfo.rocket,
                                    rocketImage: rocketInfo.image,
                                    associatedLaunches: rocketInfo.launches,
                                    allLaunches: launches,
                                    viewModel: LaunchViewModel()
                                )
                            ) {
                                RocketTypeCard(
                                    rocketName: rocketInfo.rocket,
                                    imageUrl: rocketInfo.image,
                                    launchCount: rocketInfo.launches.count
                                )
                            }
                            .buttonStyle(ScaleButtonStyle())
                        }
                    }
                    .padding(.bottom, Styles.paddingSmall)
                    .padding(.horizontal, Styles.paddingStandard)
                }
                .frame(height: Styles.rocketCardHeight + Styles.paddingSmall * 2)
            }
        }
        .sheet(isPresented: $showFullGallery) {
            FullMediaGalleryView(rocketTypes: rocketTypes, allLaunches: launches)
        }
    }
}

struct RocketTypeCard: View {
    let rocketName: String
    let imageUrl: URL?
    let launchCount: Int
    
    var body: some View {
        ZStack(alignment: .bottomLeading) {
            // Using GeometryReader to ensure consistent dimensions
            GeometryReader { geometry in
                LaunchImageView(
                    launchId: rocketName,
                    url: imageUrl,
                    style: .rocketCard,
                    fallbackMessage: "Rocket Image Unavailable"
                )
                .frame(width: geometry.size.width, height: geometry.size.height)
            }
            
            // Text overlay at the bottom with consistent positioning
            VStack(alignment: .leading, spacing: Styles.paddingTiny) {
                Text("\(launchCount) launch\(launchCount == 1 ? "" : "es")")
                    .font(Font.system(size: 12))
                    .foregroundColor(Styles.textSecondary)
                    .lineLimit(1)
                
                Text(rocketName)
                    .font(Font.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                    .lineLimit(1)
            }
            .padding(.horizontal, Styles.paddingSmall)
            .padding(.vertical, Styles.paddingSmall)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.black.opacity(0.7),
                        Color.black.opacity(0.3),
                        Color.clear
                    ]),
                    startPoint: .bottom,
                    endPoint: .top
                )
            )
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .cornerRadius(Styles.cornerRadiusMedium)
        .frame(width: Styles.rocketCardWidth, height: Styles.rocketCardHeight)
        .clipped()
    }
}


// MARK: - Preview
struct MediaGalleryView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            MediaGalleryView(launches: [
                Launch(
                    id: "1",
                    name: "Falcon 9 | Starlink Group 6-10",
                    net: Date().addingTimeInterval(86400),
                    provider: "SpaceX",
                    location: "Cape Canaveral, FL",
                    padLatitude: 28.5618,
                    padLongitude: -80.5772,
                    missionOverview: nil,
                    insights: nil,
                    image: URL(string: "https://example.com/image.jpg"),
                    rocketName: "Falcon 9",
                    isFavorite: false,
                    notificationsEnabled: false,
                    status: "Go",
                    missionName: "Starlink Group 6-10",
                    probability: 90,
                    url: nil,
                    slug: nil,
                    launchDesignator: nil,
                    windowStart: nil,
                    windowEnd: nil,
                    webcastLive: nil,
                    mission: nil
                )
            ])
            .padding()
        }
        .preferredColorScheme(.dark)
    }
}
struct RocketTypeCard_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            RocketTypeCard(
                rocketName: "Falcon 9",
                imageUrl: URL(string: "https://example.com/falcon9.jpg"),
                launchCount: 42
            )
            .padding()
        }
        .previewLayout(.sizeThatFits)
        .preferredColorScheme(.dark)
    }
}
