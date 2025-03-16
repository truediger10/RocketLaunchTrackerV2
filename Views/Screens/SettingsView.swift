import SwiftUI
import WebKit

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var notificationsEnabled = false
    @State private var isUpdatingPermissions = false
    @State private var showAbout = false
    @State private var showPrivacyPolicy = false
    @State private var darkMode = true

    var body: some View {
        NavigationView {
            ZStack {
                Styles.spaceBackgroundGradient
                    .edgesIgnoringSafeArea(.all)

                ScrollView {
                    VStack(spacing: Styles.spacingLarge) {
                        notificationsSection
                        appearanceSection
                        aboutSection
                        supportSection
                    }
                    .padding(.vertical, Styles.paddingStandard)
                }
            }
            .navigationBarHidden(true)
            .toolbar {
                // Top-right close button
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: Styles.iconSizeMedium))
                            .foregroundColor(Styles.textSecondary)
                    }
                }
            }
            .interactiveDismissDisabled(false) // Allows swipe down to dismiss
            .sheet(isPresented: $showAbout) {
                AboutView()
            }
            .sheet(isPresented: $showPrivacyPolicy) {
                SafariView(url: URL(string: "https://example.com/privacy")!)
            }
        }
    }
    struct SafariView: UIViewRepresentable {
        let url: URL

        func makeUIView(context: Context) -> WKWebView {
            WKWebView()
        }

        func updateUIView(_ uiView: WKWebView, context: Context) {
            uiView.load(URLRequest(url: url))
        }
    }
    
    private var notificationsSection: some View {
        VStack(alignment: .leading, spacing: Styles.spacingMedium) {
            Text("NOTIFICATIONS")
                .font(.system(size: Styles.fontTiny, weight: .medium))
                .tracking(1.2)
                .foregroundColor(Styles.textTertiary)
                .padding(.horizontal, Styles.paddingLarge)

            Toggle("Enable Launch Notifications", isOn: $notificationsEnabled)
                .toggleStyle(SwitchToggleStyle(tint: Styles.highlightAccent))
                .onChange(of: notificationsEnabled) { oldValue, newValue in
                    handleNotificationToggle(newValue)
                }
                .disabled(isUpdatingPermissions)
                .padding(.horizontal, Styles.paddingLarge)
                .padding(.vertical, Styles.paddingSmall)
                .font(Styles.bodyFont)
                .foregroundColor(Styles.textPrimary)

            Text("Get notified about upcoming rocket launches. Future updates will allow subscribing to specific launches.")
                .font(Styles.captionFont)
                .foregroundColor(Styles.textSecondary)
                .padding(.horizontal, Styles.paddingLarge)

            if isUpdatingPermissions {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: Styles.highlightAccent))
                    .padding(.horizontal, Styles.paddingLarge)
            }
        }
    }

    private var appearanceSection: some View {
        VStack(alignment: .leading, spacing: Styles.spacingMedium) {
            Text("APPEARANCE")
                .font(.system(size: Styles.fontTiny, weight: .medium))
                .tracking(1.2)
                .foregroundColor(Styles.textTertiary)
                .padding(.horizontal, Styles.paddingLarge)

            Toggle("Dark Mode (Currently Unavailable)", isOn: $darkMode)
                .toggleStyle(SwitchToggleStyle(tint: Styles.highlightAccent))
                .disabled(true)
                .padding(.horizontal, Styles.paddingLarge)
                .padding(.vertical, Styles.paddingSmall)
                .font(Styles.bodyFont)
                .foregroundColor(Styles.textPrimary)
        }
    }

    private var aboutSection: some View {
        VStack(alignment: .leading, spacing: Styles.spacingMedium) {
            Text("ABOUT")
                .font(.system(size: Styles.fontTiny, weight: .medium))
                .tracking(1.2)
                .foregroundColor(Styles.textTertiary)
                .padding(.horizontal, Styles.paddingLarge)

            Button {
                showAbout = true
            } label: {
                settingRow(title: "About RocketLaunchTracker", value: "Version 1.0", icon: "info.circle")
            }
            .buttonStyle(ScaleButtonStyle())

            Button {
                showPrivacyPolicy = true
            } label: {
                settingRow(title: "Privacy Policy", icon: "lock")
            }
            .buttonStyle(ScaleButtonStyle())
        }
    }

    private var supportSection: some View {
        VStack(alignment: .leading, spacing: Styles.spacingMedium) {
            Text("SUPPORT")
                .font(.system(size: Styles.fontTiny, weight: .medium))
                .tracking(1.2)
                .foregroundColor(Styles.textTertiary)
                .padding(.horizontal, Styles.paddingLarge)

            Button {
                if let url = URL(string: "mailto:troy.ruediger@gmail.com") {
                    UIApplication.shared.open(url)
                }
            } label: {
                settingRow(title: "Share Your Ideas", icon: "envelope")
            }
            .buttonStyle(ScaleButtonStyle())
        }
    }

    private func settingRow(title: String, value: String? = nil, valueColor: Color = Styles.textSecondary, icon: String? = nil) -> some View {
        HStack {
            if let iconName = icon {
                Image(systemName: iconName)
                    .font(.system(size: Styles.iconSizeSmall))
                    .foregroundColor(Styles.highlightAccent)
                    .frame(width: Styles.iconSizeMedium)
            }
            Text(title)
                .font(Styles.bodyFont)
                .foregroundColor(Styles.textPrimary)
            Spacer()
            if let valueText = value {
                Text(valueText)
                    .font(Styles.captionFont)
                    .foregroundColor(valueColor)
            }
        }
        .padding(.horizontal, Styles.paddingLarge)
        .padding(.vertical, Styles.paddingMedium)
        .background(Styles.cardSurface)
        .cornerRadius(Styles.cornerRadiusMedium)
        .overlay(
            RoundedRectangle(cornerRadius: Styles.cornerRadiusMedium)
                .stroke(Styles.glassHighlight, lineWidth: Styles.hairlineBorder)
        )
        .grokShadow(radius: Styles.shadowRadiusSmall)
    }

    private func handleNotificationToggle(_ newValue: Bool) {
        isUpdatingPermissions = true
        if newValue {
            NotificationManager.shared.requestNotificationAuthorization { [self] granted, error in
                DispatchQueue.main.async {
                    if let error = error {
                        notificationsEnabled = false
                        showPermissionDeniedAlert()
                        print("Failed to request notification permissions: \(error.localizedDescription)")
                    } else {
                        notificationsEnabled = granted
                    }
                    isUpdatingPermissions = false
                }
            }
        } else {
            // Turn off notifications
            DispatchQueue.main.async {
                notificationsEnabled = false
                isUpdatingPermissions = false
                NotificationManager.shared.cancelAllNotifications()
                print("Notifications disabled.")
            }
        }
    }

    private func showPermissionDeniedAlert() {
        let alert = UIAlertController(
            title: "Notifications Disabled",
            message: "Please enable notifications in Settings to receive alerts.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Settings", style: .default) { _ in
            if let url = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(url)
            }
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            rootVC.present(alert, animated: true)
        }
    }
}
struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
            .preferredColorScheme(.dark)
    }
}
