// Entry point: a plain NSApplication with an accessory activation policy (menu bar only,
// no Dock icon; Info.plist also sets LSUIElement).

import AppKit

@main
enum AppMain {
    @MainActor
    static func main() {
        let app = NSApplication.shared
        let delegate = AppDelegate()
        app.delegate = delegate
        app.setActivationPolicy(.accessory)
        withExtendedLifetime(delegate) {
            app.run()
        }
    }
}
