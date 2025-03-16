import SwiftUI

/// A standard primary button with Grok 3-inspired styling
struct PrimaryButton: View {
    var title: String
    var iconName: String?
    var action: () -> Void
    var isFullWidth: Bool = true
    var isDisabled: Bool = false
    
    var body: some View {
        Button(action: {
            if !isDisabled {
                action()
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            }
        }) {
            HStack(spacing: Styles.spacingSmall) {
                if let icon = iconName {
                    Image(systemName: icon)
                        .font(.system(size: Styles.iconSizeMedium))
                        .foregroundColor(.black)
                }
                
                Text(title)
                    .font(Styles.buttonFont)
                    .foregroundColor(.black)
            }
            .padding(.vertical, Styles.paddingMedium)
            .frame(maxWidth: isFullWidth ? .infinity : nil)
            .padding(.horizontal, isFullWidth ? Styles.paddingStandard : Styles.paddingLarge)
            .background(
                isDisabled
                    ? AnyView(Styles.highlightAccent.opacity(0.5))
                    : AnyView(Styles.buttonGradient)
            )
            .cornerRadius(Styles.cornerRadiusMedium)
            .overlay(
                RoundedRectangle(cornerRadius: Styles.cornerRadiusMedium)
                    .stroke(Styles.glassHighlight, lineWidth: Styles.hairlineBorder)
            )
            .shadow(color: Styles.glassShadow, radius: Styles.shadowRadiusMedium, x: 0, y: 4)
        }
        .buttonStyle(ScaleButtonStyle())
        .disabled(isDisabled)
    }
}

struct PrimaryButton_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Styles.spaceBackgroundGradient.edgesIgnoringSafeArea(.all)
            VStack(spacing: 20) {
                PrimaryButton(title: "Launch Now", iconName: "rocket.fill", action: {})
                PrimaryButton(title: "Disabled", action: {}, isDisabled: true)
                PrimaryButton(title: "Small", action: {}, isFullWidth: false)
            }
            .padding()
        }
        .preferredColorScheme(.dark)
    }
}
