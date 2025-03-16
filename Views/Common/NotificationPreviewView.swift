import SwiftUI
import UserNotifications

struct NotificationPreviewView: View {
    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [Styles.cardSurface.opacity(0.9), Styles.textTertiary.opacity(0.3)]),
                startPoint: .top,
                endPoint: .bottom
            )
            .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: Styles.spacingLarge) {
                Text("Notification Preview")
                    .font(Styles.buttonFont)
                    .foregroundColor(Styles.textPrimary)

                Button(action: {
                    scheduleTestNotification()
                }) {
                    Text("Schedule Test Notification")
                        .font(Styles.buttonFont)
                        .foregroundColor(.black)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Styles.highlightAccent)
                        .cornerRadius(Styles.cornerRadiusMedium)
                }
                .buttonStyle(ScaleButtonStyle())

                Text("Tap the button to schedule a test notification. Check your console for log messages.")
                    .font(Styles.captionFont)
                    .foregroundColor(Styles.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Styles.paddingMedium)
            }
            .padding(Styles.paddingLarge)
            .background(Styles.cardSurface)
            .cornerRadius(Styles.cornerRadiusMedium)
            .shadow(color: Styles.cardShadow, radius: Styles.shadowRadiusMedium, x: 0, y: Styles.shadowOffset.height)
        }
    }
    
    private func scheduleTestNotification() {
        let content = UNMutableNotificationContent()
        content.title = "Test Notification"
        content.body = "This is a test notification."
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 10, repeats: false)
        let request = UNNotificationRequest(identifier: "test_notification", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Failed to schedule test notification: \(error.localizedDescription)")
            } else {
                print("Test notification scheduled")
            }
        }
    }
}

struct NotificationPreviewView_Previews: PreviewProvider {
    static var previews: some View {
        NotificationPreviewView()
            .preferredColorScheme(.dark)
            .background(Styles.spaceBackgroundGradient.edgesIgnoringSafeArea(.all))
    }
}
