import SwiftUI

/**
 A centralized styling system for the Rocket Launch Tracker app with Grok 3-inspired aesthetics.
 
 This file defines constants for colors, fonts, spacing, animations, and more. It keeps the design
 consistent throughout the app. Each section includes inline comments to explain what each part does,
 making it easier to understand even if you're new to coding.
 */
struct Styles {
    // MARK: - Colors
    // Base Colors: Used for backgrounds and surfaces throughout the app.
    static let baseBackground = Color.black                       // Main screen background.
    static let deepBackground = Color(hex: "#0A0A0A")               // Darker background for layered areas.
    static let cardSurface = Color(hex: "#1A1A1A").opacity(0.85)     // For cards with a glass-like (glassmorphic) effect.
    static let elevatedSurface = Color(hex: "#212121").opacity(0.9)   // For elevated elements.
    static let divider = Color(hex: "#3A3A3A").opacity(0.2)           // Divider lines between UI elements.
    static let inputBackground = Color(hex: "#1D1D1D").opacity(0.8)   // Background for text fields.
    
    // Text Colors: Define the colors used for different types of text.
    static let textPrimary = Color.white                           // Main text color.
    static let textSecondary = Color(hex: "#A0A0A0")                // For less prominent text (subtitles, etc.).
    static let textTertiary = Color(hex: "#777777")                 // For even less emphasized text.
    static let textDisabled = Color(hex: "#505050")                 // For disabled/inactive text.
    
    // Accent Colors: Used to highlight important UI elements.
    static let highlightAccent = Color(hex: "#00AEEF")              // Primary blue accent.
    static let supportAccent = Color(hex: "#D7FF00")                // Secondary bright yellow accent.
    static let tertiaryAccent = Color.clear                        // Currently not used.
    static let primaryAccent = highlightAccent                     // Alias for highlightAccent.
    
    // Status Colors: Indicate various states like success, warning, or error.
    static let statusSuccess = Color(hex: "#00AEEF").opacity(0.9)    // Blue indicates success.
    static let statusWarning = Color(hex: "#FF8A00").opacity(0.9)    // Orange indicates warnings.
    static let statusError = Color(hex: "#FF5470").opacity(0.9)      // Red indicates errors.
    static let warningColor = statusWarning                        // Alias for consistency.
    static let successColor = statusSuccess                        // Alias for consistency.
    
    // Gradients: For smooth color transitions in backgrounds and overlays.
    static let spaceBackgroundGradient = LinearGradient(
        colors: [
            Color.black,
            Color(hex: "#0A0A0A"),
            Color(hex: "#00AEEF").opacity(0.05)
        ],
        startPoint: .top,
        endPoint: .bottom
    )
    
    static let purpleBackgroundGradient = LinearGradient(
        colors: [Color.black, Color(hex: "#0A0A0A"), Color.black],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let blueBackgroundGradient = LinearGradient(
        colors: [Color.black, Color(hex: "#0A0A0A"), Color.black],
        startPoint: .topTrailing,
        endPoint: .bottomLeading
    )
    
    static let backgroundGradient = LinearGradient(
        colors: [Color.black, Color(hex: "#0A0A0A"), Color.black],
        startPoint: .top,
        endPoint: .bottom
    )
    
    static let cardGradient = LinearGradient(
        colors: [Color(hex: "#1A1A1A").opacity(0.85), Color(hex: "#212121").opacity(0.9)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    // Effects for glassmorphic design.
    static let glassEffect = Color.white.opacity(0.05)             // Subtle overlay for glass effect.
    static let glassHighlight = Color.white.opacity(0.1)           // Highlights on glass surfaces.
    static let glassShadow = Color.black.opacity(0.3)              // Shadow for glass effect.
    
    // Overlay Gradient: Typically used on images to enhance text readability.
    static let imageOverlayGradient = LinearGradient(
        colors: [Color.black.opacity(0.7), Color.black.opacity(0.3), Color.clear],
        startPoint: .bottom,
        endPoint: .top
    )
    
    // Button Gradient: Used for button backgrounds.
    static let buttonGradient = LinearGradient(
        colors: [highlightAccent, highlightAccent.opacity(0.8)],
        startPoint: .leading,
        endPoint: .trailing
    )
    
    // MARK: - Sizing & Spacing
    // These values ensure consistent spacing, padding, and sizing across the UI.
    static let grid: CGFloat = 8                                  // Base unit for size calculations.
    static let cornerRadiusSmall: CGFloat = grid * 1.5              // Small rounded corners (~12 pts).
    static let cornerRadiusMedium: CGFloat = grid * 2               // Medium rounded corners (~16 pts).
    static let cornerRadiusLarge: CGFloat = grid * 3                // Large rounded corners (~24 pts).
    static let cornerRadiusPill: CGFloat = grid * 4                 // For pill-shaped elements (~32 pts).
    
    static let paddingTiny: CGFloat = grid / 2                      // Minimal padding (~4 pts).
    static let paddingSmall: CGFloat = grid                         // Small padding (8 pts).
    static let paddingMedium: CGFloat = grid * 1.5                  // Medium padding (~12 pts).
    static let paddingStandard: CGFloat = grid * 2                  // Standard padding (16 pts).
    static let paddingLarge: CGFloat = grid * 3                     // Large padding (24 pts).
    static let paddingExtraLarge: CGFloat = grid * 4                // Extra-large padding (32 pts).
    
    static let spacingTiny: CGFloat = grid / 2                      // Minimal spacing.
    static let spacingSmall: CGFloat = grid                         // Small spacing.
    static let spacingMedium: CGFloat = grid * 2                    // Medium spacing.
    static let spacingLarge: CGFloat = grid * 3                     // Large spacing.
    
    // MARK: - Element Sizing
    // Sizes for buttons, icons, avatars, etc.
    static let buttonHeight: CGFloat = grid * 6                    // Standard button height (~48 pts).
    static let inputHeight: CGFloat = grid * 6                     // Input field height (~48 pts).
    static let iconSizeSmall: CGFloat = grid * 2                    // Small icon (~16 pts).
    static let iconSizeMedium: CGFloat = grid * 2.5                 // Medium icon (~20 pts).
    static let iconSizeLarge: CGFloat = grid * 3                    // Large icon (~24 pts).
    static let avatarSizeSmall: CGFloat = grid * 4                  // Small avatar (~32 pts).
    static let avatarSizeMedium: CGFloat = grid * 6                 // Medium avatar (~48 pts).
    static let avatarSizeLarge: CGFloat = grid * 10                 // Large avatar (~80 pts).
    
    // MARK: - Typography
    // Font sizes and weights for consistent text styling.
    static let fontTiny: CGFloat = 12
    static let fontSmall: CGFloat = 14
    static let fontMedium: CGFloat = 16
    static let fontLarge: CGFloat = 20
    static let fontHeader: CGFloat = 24
    static let fontTitle: CGFloat = 24                             // Typically used for headers and titles.
    static let fontDisplay: CGFloat = 40                           // For very large display text.
    
    static let weightLight = Font.Weight.light
    static let weightRegular = Font.Weight.regular
    static let weightMedium = Font.Weight.medium
    static let weightSemibold = Font.Weight.semibold
    static let weightBold = Font.Weight.bold
    
    // Line heights for text.
    static let lineHeightTight: CGFloat = 1.1                      // Tight spacing.
    static let lineHeightNormal: CGFloat = 1.3                     // Standard spacing.
    static let lineHeightRelaxed: CGFloat = 1.5                    // Relaxed spacing.
    
    // Predefined fonts using the sizes and weights above.
    static let displayFont = Font.system(size: fontDisplay, weight: weightBold)
    static let titleFont = Font.system(size: fontTitle, weight: weightBold)
    static let headerFont = Font.system(size: fontLarge, weight: weightSemibold)
    static let subheaderFont = Font.system(size: fontMedium, weight: weightSemibold)
    static let bodyFont = Font.system(size: fontMedium, weight: weightRegular)
    static let captionFont = Font.system(size: fontSmall, weight: weightRegular)
    static let smallCaptionFont = Font.system(size: fontTiny, weight: weightMedium)
    static let buttonFont = Font.system(size: fontSmall, weight: weightMedium) // For button text.
    
    // MARK: - Animation Effects
    // Preset animation durations and easing options for smooth UI transitions.
    static let animationFast: Double = 0.15
    static let animationStandard: Double = 0.25
    static let animationSlow: Double = 0.4
    
    static let easeInOut = Animation.easeInOut(duration: animationStandard)
    static let easeIn = Animation.easeIn(duration: animationStandard)
    static let easeOut = Animation.easeOut(duration: animationStandard)
    static let spring = Animation.spring(response: 0.3, dampingFraction: 0.7)
    static let bouncy = Animation.spring(response: 0.4, dampingFraction: 0.6, blendDuration: 0.2)
    
    // MARK: - Blur Effects
    // Standard blur values for visual effects.
    static let blurLight: CGFloat = 10
    static let blurMedium: CGFloat = 20
    static let blurHeavy: CGFloat = 30
    
    // MARK: - Shadow Values
    // Settings for shadows to add depth to UI elements.
    static let shadowRadiusSmall: CGFloat = 10
    static let shadowRadiusMedium: CGFloat = 15
    static let shadowRadiusLarge: CGFloat = 25
    
    static let shadowOpacityLight: Double = 0.1
    static let shadowOpacityMedium: Double = 0.2
    static let shadowOpacityHeavy: Double = 0.3
    
    static let shadowOffset = CGSize(width: 0, height: 8)         // Default shadow offset.
    static let shadowColor = Color.black                           // Default shadow color.
    
    static let cardShadow = Color.black.opacity(shadowOpacityMedium)
    static let elevatedShadow = Color.black.opacity(shadowOpacityHeavy)
    static let subtleShadow = Color.black.opacity(shadowOpacityLight)
    
    // MARK: - Other
    // Additional constants for borders and specific image sizes.
    static let hairlineBorder: CGFloat = 0.5
    static let standardBorder: CGFloat = 1.0
    static let thickBorder: CGFloat = 2.0
    
    static let launchCardImageHeight: CGFloat = 220
    static let detailImageHeight: CGFloat = 240
    static let rocketCardWidth: CGFloat = 180
    static let rocketCardHeight: CGFloat = 140
    static let preferenceImageHeight: CGFloat = 160
    
    // MARK: - Glassmorphic Effects
    // Effects to create a frosted glass look for UI components.
    static let glassTint = Color.white.opacity(0.1)
    static let glassBorderOpacity = 0.2
    static let glassContentOpacity = 0.8
}

// MARK: - Color Extensions
// This extension allows you to create a Color from a hex string (e.g., "#FF0000").
extension Color {
    init(hex: String) {
        let cleanedHex = hex.trimmingCharacters(in: .alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: cleanedHex).scanHexInt64(&int)
        let r, g, b: Double
        switch cleanedHex.count {
        case 3: // Short format, e.g., "#RGB"
            (r, g, b) = (
                Double((int >> 8) & 0xF) / 15.0,
                Double((int >> 4) & 0xF) / 15.0,
                Double(int & 0xF) / 15.0
            )
        case 6: // Standard format, e.g., "#RRGGBB"
            (r, g, b) = (
                Double((int >> 16) & 0xFF) / 255.0,
                Double((int >> 8) & 0xFF) / 255.0,
                Double(int & 0xFF) / 255.0
            )
        default:
            (r, g, b) = (0, 0, 0)
        }
        self.init(red: r, green: g, blue: b)
    }
}

// MARK: - View Modifiers
// Custom styling methods that can be applied to any SwiftUI view.
extension View {
    /// Applies rounded corners and a subtle shadow to an image.
    func grokImage(cornerRadius: CGFloat = Styles.cornerRadiusMedium) -> some View {
        self
            .cornerRadius(cornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .strokeBorder(Styles.glassHighlight.opacity(0.2), lineWidth: Styles.hairlineBorder)
            )
            .shadow(color: Styles.cardShadow, radius: Styles.shadowRadiusSmall, y: Styles.shadowOffset.height)
    }
    
    /// Adds a gradient overlay at the bottom of a view to improve text readability (commonly used on images).
    func withTextOverlay(height: CGFloat? = nil) -> some View {
        ZStack(alignment: .bottom) {
            self
            Styles.imageOverlayGradient
                .frame(height: height ?? 100)
                .allowsHitTesting(false)
        }
    }
    
    /// Applies a glassmorphic card style to the view.
    func glassmorphicCard() -> some View {
        self.modifier(GlassmorphicCardStyle())
    }
    
    /// Styles a view as a glowing pill button, ideal for accent actions.
    func glowingPill(color: Color = Styles.highlightAccent, textColor: Color = .black) -> some View {
        self.modifier(GlowingPillStyle(color: color, textColor: textColor))
    }
    
    /// Styles text to be used as section headers.
    func grokSectionHeader() -> some View {
        self.modifier(GrokSectionHeaderStyle())
    }
    
    /// Applies a space-themed gradient background that fills the screen.
    func grokBackground() -> some View {
        self.background(Styles.spaceBackgroundGradient.edgesIgnoringSafeArea(.all))
    }
    
    /// Adds a standard shadow to the view.
    func grokShadow(radius: CGFloat = Styles.shadowRadiusMedium) -> some View {
        self.shadow(
            color: Styles.shadowColor,
            radius: radius,
            x: Styles.shadowOffset.width,
            y: Styles.shadowOffset.height
        )
    }
    
    /// Applies a glass effect overlay, giving the view a frosted look.
    func grokGlass(opacity: Double = 0.7, blur: CGFloat = 10) -> some View {
        self.modifier(GrokGlassEffect(opacity: opacity, blur: blur))
    }
}

// MARK: - View Modifiers (Implementations)
/// Custom modifier to style a card with a glass-like effect.
struct GlassmorphicCardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(Styles.paddingStandard) // Internal padding for card content.
            .background(
                RoundedRectangle(cornerRadius: Styles.cornerRadiusMedium)
                    .fill(Styles.cardSurface)
                    .overlay(
                        RoundedRectangle(cornerRadius: Styles.cornerRadiusMedium)
                            .fill(Styles.glassEffect)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: Styles.cornerRadiusMedium)
                            .stroke(Styles.glassHighlight, lineWidth: Styles.hairlineBorder)
                    )
                    .shadow(color: Styles.glassShadow, radius: Styles.shadowRadiusMedium, x: 0, y: 4)
            )
    }
}

/// Custom modifier for a glowing pill button style.
struct GlowingPillStyle: ViewModifier {
    var color: Color = Styles.highlightAccent
    var textColor: Color = .black
    
    func body(content: Content) -> some View {
        content
            .font(Styles.buttonFont) // Use button font style.
            .foregroundColor(textColor) // Set text color.
            .padding(.horizontal, Styles.paddingMedium) // Horizontal padding inside the pill.
            .padding(.vertical, Styles.paddingSmall) // Vertical padding inside the pill.
            .background(
                Capsule()
                    .fill(color) // Fill with specified color.
                    .shadow(color: color.opacity(0.5), radius: Styles.shadowRadiusMedium, x: 0, y: 0) // Glow effect.
            )
    }
}

/// Custom modifier for styling section headers.
struct GrokSectionHeaderStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.system(size: Styles.fontMedium, weight: .medium)) // Medium-sized text.
            .foregroundColor(Styles.textSecondary) // Use secondary text color.
            .tracking(1.0) // Slight letter spacing.
            .padding(.horizontal, Styles.paddingStandard) // Horizontal padding.
            .padding(.vertical, Styles.paddingSmall) // Vertical padding.
    }
}

/// Custom modifier to apply a frosted glass effect.
struct GrokGlassEffect: ViewModifier {
    var opacity: Double = 0.7
    var blur: CGFloat = 10
    
    func body(content: Content) -> some View {
        content
            .background(
                Color.white.opacity(0.05)
                    .background(Color.black.opacity(opacity))
                    .blur(radius: blur)
                    .clipShape(RoundedRectangle(cornerRadius: Styles.cornerRadiusMedium))
                    .overlay(
                        RoundedRectangle(cornerRadius: Styles.cornerRadiusMedium)
                            .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
                    )
            )
    }
}

// MARK: - Reusable UI Components
/// A custom button view styled as a glowing pill. Can be reused anywhere in the app.
struct GrokButton: View {
    let title: String           // Text displayed on the button.
    let icon: String?           // Optional SF Symbol name for an icon.
    let action: () -> Void      // Action executed when the button is pressed.
    var isPrimary: Bool = true  // True for primary (filled) style; false for secondary style.
    var isFullWidth: Bool = false // If true, the button stretches to fill available width.
    
    var body: some View {
        Button(action: {
            action()
            UIImpactFeedbackGenerator(style: .medium).impactOccurred() // Haptic feedback.
        }) {
            HStack(spacing: Styles.spacingSmall) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: Styles.iconSizeMedium, weight: .medium))
                }
                Text(title)
                    .font(.system(size: Styles.fontMedium, weight: .medium))
            }
            .foregroundColor(isPrimary ? .black : Styles.textPrimary)
            .padding(.horizontal, Styles.paddingLarge)
            .padding(.vertical, Styles.paddingMedium)
            .frame(maxWidth: isFullWidth ? .infinity : nil)
            .background(
                isPrimary ?
                    AnyView(
                        Capsule()
                            .fill(Styles.buttonGradient)
                            .shadow(color: Styles.highlightAccent.opacity(0.5), radius: Styles.shadowRadiusMedium, x: 0, y: 0)
                    ) :
                    AnyView(
                        Capsule()
                            .fill(Styles.cardSurface)
                            .overlay(
                                Capsule()
                                    .stroke(Styles.highlightAccent, lineWidth: 1)
                            )
                    )
            )
        }
        .buttonStyle(ScaleButtonStyle()) // Apply scaling effect when pressed.
    }
}

// MARK: - Fancy Colors and Styles Extension
// Extra creative styles you can copy and paste into your code as needed.
extension Styles {
    // Fancy Colors: Vibrant, eye-catching colors.
    static let fancyPink = Color(hex: "#FF69B4")      // Neon pink.
    static let fancyPurple = Color(hex: "#9B59B6")      // Vibrant purple.
    
    // Fancy Gradient: A gradient transitioning from neon pink to vibrant purple.
    static let fancyGradient = LinearGradient(
        colors: [fancyPink, fancyPurple],
        startPoint: .leading,
        endPoint: .trailing
    )
    
    // Additional Fancy Colors:
    static let fancyTeal = Color(hex: "#00FFFF")        // Bright teal.
    static let fancyLime = Color(hex: "#7FFF00")        // Bright lime green.
    
    // Fancy Teal Green Gradient: A gradient from teal to lime.
    static let fancyTealGreenGradient = LinearGradient(
        colors: [fancyTeal, fancyLime],
        startPoint: .top,
        endPoint: .bottom
    )
}

// MARK: - Scale Button Style
/// A custom button style that slightly scales down the button when pressed for visual feedback.
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .animation(.easeOut(duration: Styles.animationFast), value: configuration.isPressed)
    }
}

// MARK: - Previews
// Previews allow you to see how components look directly in Xcode's canvas.
struct GrokButton_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Styles.spaceBackgroundGradient.edgesIgnoringSafeArea(.all)
            VStack(spacing: Styles.spacingMedium) {
                GrokButton(title: "Primary", icon: "star.fill", action: {})
                GrokButton(title: "Secondary", icon: "star", action: {}, isPrimary: false)
                GrokButton(title: "Full Width", icon: "star.fill", action: {}, isFullWidth: true)
            }
            .padding()
        }
        .preferredColorScheme(.dark)
    }
}

struct GrokSectionHeaderPreview: View {
    var body: some View {
        VStack {
            Text("Upcoming Launches")
                .grokSectionHeader()
            Text("Previous Launches")
                .grokSectionHeader()
        }
        .padding()
        .background(Styles.baseBackground)
    }
}
