import SwiftUI
import UIKit

/// Centralized service for managing sharing functionality across the app
class ShareService {
    // MARK: - Shared Instance
    
    /// Shared singleton instance
    static let shared = ShareService()
    
    // MARK: - Initialization
    
    private init() {}
    
    // MARK: - Public Methods
    
    /// Shares information about a launch
    /// - Parameters:
    ///   - launch: The launch to share information about
    ///   - from: The view controller to present the share sheet from
    ///   - sourceView: Optional source view for iPad
    ///   - sourceRect: Optional source rect for iPad
    ///   - completion: Optional completion handler
    func shareLaunch(_ launch: Launch,
                    from viewController: UIViewController? = nil,
                    sourceView: UIView? = nil,
                    sourceRect: CGRect? = nil,
                    completion: (() -> Void)? = nil) {
        
        // Create share text
        let shareText = createShareText(for: launch)
        
        // Create the activity view controller
        let activityItems: [Any] = [shareText]
        let activityController = UIActivityViewController(
            activityItems: activityItems,
            applicationActivities: nil
        )
        
        // Configure for iPad
        if let sourceView = sourceView {
            activityController.popoverPresentationController?.sourceView = sourceView
            if let sourceRect = sourceRect {
                activityController.popoverPresentationController?.sourceRect = sourceRect
            }
        }
        
        // Set completion handler
        activityController.completionWithItemsHandler = { _, _, _, _ in
            completion?()
        }
        
        // Present the share sheet
        if let viewController = viewController {
            viewController.present(activityController, animated: true)
        } else {
            presentShareSheet(activityController)
        }
    }
    
    /// Creates and presents a sharing sheet for a launch
    /// - Parameters:
    ///   - launch: The launch to share
    ///   - hapticFeedback: Whether to provide haptic feedback
    func presentShareSheet(for launch: Launch, hapticFeedback: Bool = true) {
        let shareText = createShareText(for: launch)
        let activityItems: [Any] = [shareText]
        
        if hapticFeedback {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        }
        
        let activityController = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
        presentShareSheet(activityController)
    }
    
    // MARK: - Private Methods
    
    /// Creates a standardized share text for a launch
    /// - Parameter launch: The launch to create share text for
    /// - Returns: Formatted share text
    private func createShareText(for launch: Launch) -> String {
        // Get additional details if available
        let rocketInfo = !launch.rocketName.isEmpty ? "aboard \(launch.rocketName)" : ""
        let probabilityInfo = launch.probability != nil ? " (Success probability: \(launch.probability!)%)" : ""
        
        // Create standardized share text
        return "Check out this upcoming rocket launch: \(launch.missionName) by \(launch.provider) \(rocketInfo) on \(launch.formattedNet(style: .dateAndTime)) from \(launch.location)\(probabilityInfo)"
    }
    
    /// Presents a share sheet using the active window scene
    /// - Parameter activityController: The share sheet controller to present
    private func presentShareSheet(_ activityController: UIActivityViewController) {
        // Get current active scene and present from there
        if let windowScene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene {
            
            // Get the root view controller from the window
            if let rootViewController = windowScene.windows.first?.rootViewController {
                // Configure for iPad
                activityController.popoverPresentationController?.sourceView = rootViewController.view
                
                // Present the controller
                rootViewController.present(activityController, animated: true)
            }
        }
    }
}

// MARK: - SwiftUI Extensions

extension View {
    /// SwiftUI helper to share a launch
    /// - Parameters:
    ///   - launch: The launch to share
    ///   - hapticFeedback: Whether to provide haptic feedback
    func shareLaunch(_ launch: Launch, hapticFeedback: Bool = true) {
        ShareService.shared.presentShareSheet(for: launch, hapticFeedback: hapticFeedback)
    }
}
