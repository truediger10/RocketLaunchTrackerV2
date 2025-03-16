import Foundation
import UserNotifications
import os

/// Manages scheduling and handling of local notifications for rocket launches.
final class NotificationManager {
    static let shared = NotificationManager()
    private let notificationCenter = UNUserNotificationCenter.current()
    private var isAuthorized = false
    private let maxNotificationsToSchedule = 5
    
    private static let logger = Logger(subsystem: "com.rocketlaunch.tracker", category: "NotificationManager")

    private init() {
        requestNotificationAuthorization { granted, error in
            if let error = error {
                Self.logger.error("Notification authorization failed: \(error.localizedDescription)")
            } else if granted {
                Self.logger.info("Notification permissions granted")
            } else {
                Self.logger.warning("Notification permissions denied")
            }
        }
    }
    
    func scheduleNotification(for launch: Launch,
                              timeInterval: Int = 24,
                              sound: String = "default",
                              completion: ((Result<Void, Error>) -> Void)? = nil) {
        checkNotificationCount { [weak self] (count: Int) in
            guard let self = self else { return }
            
            if count >= self.maxNotificationsToSchedule {
                let error = NSError(
                    domain: "NotificationManager",
                    code: 4,
                    userInfo: [NSLocalizedDescriptionKey: "Too many notifications scheduled (\(count)). Max allowed: \(self.maxNotificationsToSchedule)"]
                )
                Self.logger.warning("\(error.localizedDescription)")
                completion?(.failure(error))
                return
            }
            self.scheduleNotificationInternal(for: launch, timeInterval: timeInterval, sound: sound, completion: completion)
        }
    }
    
    private func scheduleNotificationInternal(for launch: Launch,
                                             timeInterval: Int = 24,
                                             sound: String = "default",
                                             completion: ((Result<Void, Error>) -> Void)? = nil) {
        guard launch.net.timeIntervalSince1970 > Date().timeIntervalSince1970 else {
            let error = NSError(domain: "NotificationManager",
                                code: 1,
                                userInfo: [NSLocalizedDescriptionKey: "Cannot schedule notification for past launch"])
            completion?(.failure(error))
            return
        }
        
        let content = UNMutableNotificationContent()
        content.title = "🚀 Upcoming Launch: \(launch.missionName)"
        content.body = "🚀 \(launch.rocketName) launching from \(launch.location) on \(launch.formattedNet(style: .dateAndTime))"
        content.sound = UNNotificationSound(named: UNNotificationSoundName(rawValue: "\(sound).caf"))
        content.categoryIdentifier = "LAUNCH"
        
        content.userInfo = [
            "launchId": launch.id,
            "provider": launch.provider,
            "rocketType": launch.rocketName
        ]
        
        guard let triggerDate = Calendar.current.date(byAdding: .hour, value: -timeInterval, to: launch.net) else {
            let error = NSError(domain: "NotificationManager",
                                code: 2,
                                userInfo: [NSLocalizedDescriptionKey: "Failed to calculate notification date"])
            completion?(.failure(error))
            return
        }
        
        guard triggerDate.timeIntervalSince1970 > Date().timeIntervalSince1970 else {
            let error = NSError(domain: "NotificationManager",
                                code: 3,
                                userInfo: [NSLocalizedDescriptionKey: "Notification trigger time is in the past"])
            completion?(.failure(error))
            return
        }
        
        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: triggerDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        
        let identifier = "launch-\(launch.id)"
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        notificationCenter.add(request) { error in
            if let error = error {
                completion?(.failure(error))
            } else {
                Self.logger.info("Scheduled notification for \(launch.name)")
                completion?(.success(()))
            }
        }
    }
    
    private func checkNotificationCount(completion: @escaping (Int) -> Void) {
        notificationCenter.getPendingNotificationRequests { requests in
            completion(requests.count)
        }
    }
    
    func cancelNotification(for launchId: String) {
        notificationCenter.removePendingNotificationRequests(withIdentifiers: ["launch-\(launchId)"])
        Self.logger.info("Cancelled notification for launch ID: \(launchId)")
    }
    
    func cancelAllNotifications() {
        notificationCenter.removeAllPendingNotificationRequests()
    }
    
    func isNotificationScheduled(for launchId: String, completion: @escaping (Bool) -> Void) {
        notificationCenter.getPendingNotificationRequests { requests in
            let isScheduled = requests.contains { $0.identifier == "launch-\(launchId)" }
            completion(isScheduled)
        }
    }
    
    func requestNotificationAuthorization(completion: ((Bool, Error?) -> Void)? = nil) {
        let options: UNAuthorizationOptions = [.alert, .sound, .badge]
        
        notificationCenter.getNotificationSettings { [weak self] settings in
            guard let self = self else { return }
            switch settings.authorizationStatus {
            case .notDetermined:
                self.requestPermission(options: options, completion: completion)
            case .authorized, .provisional:
                self.isAuthorized = true
                completion?(true, nil)
            case .denied, .ephemeral:
                self.isAuthorized = false
                completion?(false, nil)
            @unknown default:
                self.requestPermission(options: options, completion: completion)
            }
        }
    }
    
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
                if request.identifier.hasPrefix("launch-") {
                    if let trigger = request.trigger as? UNCalendarNotificationTrigger,
                       let triggerDate = Calendar.current.date(from: trigger.dateComponents),
                       triggerDate < now {
                        notificationsToRemove.append(request.identifier)
                        Self.logger.info("Found past notification to remove: \(request.identifier)")
                    }
                }
            }
            
            if !notificationsToRemove.isEmpty {
                self.notificationCenter.removePendingNotificationRequests(withIdentifiers: notificationsToRemove)
                Self.logger.info("Removed \(notificationsToRemove.count) past notifications")
            }
            
            let remainingCount = requests.count - notificationsToRemove.count
            if remainingCount > self.maxNotificationsToSchedule {
                Self.logger.warning("Found \(remainingCount) notifications, which exceeds max of \(self.maxNotificationsToSchedule)")
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
                        Self.logger.info("Removed \(idsToRemove.count) excess notifications")
                    }
                }
            }
            Self.logger.info("Currently scheduled notifications: \(requests.count - notificationsToRemove.count)")
        }
    }
    
    private func requestPermission(options: UNAuthorizationOptions,
                                   completion: ((Bool, Error?) -> Void)?) {
        notificationCenter.requestAuthorization(options: options) { [weak self] granted, error in
            self?.isAuthorized = granted
            completion?(granted, error)
        }
    }
}