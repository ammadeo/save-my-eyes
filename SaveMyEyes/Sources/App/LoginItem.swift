// Start at login through SMAppService. Replaces the Tauri autostart plugin's LaunchAgent.

import Foundation
import ServiceManagement

enum LoginItem {
    /// LaunchAgent written by the Tauri build's autostart plugin; its binary is gone after
    /// the native app replaces it.
    private static let legacyLabel = "com.ammadeo.savemyeyes"

    @MainActor
    static func enable() {
        #if DEBUG
        // A debug build in a worktree must not become a login item; opt in explicitly.
        guard ProcessInfo.processInfo.environment["SME_DEV_AUTOSTART"] == "1" else {
            Log.info("startup", "autostart skipped in debug build (set SME_DEV_AUTOSTART=1 to test)")
            return
        }
        #endif
        removeLegacyLaunchAgent()
        let service = SMAppService.mainApp
        guard service.status != .enabled else {
            Log.info("startup", "login item already enabled")
            return
        }
        do {
            try service.register()
            Log.info("startup", "login item registered (status \(service.status.rawValue))")
        } catch {
            Log.error("startup", "login item: \(error)")
        }
    }

    private static func removeLegacyLaunchAgent() {
        let plist = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/LaunchAgents/\(legacyLabel).plist")
        guard FileManager.default.fileExists(atPath: plist.path) else { return }
        let label = (NSDictionary(contentsOf: plist)?["Label"] as? String) ?? legacyLabel
        let launchctl = Process()
        launchctl.executableURL = URL(fileURLWithPath: "/bin/launchctl")
        launchctl.arguments = ["bootout", "gui/\(getuid())/\(label)"]
        launchctl.standardOutput = FileHandle.nullDevice
        launchctl.standardError = FileHandle.nullDevice
        do {
            try launchctl.run()
            launchctl.waitUntilExit()
            Log.info("startup", "legacy LaunchAgent \(label): launchctl bootout exited \(launchctl.terminationStatus)")
        } catch {
            Log.warn("startup", "legacy LaunchAgent \(label): launchctl bootout failed: \(error)")
        }
        do {
            try FileManager.default.removeItem(at: plist)
            Log.info("startup", "removed legacy LaunchAgent \(plist.path)")
        } catch {
            Log.warn("startup", "could not remove legacy LaunchAgent \(plist.path): \(error)")
        }
    }
}
