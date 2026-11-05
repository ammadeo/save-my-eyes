// Call detection without a calendar: is any app using a camera or a microphone right now?
// Each kind of device has a probe (`CameraProbe`, `MicrophoneProbe`) that only reads whether
// a device is in use. Nothing is opened, so the app cannot see, hear or record anything, and
// no permission is involved.
//
// Event driven: the probes listen for device changes, only while the feature is on. Every
// callback, and `refresh()` right before a break fires (`Scheduler`), re-reads all devices,
// so a spurious or missed callback costs nothing. Any system error or no devices mean "not
// in use": a detection problem never stops breaks.

import Foundation

private enum T {
    static let cameraOn = L("Camera is on", "Kamera jest włączona")
    static let microphoneOn = L("Microphone is on", "Mikrofon jest włączony")
    static let cameraAndMicrophoneOn = L("Camera and microphone are on", "Kamera i mikrofon są włączone")
    static let deviceNext = L("Your next break starts once the camera and microphone are off", "Następna przerwa zaplanowana jest po rozmowie")
    static let afterCall = L("Pause after a call", "Wstrzymanie po rozmowie")
    static let afterCallNext = L("Your next break starts after this pause", "Następna przerwa zacznie się po tym wstrzymaniu")
}

@MainActor
final class CallDetector: CallDetecting {
    var enabled = false {
        didSet { if enabled != oldValue { apply() } }
    }
    var graceSecs = 60
    var onStatusChanged: ((CallStatus) -> Void)?
    var onPauseChanged: (() -> Void)?

    private let probes: [CallDevice: CallProbe]
    private let clock: () -> Date
    private var started = false
    private var watching = false
    private var active: Set<CallDevice> = []
    /// When the last device in use was seen going off; nil while one is on, or none was seen on.
    private var offAt: Date?
    private var published = CallStatus.off

    /// `probes` defaults to the real camera and microphone ones (`nil` so the default is built
    /// on the main actor).
    init(probes: [CallDevice: CallProbe]? = nil, clock: @escaping () -> Date = Date.init) {
        self.probes = probes ?? [.camera: CMIOCameraProbe(), .microphone: CoreAudioMicrophoneProbe()]
        self.clock = clock
    }

    var status: CallStatus { CallStatus(enabled: enabled, active: enabled ? active : []) }

    /// A device in use holds breaks for as long as it stays on (nobody knows until when),
    /// then for the grace period after the last one goes off.
    func pause(now: Date) -> Pause? {
        guard enabled, watching,
              let until = CallRules.heldUntil(now: now, inUse: !active.isEmpty, offAt: offAt, grace: TimeInterval(graceSecs))
        else { return nil }
        if active.isEmpty {
            return Pause(holdsUntil: until, endsAt: until, symbol: "phone.down", label: T.afterCall, next: T.afterCallNext)
        }
        let camera = active.contains(.camera)
        return Pause(holdsUntil: until, endsAt: nil, symbol: camera ? "video" : "mic",
                     label: active.count > 1 ? T.cameraAndMicrophoneOn : camera ? T.cameraOn : T.microphoneOn, next: T.deviceNext)
    }

    /// Polling backstop for a missed listener callback.
    func refresh() async {
        recompute()
    }

    /// Start watching (when enabled) and publish the initial status once.
    func start() {
        guard !started else { return }
        started = true
        apply(publishing: false)
        published = status
        onStatusChanged?(published)
        onPauseChanged?()
    }

    // MARK: Internals

    private func read() -> Set<CallDevice> {
        Set(probes.filter { $0.value.anyRunning() }.keys)
    }

    private static func names(_ devices: Set<CallDevice>) -> String {
        devices.isEmpty ? "nothing" : devices.map(\.rawValue).sorted().joined(separator: " and ")
    }

    /// Watch devices exactly while started and enabled.
    private func apply(publishing: Bool = true) {
        let shouldWatch = started && enabled
        if shouldWatch, !watching {
            watching = true
            for probe in probes.values {
                probe.startObserving { [weak self] in self?.recompute() }
            }
            active = read()
            offAt = nil
            Log.info("calls", "watching cameras and microphones, in use: \(Self.names(active))")
        } else if !shouldWatch, watching {
            watching = false
            for probe in probes.values {
                probe.stopObserving()
            }
            active = []
            offAt = nil
            Log.info("calls", "stopped watching cameras and microphones")
        }
        if publishing { publish() }
    }

    /// Re-read every device; change state only on a real difference.
    private func recompute() {
        guard watching else { return }
        let now = read()
        guard now != active else { return }
        let wasInUse = !active.isEmpty
        active = now
        if !now.isEmpty {
            offAt = nil
            Log.info("calls", "in use: \(Self.names(now)), breaks are held")
        } else if wasInUse {
            offAt = clock()
            Log.info("calls", "camera and microphone are off, holding breaks for \(graceSecs)s more")
        }
        publish()
    }

    private func publish() {
        let next = status
        guard next != published else { return }
        published = next
        onStatusChanged?(next)
        onPauseChanged?()
    }
}

/// The system half of `CallDetector` for one kind of device, behind a seam so the detector's
/// state logic can be tested.
@MainActor
protocol CallProbe: AnyObject {
    /// Is a device of this kind in use by any process right now? False on any error.
    func anyRunning() -> Bool
    /// Call `onChange` on the main queue whenever a device may have started or stopped, or
    /// the device list may have changed. Callbacks can be spurious.
    func startObserving(_ onChange: @escaping () -> Void)
    func stopObserving()
}
