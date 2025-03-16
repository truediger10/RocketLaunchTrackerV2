import SwiftUI
import Foundation

/// A collection of reusable, standardized UI components to improve consistency
/// throughout the app.
/// (Components.swift has been merged into this file; please update any references accordingly.)

// MARK: - Card Components

/// A standardized card container with consistent styling
struct StandardCard<Content: View>: View {
    var content: Content
    var padding: EdgeInsets = EdgeInsets(
        top: Styles.paddingStandard,
        leading: Styles.paddingStandard,
        bottom: Styles.paddingStandard,
        trailing: Styles.paddingStandard
    )
    var cornerRadius: CGFloat = Styles.cornerRadiusMedium
    var shadowRadius: CGFloat = Styles.shadowRadiusMedium
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .padding(padding)
            .background(Styles.cardSurface)
            .cornerRadius(cornerRadius)
            .shadow(
                color: Styles.shadowColor,
                radius: shadowRadius,
                x: 0,
                y: Styles.shadowOffset.height
            )
    }
}

/// A card with header and content sections for consistent display of information
struct SectionCard<Content: View>: View {
    var title: String
    var iconName: String?
    var content: Content
    
    init(title: String, iconName: String? = nil, @ViewBuilder content: () -> Content) {
        self.title = title
        self.iconName = iconName
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: Styles.paddingMedium) {
            // Section header
            HStack(spacing: Styles.paddingSmall) {
                if let icon = iconName {
                    Image(systemName: icon)
                        .foregroundColor(Styles.highlightAccent)
                        .font(.system(size: Styles.fontSmall))
                }
                
                Text(title)
                    .font(.system(size: Styles.fontSmall, weight: .medium))
                    .tracking(1.2)
                    .foregroundColor(Styles.textTertiary)
            }
            .padding(.horizontal, Styles.paddingTiny)
            
            // Content area
            content
                .padding(Styles.paddingMedium)
                .background(Styles.deepBackground.opacity(0.6))
                .cornerRadius(Styles.cornerRadiusMedium)
                .overlay(
                    RoundedRectangle(cornerRadius: Styles.cornerRadiusMedium)
                        .stroke(Color.white.opacity(0.1), lineWidth: Styles.hairlineBorder)
                )
        }
        .padding(.horizontal, Styles.paddingStandard)
    }
}

/// Ensures consistent image presentation with gradient overlays for readability.
struct StandardImageModifier: ViewModifier {
    var height: CGFloat
    var cornerRadius: CGFloat = Styles.cornerRadiusMedium
    var addGradientOverlay: Bool = true
    
    func body(content: Content) -> some View {
        content
            .frame(height: height)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .overlay(
                Group {
                    if addGradientOverlay {
                        VStack {
                            Spacer()
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.black.opacity(0.7),
                                    Color.black.opacity(0.3),
                                    Color.clear
                                ]),
                                startPoint: .bottom,
                                endPoint: .top
                            )
                            .frame(height: 80)
                            .frame(maxWidth: .infinity, alignment: .bottomLeading)
                            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
                        }
                    }
                }
            )
    }
}

extension View {
    /// Simplified application of consistent image styling.
    func standardImage(height: CGFloat, cornerRadius: CGFloat = Styles.cornerRadiusMedium, addGradientOverlay: Bool = true) -> some View {
        self.modifier(StandardImageModifier(height: height, cornerRadius: cornerRadius, addGradientOverlay: addGradientOverlay))
    }
}

// MARK: - Button Components

/// A secondary button with outlined style
struct SecondaryButton: View {
    var title: String
    var iconName: String?
    var action: () -> Void
    var isFullWidth: Bool = true
    var isDisabled: Bool = false
    
    var body: some View {
        Button(action: {
            if !isDisabled {
                action()
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            }
        }) {
            HStack {
                if let icon = iconName {
                    Image(systemName: icon)
                        .font(.system(size: 18))
                        .foregroundColor(isDisabled ? Styles.textTertiary : Styles.highlightAccent)
                }
                
                Text(title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(isDisabled ? Styles.textTertiary : Styles.highlightAccent)
            }
            .padding(.vertical, 12)
            .frame(maxWidth: isFullWidth ? .infinity : nil)
            .padding(.horizontal, isFullWidth ? Styles.paddingStandard : Styles.paddingLarge)
            .background(Styles.cardSurface)
            .cornerRadius(Styles.cornerRadiusMedium)
            .overlay(
                RoundedRectangle(cornerRadius: Styles.cornerRadiusMedium)
                    .stroke(isDisabled ? Styles.textTertiary : Styles.highlightAccent, lineWidth: 1)
            )
        }
        .buttonStyle(ScaleButtonStyle())
        .disabled(isDisabled)
    }
}

// MARK: - Input Components

/// A standardized text field with consistent styling and placeholder handling
struct StandardTextField: View {
    var placeholder: String
    @Binding var text: String
    var iconName: String?
    var isSecure: Bool = false
    var keyboardType: UIKeyboardType = .default
    var submitLabel: SubmitLabel = .done
    var onSubmit: (() -> Void)? = nil
    
    @FocusState private var isFocused: Bool
    
    var body: some View {
        HStack(spacing: Styles.paddingSmall) {
            if let icon = iconName {
                Image(systemName: icon)
                    .foregroundColor(isFocused ? Styles.highlightAccent : Styles.textTertiary)
                    .frame(width: 24)
            }
            
            Group {
                if isSecure {
                    SecureField("", text: $text)
                        .focused($isFocused)
                        .submitLabel(submitLabel)
                } else {
                    TextField("", text: $text)
                        .focused($isFocused)
                        .keyboardType(keyboardType)
                        .submitLabel(submitLabel)
                }
            }
            .font(.system(size: Styles.fontMedium))
            .foregroundColor(Styles.textPrimary)
            .placeholder(when: text.isEmpty) {
                Text(placeholder)
                    .foregroundColor(Styles.textTertiary)
            }
            
            if !text.isEmpty {
                Button(action: {
                    text = ""
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(Styles.textTertiary)
                        .font(.system(size: 16))
                }
                .buttonStyle(ScaleButtonStyle())
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, Styles.paddingMedium)
        .background(Styles.inputBackground)
        .cornerRadius(Styles.cornerRadiusMedium)
        .overlay(
            RoundedRectangle(cornerRadius: Styles.cornerRadiusMedium)
                .stroke(isFocused ? Styles.highlightAccent : Styles.divider, lineWidth: Styles.hairlineBorder)
        )
        .onSubmit {
            onSubmit?()
        }
    }
}

// MARK: - List and Grid Components

/// A standardized list row with consistent styling
struct StandardListRow: View {
    var title: String
    var subtitle: String?
    var iconName: String?
    var iconColor: Color = Styles.highlightAccent
    var trailingText: String?
    var showChevron: Bool = true
    var action: () -> Void
    
    var body: some View {
        Button(action: {
            action()
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }) {
            HStack {
                if let icon = iconName {
                    Image(systemName: icon)
                        .foregroundColor(iconColor)
                        .font(.system(size: 18))
                        .frame(width: 24, height: 24)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: Styles.fontMedium, weight: .medium))
                        .foregroundColor(Styles.textPrimary)
                    
                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(.system(size: Styles.fontSmall))
                            .foregroundColor(Styles.textSecondary)
                    }
                }
                
                Spacer()
                
                if let trailing = trailingText {
                    Text(trailing)
                        .font(.system(size: Styles.fontSmall, weight: .medium))
                        .foregroundColor(Styles.textSecondary)
                }
                
                if showChevron {
                    Image(systemName: "chevron.right")
                        .foregroundColor(Styles.textTertiary)
                        .font(.system(size: 14))
                }
            }
            .padding(.vertical, 12)
            .padding(.horizontal, Styles.paddingMedium)
            .background(Styles.cardSurface)
            .cornerRadius(Styles.cornerRadiusMedium)
            .overlay(
                RoundedRectangle(cornerRadius: Styles.cornerRadiusMedium)
                    .stroke(Color.white.opacity(0.1), lineWidth: Styles.hairlineBorder)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Status and Feedback Components

/// A standardized badge with consistent styling for statuses and tags
struct StatusBadge: View {
    enum BadgeStyle {
        case success, warning, error, info, neutral
        
        var color: Color {
            switch self {
            case .success: return Styles.statusSuccess
            case .warning: return Styles.statusWarning
            case .error: return Styles.statusError
            case .info: return Styles.highlightAccent
            case .neutral: return Styles.textTertiary
            }
        }
        
        var iconName: String? {
            switch self {
            case .success: return "checkmark.circle.fill"
            case .warning: return "exclamationmark.triangle.fill"
            case .error: return "xmark.circle.fill"
            case .info: return "info.circle.fill"
            case .neutral: return nil
            }
        }
    }
    
    var text: String
    var style: BadgeStyle
    var showIcon: Bool = true
    
    var body: some View {
        HStack(spacing: 4) {
            if showIcon, let iconName = style.iconName {
                Image(systemName: iconName)
                    .font(.system(size: 12))
                    .foregroundColor(.white)
            }
            
            Text(text)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(style.color)
        )
    }
}

/// A consistent toast notification for user feedback
struct ToastMessage: View {
    var message: String
    var iconName: String
    var style: StatusBadge.BadgeStyle = .success
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: iconName)
                .font(.system(size: 20))
                .foregroundColor(style.color)
            
            Text(message)
                .font(Styles.bodyFont)
                .foregroundColor(Styles.textPrimary)
            
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: Styles.cornerRadiusMedium)
                .fill(Styles.cardSurface.opacity(0.95))
                .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 5)
        )
        .padding(.horizontal, 20)
        .padding(.bottom, 20)
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }
}

// MARK: - Header Components

/// A consistent section header with a title and optional button
struct SectionHeader: View {
    var title: String
    var buttonTitle: String?
    var buttonAction: (() -> Void)?
    
    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(Styles.textSecondary)
                .tracking(1.2)
            
            Spacer()
            
            if let buttonTitle = buttonTitle, let action = buttonAction {
                Button(action: action) {
                    HStack(spacing: 4) {
                        Text(buttonTitle)
                            .font(Font.system(size: 14, weight: .medium))
                            .foregroundColor(Styles.highlightAccent)
                        
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12))
                            .foregroundColor(Styles.highlightAccent)
                    }
                }
                .buttonStyle(ScaleButtonStyle())
            }
        }
        .padding(.horizontal, Styles.paddingStandard)
    }
}

// MARK: - Performance-optimized Components

/// A low-impact glassmorphic effect that's more performant than the full version
struct LightweightGlassmorphicView<Content: View>: View {
    var tint: Color = .white
    var intensity: Double = 0.15
    var cornerRadius: CGFloat = 16
    
    @ViewBuilder let content: Content
    
    var body: some View {
        content
            .padding()
            .background(
                ZStack {
                    Color.black.opacity(intensity)
                    
                    // Simple gradient instead of complex blur
                    LinearGradient(
                        gradient: Gradient(colors: [
                            tint.opacity(0.05),
                            tint.opacity(0.02)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                }
            )
            .cornerRadius(cornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(tint.opacity(0.2), lineWidth: 0.5)
            )
    }
}

// MARK: - Helper Method Extensions

extension View {
    /// Applies a shadow with the app's standard style
    func standardShadow(radius: CGFloat = Styles.shadowRadiusMedium) -> some View {
        self.shadow(
            color: Styles.shadowColor,
            radius: radius,
            x: 0,
            y: Styles.shadowOffset.height
        )
    }
    
    /// Applies a standard card style to any view
    func standardCard(padding: EdgeInsets? = nil) -> some View {
        let cardPadding = padding ?? EdgeInsets(
            top: Styles.paddingStandard,
            leading: Styles.paddingStandard,
            bottom: Styles.paddingStandard,
            trailing: Styles.paddingStandard
        )
        
        return self
            .padding(cardPadding)
            .background(Styles.cardSurface)
            .cornerRadius(Styles.cornerRadiusMedium)
            .standardShadow()
    }
    
    /// Applies a lightweight parallax effect that's more performance-friendly
    func lightweightParallax(magnitude: CGFloat = 5) -> some View {
        self.modifier(LightweightParallaxEffect(magnitude: magnitude))
    }
}

/// A more performance-optimized parallax effect
struct LightweightParallaxEffect: ViewModifier {
    let magnitude: CGFloat
    @State private var offset = CGSize.zero
    
    func body(content: Content) -> some View {
        content
            .offset(x: offset.width, y: offset.height)
            .onAppear {
                // Simplified animation with fewer parameters and less resource usage
                withAnimation(
                    Animation
                        .easeInOut(duration: 3)
                        .repeatForever(autoreverses: true)
                ) {
                    offset = CGSize(width: magnitude * 0.3, height: magnitude * 0.5)
                }
            }
    }
}
