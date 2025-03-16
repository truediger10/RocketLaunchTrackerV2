import SwiftUI

/// A larger status badge with icon for use in detailed views
struct LargeStatusBadgeView: View {
    let status: String
    let statusColor: Color
    let statusSymbol: String
    
    var body: some View {
        HStack(spacing: Styles.spacingSmall) {
            Image(systemName: statusSymbol)
                .foregroundColor(statusColor)
                .font(.system(size: 16, weight: .semibold))
                .frame(width: 22, height: 22)
            
            Text(status)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white)
        }
        .padding(.horizontal, Styles.paddingMedium)
        .padding(.vertical, Styles.paddingSmall)
        .background(
            Capsule()
                .fill(Styles.cardSurface)
                .overlay(
                    Capsule()
                        .stroke(statusColor.opacity(0.3), lineWidth: 1.5)
                )
        )
        .shadow(color: statusColor.opacity(0.2), radius: Styles.shadowRadiusSmall, x: 0, y: Styles.shadowOffset.height)
    }
}

/// A standard-sized status badge for use in list items
struct StatusBadgeView: View {
    let status: String
    let statusColor: Color
    let statusSymbol: String
    
    var body: some View {
        HStack(spacing: Styles.spacingTiny) {
            Image(systemName: statusSymbol)
                .foregroundColor(statusColor)
                .font(.system(size: 10, weight: .semibold))
                .frame(width: 14, height: 14)
            
            Text(status)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.white)
        }
        .padding(.horizontal, Styles.paddingMedium)
        .padding(.vertical, Styles.paddingTiny)
        .background(
            Capsule()
                .fill(Styles.cardSurface)
                .overlay(
                    Capsule()
                        .stroke(statusColor.opacity(0.3), lineWidth: 1)
                )
        )
        .shadow(color: statusColor.opacity(0.15), radius: Styles.shadowRadiusSmall, x: 0, y: Styles.shadowOffset.height)
    }
}

/// Variant with glow effect for special statuses
struct GlowingStatusBadgeView: View {
    let status: String
    let statusColor: Color
    let statusSymbol: String
    
    var body: some View {
        HStack(spacing: Styles.spacingTiny) {
            Image(systemName: statusSymbol)
                .foregroundColor(statusColor)
                .font(.system(size: 10, weight: .semibold))
                .frame(width: 14, height: 14)
            
            Text(status)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.white)
        }
        .padding(.horizontal, Styles.paddingMedium)
        .padding(.vertical, Styles.paddingTiny)
        .background(
            Capsule()
                .fill(Styles.cardSurface)
        )
        .overlay(
            Capsule()
                .strokeBorder(statusColor.opacity(0.6), lineWidth: 1)
        )
        .shadow(color: statusColor.opacity(0.5), radius: Styles.shadowRadiusMedium, x: 0, y: 0)
    }
}

// MARK: - Preview
struct StatusBadgeView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Styles.spaceBackgroundGradient.edgesIgnoringSafeArea(.all)
            VStack(spacing: Styles.spacingLarge) {
                // Group 1: Success badges
                VStack(spacing: Styles.spacingMedium) {
                    StatusBadgeView(
                        status: "Go for Launch",
                        statusColor: Styles.statusSuccess,
                        statusSymbol: "checkmark.circle.fill"
                    )
                    
                    LargeStatusBadgeView(
                        status: "Go for Launch",
                        statusColor: Styles.statusSuccess,
                        statusSymbol: "checkmark.circle.fill"
                    )
                    
                    GlowingStatusBadgeView(
                        status: "Go for Launch",
                        statusColor: Styles.statusSuccess,
                        statusSymbol: "checkmark.circle.fill"
                    )
                }
                
                // Group 2: Warning badges
                VStack(spacing: Styles.spacingMedium) {
                    StatusBadgeView(
                        status: "Hold",
                        statusColor: Styles.statusWarning,
                        statusSymbol: "pause.circle.fill"
                    )
                    
                    LargeStatusBadgeView(
                        status: "Hold",
                        statusColor: Styles.statusWarning,
                        statusSymbol: "pause.circle.fill"
                    )
                    
                    GlowingStatusBadgeView(
                        status: "Hold",
                        statusColor: Styles.statusWarning,
                        statusSymbol: "pause.circle.fill"
                    )
                }
                
                // Group 3: Error badges
                VStack(spacing: Styles.spacingMedium) {
                    StatusBadgeView(
                        status: "Failure",
                        statusColor: Styles.statusError,
                        statusSymbol: "xmark.circle.fill"
                    )
                    
                    LargeStatusBadgeView(
                        status: "Failure",
                        statusColor: Styles.statusError,
                        statusSymbol: "xmark.circle.fill"
                    )
                    
                    GlowingStatusBadgeView(
                        status: "Failure",
                        statusColor: Styles.statusError,
                        statusSymbol: "xmark.circle.fill"
                    )
                }
                
                // Group 4: Highlight accent badges
                VStack(spacing: Styles.spacingMedium) {
                    StatusBadgeView(
                        status: "T-Minus",
                        statusColor: Styles.highlightAccent,
                        statusSymbol: "clock.fill"
                    )
                    
                    LargeStatusBadgeView(
                        status: "T-Minus",
                        statusColor: Styles.highlightAccent,
                        statusSymbol: "clock.fill"
                    )
                    
                    GlowingStatusBadgeView(
                        status: "T-Minus",
                        statusColor: Styles.highlightAccent,
                        statusSymbol: "clock.fill"
                    )
                }
                
                // Group 5: Support accent badges
                VStack(spacing: Styles.spacingMedium) {
                    StatusBadgeView(
                        status: "Special Event",
                        statusColor: Styles.highlightAccent,
                        statusSymbol: "star.fill"
                    )
                    
                    LargeStatusBadgeView(
                        status: "Special Event",
                        statusColor: Styles.highlightAccent,
                        statusSymbol: "star.fill"
                    )
                    
                    GlowingStatusBadgeView(
                        status: "Special Event",
                        statusColor: Styles.highlightAccent,
                        statusSymbol: "star.fill"
                    )
                }
            }
            .padding(Styles.paddingLarge)
        }
        .preferredColorScheme(.dark)
    }
}
