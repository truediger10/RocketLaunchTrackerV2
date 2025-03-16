//
//  FavoriteButton.swift
//  RocketLaunchTrackerV2
//
//  Created by Troy Ruediger on 3/12/25.
//


import SwiftUI

/// A reusable button for toggling favorites with visual feedback
struct FavoriteButton: View {
    // MARK: - Properties
    
    /// The launch to toggle as favorite
    let launch: Launch
    
    /// Whether to use a compact style (icon only)
    var isCompact: Bool = false
    
    /// Custom size for the button
    var size: CGFloat = 36
    
    /// Custom tint color for the button
    var tint: Color = Styles.highlightAccent
    
    /// Callback when favorite status changes
    var onStatusChanged: ((Bool) -> Void)? = nil
    
    /// Access to the favorite service
    @ObservedObject private var favoriteService = FavoriteService.shared
    
    /// Local state for animation
    @State private var isAnimating = false
    
    /// Computed property to check if the launch is a favorite
    private var isFavorite: Bool {
        return favoriteService.isFavorite(launchId: launch.id)
    }
    
    // MARK: - Body
    
    var body: some View {
        Button {
            // Animation for feedback
            withAnimation(Styles.spring) {
                isAnimating = true
            }
            
            // Toggle favorite state
            let newState = !isFavorite
            favoriteService.toggleFavorite(launchId: launch.id, isFavorite: newState)
            
            // Notify callback
            onStatusChanged?(newState)
            
            // Haptic feedback - different intensity based on action
            if newState {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            } else {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            }
            
            // Reset animation after a short delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation(Styles.spring) {
                    isAnimating = false
                }
            }
        } label: {
            if isCompact {
                compactView
            } else {
                standardView
            }
        }
        .buttonStyle(ScaleButtonStyle())
        .accessibilityLabel(isFavorite ? "Remove from favorites" : "Add to favorites")
        .help(isFavorite ? "Remove from favorites" : "Add to favorites") // Tooltip on macOS
    }
    
    // MARK: - Component Views
    
    /// Compact version showing only the icon
    private var compactView: some View {
        Image(systemName: isFavorite ? "star.fill" : "star")
            .font(.system(size: size * 0.5))
            .foregroundColor(isFavorite ? tint : Styles.textPrimary)
            .frame(width: size, height: size)
            .background(
                Circle()
                    .fill(Styles.elevatedSurface.opacity(0.8))
                    .overlay(
                        Circle()
                            .stroke(
                                isFavorite ? tint.opacity(0.5) : Styles.glassHighlight,
                                lineWidth: isFavorite ? 1.5 : Styles.hairlineBorder
                            )
                    )
                    .shadow(
                        color: isFavorite ? tint.opacity(0.3) : Styles.shadowColor.opacity(0.1),
                        radius: Styles.shadowRadiusSmall,
                        x: 0,
                        y: Styles.shadowOffset.height * 0.5
                    )
            )
            .scaleEffect(isAnimating ? 1.1 : 1.0)
    }
    
    /// Standard view with text label
    private var standardView: some View {
        HStack(spacing: Styles.spacingSmall) {
            Image(systemName: isFavorite ? "star.fill" : "star")
                .foregroundColor(isFavorite ? tint : Styles.textPrimary)
                .font(.system(size: Styles.iconSizeSmall))
            
            Text(isFavorite ? "Favorited" : "Add to Favorites")
                .font(Styles.captionFont)
                .foregroundColor(isFavorite ? tint : Styles.textPrimary)
        }
        .padding(.horizontal, Styles.paddingMedium)
        .padding(.vertical, Styles.paddingSmall)
        .background(
            Capsule()
                .fill(isFavorite ? tint.opacity(0.15) : Styles.cardSurface)
                .overlay(
                    Capsule()
                        .stroke(
                            isFavorite ? tint.opacity(0.3) : Styles.glassHighlight,
                            lineWidth: Styles.hairlineBorder
                        )
                )
        )
        .scaleEffect(isAnimating ? 1.05 : 1.0)
    }
}

struct FavoriteButton_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Styles.spaceBackgroundGradient
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 40) {
                FavoriteButton(
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
                    isCompact: false
                )
                
                FavoriteButton(
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
                    isCompact: true
                )
            }
            .padding()
        }
        .preferredColorScheme(.dark)
    }
}
