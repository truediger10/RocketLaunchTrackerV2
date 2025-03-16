//
//  ShareButton.swift
//  RocketLaunchTrackerV2
//
//  Created by Troy Ruediger on 3/12/25.
//


import SwiftUI

/// A reusable button for sharing launch information
struct ShareButton: View {
    // MARK: - Properties
    
    /// The launch to share
    let launch: Launch
    
    /// Whether to use a compact style (icon only)
    var isCompact: Bool = false
    
    /// Custom size for the button
    var size: CGFloat = 36
    
    /// Custom tint color for the button
    var tint: Color = Styles.textPrimary
    
    /// Callback when sharing action completes
    var onShareComplete: (() -> Void)? = nil
    
    /// Local state for animation
    @State private var isAnimating = false
    
    // MARK: - Body
    
    var body: some View {
        Button {
            // Animation for feedback
            withAnimation(Styles.spring) {
                isAnimating = true
            }
            
            // Use the ShareService to handle sharing
            ShareService.shared.presentShareSheet(for: launch)
            
            // Add consistent haptic feedback
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            
            // Reset animation after a short delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation(Styles.spring) {
                    isAnimating = false
                }
                onShareComplete?()
            }
        } label: {
            if isCompact {
                compactView
            } else {
                standardView
            }
        }
        .buttonStyle(ScaleButtonStyle())
        .accessibilityLabel("Share launch information")
        .help("Share launch information") // Tooltip on macOS
    }
    
    // MARK: - Component Views
    
    /// Compact version showing only the icon
    private var compactView: some View {
        Image(systemName: "square.and.arrow.up")
            .font(.system(size: size * 0.5))
            .foregroundColor(tint)
            .frame(width: size, height: size)
            .background(
                Circle()
                    .fill(Styles.elevatedSurface.opacity(0.8))
                    .overlay(
                        Circle()
                            .stroke(Styles.glassHighlight, lineWidth: Styles.hairlineBorder)
                    )
                    .shadow(
                        color: Styles.shadowColor.opacity(0.1),
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
            Image(systemName: "square.and.arrow.up")
                .foregroundColor(tint)
                .font(.system(size: Styles.iconSizeSmall))
            
            Text("Share Launch")
                .font(Styles.captionFont)
                .foregroundColor(tint)
        }
        .padding(.horizontal, Styles.paddingMedium)
        .padding(.vertical, Styles.paddingSmall)
        .background(
            Capsule()
                .fill(Styles.cardSurface)
                .overlay(
                    Capsule()
                        .stroke(Styles.glassHighlight, lineWidth: Styles.hairlineBorder)
                )
        )
        .scaleEffect(isAnimating ? 1.05 : 1.0)
    }
}

struct ShareButton_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Styles.spaceBackgroundGradient
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 40) {
                ShareButton(
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
                
                ShareButton(
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