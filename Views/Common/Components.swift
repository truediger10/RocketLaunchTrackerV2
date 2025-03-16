import SwiftUI

/// A collection of reusable UI components for the app
struct LoadingView: View {
    var body: some View {
        ProgressView()
            .progressViewStyle(CircularProgressViewStyle(tint: Styles.highlightAccent))
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

/// Displays an error message with a retry button
struct ErrorView: View {
    let message: String
    let retryAction: () -> Void

    var body: some View {
        VStack {
            Text("Error: \(message)")
                .font(.system(size: Styles.fontMedium))
                .foregroundColor(Styles.highlightAccent)
            Button(action: retryAction) {
                Text("Retry")
                    .font(.system(size: Styles.fontMedium, weight: Styles.weightMedium))
                    .foregroundColor(.black)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Styles.highlightAccent)
                    .cornerRadius(Styles.cornerRadiusMedium)
            }
            .buttonStyle(ScaleButtonStyle())
        }
        .padding(Styles.paddingMedium)
    }
}

/// A standardized button with rounded corners
struct RoundedButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: Styles.fontMedium, weight: Styles.weightMedium))
                .foregroundColor(.black)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Styles.highlightAccent)
                .cornerRadius(Styles.cornerRadiusMedium)
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

/// A button with a glowing effect, ideal for call-to-action buttons
struct GlowingButton: View {
    let title: String
    let icon: String?
    let color: Color
    let action: () -> Void
    
    @State private var isAnimating = false
    
    init(title: String, icon: String? = nil, color: Color = Styles.highlightAccent, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.color = color
        self.action = action
    }
    
    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                isAnimating = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    isAnimating = false
                }
            }
            
            action()
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        }) {
            HStack {
                if let iconName = icon {
                    Image(systemName: iconName)
                        .font(.system(size: 18))
                        .foregroundColor(.black)
                }
                
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.black)
            }
            .padding(.vertical, Styles.paddingMedium)
            .frame(maxWidth: .infinity)
            .background(
                ZStack {
                    // Base gradient
                    LinearGradient(
                        gradient: Gradient(colors: [color, color.opacity(0.8)]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    
                    // Glow overlay
                    color
                        .opacity(0.5)
                        .blur(radius: isAnimating ? 12 : 8)
                        .scaleEffect(isAnimating ? 1.1 : 1.0)
                        .animation(
                            Animation.easeInOut(duration: 1.2)
                                .repeatForever(autoreverses: true),
                            value: isAnimating
                        )
                }
            )
            .cornerRadius(Styles.cornerRadiusMedium)
            .overlay(
                RoundedRectangle(cornerRadius: Styles.cornerRadiusMedium)
                    .stroke(color.opacity(0.6), lineWidth: 1)
            )
            .shadow(color: color.opacity(0.5), radius: isAnimating ? Styles.shadowRadiusMedium : Styles.shadowRadiusSmall, x: 0, y: 0)
            .scaleEffect(isAnimating ? 0.96 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
        .onAppear {
            withAnimation(Animation.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                isAnimating = true
            }
        }
    }
}

/// A row displaying a label and value
struct InfoRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: Styles.fontSmall))
                .foregroundColor(Styles.textTertiary)
            Spacer()
            Text(value)
                .font(.system(size: Styles.fontMedium))
                .foregroundColor(Styles.textPrimary)
        }
    }
}

/// A view to display X posts related to a launch
struct TweetFeedView: View {
    let launchName: String
    @State private var xPosts: [XPost] = []

    var body: some View {
        VStack(alignment: .leading, spacing: Styles.spacingSmall) {
            Text("Community X Posts")
                .font(.system(size: Styles.fontLarge, weight: Styles.weightSemibold))
                .foregroundColor(Styles.highlightAccent)
            ScrollView {
                LazyVStack(spacing: Styles.spacingMedium) {
                    ForEach(xPosts) { xPost in
                        HStack(alignment: .top, spacing: Styles.spacingSmall) {
                            Image(systemName: "person.circle.fill")
                                .foregroundColor(Styles.textTertiary)
                                .font(.system(size: 24))
                            VStack(alignment: .leading, spacing: Styles.spacingTiny) {
                                Text(xPost.username)
                                    .font(.system(size: Styles.fontMedium))
                                    .foregroundColor(Styles.textPrimary)
                                Text(xPost.text)
                                    .font(.system(size: Styles.fontMedium))
                                    .foregroundColor(Styles.textSecondary)
                                Text(xPost.createdAt.formatted(date: .abbreviated, time: .shortened))
                                    .font(.system(size: Styles.fontSmall))
                                    .foregroundColor(Styles.textTertiary)
                            }
                        }
                        .padding(.vertical, Styles.paddingSmall)
                        .padding(.horizontal, Styles.paddingMedium)
                        .background(Styles.cardSurface)
                        .cornerRadius(Styles.cornerRadiusMedium)
                    }
                }
            }
            .frame(height: 200)
        }
        .task {
            xPosts = await XService.shared.fetchXPosts(for: launchName)
        }
    }
}

/**
 Extension for View with a single placeholder method:
 
 - Parameters:
   - shouldShow: Whether placeholder should be shown.
   - alignment: The alignment for the placeholder overlay.
   - placeholder: A view builder returning placeholder content.
 
 - Returns: A modified view that conditionally overlays the placeholder.
 */
extension View {
    func placeholder<Content: View>(
        when shouldShow: Bool,
        alignment: Alignment = .leading,
        @ViewBuilder placeholder: () -> Content
    ) -> some View {
        ZStack(alignment: alignment) {
            if shouldShow {
                placeholder()
            }
            self
        }
    }
}

/// A custom segmented picker with animation and styling
struct SegmentedPicker<T: Hashable & Identifiable & CustomStringConvertible>: View {
    @Binding var selection: T
    let options: [T]
    var backgroundColor: Color = Styles.cardSurface
    var accentColor: Color = Styles.highlightAccent
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(options) { option in
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selection = option
                    }
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                }) {
                    Text(option.description)
                        .font(.system(size: 14, weight: selection == option ? .semibold : .regular))
                        .foregroundColor(selection == option ? .black : .white)
                        .padding(.vertical, Styles.paddingSmall)
                        .padding(.horizontal, Styles.paddingMedium)
                        .frame(maxWidth: .infinity)
                        .background(
                            ZStack {
                                if selection == option {
                                    accentColor
                                        .cornerRadius(Styles.cornerRadiusPill)
                                }
                            }
                        )
                        .contentShape(Rectangle())
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(Styles.paddingTiny)
        .background(backgroundColor)
        .cornerRadius(Styles.cornerRadiusPill)
    }
}