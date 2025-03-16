import Foundation
import UserNotifications
import SwiftUI
import Combine
import os

/// Centralized service for managing all notification-related functionality
class NotificationService: ObservableObject {
    // MARK: - Published Properties
    
    /// Published property to track global notification settings
    @Published var isGloballyEnabled: Bool = false
    
    /// Published dictionary of launch IDs to their notification status
    @Published var enabledNotifications: [String: Bool] = [:]
    
    /// Published dictionary of launch IDs to their notification types
    @Published var notificationTypes: [String: Set<NotificationType>] = [:]
    
    // MARK: - Private Properties
    
    /// The notification center for managing user notifications
    private let notificationCenter = UNUserNotificationCenter.current()
    
    /// Maximum number of notifications to schedule at once
    private let maxNotificationsToSchedule = 5
    
    /// UserDefaults keys
    private let enabledNotificationsKey = "EnabledNotifications"
    private let notificationTypesKey = "NotificationTypes"
    private let globalNotificationsKey = "GlobalNotificationsEnabled"
    
    /// Tracks whether notifications are authorized
    private var isAuthorized = false
    
    /// System logger
    private static let logger = Logger(subsystem: "com.rocketlaunch.tracker", category: "NotificationService")
    
    // MARK: - Notification Types
    
    /// Types of notifications that can be scheduled
    enum NotificationType: String, CaseIterable, Identifiable, Codable {
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
        
        /// Returns time in seconds before launch
        var timeInterval: TimeInterval? {
            switch self {
            case .launchDay: return 0
            case .beforeLaunch: return 3600 * 6 // 6 hours
            case .tMinus1Hour: return 3600
            case .tMinus24Hours: return 3600 * 24
            case .tMinus3Days: return 3600 * 24 * 3
            case .tMinus7Days: return 3600 * 24 * 7
            case .custom: return nil
            }
        }
    }
    
    // MARK: - Initialization
    
    /// Shared singleton instance
    static let shared = NotificationService()
    
    private init() {
        loadPersistedSettings()
        
        // Check authorization status
        requestAuthorization { [weak self] granted, _ in
            self?.isAuthorized = granted
            if granted {
                // Clean up old notifications
                self?.verifyScheduledNotifications()
            }
        }
    }
    
    // MARK: - Public Methods
    
    /// Requests authorization for sending notifications
    /// - Parameter completion: Optional callback with authorization result
    func requestAuthorization(completion: @escaping (Bool, Error?) -> Void) {
        let options: UNAuthorizationOptions = [.alert, .sound, .badge]
        
        notificationCenter.getNotificationSettings { [weak self] settings in
            switch settings.authorizationStatus {
            case .notDetermined:
                // Request authorization
                self?.requestPermission(options: options, completion: completion)
            case .authorized, .provisional:
                // Already authorized
                self?.isAuthorized = true
                completion(true, nil)
            case .denied, .ephemeral:
                // Authorization denied
                self?.isAuthorized = false
                completion(false, nil)
            @unknown default:
                // Handle future cases
                self?.requestPermission(options: options, completion: completion)
            }
        }
    }
    
    /// Toggles notifications for a specific launch
    /// - Parameters:
    ///   - enabled: Whether to enable or disable notifications
    ///   - launch: The launch to toggle notifications for
    ///   - completion: Optional callback with success/failure result
    func toggleNotification(enabled: Bool, for launch: Launch, completion: ((Result<Bool, Error>) -> Void)? = nil) {
        if enabled {
            // Enable notifications
            requestAuthorization { [weak self] granted, error in
                guard let self = self else { return }
                
                if let error = error {
                    DispatchQueue.main.async {
                        completion?(.failure(error))
                    }
                    return
                }
                
                if granted {
                    DispatchQueue.main.async {
                        // Update published state
                        self.enabledNotifications[launch.id] = true
                        
                        // Ensure there's at least one notification type
                        if self.notificationTypes[launch.id] == nil || self.notificationTypes[launch.id]!.isEmpty {
                            self.notificationTypes[launch.id] = [.launchDay]
                        }
                        
                        // Schedule notifications
                        self.scheduleNotificationsForLaunch(launch)
                        
                        // Persist changes
                        self.savePersistedSettings()
                        
                        completion?(.success(true))
                    }
                } else {
                    DispatchQueue.main.async {
                        completion?(.success(false))
                    }
                }
            }
        } else {
            // Disable notifications
            enabledNotifications[launch.id] = false
            cancelNotification(for: launch.id)
            savePersistedSettings()
            completion?(.success(false))
        }
    }
    
    /// Sets the notification types for a launch
    /// - Parameters:
    ///   - types: The set of notification types
    ///   - launch: The launch to set types for
    func setNotificationTypes(_ types: Set<NotificationType>, for launch: Launch) {
        notificationTypes[launch.id] = types
        
        // Reschedule notifications if enabled
        if enabledNotifications[launch.id] == true {
            cancelNotification(for: launch.id)
            scheduleNotificationsForLaunch(launch)
        }
        
        savePersistedSettings()
    }
    
    /// Returns the notification types for a launch
    /// - Parameter launchId: The ID of the launch
    /// - Returns: The set of notification types, or an empty set if none
    func getNotificationTypes(for launchId: String) -> Set<NotificationType> {
        return notificationTypes[launchId] ?? []
    }
    
    /// Checks if notifications are enabled for a launch
    /// - Parameter launchId: The ID of the launch
    /// - Returns: Whether notifications are enabled
    func isNotificationEnabled(for launchId: String) -> Bool {
        return enabledNotifications[launchId] == true
    }
    
    /// Sets the global notification setting
    /// - Parameter enabled: Whether to enable or disable all notifications
    func setGlobalNotifications(enabled: Bool) {
        isGloballyEnabled = enabled
        
        if !enabled {
            // Cancel all notifications if disabled globally
            cancelAllNotifications()
        }
        
        UserDefaults.standard.set(enabled, forKey: globalNotificationsKey)
    }
    
    /// Schedules a test notification for a launch
    /// - Parameters:
    ///   - launch: The launch to schedule a test notification for
    ///   - completion: Optional callback with success/failure result
    func scheduleTestNotification(for launch: Launch, completion: ((Result<Void, Error>) -> Void)? = nil) {
        requestAuthorization { [weak self] granted, error in
            guard let self = self else { return }
            
            if let error = error {
                DispatchQueue.main.async {
                    completion?(.failure(error))
                }
                return
            }
            
            if granted {
                // Create notification content
                let content = UNMutableNotificationContent()
                content.title = "🚀 Test: \(launch.missionName)"
                content.body = "This is a test notification for the launch of \(launch.rocketName) from \(launch.location) on \(launch.formattedNet(style: .dateAndTime))"
                content.sound = .default
                
                // Create trigger for 3 seconds from now
                let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 3, repeats: false)
                
                // Create request with unique identifier
                let identifier = "test-\(launch.id)-\(UUID().uuidString)"
                let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
                
                // Add the request
                self.notificationCenter.add(request) { error in
                    DispatchQueue.main.async {
                        if let error = error {
                            completion?(.failure(error))
                        } else {
                            completion?(.success(()))
                        }
                    }
                }
            } else {
                DispatchQueue.main.async {
                    completion?(.failure(NSError(domain: "NotificationService", code: 403, userInfo: [NSLocalizedDescriptionKey: "Notification permission denied"])))
                }
            }
        }
    }
    
    /// Cancels a scheduled notification for a launch
    /// - Parameter launchId: The ID of the launch
    func cancelNotification(for launchId: String) {
        notificationCenter.removePendingNotificationRequests(withIdentifiers: ["launch-\(launchId)"])
        
        // Also remove any custom notifications
        notificationCenter.getPendingNotificationRequests { requests in
            let customRequests = requests.filter { $0.identifier.hasPrefix("custom-\(launchId)") }
            self.notificationCenter.removePendingNotificationRequests(withIdentifiers: customRequests.map { $0.identifier })
        }
        Self.logger.info("Cancelled notification(s) for launch ID: \(launchId)")
    }
    
    /// Cancels all scheduled notifications
    func cancelAllNotifications() {
        notificationCenter.removeAllPendingNotificationRequests()
        Self.logger.info("Cancelled all scheduled notifications.")
    }
    
    /// Adds a custom notification at a specific time
    /// - Parameters:
    ///   - launch: The launch to add a notification for
    ///   - date: The date to schedule the notification
    ///   - message: Optional custom message
    ///   - completion: Optional callback with success/failure result
    func addCustomNotification(for launch: Launch, at date: Date, message: String = "", completion: ((Result<Void, Error>) -> Void)? = nil) {
        requestAuthorization { [weak self] granted, error in
            guard let self = self else { return }
            
            if let error = error {
                DispatchQueue.main.async {
                    completion?(.failure(error))
                }
                return
            }
            
            if granted {
                // Create content
                let content = UNMutableNotificationContent()
                content.title = "🚀 Custom Alert: \(launch.missionName)"
                
                if message.isEmpty {
                    content.body = "Custom notification for launch on \(launch.formattedNet(style: .dateAndTime))"
                } else {
                    content.body = message
                }
                
                content.sound = .default
                
                // Create date components trigger
                let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: date)
                let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
                
                // Create request with unique identifier
                let identifier = "custom-\(launch.id)-\(Date().timeIntervalSince1970)"
                let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
                
                // Add request
                self.notificationCenter.add(request) { error in
                    DispatchQueue.main.async {
                        if let error = error {
                            completion?(.failure(error))
                        } else {
                            // Update notification types to include custom
                            var types = self.notificationTypes[launch.id] ?? []
                            types.insert(.custom)
                            self.notificationTypes[launch.id] = types
                            self.savePersistedSettings()
                            
                            completion?(.success(()))
                        }
                    }
                }
            } else {
                DispatchQueue.main.async {
                    completion?(.failure(NSError(domain: "NotificationService", code: 403, userInfo: [NSLocalizedDescriptionKey: "Notification permission denied"])))
                }
            }
        }
    }
    
    // MARK: - Private Methods
    
    /// Schedules notifications for a launch based on its notification types
    /// - Parameter launch: The launch to schedule notifications for
    private func scheduleNotificationsForLaunch(_ launch: Launch) {
        guard isGloballyEnabled else {
            Self.logger.info("Global notifications disabled, skipping scheduling for \(launch.id)")
            return
        }
        
        checkNotificationCount { [weak self] count in
            guard let self = self else { return }
            
            if count >= self.maxNotificationsToSchedule {
                Self.logger.warning("Too many notifications scheduled (\(count)). Max allowed: \(self.maxNotificationsToSchedule)")
                return
            }
            
            let types = self.notificationTypes[launch.id] ?? [.launchDay]
            
            for type in types {
                if type == .custom {
                    // Custom notifications are scheduled separately
                    continue
                }
                
                if let interval = type.timeInterval {
                    self.scheduleNotification(for: launch, timeInterval: Int(interval / 3600))
                }
            }
        }
    }
    
    /// Schedules a notification for a launch at a specific time before launch
    /// - Parameters:
    ///   - launch: The launch to schedule a notification for
    ///   - timeInterval: Hours before launch to send notification
    private func scheduleNotification(for launch: Launch, timeInterval: Int) {
        // Verify launch date is in the future
        guard launch.net > Date() else {
            Self.logger.warning("Cannot schedule notification for past launch: \(launch.name)")
            return
        }
        
        // Calculate trigger time
        guard let triggerDate = Calendar.current.date(byAdding: .hour, value: -timeInterval, to: launch.net) else {
            Self.logger.warning("Failed to calculate notification date for launch: \(launch.name)")
            return
        }
        
        // If trigger date is in the past, don't schedule
        guard triggerDate > Date() else {
            Self.logger.warning("Notification trigger time is in the past for launch: \(launch.name)")
            return
        }
        
        // Create content
        let content = UNMutableNotificationContent()
        content.title = "🚀 Upcoming Launch: \(launch.missionName)"
        content.body = "🚀 \(launch.rocketName) launching from \(launch.location) on \(launch.formattedNet(style: .dateAndTime))"
        content.sound = .default
        content.categoryIdentifier = "LAUNCH"
        
        // Add additional information
        content.userInfo = [
            "launchId": launch.id,
            "provider": launch.provider,
            "rocketType": launch.rocketName
        ]
        
        // Create trigger
        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: triggerDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        
        // Create request
        let identifier = "launch-\(launch.id)-\(timeInterval)"
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        // Add request
        notificationCenter.add(request) { error in
            if let error = error {
                Self.logger.error("Failed to schedule notification: \(error.localizedDescription)")
            } else {
                Self.logger.info("Scheduled notification for \(launch.name) \(timeInterval) hours before launch")
            }
        }
    }
    
    /// Checks the number of scheduled notifications
    /// - Parameter completion: Callback with the count
    private func checkNotificationCount(completion: @escaping (Int) -> Void) {
        notificationCenter.getPendingNotificationRequests { requests in
            completion(requests.count)
        }
    }
    
    /// Requests notification permissions from the user
    /// - Parameters:
    ///   - options: The notification options to request
    ///   - completion: Optional callback with result
    private func requestPermission(options: UNAuthorizationOptions, completion: @escaping (Bool, Error?) -> Void) {
        notificationCenter.requestAuthorization(options: options) { [weak self] granted, error in
            self?.isAuthorized = granted
            completion(granted, error)
        }
    }
    
    /// Verifies and cleans up scheduled notifications
    func verifyScheduledNotifications() {
        #if DEBUG
        if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1" {
            Self.logger.info("Running in SwiftUI preview mode, skipping verifyScheduledNotifications")
            return
        }
        #endif
        
        notificationCenter.getPendingNotificationRequests { [weak self] requests in
            guard let self = self else { return }
            
            let now = Date()
            var notificationsToRemove = [String]()
            
            for request in requests {
                if request.identifier.contains("launch-") {
                    if let trigger = request.trigger as? UNCalendarNotificationTrigger,
                       let triggerDate = Calendar.current.date(from: trigger.dateComponents),
                       triggerDate < now {
                        notificationsToRemove.append(request.identifier)
                        Self.logger.info("🔍 Found past notification to remove: \(request.identifier)")
                    }
                }
            }
            
            if !notificationsToRemove.isEmpty {
                self.notificationCenter.removePendingNotificationRequests(withIdentifiers: notificationsToRemove)
                Self.logger.info("🧹 Removed \(notificationsToRemove.count) past notifications")
            }
            
            let remainingCount = requests.count - notificationsToRemove.count
            if remainingCount > self.maxNotificationsToSchedule {
                Self.logger.warning("⚠️ Found \(remainingCount) notifications, which exceeds max of \(self.maxNotificationsToSchedule)")
                
                let excessNotifications = remainingCount - self.maxNotificationsToSchedule
                if excessNotifications > 0 {
                    let sortedRequests = requests
                        .filter { !notificationsToRemove.contains($0.identifier) }
                        .compactMap { req -> (String, Date)? in
                            if let trig = req.trigger as? UNCalendarNotificationTrigger,
                               let trigDate = Calendar.current.date(from: trig.dateComponents) {
                                return (req.identifier, trigDate)
                            }
                            return nil
                        }
                        .sorted { $0.1 > $1.1 }
                    
                    let idsToRemove = sortedRequests.suffix(excessNotifications).map { $0.0 }
                    if !idsToRemove.isEmpty {
                        self.notificationCenter.removePendingNotificationRequests(withIdentifiers: idsToRemove)
                        Self.logger.info("🧹 Removed \(idsToRemove.count) excess notifications")
                    }
                }
            }
            
            Self.logger.info("📱 Currently scheduled notifications: \(requests.count - notificationsToRemove.count)")
        }
    }
    
    /// Loads notification settings from UserDefaults
    private func loadPersistedSettings() {
        // Load enabled notifications
        if let data = UserDefaults.standard.data(forKey: enabledNotificationsKey),
           let decoded = try? JSONDecoder().decode([String: Bool].self, from: data) {
            enabledNotifications = decoded
        }
        
        // Load notification types
        if let data = UserDefaults.standard.data(forKey: notificationTypesKey),
           let decoded = try? JSONDecoder().decode([String: Set<NotificationType>].self, from: data) {
            notificationTypes = decoded
        }
        
        // Load global setting
        isGloballyEnabled = UserDefaults.standard.bool(forKey: globalNotificationsKey)
    }
    
    /// Saves notification settings to UserDefaults
    private func savePersistedSettings() {
        if let encoded = try? JSONEncoder().encode(enabledNotifications) {
            UserDefaults.standard.set(encoded, forKey: enabledNotificationsKey)
        }
        
        if let encoded = try? JSONEncoder().encode(notificationTypes) {
            UserDefaults.standard.set(encoded, forKey: notificationTypesKey)
        }
    }
}