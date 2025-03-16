import SwiftUI

struct BubbleView: View {
    let text: String
    let icon: String
    let action: () -> Void
    
    @State private var isHovering = false
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                isPressed = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    isPressed = false
                }
            }
            
            action()
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }) {
            HStack(spacing: Styles.spacingSmall) {
                Image(systemName: icon)
                    .font(Font.system(size: 20, weight: .medium))
                    .foregroundColor(Styles.highlightAccent)
                    .scaleEffect(isPressed ? 0.9 : 1.0)
                
                Text(text)
                    .font(Font.system(size: 15, weight: .medium))
                    .foregroundColor(isHovering ? Styles.textPrimary : Styles.textSecondary)
            }
            .padding(.horizontal, Styles.paddingMedium)
            .padding(.vertical, Styles.paddingSmall)
            .background(
                ZStack {
                    // Glassmorphic background
                    RoundedRectangle(cornerRadius: Styles.cornerRadiusPill)
                        .fill(Styles.cardSurface)
                    
                    // Subtle gradient overlay
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.white.opacity(0.1),
                            Color.clear
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .clipShape(RoundedRectangle(cornerRadius: Styles.cornerRadiusPill))
                    
                    // Border
                    RoundedRectangle(cornerRadius: Styles.cornerRadiusPill)
                        .stroke(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Styles.highlightAccent.opacity(isHovering ? 0.3 : 0.1),
                                    Styles.highlightAccent.opacity(isHovering ? 0.15 : 0.05)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                }
            )
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .shadow(color: Styles.highlightAccent.opacity(isHovering ? 0.15 : 0), radius: Styles.shadowRadiusMedium, x: 0, y: Styles.shadowOffset.height)
        }
        .buttonStyle(PlainButtonStyle())
        .onHoverEffect(perform: { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovering = hovering
            }
        })
    }
}

// Custom hover effect for iOS compatibility
extension View {
    func onHoverEffect(perform action: @escaping (Bool) -> Void) -> some View {
        #if os(macOS)
        return self.onHover(perform: action)
        #else
        return self // iOS doesn't have onHover, so return self
        #endif
    }
}

#Preview {
    ZStack {
        Color.black.edgesIgnoringSafeArea(.all)
        VStack(spacing: Styles.spacingLarge) {
            BubbleView(text: "Track Launch", icon: "paperplane.fill") {
                print("Bubble tapped")
            }
            
            BubbleView(text: "Set Reminder", icon: "bell.fill") {
                print("Reminder tapped")
            }
            
            BubbleView(text: "Share", icon: "square.and.arrow.up") {
                print("Share tapped")
            }
        }
        .padding(Styles.paddingStandard)
    }
}