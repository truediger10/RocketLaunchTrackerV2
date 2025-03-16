//
//  LaunchQuickActions.swift
//  RocketLaunchTrackerV2
//
//  Created by Troy Ruediger on 3/12/25.
//


import SwiftUI

/// Quick action buttons for launches in list views
struct LaunchQuickActions: View {
    let launch: Launch
    var size: CGFloat = 30
    var spacing: CGFloat = 8
    var showNotification: Bool = true
    var showFavorite: Bool = true
    var showShare: Bool = true
    var alignment: Alignment = .trailing
    
    // Unified success feedback mechanism
    @State private var showFeedback: Bool = false
    @State private var feedbackMessage: String = ""
    @State private var feedbackColor: Color = Styles.statusSuccess
    
    var body: some View {
        ZStack(alignment: .bottom) {
            HStack(spacing: spacing) {
                if showNotification {
                    // Notification toggle
                    NotificationButton(
                        launch: launch,
                        isCompact: true,
                        size: size,
                        onStatusChanged: { enabled in
                            if enabled {
                                showActionFeedback("Notifications enabled", color: Styles.primaryAccent)
                            }
                        }
                    )
                }
                
                if showFavorite {
                    // Favorite toggle
                    FavoriteButton(
                        launch: launch,
                        isCompact: true,
                        size: size,
                        onStatusChanged: { isFavorite in
                            if isFavorite {
                                showActionFeedback("Added to favorites", color: Styles.highlightAccent)
                            }
                        }
                    )
                }
                
                if showShare {
                    // Share button
                    ShareButton(
                        launch: launch,
                        isCompact: true,
                        size: size
                    )
                }
            }
            .frame(maxWidth: .infinity, alignment: alignment)
            
            // Visual feedback for user actions
            if showFeedback {
                Text(feedbackMessage)
                    .font(Styles.captionFont)
                    .foregroundColor(.white)
                    .padding(.horizontal, Styles.paddingMedium)
                    .padding(.vertical, Styles.paddingSmall / 2)
                    .background(
                        Capsule()
                            .fill(feedbackColor)
                            .shadow(color: feedbackColor.opacity(0.3), radius: Styles.shadowRadiusSmall, x: 0, y: 2)
                    )
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                    .offset(y: 30)
            }
        }
    }
    
    // Helper function to show feedback toast
    private func showActionFeedback(_ message: String, color: Color = Styles.statusSuccess) {
        feedbackMessage = message
        feedbackColor = color
        
        withAnimation(Styles.spring) {
            showFeedback = true
        }
        
        // Hide after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation(Styles.spring) {
                showFeedback = false
            }
        }
    }
}

struct LaunchQuickActions_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Styles.spaceBackgroundGradient.edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 40) {
                LaunchQuickActions(
                    launch: Launch(
                        id: "123",
                        name: "Falcon 9 Block 5 | Starlink Group 6-14",
                        net: Date().addingTimeInterval(86400 * 3),
                        provider: "SpaceX",
                        location: "Kennedy Space Center, FL",
                        padLatitude: nil,
                        padLongitude: nil,
                        missionOverview: nil,
                        insights: nil,
                        image: nil,
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
                    alignment: .center
                )
                
                LaunchQuickActions(
                    launch: Launch(
                        id: "124",
                        name: "Atlas V | STP-3",
                        net: Date().addingTimeInterval(86400 * 5),
                        provider: "ULA",
                        location: "Cape Canaveral, FL",
                        padLatitude: nil,
                        padLongitude: nil,
                        missionOverview: nil,
                        insights: nil,
                        image: nil,
                        rocketName: "Atlas V",
                        isFavorite: false,
                        notificationsEnabled: false,
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
                    showNotification: false,
                    alignment: .center
                )
            }
            .padding()
        }
        .preferredColorScheme(.dark)
    }
}
