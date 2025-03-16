    import SwiftUI

    struct RocketLoadingView: View {
        @Binding var loadingStage: RocketLaunchTrackerV2App.LoadingStage
        
        @State private var isAnimating = false
        @State private var rocketOffset: CGFloat = 0
        @State private var flameHeight: CGFloat = 5
        @State private var stars: [Star] = []
        @State private var messageOpacity: Double = 0
        @State private var currentMessage: String = ""
        
        private let starCount = 50
        
        struct Star: Identifiable {
            let id = UUID()
            var x: CGFloat
            var y: CGFloat
            var size: CGFloat
            var opacity: Double
            var speed: Double
        }
        
        var body: some View {
            ZStack {
                // Background with subtle gradient - use the exact same one as LaunchListView
                Styles.spaceBackgroundGradient
                    .edgesIgnoringSafeArea(.all)
                
                // Stars background
                ForEach(stars) { star in
                    Circle()
                        .fill(Color.white.opacity(star.opacity))
                        .frame(width: star.size, height: star.size)
                        .position(x: star.x, y: star.y + (isAnimating ? 200 * star.speed : 0))
                        .animation(
                            Animation.linear(duration: 3.5) // Slower, more subtle animation
                                .repeatForever(autoreverses: false)
                                .delay(Double.random(in: 0...0.5)),
                            value: isAnimating
                        )
                }
                
                // Rocket
                VStack(spacing: 60) {
                    ZStack {
                        // Flame
                        flameView
                            .offset(y: 25 + (isAnimating ? 2 : 0))
                        
                        // Rocket body
                        rocketBody
                    }
                    .offset(y: rocketOffset)
                    .animation(
                        // Gentler animation, less bouncy
                        Animation.easeInOut(duration: 1.8).repeatForever(autoreverses: true),
                        value: rocketOffset
                    )
                    .shadow(
                        color: Styles.cardShadow,
                        radius: Styles.shadowRadiusMedium,
                        x: 0,
                        y: Styles.shadowOffset.height
                    )
                    
                    // Loading message
                    VStack(spacing: Styles.spacingMedium) {
                        Text(currentMessage)
                            .font(Styles.subheaderFont) // Use the style guide font
                            .foregroundColor(Styles.textPrimary)
                            .opacity(messageOpacity)
                            .animation(Styles.easeInOut, value: messageOpacity)
                            .multilineTextAlignment(.center)
                        
                        // Animated dots
                        HStack(spacing: Styles.spacingTiny) {
                            ForEach(0..<3) { index in
                                Circle()
                                    .fill(Styles.highlightAccent) // Use the accent color from style guide
                                    .frame(width: 6, height: 6)
                                    .opacity(dotOpacity(for: index))
                                    .animation(
                                        Animation.easeInOut(duration: 0.8) // Slower animation
                                            .repeatForever()
                                            .delay(0.3 * Double(index)),
                                        value: isAnimating
                                    )
                            }
                        }
                        .padding(.top, Styles.paddingSmall)
                    }
                    .padding(.horizontal, Styles.paddingLarge)
                    .opacity(messageOpacity)
                }
            }
            .onAppear {
                setupStars()
                
                // Set initial message
                updateMessage()
                
                // Start gentle animations
                withAnimation(Animation.easeInOut(duration: 1.8).repeatForever(autoreverses: true)) {
                    rocketOffset = -15 // Less movement
                    flameHeight = 15
                    isAnimating = true
                }
                
                // Fade in message
                withAnimation(Animation.easeIn(duration: 0.8)) {
                    messageOpacity = 1
                }
            }
            .onChange(of: loadingStage) { _, newStage in
                // Fade out current message
                withAnimation(Animation.easeOut(duration: 0.5)) {
                    messageOpacity = 0
                }
                
                // Delay to allow fade out
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    // Update message
                    updateMessage()
                    
                    // Fade in new message
                    withAnimation(Animation.easeIn(duration: 0.5)) {
                        messageOpacity = 1
                    }
                }
            }
        }
        
        private func updateMessage() {
            currentMessage = loadingStage.rawValue
        }
        
        private func dotOpacity(for index: Int) -> Double {
            let baseDelay = 0.3 * Double(index)
            let duration = 0.8
            let t = fmod(Date().timeIntervalSince1970, duration * 3)
            let adjustedT = fmod(t + baseDelay, duration * 3)
            
            if adjustedT < duration {
                return 1.0
            } else {
                return 0.3
            }
        }
        
        private var rocketBody: some View {
            ZStack {
                // Rocket body
                Capsule()
                    .fill(Styles.elevatedSurface)
                    .frame(width: 20, height: 50)
                    .overlay(
                        Capsule()
                            .fill(Styles.glassEffect)
                    )
                    .overlay(
                        Capsule()
                            .stroke(Styles.glassHighlight, lineWidth: Styles.hairlineBorder)
                    )
                
                // Rocket nose
                Triangle()
                    .fill(Color(hex: "#1E1E1E"))
                    .frame(width: 20, height: 20)
                    .overlay(
                        Triangle()
                            .fill(Styles.glassEffect)
                    )
                    .overlay(
                        Triangle()
                            .stroke(Styles.glassHighlight, lineWidth: Styles.hairlineBorder)
                    )
                    .offset(y: -35)
                
                // Window
                Circle()
                    .fill(Styles.primaryAccent.opacity(0.8)) // Use accent color from style guide
                    .frame(width: 8, height: 8)
                    .offset(y: -10)
                
                // Fins
                HStack(spacing: 10) {
                    RocketFin(isLeft: true)
                        .fill(Styles.highlightAccent)
                        .frame(width: 10, height: 15)
                    
                    RocketFin(isLeft: false)
                        .fill(Styles.highlightAccent)
                        .frame(width: 10, height: 15)
                }
                .offset(y: 20)
                
                // Bottom cap
                Capsule()
                    .fill(Styles.highlightAccent)
                    .frame(width: 15, height: 5)
                    .offset(y: 25)
            }
        }
        
        private var flameView: some View {
            ZStack {
                // Main flame
                FlameShape()
                    .fill(
                        LinearGradient(
                            colors: [Styles.statusWarning, Styles.highlightAccent, Styles.textPrimary],
                            startPoint: .bottom,
                            endPoint: .top
                        )
                    )
                    .frame(width: 10, height: flameHeight)
                    .animation(
                        Animation.easeInOut(duration: 0.7) // Slower animation
                            .repeatForever(autoreverses: true),
                        value: flameHeight
                    )
                
                // Secondary flame
                FlameShape()
                    .fill(
                        LinearGradient(
                            colors: [Styles.statusError, Styles.statusWarning],
                            startPoint: .bottom,
                            endPoint: .top
                        )
                    )
                    .frame(width: 6, height: flameHeight * 0.7)
                    .animation(
                        Animation.easeInOut(duration: 0.7) // Slower animation
                            .repeatForever(autoreverses: true),
                        value: flameHeight
                    )
            }
        }
        
        private func setupStars() {
            stars = (0..<starCount).map { _ in
                Star(
                    x: CGFloat.random(in: 0...UIScreen.main.bounds.width),
                    y: CGFloat.random(in: 0...UIScreen.main.bounds.height),
                    size: CGFloat.random(in: 1...3),
                    opacity: Double.random(in: 0.3...1.0),
                    speed: Double.random(in: 0.3...0.8) // Slower speed for gentler motion
                )
            }
        }
    }

    // Custom shapes remain the same
    struct Triangle: Shape {
        func path(in rect: CGRect) -> Path {
            var path = Path()
            path.move(to: CGPoint(x: rect.midX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
            path.closeSubpath()
            return path
        }
    }

    struct RocketFin: Shape {
        var isLeft: Bool
        
        func path(in rect: CGRect) -> Path {
            var path = Path()
            if isLeft {
                path.move(to: CGPoint(x: rect.maxX, y: rect.minY))
                path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
                path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
            } else {
                path.move(to: CGPoint(x: rect.minX, y: rect.minY))
                path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
                path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
            }
            path.closeSubpath()
            return path
        }
    }

    struct FlameShape: Shape {
        func path(in rect: CGRect) -> Path {
            var path = Path()
            path.move(to: CGPoint(x: rect.minX, y: rect.minY))
            
            path.addCurve(
                to: CGPoint(x: rect.midX, y: rect.maxY),
                control1: CGPoint(x: rect.minX, y: rect.height * 0.33),
                control2: CGPoint(x: rect.midX - rect.width * 0.25, y: rect.height * 0.66)
            )
            
            path.addCurve(
                to: CGPoint(x: rect.maxX, y: rect.minY),
                control1: CGPoint(x: rect.midX + rect.width * 0.25, y: rect.height * 0.66),
                control2: CGPoint(x: rect.maxX, y: rect.height * 0.33)
            )
            
            path.closeSubpath()
            return path
        }
    }

    struct RocketLoadingView_Previews: PreviewProvider {
        static var previews: some View {
            RocketLoadingView(loadingStage: .constant(.fetching))
                .preferredColorScheme(.dark)
        }
    }
