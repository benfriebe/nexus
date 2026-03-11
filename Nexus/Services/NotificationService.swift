import ComposableArchitecture
import Foundation
import UserNotifications

/// Posts macOS desktop notifications via UNUserNotificationCenter.
/// Handles permission requests and focus-based suppression.
final class NotificationService: NSObject, Sendable, UNUserNotificationCenterDelegate {

    override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
    }

    /// Request notification permission. Call once on app launch.
    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, error in
            if let error {
                print("NotificationService: permission error — \(error)")
            }
        }
    }

    /// Post a desktop notification.
    /// - Parameters:
    ///   - title: Notification title
    ///   - body: Notification body text
    ///   - paneID: The pane that triggered this notification (used as identifier for dedup)
    func post(title: String, body: String, paneID: UUID) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.userInfo = ["paneID": paneID.uuidString]

        let request = UNNotificationRequest(
            identifier: "nexus-\(paneID.uuidString)",
            content: content,
            trigger: nil // Deliver immediately
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error {
                print("NotificationService: post error — \(error)")
            }
        }
    }

    // MARK: - UNUserNotificationCenterDelegate

    /// Show notifications even when the app is in the foreground.
    /// Suppression is handled at the call site (AppReducer checks focus state).
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .sound]
    }
}

// MARK: - TCA Dependency

extension NotificationService: DependencyKey {
    static let liveValue = NotificationService()
    static let testValue = NotificationService()
}

extension DependencyValues {
    var notificationService: NotificationService {
        get { self[NotificationService.self] }
        set { self[NotificationService.self] = newValue }
    }
}
