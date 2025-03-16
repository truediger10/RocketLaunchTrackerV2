import SwiftUI

struct NotificationPreferencesView: View {
    let launch: Launch
    @ObservedObject var viewModel: LaunchViewModel
    @Environment(\.dismiss) private var dismiss

    @EnvironmentObject var notificationService: NotificationService

    @State private var isNotificationEnabled: Bool
    @State private var selectedTypes: Set<NotificationService.NotificationType>
    @State private var showingDatePicker = false
    @State private var customDate = Date()
    @State private var customTimes: [Date]
    @State private var showFeedback = false
    @State private var feedbackMessage = ""
    
    init(launch: Launch, viewModel: LaunchViewModel) {
        self.launch = launch
        self.viewModel = viewModel
        
        let service = NotificationService.shared
        _isNotificationEnabled = State(initialValue: service.isNotificationEnabled(for: launch.id))
        _selectedTypes = State(initialValue: service.getNotificationTypes(for: launch.id))
        _customTimes = State(initialValue: [])
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Styles.spaceBackgroundGradient
                    .edgesIgnoringSafeArea(.all)
                
                VStack(spacing: Styles.spacingLarge) {
                    launchHeaderView
                    
                    ScrollView {
                        VStack(spacing: Styles.spacingLarge) {
                            notificationToggleSection
                            
                            if isNotificationEnabled {
                                notificationTypesSection
                                
                                if selectedTypes.contains(.custom) {
                                    customTimesSection
                                }
                                
                                testNotificationSection
                            }
                        }
                        .padding(.horizontal, Styles.paddingStandard)
                    }
                    
                    PrimaryButton(
                        title: "Save Preferences",
                        iconName: "checkmark",
                        action: savePreferences
                    )
                    .padding(.horizontal, Styles.paddingStandard)
                    .padding(.vertical, Styles.paddingMedium)
                }
                
                if showFeedback {
                    feedbackView
                }
            }
            .navigationBarTitle("Notification Settings", displayMode: .inline)
            .navigationBarItems(
                trailing: Button("Close") {
                    dismiss()
                }
            )
            .sheet(isPresented: $showingDatePicker) {
                customDatePickerView
            }
        }
    }
    
    // MARK: - UI Components
    
    private var launchHeaderView: some View {
        VStack(spacing: Styles.spacingMedium) {
            LaunchImageView(
                launchId: launch.id,
                url: launch.image,
                style: .custom(height: 120, width: nil),
                fallbackMessage: "Launch Image"
            )
            
            VStack(spacing: Styles.spacingTiny) {
                Text(launch.missionName)
                    .font(Styles.headerFont)
                    .foregroundColor(Styles.textPrimary)
                    .multilineTextAlignment(.center)
                
                Text("\(launch.formattedNet(style: .dateAndTime)) • \(launch.rocketName)")
                    .font(Styles.captionFont)
                    .foregroundColor(Styles.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, Styles.paddingStandard)
        }
    }
    
    private var notificationToggleSection: some View {
        VStack(alignment: .leading, spacing: Styles.spacingMedium) {
            Text("NOTIFICATION STATUS")
                .font(.system(size: Styles.fontTiny, weight: .medium))
                .tracking(1.2)
                .foregroundColor(Styles.textTertiary)
            
            Toggle(isOn: $isNotificationEnabled) {
                HStack {
                    Image(systemName: isNotificationEnabled ? "bell.fill" : "bell.slash")
                        .foregroundColor(isNotificationEnabled ? Styles.primaryAccent : Styles.textSecondary)
                    
                    Text(isNotificationEnabled ? "Notifications Enabled" : "Notifications Disabled")
                        .font(Styles.bodyFont)
                        .foregroundColor(Styles.textPrimary)
                }
            }
            .toggleStyle(SwitchToggleStyle(tint: Styles.primaryAccent))
            .padding(Styles.paddingMedium)
            .background(Styles.cardSurface)
            .cornerRadius(Styles.cornerRadiusMedium)
        }
    }
    
    private var notificationTypesSection: some View {
        VStack(alignment: .leading, spacing: Styles.spacingMedium) {
            Text("WHEN TO NOTIFY")
                .font(.system(size: Styles.fontTiny, weight: .medium))
                .tracking(1.2)
                .foregroundColor(Styles.textTertiary)
            
            VStack(spacing: 1) {
                ForEach(NotificationService.NotificationType.allCases) { type in
                    Button(action: {
                        toggleType(type)
                    }) {
                        HStack {
                            Image(systemName: type.iconName)
                                .foregroundColor(Styles.primaryAccent)
                                .frame(width: 24)
                            
                            Text(type.rawValue)
                                .font(Styles.bodyFont)
                                .foregroundColor(Styles.textPrimary)
                            
                            Spacer()
                            
                            Image(systemName: selectedTypes.contains(type) ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(selectedTypes.contains(type) ? Styles.primaryAccent : Styles.textTertiary)
                        }
                        .contentShape(Rectangle())
                        .padding(Styles.paddingMedium)
                        .background(selectedTypes.contains(type) ? Styles.primaryAccent.opacity(0.1) : Styles.cardSurface)
                    }
                    .buttonStyle(ScaleButtonStyle())
                }
            }
            .background(Styles.cardSurface)
            .cornerRadius(Styles.cornerRadiusMedium)
        }
    }
    
    private var customTimesSection: some View {
        VStack(alignment: .leading, spacing: Styles.spacingMedium) {
            HStack {
                Text("CUSTOM TIMES")
                    .font(.system(size: Styles.fontTiny, weight: .medium))
                    .tracking(1.2)
                    .foregroundColor(Styles.textTertiary)
                
                Spacer()
                
                Button(action: {
                    customDate = Date().addingTimeInterval(3600)
                    showingDatePicker = true
                }) {
                    Label("Add", systemImage: "plus")
                        .font(Styles.captionFont)
                        .foregroundColor(Styles.primaryAccent)
                }
            }
            
            if customTimes.isEmpty {
                Text("No custom times scheduled")
                    .font(Styles.captionFont)
                    .foregroundColor(Styles.textTertiary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(Styles.paddingMedium)
                    .background(Styles.cardSurface)
                    .cornerRadius(Styles.cornerRadiusMedium)
            } else {
                VStack(spacing: 1) {
                    ForEach(customTimes.indices, id: \.self) { index in
                        HStack {
                            Image(systemName: "clock")
                                .foregroundColor(Styles.primaryAccent)
                                .frame(width: 24)
                            
                            Text(formatDate(customTimes[index]))
                                .font(Styles.bodyFont)
                                .foregroundColor(Styles.textPrimary)
                            
                            Spacer()
                            
                            Button(action: {
                                removeCustomTime(at: index)
                            }) {
                                Image(systemName: "trash")
                                    .foregroundColor(Styles.statusError)
                                    .frame(width: 24, height: 24)
                            }
                            .buttonStyle(ScaleButtonStyle())
                        }
                        .padding(Styles.paddingMedium)
                        .background(Styles.cardSurface)
                    }
                }
                .background(Styles.cardSurface)
                .cornerRadius(Styles.cornerRadiusMedium)
            }
        }
    }
    
    private var testNotificationSection: some View {
        VStack(alignment: .leading, spacing: Styles.spacingMedium) {
            Text("TEST")
                .font(.system(size: Styles.fontTiny, weight: .medium))
                .tracking(1.2)
                .foregroundColor(Styles.textTertiary)
            
            Button(action: {
                testNotification()
            }) {
                HStack {
                    Image(systemName: "bell.badge")
                        .foregroundColor(Styles.primaryAccent)
                        .frame(width: 24)
                    
                    Text("Send Test Notification")
                        .font(Styles.bodyFont)
                        .foregroundColor(Styles.textPrimary)
                    
                    Spacer()
                    
                    Image(systemName: "arrow.right")
                        .foregroundColor(Styles.textSecondary)
                }
                .padding(Styles.paddingMedium)
                .background(Styles.cardSurface)
                .cornerRadius(Styles.cornerRadiusMedium)
            }
            .buttonStyle(ScaleButtonStyle())
        }
    }
    
    private var customDatePickerView: some View {
        NavigationView {
            VStack {
                DatePicker(
                    "Select Time",
                    selection: $customDate,
                    in: Date()...launch.net,
                    displayedComponents: [.date, .hourAndMinute]
                )
                .datePickerStyle(WheelDatePickerStyle())
                .labelsHidden()
                .padding()
                
                Text("When do you want to be notified?")
                    .font(Styles.bodyFont)
                    .foregroundColor(Styles.textPrimary)
                    .padding(.horizontal)
                
                if customDate < Date() {
                    Text("⚠️ Selected time is in the past")
                        .font(Styles.captionFont)
                        .foregroundColor(Styles.statusError)
                        .padding(.horizontal)
                }
                
                PrimaryButton(
                    title: "Add Notification",
                    iconName: "plus",
                    action: {
                        if customDate > Date() {
                            customTimes.append(customDate)
                            showingDatePicker = false
                        } else {
                            showFeedbackMessage("Cannot set notifications in the past")
                        }
                    },
                    isDisabled: customDate < Date()
                )
                .padding()
            }
            .navigationBarTitle("Custom Notification", displayMode: .inline)
            .navigationBarItems(
                trailing: Button("Cancel") {
                    showingDatePicker = false
                }
            )
            .background(Styles.spaceBackgroundGradient.edgesIgnoringSafeArea(.all))
        }
    }
    
    private var feedbackView: some View {
        VStack {
            Spacer()
            
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(Styles.statusSuccess)
                    .font(.system(size: Styles.iconSizeMedium))
                
                Text(feedbackMessage)
                    .font(Styles.bodyFont)
                    .foregroundColor(Styles.textPrimary)
                
                Spacer()
            }
            .padding(.horizontal, Styles.paddingStandard)
            .padding(.vertical, Styles.paddingMedium)
            .background(
                RoundedRectangle(cornerRadius: Styles.cornerRadiusMedium)
                    .fill(Styles.cardSurface)
                    .shadow(color: Styles.cardShadow, radius: Styles.shadowRadiusMedium, x: 0, y: 4)
            )
            .padding(.horizontal, Styles.paddingStandard)
            .padding(.bottom, Styles.paddingLarge)
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }
    }
    
    // MARK: - Helper Functions
    private func toggleType(_ type: NotificationService.NotificationType) {
        withAnimation {
            if selectedTypes.contains(type) {
                selectedTypes.remove(type)
                if type == .custom {
                    customTimes.removeAll()
                }
            } else {
                selectedTypes.insert(type)
            }
        }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
    
    private func removeCustomTime(at index: Int) {
        withAnimation {
            customTimes.remove(at: index)
            if customTimes.isEmpty {
                selectedTypes.remove(.custom)
            }
        }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
    
    private func testNotification() {
        NotificationService.shared.scheduleTestNotification(for: launch) { result in
            switch result {
            case .success:
                showFeedbackMessage("Test notification sent!")
            case .failure:
                showFeedbackMessage("Failed to send test notification")
            }
        }
    }
    
    private func savePreferences() {
        var finalTypes = selectedTypes
        if finalTypes.isEmpty && isNotificationEnabled {
            finalTypes.insert(.launchDay)
        }
        
        NotificationService.shared.setNotificationTypes(finalTypes, for: launch)
        
        if NotificationService.shared.isNotificationEnabled(for: launch.id) != isNotificationEnabled {
            NotificationService.shared.toggleNotification(enabled: isNotificationEnabled, for: launch)
        }
        
        if let index = viewModel.launches.firstIndex(where: { $0.id == launch.id }) {
            viewModel.launches[index].notificationsEnabled = isNotificationEnabled
        }
        
        showFeedbackMessage("Notification preferences saved!")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            dismiss()
        }
    }
    
    private func showFeedbackMessage(_ message: String) {
        feedbackMessage = message
        
        withAnimation(Styles.spring) {
            showFeedback = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation(Styles.spring) {
                showFeedback = false
            }
        }
        
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct NotificationPreferencesView_Previews: PreviewProvider {
    static var previews: some View {
        NotificationPreferencesView(
            launch: Launch(
                id: "123",
                name: "Falcon 9 Block 5 | Starlink Group 6-14",
                net: Date().addingTimeInterval(86400 * 3),
                provider: "SpaceX",
                location: "Kennedy Space Center, FL",
                padLatitude: nil,
                padLongitude: nil,
                missionOverview: nil,
                insights: nil,
                image: nil,
                rocketName: "Falcon 9 Block 5",
                isFavorite: false,
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
        .environmentObject(NotificationService.shared)
        .preferredColorScheme(.dark)
    }
}
