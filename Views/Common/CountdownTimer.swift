import SwiftUI

struct CountdownTimer: View {
    let targetDate: Date
    let isCompact: Bool
    let enablePulseUnderOneHour: Bool

    @State private var timeRemaining: TimeInterval = 0
    @State private var isAnimating = false
    @State private var pulsate = false
    @State private var digitChanged = false
    
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    // MARK: - Computed Properties
    private var days: Int { Int(timeRemaining / 86400) }
    private var hours: Int { Int(timeRemaining.truncatingRemainder(dividingBy: 86400) / 3600) }
    private var minutes: Int { Int(timeRemaining.truncatingRemainder(dividingBy: 3600) / 60) }
    private var seconds: Int { Int(timeRemaining.truncatingRemainder(dividingBy: 60)) }

    private var secondsProgress: Double { Double(seconds) / 60.0 }
    private var minutesProgress: Double { Double(minutes) / 60.0 }
    private var hoursProgress: Double { Double(hours) / 24.0 }
    private var daysProgress: Double { Double(days) / 14.0 } // Max 2 weeks for progress

    /// Color logic: Use highlightAccent for all timers.
    private var timeColor: Color {
        Styles.highlightAccent
    }
    
    // Secondary color for backgrounds and subtle elements
    private var secondaryColor: Color {
        timeColor.opacity(0.15)
    }

    init(
        targetDate: Date,
        isCompact: Bool,
        enablePulseUnderOneHour: Bool = true
    ) {
        self.targetDate = targetDate
        self.isCompact = isCompact
        self.enablePulseUnderOneHour = enablePulseUnderOneHour
    }

    // MARK: - Body
    var body: some View {
        Group {
            if isCompact {
                compactView
            } else {
                // Always use the ring-based approach for all time periods
                if timeRemaining <= 0 {
                    launchedView
                } else {
                    VStack(spacing: Styles.spacingSmall) {
                        ringCountdownDigits
                        Text(getStatusText())
                            .font(Styles.captionFont)
                            .foregroundColor(Styles.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityAddTraits(.updatesFrequently)
        .onAppear {
            updateTimeRemaining()
            isAnimating = true

            // Start pulsing only if < 1 hour, if enabled and reduce motion is off
            if enablePulseUnderOneHour && !reduceMotion {
                withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                    pulsate = (timeRemaining < 3600 && timeRemaining > 0)
                }
            }
        }
        .onReceive(timer) { _ in
            let oldTime = timeRemaining
            updateTimeRemaining()

            if oldTime != timeRemaining {
                // Only trigger digit change animation if not already animating
                if !digitChanged {
                    digitChanged = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        digitChanged = false
                    }
                }
            }
            
            if enablePulseUnderOneHour && !reduceMotion {
                pulsate = (timeRemaining < 3600 && timeRemaining > 0)
            }
        }
    }

    // MARK: - Accessibility Label
    private var accessibilityLabel: String {
        if timeRemaining <= 0 {
            return "Launch has already occurred"
        } else {
            return "\(days) days, \(hours) hours, \(minutes) minutes, and \(seconds) seconds until launch"
        }
    }

    // MARK: - Compact View
    /// Minimal countdown for small spaces with Grok styling
    private var compactView: some View {
        HStack(spacing: Styles.spacingSmall) {
            Image(systemName: "clock")
                .foregroundColor(timeColor)
                .font(.system(size: Styles.iconSizeSmall))

            if timeRemaining <= 0 {
                Text("Launched")
                    .font(Styles.smallCaptionFont)
                    .foregroundColor(Styles.textPrimary)
            } else {
                Text(String(format: "%dd %dh %dm", days, hours, minutes))
                    .font(Styles.smallCaptionFont)
                    .foregroundColor(Styles.textPrimary)
                    .opacity(pulsate && !reduceMotion ? 0.7 : 1.0)
                    .scaleEffect(pulsate && !reduceMotion ? 1.05 : 1.0)
            }
        }
        .padding(.horizontal, Styles.paddingMedium)
        .padding(.vertical, Styles.paddingTiny)
        .background(
            Capsule()
                .fill(Styles.elevatedSurface)
                .overlay(
                    Capsule()
                        .stroke(timeColor.opacity(0.3), lineWidth: Styles.hairlineBorder)
                )
        )
        .shadow(color: timeColor.opacity(0.2), radius: Styles.shadowRadiusSmall, x: 0, y: 0)
    }

    // MARK: - Ring-based countdown view - Grok-inspired
    private var ringCountdownDigits: some View {
        HStack(spacing: Styles.spacingMedium) {
            ringDigit(value: days, unit: "DAYS", progress: daysProgress)
            ringDigit(value: hours, unit: "HOURS", progress: hoursProgress)
            ringDigit(value: minutes, unit: "MINS", progress: minutesProgress)
            ringDigit(value: seconds, unit: "SECS", progress: secondsProgress)
        }
        .padding(.horizontal, Styles.paddingMedium)
        .padding(.vertical, Styles.paddingMedium)
        .background(
            RoundedRectangle(cornerRadius: Styles.cornerRadiusMedium)
                .fill(Styles.deepBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: Styles.cornerRadiusMedium)
                        .stroke(timeColor.opacity(0.2), lineWidth: Styles.hairlineBorder)
                )
                .shadow(color: timeColor.opacity(0.1), radius: Styles.shadowRadiusMedium, x: 0, y: Styles.shadowOffset.height)
        )
    }

    private func ringDigit(
        value: Int,
        unit: String,
        progress: Double = 0
    ) -> some View {
        ZStack {
            // Background circle with subtle glow
            Circle()
                .fill(Styles.deepBackground)
                .overlay(
                    Circle()
                        .fill(secondaryColor)
                        .blur(radius: Styles.blurLight)
                        .opacity(0.5)
                )
                .frame(width: 70, height: 70)
            
            // Track circle
            Circle()
                .stroke(lineWidth: Styles.hairlineBorder * 2)
                .opacity(0.2)
                .foregroundColor(timeColor)
            
            // Progress circle with glow
            Circle()
                .trim(from: 0.0, to: CGFloat(min(progress, 1.0)))
                .stroke(style: StrokeStyle(lineWidth: Styles.hairlineBorder * 2, lineCap: .round, lineJoin: .round))
                .foregroundColor(timeColor)
                .rotationEffect(Angle(degrees: 270.0))
                .shadow(color: timeColor.opacity(0.5), radius: Styles.shadowRadiusSmall, x: 0, y: 0)
                .animation(Styles.easeOut, value: progress)

            VStack(spacing: Styles.spacingTiny) {
                // Digit with animation
                Text("\(value)")
                    .font(.system(size: Styles.fontLarge, weight: Styles.weightBold, design: .rounded))
                    .foregroundColor(Styles.textPrimary)
                    .frame(minWidth: 40)
                    .scaleEffect(digitChanged && timeRemaining < 3600 ? 1.2 : 1.0)
                    .animation(
                        Styles.spring,
                        value: (digitChanged && timeRemaining < 3600)
                    )
                
                // Unit label
                Text(unit)
                    .font(Styles.smallCaptionFont)
                    .foregroundColor(Styles.textTertiary)
            }
            .padding(.vertical, Styles.paddingTiny)
            .padding(.horizontal, Styles.paddingSmall)
        }
        .frame(width: 72, height: 72)
    }

    /// Common "Launched" section with Grok styling
    private var launchedView: some View {
        HStack(spacing: Styles.spacingMedium) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(Styles.statusSuccess)
                .font(.system(size: Styles.iconSizeLarge))
                .shadow(color: Styles.statusSuccess.opacity(0.5), radius: Styles.shadowRadiusSmall, x: 0, y: 0)
            
            Text("LAUNCHED")
                .font(.system(size: Styles.fontLarge, weight: Styles.weightBold))
                .foregroundColor(Styles.textPrimary)
        }
        .padding(.horizontal, Styles.paddingLarge)
        .padding(.vertical, Styles.paddingMedium)
        .background(
            RoundedRectangle(cornerRadius: Styles.cornerRadiusMedium)
                .fill(Styles.deepBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: Styles.cornerRadiusMedium)
                        .stroke(Styles.statusSuccess.opacity(0.3), lineWidth: Styles.hairlineBorder)
                )
                .shadow(color: Styles.statusSuccess.opacity(0.2), radius: Styles.shadowRadiusMedium, x: 0, y: Styles.shadowOffset.height)
        )
    }

    // MARK: - Helpers
    private func updateTimeRemaining() {
        timeRemaining = max(0, targetDate.timeIntervalSinceNow)
    }
    
    private func getStatusText() -> String {
        if timeRemaining <= 0 {
            return "The mission has launched"
        } else if timeRemaining < 60 {
            return "Launching any moment now!"
        } else if timeRemaining < 3600 {
            return "Countdown is in final minutes!"
        } else if timeRemaining < 86400 {
            return "Launch is within 24 hours"
        } else if timeRemaining < 86400 * 7 {
            return "Launch is this week"
        } else {
            return "Counting down to launch day"
        }
    }
}

// MARK: - PREVIEWS
struct CountdownTimer_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Styles.spaceBackgroundGradient.edgesIgnoringSafeArea(.all)
            VStack(spacing: Styles.spacingLarge) {
                // Example 1: 3 days => now shows ring approach
                CountdownTimer(
                    targetDate: Date().addingTimeInterval(86400 * 3 + 3600),
                    isCompact: false
                )
                
                // Example 2: 12 hours => ring approach
                CountdownTimer(
                    targetDate: Date().addingTimeInterval(3600 * 12),
                    isCompact: false
                )

                // Example 3: 30 minutes => ring approach + red color + digit bounce
                CountdownTimer(
                    targetDate: Date().addingTimeInterval(1800),
                    isCompact: false
                )

                // Example 4: Already launched
                CountdownTimer(
                    targetDate: Date().addingTimeInterval(-3600),
                    isCompact: true
                )

                // Example 5: Compact with 2 days to go
                CountdownTimer(
                    targetDate: Date().addingTimeInterval(86400 * 2 + 3600 * 5),
                    isCompact: true
                )
            }
            .padding(Styles.paddingStandard)
        }
        .preferredColorScheme(.dark)
    }
}