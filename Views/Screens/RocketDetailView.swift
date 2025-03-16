import SwiftUI
import Foundation
import Combine

/// View for displaying details about a specific rocket type
struct RocketDetailView: View {
    let rocketName: String
    let rocketImage: URL?
    let associatedLaunches: [Launch]
    let allLaunches: [Launch]
    @ObservedObject var viewModel: LaunchViewModel
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Back button
                    Button(action: { dismiss() }) {
                        HStack(spacing: 6) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 16))
                            Text("← Back to Rockets")
                                .font(.system(size: 18, weight: .medium))
                        }
                        .foregroundColor(Styles.primaryAccent)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(Styles.cardSurface.opacity(0.9))
                        )
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 8)
                    
                    // Rocket image with standardized styling
                    GeometryReader { geometry in
                        LaunchImageView(
                            launchId: rocketName,
                            url: rocketImage,
                            style: .detailView,
                            fallbackMessage: "Image Unavailable"
                        )
                        .frame(width: geometry.size.width)
                    }
                    .frame(height: Styles.detailImageHeight)
                    .padding(.horizontal, 20)
                    
                    // Rocket info
                    VStack(alignment: .leading, spacing: 8) {
                        Text(rocketName)
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white)
                        
                        let providers = Array(Set(associatedLaunches.map(\.provider)))
                        Text(providers.joined(separator: ", "))
                            .font(.system(size: 18))
                            .foregroundColor(Styles.textSecondary)
                    }
                    .padding(.horizontal, 20)
                    
                    // Launch details
                    VStack(alignment: .leading, spacing: 12) {
                        Text("SCHEDULED LAUNCHES")
                            .font(.system(size: 14, weight: .medium))
                            .tracking(1.2)
                            .foregroundColor(Styles.textTertiary)
                            .padding(.horizontal, 20)
                            .padding(.top, 16)
                        
                        // Upcoming launches with this rocket
                        let upcomingLaunches = associatedLaunches
                            .filter { $0.net > Date() }
                            .sorted { $0.net < $1.net }
                        
                        if upcomingLaunches.isEmpty {
                            Text("No upcoming launches scheduled")
                                .font(.system(size: 16))
                                .foregroundColor(Styles.textSecondary)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 12)
                        } else {
                            ForEach(upcomingLaunches) { launch in
                                NavigationLink(
                                    destination: LaunchDetailView(
                                        launch: launch,
                                        viewModel: viewModel
                                    )
                                ) {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(launch.missionName)
                                            .font(.system(size: 16, weight: .medium))
                                            .foregroundColor(.white)
                                        
                                        HStack {
                                            Text(launch.formattedNet(style: .dateAndTime))
                                                .font(.system(size: 14))
                                                .foregroundColor(Styles.textSecondary)
                                            
                                            Spacer()
                                            
                                            Text(launch.location)
                                                .font(.system(size: 14))
                                                .foregroundColor(Styles.textSecondary)
                                                .lineLimit(1)
                                        }
                                    }
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 12)
                                    .background(Styles.cardSurface.opacity(0.6))
                                    .cornerRadius(Styles.cornerRadiusSmall)
                                }
                                .buttonStyle(PlainButtonStyle())
                                .padding(.horizontal, 20)
                                .padding(.bottom, 4)
                            }
                        }
                    }
                }
                .padding(.bottom, 40)
            }
            .padding(.bottom, 40)
        }
        .navigationBarHidden(true)
    }
}

#Preview {
    RocketDetailView(
        rocketName: "Falcon 9",
        rocketImage: URL(string: "https://example.com/falcon9.jpg"),
        associatedLaunches: [
            Launch(id: "1", name: "Starlink 10", net: Date().addingTimeInterval(86400 * 3), provider: "SpaceX", location: "Cape Canaveral, FL", padLatitude: nil, padLongitude: nil, missionOverview: "Deployment of Starlink satellites.", insights: nil, image: nil, rocketName: "Falcon 9", isFavorite: false, notificationsEnabled: false, status: "Go for Launch", missionName: "Starlink 10", probability: 90, url: nil, slug: nil, launchDesignator: nil, windowStart: nil, windowEnd: nil, webcastLive: nil, mission: nil),
            Launch(id: "2", name: "Starlink 11", net: Date().addingTimeInterval(86400 * 5), provider: "SpaceX", location: "Cape Canaveral, FL", padLatitude: nil, padLongitude: nil, missionOverview: "Deployment of Starlink satellites.", insights: nil, image: nil, rocketName: "Falcon 9", isFavorite: false, notificationsEnabled: false, status: "Go for Launch", missionName: "Starlink 11", probability: 85, url: nil, slug: nil, launchDesignator: nil, windowStart: nil, windowEnd: nil, webcastLive: nil, mission: nil)
        ],
        allLaunches: [],
        viewModel: LaunchViewModel()
    )
    .preferredColorScheme(.dark)
}
