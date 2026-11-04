// "Your eyes are protected. Next break will start in 20 minutes." at launch.
// Failures only log: an unbundled or unsigned build may be refused.

import Foundation
import UserNotifications

enum StartupNotification {
    @MainActor
    static func post(secs: Int, lang: Lang) {
        // `UNUserNotificationCenter.current()` raises when the process has no bundle.
        guard Bundle.main.bundleIdentifier != nil else {
            Log.warn("startup", "notification skipped: no bundle identifier")
            return
        }
        let body = Strings.startupMessage(secs: secs, lang: lang)
        let center = UNUserNotificationCenter.current()
        center.delegate = Presenter.shared
        Task {
            do {
                guard try await center.requestAuthorization(options: [.alert]) else {
                    Log.warn("startup", "notification not authorized")
                    return
                }
                let content = UNMutableNotificationContent()
                content.title = "Save My Eyes"
                content.body = body
                try await center.add(UNNotificationRequest(identifier: "startup", content: content, trigger: nil))
                Log.info("startup", "notification posted: \(body)")
            } catch {
                Log.warn("startup", "notification: \(error)")
            }
        }
    }

    /// Show the banner even when the app is active (e.g. the dev aid opened the menu).
    private final class Presenter: NSObject, UNUserNotificationCenterDelegate {
        static let shared = Presenter()
        func userNotificationCenter(
            _ center: UNUserNotificationCenter,
            willPresent notification: UNNotification
        ) async -> UNNotificationPresentationOptions {
            [.banner, .list]
        }
    }
}
