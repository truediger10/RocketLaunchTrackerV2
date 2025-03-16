import SwiftUI
import Foundation

struct LaunchPreferencesView: View {
    let launch: Launch
    @ObservedObject var viewModel: LaunchViewModel
    @Environment(\.dismiss) var dismiss
    var initialTab: String? = nil
    
    // UI state
    @State private var notificationOffset: Int = 24
    @State private var isFavorite: Bool
    @State private var notificationsEnabled: Bool
    @State private var isProcessing = false
    @State private var showNotificationModal = false
    @State private var showCustomNotificationSheet = false
    @State private var customNotificationDate = Date()
    @State private var customNotificationMessage = ""
    @State private var notificationSound = "default"
    @State private var selectedNotificationTypes: [NotificationType] = [.launchDay]
    @State private var showSuccess = false
    @State private var successMessage = ""
    
    // Available notification sounds
    private let notificationSounds = ["default", "alert", "chime", "bell", "electronic"]
    
    // Available notification types
    enum NotificationType: String, CaseIterable, Identifiable {
        case launchDay = "Launch Day"
        case beforeLaunch = "Before Launch"
        case tMinus1Hour = "T-1 Hour"
        case tMinus24Hours = "T-24 Hours"
        case tMinus3Days = "T-3 Days"
        case tMinus7Days = "T-7 Days"
        case custom = "Custom Time"
        
        var id: String { self.rawValue }
        
        var iconName: String {
            switch self {
            case .launchDay: return "calendar.badge.clock"
            case .beforeLaunch: return "timer"
            case .tMinus1Hour: return "clock"
            case .tMinus24Hours: return "clock.badge.exclamationmark"
            case .tMinus3Days: return "calendar"
            case .tMinus7Days: return "calendar.badge"
            case .custom: return "calendar.badge.plus"
            }
        }
        
        var timeInterval: TimeInterval? {
            switch self {
            case .launchDay: return 0
            case .beforeLaunch: return 3600 * 6 // 6 hours before
            case .tMinus1Hour: return 3600
            case .tMinus24Hours: return 3600 * 24
            case .tMinus3Days: return 3600 * 24 * 3
            case .tMinus7Days: return 3600 * 24 * 7
            case .custom: return nil
            }
        }
    }
    
    init(launch: Launch, viewModel: LaunchViewModel, initialTab: String? = nil) {
        self.launch = launch
        self.viewModel = viewModel
        self.initialTab = initialTab
        _isFavorite = State(initialValue: launch.isFavorite)
        _notificationsEnabled = State(initialValue: launch.notificationsEnabled)
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                Styles.spaceBackgroundGradient
                    .edgesIgnoringSafeArea(.all)
                
                ScrollView {
                    VStack(spacing: Styles.spacingLarge) {
                        // Launch info card
                        launchInfoCard
                        
                        // Favorites toggle
                        favoriteSection
                        
                        // Notifications
                        notificationSection
                        
                        // Share section
                        shareSection
                        
                        // Extra space at bottom
                        Spacer(minLength: Styles.paddingExtraLarge)
                    }
                    .padding(.horizontal, Styles.paddingStandard)
                }
                
                // Processing overlay
                if isProcessing {
                    Color.black.opacity(0.4)
                        .edgesIgnoringSafeArea(.all)
                    
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: Styles.primaryAccent))
                        .scaleEffect(1.5)
                }
                
                // Success notification
                if showSuccess {
                    VStack {
                        Spacer()
                        
                        // Success toast
                        HStack(spacing: Styles.spacingMedium) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: Styles.iconSizeMedium))
                                .foregroundColor(Styles.successColor)
                            
                            Text(successMessage)
                                .font(Styles.bodyFont)
                                .foregroundColor(Styles.textPrimary)
                            
                            Spacer()
                        }
                        .padding(.horizontal, Styles.paddingStandard)
                        .padding(.vertical, Styles.paddingMedium)
                        .background(
                            RoundedRectangle(cornerRadius: Styles.cornerRadiusMedium)
                                .fill(Styles.cardSurface)
                                .overlay(
                                    RoundedRectangle(cornerRadius: Styles.cornerRadiusMedium)
                                        .stroke(Styles.glassHighlight, lineWidth: Styles.hairlineBorder)
                                )
                        )
                        .grokShadow(radius: Styles.shadowRadiusSmall)
                        .padding(.horizontal, Styles.paddingLarge)
                        .padding(.bottom, Styles.paddingLarge)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
            }
            .navigationTitle("Launch Preferences")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .font(Styles.bodyFont)
                        .foregroundColor(Styles.primaryAccent)
                }
            }
            .sheet(isPresented: $showNotificationModal) {
                notificationSettingsModal
            }
            .sheet(isPresented: $showCustomNotificationSheet) {
                customNotificationView
            }
            .onAppear {
                if let tab = initialTab {
                    switch tab {
                    case "notifications":
                        showNotificationModal = true
                    case "share":
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            shareLaunchInfo()
                        }
                    default:
                        break
                    }
                }
            }
        }
    }
    
    // MARK: - UI Components
    
    // Launch info at the top of the screen
    private var launchInfoCard: some View {
        VStack(spacing: Styles.spacingMedium) {
            // Launch image with reduced height
            LaunchImageView(
                launchId: launch.id,
                url: launch.image,
                style: .custom(height: 160, width: nil),
                fallbackMessage: "Image Unavailable"
            )
            .cornerRadius(Styles.cornerRadiusMedium)
            
            // Launch details
            VStack(alignment: .leading, spacing: Styles.spacingSmall) {
                Text(launch.missionName)
                    .font(Styles.titleFont)
                    .foregroundColor(Styles.textPrimary)
                
                HStack(spacing: Styles.spacingMedium) {
                    Label(launch.provider, systemImage: "building.2")
                        .font(Styles.captionFont)
                        .foregroundColor(Styles.textSecondary)
                    
                    Label(launch.formattedNet(style: .dateAndTime), systemImage: "calendar")
                        .font(Styles.captionFont)
                        .foregroundColor(Styles.textSecondary)
                }
                
                // Countdown
                HStack {
                    Spacer()
                    CountdownTimer(targetDate: launch.net, isCompact: false)
                    Spacer()
                }
                .padding(.top, Styles.paddingSmall)
            }
        }
    }
    
    // Favorite section with toggle
    private var favoriteSection: some View {
        VStack(alignment: .leading, spacing: Styles.spacingMedium) {
            HStack {
                Image(systemName: "star.fill")
                    .foregroundColor(Styles.primaryAccent)
                    .font(.system(size: Styles.iconSizeMedium))
                
                Text("Favorite")
                    .font(Styles.subheaderFont)
                    .foregroundColor(Styles.textPrimary)
                
                Spacer()
                
                // Use FavoriteButton with a custom style
                FavoriteButton(
                    launch: launch,
                    isCompact: false,
                    onStatusChanged: { newValue in
                        isFavorite = newValue
                        if newValue {
                            showSuccessToast("Added to favorites")
                        } else {
                            showSuccessToast("Removed from favorites")
                        }
                    }
                )
            }
            
            Text("Add this launch to your favorites for quick access")
                .font(Styles.captionFont)
                .foregroundColor(Styles.textSecondary)
                .padding(.leading, Styles.paddingLarge)
        }
        .padding(Styles.paddingStandard)
        .glassmorphicCard()
        .grokShadow(radius: Styles.shadowRadiusSmall)
    }
    
    // Notification section with toggle and options
    private var notificationSection: some View {
        VStack(alignment: .leading, spacing: Styles.spacingMedium) {
            HStack {
                Image(systemName: "bell.fill")
                    .foregroundColor(Styles.primaryAccent)
                    .font(.system(size: Styles.iconSizeMedium))
                
                Text("Notifications")
                    .font(Styles.subheaderFont)
                    .foregroundColor(Styles.textPrimary)
                
                Spacer()
                
                // Use NotificationButton with a custom style
                NotificationButton(
                    launch: launch,
                    isCompact: false,
                    onStatusChanged: { newValue in
                        notificationsEnabled = newValue
                        if newValue {
                            // Add default notification type if none selected
                            if !selectedNotificationTypes.contains(.launchDay) {
                                selectedNotificationTypes.append(.launchDay)
                            }
                            showSuccessToast("Notifications enabled")
                        } else {
                            // Clear notification types
                            selectedNotificationTypes.removeAll()
                            showSuccessToast("Notifications disabled")
                        }
                    }
                )
            }
            
            Text("Receive updates for this launch")
                .font(Styles.captionFont)
                .foregroundColor(Styles.textSecondary)
                .padding(.leading, Styles.paddingLarge)
            
            if notificationsEnabled {
                Divider()
                    .background(Styles.divider)
                    .padding(.top, Styles.paddingSmall)
                
                VStack(spacing: Styles.spacingMedium) {
                    if selectedNotificationTypes.isEmpty {
                        HStack {
                            Text("No notification times selected")
                                .font(Styles.captionFont)
                                .foregroundColor(Styles.textTertiary)
                                .padding(.leading, Styles.paddingLarge)
                            
                            Spacer()
                        }
                    } else {
                        // Display selected notification types with delete option
                        ForEach(selectedNotificationTypes, id: \.self) { type in
                            HStack {
                                Image(systemName: type.iconName)
                                    .foregroundColor(Styles.primaryAccent)
                                    .font(.system(size: Styles.iconSizeSmall))
                                
                                Text(type.rawValue)
                                    .font(Styles.captionFont)
                                    .foregroundColor(Styles.textSecondary)
                                
                                Spacer()
                                
                                // Delete button
                                Button(action: {
                                    withAnimation(Styles.spring) {
                                        selectedNotificationTypes.removeAll { $0 == type }
                                    }
                                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(Styles.textTertiary)
                                        .font(.system(size: Styles.iconSizeSmall))
                                }
                                .buttonStyle(ScaleButtonStyle())
                            }
                            .padding(.leading, Styles.paddingLarge)
                        }
                    }
                    
                    // Configure notifications button
                    Button(action: {
                        showNotificationModal = true
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    }) {
                        HStack {
                            Image(systemName: "gear")
                                .foregroundColor(.black)
                            Text("Configure Notifications")
                                .font(Styles.buttonFont)
                                .foregroundColor(.black)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Styles.paddingMedium)
                        .background(Styles.buttonGradient)
                        .cornerRadius(Styles.cornerRadiusMedium)
                    }
                    .buttonStyle(ScaleButtonStyle())
                    .padding(.top, Styles.paddingSmall)
                    
                    // Test notification button
                    Button(action: {
                        testNotification()
                    }) {
                        HStack {
                            Image(systemName: "bell.fill")
                                .foregroundColor(Styles.primaryAccent)
                            Text("Send Test Notification")
                                .font(Styles.buttonFont)
                                .foregroundColor(Styles.textPrimary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Styles.paddingMedium)
                        .background(
                            RoundedRectangle(cornerRadius: Styles.cornerRadiusMedium)
                                .stroke(Styles.primaryAccent, lineWidth: Styles.hairlineBorder)
                        )
                    }
                    .buttonStyle(ScaleButtonStyle())
                }
            }
        }
        .padding(Styles.paddingStandard)
        .background(
            RoundedRectangle(cornerRadius: Styles.cornerRadiusMedium)
                .fill(Styles.cardSurface)
                .overlay(
                    RoundedRectangle(cornerRadius: Styles.cornerRadiusMedium)
                        .stroke(Styles.glassHighlight, lineWidth: Styles.hairlineBorder)
                )
        )
        .grokShadow(radius: Styles.shadowRadiusSmall)
    }
    
    // Share section
    private var shareSection: some View {
        VStack(alignment: .leading, spacing: Styles.spacingMedium) {
            HStack {
                Image(systemName: "square.and.arrow.up")
                    .foregroundColor(Styles.primaryAccent)
                    .font(.system(size: Styles.iconSizeMedium))
                
                Text("Share")
                    .font(Styles.subheaderFont)
                    .foregroundColor(Styles.textPrimary)
                
                Spacer()
            }
            
            Text("Share this launch with others")
                .font(Styles.captionFont)
                .foregroundColor(Styles.textSecondary)
                .padding(.leading, Styles.paddingLarge)
            
            // Use ShareButton component
            ShareButton(
                launch: launch,
                isCompact: false,
                tint: .black,
                onShareComplete: {
                    showSuccessToast("Launch shared")
                }
            )
            .padding(.top, Styles.paddingSmall)
            .frame(maxWidth: .infinity)
            .background(Styles.buttonGradient)
            .cornerRadius(Styles.cornerRadiusMedium)
        }
        .padding(Styles.paddingStandard)
        .background(
            RoundedRectangle(cornerRadius: Styles.cornerRadiusMedium)
                .fill(Styles.cardSurface)
                .overlay(
                    RoundedRectangle(cornerRadius: Styles.cornerRadiusMedium)
                        .stroke(Styles.glassHighlight, lineWidth: Styles.hairlineBorder)
                )
        )
        .grokShadow(radius: Styles.shadowRadiusSmall)
    }
    
    // Notification settings modal
    private var notificationSettingsModal: some View {
        NavigationView {
            ZStack {
                Styles.spaceBackgroundGradient
                    .edgesIgnoringSafeArea(.all)
                
                ScrollView {
                    VStack(spacing: Styles.spacingLarge) {
                        // Notification types section
                        VStack(alignment: .leading, spacing: Styles.spacingMedium) {
                            Text("NOTIFICATION TIMING")
                                .grokSectionHeader()
                            
                            // Grid of notification type options
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: Styles.spacingMedium) {
                                ForEach(NotificationType.allCases) { type in
                                    if type != .custom {
                                        Button(action: {
                                            toggleNotificationType(type)
                                        }) {
                                            HStack(spacing: Styles.spacingSmall) {
                                                Image(systemName: type.iconName)
                                                    .foregroundColor(Styles.primaryAccent)
                                                    .font(.system(size: Styles.iconSizeSmall))
                                                
                                                Text(type.rawValue)
                                                    .font(Styles.captionFont)
                                                    .foregroundColor(Styles.textSecondary)
                                                
                                                Spacer()
                                                
                                                if selectedNotificationTypes.contains(type) {
                                                    Image(systemName: "checkmark")
                                                        .foregroundColor(Styles.primaryAccent)
                                                        .font(.system(size: Styles.fontTiny, weight: Styles.weightBold))
                                                }
                                            }
                                            .padding(Styles.paddingMedium)
                                            .background(
                                                RoundedRectangle(cornerRadius: Styles.cornerRadiusMedium)
                                                    .fill(selectedNotificationTypes.contains(type) ?
                                                          Styles.primaryAccent.opacity(0.2) : Styles.cardSurface)
                                                    .overlay(
                                                        RoundedRectangle(cornerRadius: Styles.cornerRadiusMedium)
                                                            .stroke(selectedNotificationTypes.contains(type) ?
                                                                    Styles.primaryAccent : Styles.glassHighlight,
                                                                   lineWidth: Styles.hairlineBorder)
                                                    )
                                            )
                                        }
                                        .buttonStyle(ScaleButtonStyle())
                                    }
                                }
                            }
                        }
                        
                        // Custom time option
                        Button(action: {
                            showCustomNotificationSheet = true
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        }) {
                            HStack {
                                Image(systemName: "calendar.badge.plus")
                                    .foregroundColor(.black)
                                Text("Add Custom Time")
                                    .font(Styles.buttonFont)
                                    .foregroundColor(.black)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, Styles.paddingMedium)
                            .background(Styles.buttonGradient)
                            .cornerRadius(Styles.cornerRadiusMedium)
                        }
                        .buttonStyle(ScaleButtonStyle())
                    }
                    .padding(Styles.paddingStandard)
                    .background(
                        RoundedRectangle(cornerRadius: Styles.cornerRadiusMedium)
                            .fill(Styles.cardSurface)
                            .overlay(
                                RoundedRectangle(cornerRadius: Styles.cornerRadiusMedium)
                                    .stroke(Styles.glassHighlight, lineWidth: Styles.hairlineBorder)
                            )
                    )
                    .grokShadow(radius: Styles.shadowRadiusSmall)
                    
                    // Notification sound section
                    VStack(alignment: .leading, spacing: Styles.spacingMedium) {
                        Text("NOTIFICATION SOUND")
                            .grokSectionHeader()
                        
                        // Picker for notification sounds
                        Picker("Notification Sound", selection: $notificationSound) {
                            ForEach(notificationSounds, id: \.self) { sound in
                                Text(sound.capitalized)
                                    .foregroundColor(Styles.textPrimary)
                                    .tag(sound)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(height: 120)
                        
                        // Sound preview button
                        Button(action: {
                            previewSound(sound: notificationSound)
                        }) {
                            HStack {
                                Image(systemName: "speaker.wave.2")
                                    .foregroundColor(Styles.primaryAccent)
                                Text("Preview Sound")
                                    .font(Styles.buttonFont)
                                    .foregroundColor(Styles.textPrimary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, Styles.paddingMedium)
                            .background(
                                RoundedRectangle(cornerRadius: Styles.cornerRadiusMedium)
                                    .stroke(Styles.primaryAccent, lineWidth: Styles.hairlineBorder)
                            )
                        }
                        .buttonStyle(ScaleButtonStyle())
                    }
                    .padding(Styles.paddingStandard)
                    .background(
                        RoundedRectangle(cornerRadius: Styles.cornerRadiusMedium)
                            .fill(Styles.cardSurface)
                            .overlay(
                                RoundedRectangle(cornerRadius: Styles.cornerRadiusMedium)
                                    .stroke(Styles.glassHighlight, lineWidth: Styles.hairlineBorder)
                            )
                    )
                    .grokShadow(radius: Styles.shadowRadiusSmall)
                    
                    // Notification preview section
                    VStack(alignment: .leading, spacing: Styles.spacingMedium) {
                        Text("NOTIFICATION PREVIEW")
                            .grokSectionHeader()
                        
                        // Mock notification
                        VStack(spacing: 0) {
                            HStack {
                                Image("AppIcon") // App icon from Assets
                                    .resizable()
                                    .frame(width: 20, height: 20)
                                    .cornerRadius(4)
                                    .padding(.trailing, 2)
                                
                                Text("Rocket Launch Tracker")
                                    .font(.system(size: Styles.fontMedium, weight: Styles.weightSemibold))
                                    .foregroundColor(Color(.darkGray))
                                
                                Spacer()
                                
                                Text("now")
                                    .font(.system(size: Styles.fontTiny))
                                    .foregroundColor(Color(.darkGray))
                            }
                            .padding(.horizontal, Styles.paddingMedium)
                            .padding(.top, Styles.paddingMedium)
                            .padding(.bottom, Styles.paddingSmall)
                            
                            Text("🚀 Upcoming Launch: \(launch.missionName)")
                                .font(.system(size: Styles.fontMedium, weight: Styles.weightSemibold))
                                .foregroundColor(.black)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, Styles.paddingMedium)
                            
                            Text("Launching on \(launch.formattedNet(style: .dateAndTime)) from \(launch.location)")
                                .font(.system(size: Styles.fontSmall))
                                .foregroundColor(.black)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, Styles.paddingMedium)
                                .padding(.bottom, Styles.paddingMedium)
                        }
                        .background(Color.white)
                        .cornerRadius(Styles.cornerRadiusMedium)
                        .shadow(color: Color.black.opacity(0.2), radius: Styles.shadowRadiusMedium, x: 0, y: Styles.shadowOffset.height)
                    }
                    .padding(Styles.paddingStandard)
                    .background(
                        RoundedRectangle(cornerRadius: Styles.cornerRadiusMedium)
                            .fill(Styles.cardSurface)
                            .overlay(
                                RoundedRectangle(cornerRadius: Styles.cornerRadiusMedium)
                                    .stroke(Styles.glassHighlight, lineWidth: Styles.hairlineBorder)
                            )
                    )
                    .grokShadow(radius: Styles.shadowRadiusSmall)
                    
                    // Save button
                    Button(action: {
                        saveNotificationSettings()
                    }) {
                        HStack {
                            Image(systemName: "checkmark.circle")
                                .foregroundColor(.black)
                            Text("Save Settings")
                                .font(Styles.buttonFont)
                                .foregroundColor(.black)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Styles.paddingMedium)
                        .background(Styles.buttonGradient)
                        .cornerRadius(Styles.cornerRadiusMedium)
                    }
                    .buttonStyle(ScaleButtonStyle())
                    .padding(.top, Styles.paddingStandard)
                    .padding(.bottom, Styles.paddingLarge)
                }
                .padding(.horizontal, Styles.paddingStandard)
            }
            .navigationTitle("Notification Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        showNotificationModal = false
                    }
                    .foregroundColor(Styles.primaryAccent)
                }
            }
        }
    }
    
    // Custom notification time picker
    private var customNotificationView: some View {
        NavigationView {
            ZStack {
                Styles.spaceBackgroundGradient
                    .edgesIgnoringSafeArea(.all)
                
                VStack(spacing: Styles.spacingLarge) {
                    // Date picker
                    VStack(alignment: .leading, spacing: Styles.spacingMedium) {
                        Text("SELECT DATE AND TIME")
                            .grokSectionHeader()
                        
                        DatePicker("", selection: $customNotificationDate, in: Date()...launch.net)
                            .datePickerStyle(.graphical)
                            .colorScheme(.dark)
                            .accentColor(Styles.primaryAccent)
                            .padding(Styles.paddingStandard)
                            .background(
                                RoundedRectangle(cornerRadius: Styles.cornerRadiusMedium)
                                    .fill(Styles.cardSurface)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: Styles.cornerRadiusMedium)
                                            .stroke(Styles.glassHighlight, lineWidth: Styles.hairlineBorder)
                                    )
                            )
                            .grokShadow(radius: Styles.shadowRadiusSmall)
                    }
                    
                    // Custom message field
                    VStack(alignment: .leading, spacing: Styles.spacingMedium) {
                        Text("CUSTOM MESSAGE (OPTIONAL)")
                            .grokSectionHeader()
                        
                        TextEditor(text: $customNotificationMessage)
                            .foregroundColor(Styles.textPrimary)
                            .frame(height: 100)
                            .padding(Styles.paddingStandard)
                            .background(
                                RoundedRectangle(cornerRadius: Styles.cornerRadiusMedium)
                                    .fill(Styles.cardSurface)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: Styles.cornerRadiusMedium)
                                    .stroke(Styles.divider, lineWidth: Styles.hairlineBorder)
                            )
                            .overlay(
                                Group {
                                    if customNotificationMessage.isEmpty {
                                        Text("Enter a custom reminder message...")
                                            .foregroundColor(Styles.textTertiary)
                                            .padding(Styles.paddingStandard)
                                            .allowsHitTesting(false)
                                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                                    }
                                }
                            )
                    }
                    
                    // Time from now indicator
                    if customNotificationDate > Date() {
                        let seconds = customNotificationDate.timeIntervalSince(Date())
                        let days = Int(seconds / 86400)
                        let hours = Int(seconds.truncatingRemainder(dividingBy: 86400) / 3600)
                        let minutes = Int(seconds.truncatingRemainder(dividingBy: 3600) / 60)
                        
                        Text("Notification will be sent in \(days > 0 ? "\(days) days " : "")\(hours > 0 ? "\(hours) hours " : "")\(minutes) minutes")
                            .font(Styles.captionFont)
                            .foregroundColor(Styles.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, Styles.paddingStandard)
                    }
                    
                    Spacer()
                    
                    // Add button
                    Button(action: {
                        addCustomNotification()
                    }) {
                        HStack {
                            Image(systemName: "plus.circle")
                                .foregroundColor(.black)
                            Text("Add Custom Notification")
                                .font(Styles.buttonFont)
                                .foregroundColor(.black)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Styles.paddingMedium)
                        .background(Styles.buttonGradient)
                        .cornerRadius(Styles.cornerRadiusMedium)
                    }
                    .buttonStyle(ScaleButtonStyle())
                    .padding(.bottom, Styles.paddingStandard)
                }
                .padding(.horizontal, Styles.paddingStandard)
                .padding(.top, Styles.paddingSmall)
            }
            .navigationTitle("Custom Notification")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        showCustomNotificationSheet = false
                    }
                    .foregroundColor(Styles.primaryAccent)
                }
            }
        }
    }
    
    // MARK: - Actions
    
    // Updated to use FavoriteService
    private func setFavorite(_ newValue: Bool) {
        // Use the FavoriteService instead of updating directly
        FavoriteService.shared.toggleFavorite(launchId: launch.id, isFavorite: newValue)
        
        // Show success toast
        if newValue {
            showSuccessToast("Added to favorites")
        } else {
            showSuccessToast("Removed from favorites")
        }
    }
    
    // Updated to use NotificationService
    private func setNotificationsEnabled(_ newValue: Bool) {
        isProcessing = true
        
        if newValue {
            // Use NotificationService for consistent handling
            NotificationService.shared.toggleNotification(enabled: true, for: launch) { result in
                DispatchQueue.main.async {
                    switch result {
                    case .success(let enabled):
                        self.notificationsEnabled = enabled
                        if enabled {
                            // Add default notification (launch day)
                            if !self.selectedNotificationTypes.contains(.launchDay) {
                                self.selectedNotificationTypes.append(.launchDay)
                            }
                            self.showSuccessToast("Notifications enabled")
                        } else {
                            self.showAuthorizationAlert()
                        }
                    case .failure:
                        self.notificationsEnabled = false
                        self.showAuthorizationAlert()
                    }
                    self.isProcessing = false
                }
            }
        } else {
            // Turn off notifications
            NotificationService.shared.toggleNotification(enabled: false, for: launch)
            
            // Clear notification types
            selectedNotificationTypes.removeAll()
            showSuccessToast("Notifications disabled")
            isProcessing = false
        }
    }
    
    private func toggleNotificationType(_ type: NotificationType) {
        withAnimation(Styles.spring) {
            if selectedNotificationTypes.contains(type) {
                selectedNotificationTypes.removeAll { $0 == type }
            } else {
                selectedNotificationTypes.append(type)
            }
        }
        
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
    
    private func addCustomNotification() {
        // Ensure date is in the future but before launch
        guard customNotificationDate > Date() && customNotificationDate <= launch.net else {
            return
        }
        
        // Create a custom notification type
        selectedNotificationTypes.append(.custom)
        
        // Schedule the custom notification
        scheduleCustomNotification(at: customNotificationDate, message: customNotificationMessage)
        
        // Close the sheet
        showCustomNotificationSheet = false
        
        showSuccessToast("Custom notification added")
    }
    
    private func scheduleCustomNotification(at date: Date, message: String) {
        let content = UNMutableNotificationContent()
        content.title = "🚀 Custom Alert: \(launch.missionName)"
        
        if message.isEmpty {
            content.body = "Custom notification for launch on \(launch.formattedNet(style: .dateAndTime))"
        } else {
            content.body = message
        }
        
        content.sound = UNNotificationSound(named: UNNotificationSoundName(rawValue: "\(notificationSound)"))
        
        // Create date components trigger
        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        
        // Create the request
        let identifier = "custom-\(launch.id)-\(Date().timeIntervalSince1970)"
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        // Add the request to the notification center
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling custom notification: \(error.localizedDescription)")
            } else {
                print("Custom notification scheduled for \(date)")
            }
        }
    }
    
    private func saveNotificationSettings() {
        isProcessing = true
        
        // Remove all existing notifications for this launch
        NotificationManager.shared.cancelNotification(for: launch.id)
        
        // Schedule notifications for each selected type
        for type in selectedNotificationTypes {
            if type == .custom {
                // Custom notifications already scheduled
                continue
            }
            
            if let timeInterval = type.timeInterval {
                NotificationManager.shared.scheduleNotification(
                    for: launch,
                    timeInterval: Int(timeInterval / 3600)
                ) { result in
                    switch result {
                    case .success:
                        print("Scheduled notification for \(type.rawValue)")
                    case .failure(let error):
                        print("Failed to schedule notification for \(type.rawValue): \(error.localizedDescription)")
                    }
                }
            }
        }
        
        // Close the modal
        showNotificationModal = false
        isProcessing = false
        
        showSuccessToast("Notification settings saved")
    }
    
    private func testNotification() {
        isProcessing = true
        
        // Check notification authorization status first
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                guard settings.authorizationStatus == .authorized else {
                    // Not authorized - show alert
                    self.isProcessing = false
                    self.showAuthorizationAlert()
                    return
                }
                
                // Create notification content
                let content = UNMutableNotificationContent()
                content.title = "🚀 Upcoming Launch: \(self.launch.missionName)"
                content.body = "Launching on \(self.launch.formattedNet(style: .dateAndTime)) from \(self.launch.location)"
                
                // Set notification sound
                // First try with the default notification extension
                content.sound = UNNotificationSound(named: UNNotificationSoundName(rawValue: "\(self.notificationSound)"))
                
                // We need a very short delay for testing to ensure notification appears
                let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 3, repeats: false)
                
                // Create a unique identifier for the test notification
                let uniqueID = UUID().uuidString
                let request = UNNotificationRequest(
                    identifier: "test-\(self.launch.id)-\(uniqueID)",
                    content: content,
                    trigger: trigger
                )
                
                // Schedule the notification
                UNUserNotificationCenter.current().add(request) { error in
                    DispatchQueue.main.async {
                        self.isProcessing = false
                        
                        if let error = error {
                            print("Failed to schedule test notification: \(error.localizedDescription)")
                            self.showSuccessToast("Failed to send test notification")
                        } else {
                            print("Test notification scheduled for launch \(self.launch.missionName)")
                            
                            // App must be in background to see notifications
                            let appIsActive = UIApplication.shared.applicationState == .active
                            let message = appIsActive ?
                                "Test notification scheduled (close app to see it)" :
                                "Test notification sent"
                            
                            UINotificationFeedbackGenerator().notificationOccurred(.success)
                            self.showSuccessToast(message)
                        }
                    }
                }
            }
        }
    }
    
    private func previewSound(sound: String) {
        // In a real app, this would play the actual sound
        // For now, we'll just give haptic feedback
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
    
    private func showSuccessToast(_ message: String) {
        successMessage = message
        withAnimation(Styles.spring) {
            showSuccess = true
        }
        
        // Auto-hide after 2 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation(Styles.spring) {
                showSuccess = false
            }
        }
    }
    
    private func showAuthorizationAlert() {
        let alertController = UIAlertController(
            title: "Notifications Permission Required",
            message: "Please enable notifications in Settings to receive launch alerts.",
            preferredStyle: .alert
        )
        alertController.addAction(UIAlertAction(title: "Settings", style: .default) { _ in
            if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(settingsURL)
            }
        })
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            rootVC.present(alertController, animated: true)
        }
    }
    
    // Updated to use the ShareService
    private func shareLaunchInfo() {
        // Use the ShareService instead of implementing sharing directly
        ShareService.shared.presentShareSheet(for: launch)
    }
}

struct LaunchPreferencesView_Previews: PreviewProvider {
    static var previews: some View {
        LaunchPreferencesView(
            launch: Launch(
                id: "123",
                name: "Falcon 9 Block 5 | Starlink Group 6-14",
                net: Date().addingTimeInterval(86400 * 3),
                provider: "SpaceX",
                location: "Cape Canaveral, FL",
                padLatitude: 28.5618,
                padLongitude: -80.5772,
                missionOverview: "A SpaceX Falcon 9 rocket will launch Starlink satellites.",
                insights: ["Reused booster", "Drone ship landing"],
                image: URL(string: "https://spacelaunchnow-prod-east.nyc3.digitaloceanspaces.com/media/launcher_images/falcon_9_block__image_20210506060831.jpg"),
                rocketName: "Falcon 9 Block 5",
                isFavorite: true,
                notificationsEnabled: true,
                status: "Go for Launch",
                missionName: "Starlink Group 6-14",
                probability: 95,
                url: nil,
                slug: nil,
                launchDesignator: nil,
                windowStart: nil,
                windowEnd: nil,
                webcastLive: nil,
                mission: nil
            ),
            viewModel: LaunchViewModel()
        )
        .preferredColorScheme(.dark)
    }
}
