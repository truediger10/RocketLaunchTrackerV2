import SwiftUI

/// A full-screen gallery view displaying all rocket types in a grid.
/// Leverages the existing `RocketTypeCard` and navigates to RocketDetailView
/// just like MediaGalleryView does, but for the full list.
struct FullMediaGalleryView: View {
    let rocketTypes: [RocketType]
    let allLaunches: [Launch]
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 0) {
                    // Navigation bar with title and close button
                    HStack {
                        Text("ROCKET GALLERY")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                            .tracking(1.2)
                        
                        Spacer()
                        
                        Button(action: { dismiss() }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 22))
                                .foregroundColor(Styles.textSecondary)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 16)
                    
                    ScrollView {
                        LazyVGrid(columns: [
                            GridItem(.flexible(minimum: 150), spacing: 16),
                            GridItem(.flexible(minimum: 150), spacing: 16)
                        ], spacing: 16) {
                            ForEach(rocketTypes, id: \.id) { rocketInfo in
                                NavigationLink(
                                    destination: RocketDetailView(
                                        rocketName: rocketInfo.rocket,
                                        rocketImage: rocketInfo.image,
                                        associatedLaunches: rocketInfo.launches,
                                        allLaunches: allLaunches,
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
                        .padding(.horizontal, 16)
                        .padding(.top, 20)
                        .padding(.bottom, 20)
                    }
                }
            }
            .navigationBarHidden(true)
        }
    }
}

struct FullMediaGalleryView_Previews: PreviewProvider {
    static var previews: some View {
        FullMediaGalleryView(
            rocketTypes: [
                RocketType(
                    rocket: "Falcon 9",
                    image: URL(string: "https://example.com/falcon9.jpg")!,
                    launches: []
                ),
                RocketType(
                    rocket: "Atlas V 551",
                    image: URL(string: "https://example.com/atlasv.jpg")!,
                    launches: []
                )
            ],
            allLaunches: []
        )
        .preferredColorScheme(.dark)
    }
}
