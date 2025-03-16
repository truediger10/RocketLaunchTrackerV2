import SwiftUI
import Foundation

struct LaunchCard: View {
    let launch: Launch
    @ObservedObject var viewModel: LaunchViewModel
    @State private var showingActionMenu = false
    
    private var info: LaunchInfoDisplay {
        LaunchInfoDisplay(launch: launch)
    }
    
    var body: some View {
        NavigationLink(destination: LaunchDetailView(launch: launch, viewModel: viewModel)) {
            VStack(alignment: .leading, spacing: 0) {
                // Image container with overlay content
                ZStack(alignment: .topTrailing) {
                    // Main image and text container
                    ZStack(alignment: .bottomLeading) {
                        // The rocket image
                        LaunchImageView(
                            launchId: launch.id,
                            url: launch.image,
                            style: .launchCard,
                            fallbackMessage: "Image Unavailable"
                        )
                        
                        // Provider and mission name
                        VStack(alignment: .leading, spacing: Styles.spacingTiny) {
                            Text(launch.provider)
                                .font(Styles.captionFont)
                                .foregroundColor(Styles.textSecondary)
                            
                            Text(launch.missionName)
                                .font(Styles.titleFont)
                                .foregroundColor(Styles.textPrimary)
                                .lineLimit(1)
                        }
                        .padding(Styles.paddingStandard)
                    }
                    
                    // Top-right controls
                    HStack(spacing: Styles.spacingSmall) {
                        // Use the unified LaunchQuickActions component
                        LaunchQuickActions(
                            launch: launch,
                            size: Styles.iconSizeSmall * 1.5,
                            spacing: Styles.spacingSmall,
                            showShare: false // Hide share button on card to save space
                        )

                        Button(action: {
                            showingActionMenu = true
                        }) {
                            Image(systemName: "ellipsis")
                                .font(.system(size: Styles.iconSizeSmall))
                                .foregroundColor(Styles.textPrimary)
                        }
                        .buttonStyle(ScaleButtonStyle())
                    }
                    .padding(Styles.paddingStandard)
                }
                
                // Date and countdown section
                HStack {
                    // Date with icon
                    HStack(spacing: Styles.spacingSmall) {
                        Image(systemName: "calendar")
                            .font(.system(size: Styles.iconSizeSmall))
                            .foregroundColor(Styles.textSecondary)
                        
                        Text(launch.formattedNet(style: .dateAndTime))
                            .font(Styles.captionFont)
                            .foregroundColor(Styles.textSecondary)
                    }
                    
                    Spacer()
                    
                    // Countdown
                    CountdownTimer(targetDate: launch.net, isCompact: true)
                }
                .padding(.horizontal, Styles.paddingStandard)
                .padding(.vertical, Styles.paddingMedium)
                .background(Styles.cardSurface)
            }
            .background(Styles.cardSurface)
            .cornerRadius(Styles.cornerRadiusMedium)
            .overlay(
                RoundedRectangle(cornerRadius: Styles.cornerRadiusMedium)
                    .stroke(Styles.glassHighlight, lineWidth: Styles.hairlineBorder)
            )
            .grokShadow() // Using the built-in shadow modifier
        }
        .buttonStyle(ScaleButtonStyle()) // Using the standard scale button style
        .sheet(isPresented: $showingActionMenu) {
            LaunchPreferencesView(launch: launch, viewModel: viewModel)
        }
    }
}

#Preview {
    ZStack {
        Styles.spaceBackgroundGradient.edgesIgnoringSafeArea(.all)
        ScrollView {
            VStack(spacing: Styles.spacingMedium) {
                LaunchCard(
                    launch: Launch(
                        id: "123",
                        name: "Falcon 9 Block 5 | Starlink Group 6-14",
                        net: Date().addingTimeInterval(86400 * 3),
                        provider: "SpaceX",
                        location: "Kennedy Space Center, FL",
                        padLatitude: nil,
                        padLongitude: nil,
                        missionOverview: "Deployment of Starlink satellites for global internet.",
                        insights: ["Reused booster", "Drone ship landing"],
                        image: URL(string: "https://example.com/falcon9.jpg"),
                        rocketName: "Falcon 9 Block 5",
                        isFavorite: true,
                        notificationsEnabled: false,
                        status: "Go for Launch",
                        missionName: "Starlink Group 6-14",
                        probability: 95,
                        url: nil,
                        slug: nil,
                        launchDesignator: nil,
                        windowStart: nil,
                        windowEnd: nil,
                        webcastLive: nil,
                        mission: nil
                    ),
                    viewModel: LaunchViewModel()
                )
                
                // Second card to show in list
                LaunchCard(
                    launch: Launch(
                        id: "124",
                        name: "Atlas V | STP-3",
                        net: Date().addingTimeInterval(86400 * 5),
                        provider: "ULA",
                        location: "Cape Canaveral, FL",
                        padLatitude: nil,
                        padLongitude: nil,
                        missionOverview: "Space Test Program mission.",
                        insights: nil,
                        image: URL(string: "https://example.com/atlas.jpg"),
                        rocketName: "Atlas V",
                        isFavorite: false,
                        notificationsEnabled: true,
                        status: "Go for Launch",
                        missionName: "STP-3",
                        probability: 80,
                        url: nil,
                        slug: nil,
                        launchDesignator: nil,
                        windowStart: nil,
                        windowEnd: nil,
                        webcastLive: nil,
                        mission: nil
                    ),
                    viewModel: LaunchViewModel()
                )
            }
            .padding()
        }
    }
    .preferredColorScheme(.dark)
}