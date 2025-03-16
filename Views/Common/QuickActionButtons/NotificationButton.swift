//
//  NotificationButton.swift
//  RocketLaunchTrackerV2
//
//  Created by Troy Ruediger on 3/12/25.
//


import SwiftUI

/// A reusable button for toggling notifications with visual feedback
struct NotificationButton: View {
    // MARK: - Properties
    
    /// The launch to manage notifications for
    let launch: Launch
    
    /// Whether to use a compact style (icon only)
    var isCompact: Bool = false
    
    /// Custom size for the button
    var size: CGFloat = 36
    
    /// Custom tint color for the button
    var tint: Color = Styles.primaryAccent
    
    /// Callback when notification status changes
    var onStatusChanged: ((Bool) -> Void)? = nil
    
    /// Access to the notification service
    @ObservedObject private var notificationService = NotificationService.shared
    
    /// Local state for animation
    @State private var isAnimating = false
    
    /// Computed property to check if notifications are enabled for this launch
    private var isEnabled: Bool {
        return notificationService.isNotificationEnabled(for: launch.id)
    }
    
    // MARK: - Body
    
    var body: some View {
        Button {
            // Animation for feedback
            withAnimation(Styles.spring) {
                isAnimating = true
            }
            
            // Toggle notification state
            let newState = !isEnabled
            notificationService.toggleNotification(enabled: newState, for: launch) { result in
                switch result {
                case .success(let enabled):
                    // Notify callback
                    onStatusChanged?(enabled)
                    
                    // Consistent haptic feedback
                    if enabled {
                        UINotificationFeedbackGenerator().notificationOccurred(.success)
                    } else {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    }
                    
                case .failure:
                    // Haptic feedback for error
                    UINotificationFeedbackGenerator().notificationOccurred(.error)
                }
                
                // Reset animation after a short delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    withAnimation(Styles.spring) {
                        isAnimating = false
                    }
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
        .accessibilityLabel(isEnabled ? "Disable notifications" : "Enable notifications")
        .help(isEnabled ? "Disable notifications" : "Enable notifications") // Tooltip on macOS
        .contextMenu {
            if isEnabled {
                Button {
                    // Schedule a test notification
                    notificationService.scheduleTestNotification(for: launch) { _ in
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    }
                } label: {
                    Label("Send Test Notification", systemImage: "bell.and.waves.left.and.right")
                }
                
                Button {
                    // Show notification settings
                    // This would open the notification settings sheet in a real implementation
                } label: {
                    Label("Configure Notifications", systemImage: "gear")
                }
                
                Button(role: .destructive) {
                    // Disable notifications
                    notificationService.toggleNotification(enabled: false, for: launch) { _ in
                        UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                        onStatusChanged?(false)
                    }
                } label: {
                    Label("Disable Notifications", systemImage: "bell.slash")
                }
            } else {
                Button {
                    // Enable notifications
                    notificationService.toggleNotification(enabled: true, for: launch) { _ in
                        UINotificationFeedbackGenerator().notificationOccurred(.success)
                        onStatusChanged?(true)
                    }
                } label: {
                    Label("Enable Notifications", systemImage: "bell.badge")
                }
            }
        }
    }
    
    // MARK: - Component Views
    
    /// Compact version showing only the icon
    private var compactView: some View {
        Image(systemName: isEnabled ? "bell.fill" : "bell")
            .font(.system(size: size * 0.5))
            .foregroundColor(isEnabled ? tint : Styles.textPrimary)
            .frame(width: size, height: size)
            .background(
                Circle()
                    .fill(Styles.elevatedSurface.opacity(0.8))
                    .overlay(
                        Circle()
                            .stroke(
                                isEnabled ? tint.opacity(0.5) : Styles.glassHighlight,
                                lineWidth: isEnabled ? 1.5 : Styles.hairlineBorder
                            )
                    )
                    .shadow(
                        color: isEnabled ? tint.opacity(0.3) : Styles.shadowColor.opacity(0.1),
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
            Image(systemName: isEnabled ? "bell.fill" : "bell")
                .foregroundColor(isEnabled ? tint : Styles.textPrimary)
                .font(.system(size: Styles.iconSizeSmall))
            
            Text(isEnabled ? "Notifications On" : "Notifications Off")
                .font(Styles.captionFont)
                .foregroundColor(isEnabled ? tint : Styles.textPrimary)
        }
        .padding(.horizontal, Styles.paddingMedium)
        .padding(.vertical, Styles.paddingSmall)
        .background(
            Capsule()
                .fill(isEnabled ? tint.opacity(0.15) : Styles.cardSurface)
                .overlay(
                    Capsule()
                        .stroke(
                            isEnabled ? tint.opacity(0.3) : Styles.glassHighlight,
                            lineWidth: Styles.hairlineBorder
                        )
                )
        )
        .scaleEffect(isAnimating ? 1.05 : 1.0)
    }
}

struct NotificationButton_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Styles.spaceBackgroundGradient
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 40) {
                NotificationButton(
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
                        isFavorite: false,
                        notificationsEnabled: true,
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
                
                NotificationButton(
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