import Foundation
@testable import SaveMyEyes

extension Pause {
    /// A pause for tests that only care how long it holds.
    static func holding(until: Date, label: String = "test") -> Pause {
        Pause(holdsUntil: until, endsAt: until, symbol: "pause", label: L(verbatim: label), next: L(verbatim: ""))
    }
}

/// Calendar stub: always free, no EventKit, no timers outliving the test's model.
@MainActor
final class FakeCalendar: CalendarServicing {
    var enabled = false
    var graceSecs = 0
    var onStatusChanged: ((CalendarStatus) -> Void)?
    var onPauseChanged: (() -> Void)?
    var status: CalendarStatus { CalendarStatus(enabled: enabled, access: .granted, meeting: nil, syncedAt: nil) }
    func pause(now: Date) -> Pause? { nil }
    func refresh() async {}
    func start() {}
    func requestAccess() async -> CalendarAccess { .granted }
    func openPrivacySettings() {}
}

/// Device detection stub for the model wiring.
@MainActor
final class FakeDevices: DeviceDetecting {
    var enabled = false { didSet { if !enabled { active = [] } } }
    var graceSecs = 0
    var active: Set<Device> = [] { didSet { onPauseChanged?() } }
    var onStatusChanged: ((DeviceStatus) -> Void)?
    var onPauseChanged: (() -> Void)?
    var started = 0
    var status: DeviceStatus { DeviceStatus(enabled: enabled, active: enabled ? active : []) }
    func pause(now: Date) -> Pause? { status.inUse ? .holding(until: now.addingTimeInterval(30), label: "devices") : nil }
    func refresh() async {}
    func start() { started += 1 }
}
