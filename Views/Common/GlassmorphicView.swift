import SwiftUI

/// A view modifier that applies a glassmorphic effect in the style of Grok UI
struct GlassmorphicStyle: ViewModifier {
    var cornerRadius: CGFloat = 20
    var opacity: Double = 0.65
    var blurRadius: CGFloat = 10
    var saturation: Double = 1.0
    var tint: Color = .white
    var borderWidth: CGFloat = 0.5
    var borderColor: Color = Color.white.opacity(0.2)
    
    func body(content: Content) -> some View {
        content
            .background(
                ZStack {
                    // Base layer - dark with transparency
                    Color.black.opacity(opacity)
                    
                    // Subtle glass effect overlay
                    Color.white.opacity(0.05)
                    
                    // Optional subtle gradient for depth
                    LinearGradient(
                        gradient: Gradient(colors: [
                            tint.opacity(0.05),
                            tint.opacity(0.02),
                            Color.clear
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                }
            )
            .cornerRadius(cornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(borderColor, lineWidth: borderWidth)
            )
    }
}

/// A container view with a glassmorphic effect like Grok UI
struct GlassmorphicView<Content: View>: View {
    var tint: Color = .white
    var intensity: Double = 0.65
    var cornerRadius: CGFloat = 20
    
    @ViewBuilder let content: Content
    
    var body: some View {
        content
            .modifier(GlassmorphicStyle(
                cornerRadius: cornerRadius,
                opacity: intensity,
                blurRadius: 10,
                saturation: 1.0,
                tint: tint,
                borderWidth: 0.5,
                borderColor: tint.opacity(0.2)
            ))
    }
}

// Convenience extension for any view
extension View {
    func glassmorphic(
        tint: Color = .white,
        intensity: Double = 0.65,
        cornerRadius: CGFloat = 20
    ) -> some View {
        self.modifier(GlassmorphicStyle(
            cornerRadius: cornerRadius,
            opacity: intensity,
            blurRadius: 10,
            saturation: 1.0,
            tint: tint,
            borderWidth: 0.5,
            borderColor: tint.opacity(0.2)
        ))
    }
    
    // Add a variant specifically for Grok-style cards
    func grokCard(
        cornerRadius: CGFloat = 20
    ) -> some View {
        self.padding()
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(Color.black.opacity(0.65))
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .fill(Color.white.opacity(0.05))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .stroke(Color.white.opacity(0.15), lineWidth: 0.5)
                    )
                    .shadow(color: Color.black.opacity(0.3), radius: 15, x: 0, y: 8)
            )
    }
    
    // Add a variant for Grok-style controls
    func grokControl(
        cornerRadius: CGFloat = 20,
        highlightBorder: Bool = false,
        highlightColor: Color = Styles.primaryAccent
    ) -> some View {
        self.background(
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(Color.black.opacity(0.75))
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .stroke(
                            highlightBorder ?
                                highlightColor.opacity(0.5) :
                                Color.white.opacity(0.15),
                            lineWidth: highlightBorder ? 1.0 : 0.5
                        )
                )
        )
    }
}

// Preview
struct GlassmorphicView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            // Background
            LinearGradient(
                gradient: Gradient(colors: [.black, Color(hex: "#141414")]),
                startPoint: .top,
                endPoint: .bottom
            )
            .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 20) {
                // Basic glassmorphic card
                GlassmorphicView {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Glassmorphic Card")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        Text("This card has a subtle glass effect with minimum visual noise")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    .padding(20)
                }
                .frame(height: 100)
                .padding(.horizontal, 20)
                
                // Grok-style card
                VStack(alignment: .leading, spacing: 10) {
                    Text("Grok-Style Card")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Text("This uses the grokCard modifier for a Grok-like appearance")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                .padding(20)
                .grokCard()
                .frame(height: 100)
                .padding(.horizontal, 20)
                
                // Grok-style control with highlight
                HStack {
                    Text("Highlighted Control")
                        .foregroundColor(.white)
                        .padding()
                }
                .frame(width: 200, height: 50)
                .grokControl(highlightBorder: true)
                
                // Grok-style control without highlight
                HStack {
                    Text("Standard Control")
                        .foregroundColor(.white)
                        .padding()
                }
                .frame(width: 200, height: 50)
                .grokControl()
            }
            .padding()
        }
        .preferredColorScheme(.dark)
    }
}