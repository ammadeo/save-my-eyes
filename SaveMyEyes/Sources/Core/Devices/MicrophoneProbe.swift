// Is any app capturing audio right now? Read through CoreAudio, which only says that input
// is running: no audio is opened or read, and no microphone permission is involved.
//
// Where the system offers it (macOS 14.2 and later), the answer comes per process
// (`kAudioProcessPropertyIsRunningInput`), so a headset or audio interface that is only
// playing sound does not count. Before that, an input device running anywhere counts.

import CoreAudio
import Foundation

/// CoreAudio-backed probe: listeners on the device list, the process list and each input
/// device's IsRunningSomewhere, all delivered on the main queue.
@MainActor
final class CoreAudioMicrophoneProbe: DeviceProbe {
    private var onChange: (() -> Void)?
    /// Input devices that currently carry `runningListener`.
    private var observed: [AudioObjectID] = []
    // The same block instances must be passed to `AudioObjectRemovePropertyListenerBlock`.
    private var listListener: AudioObjectPropertyListenerBlock?
    private var runningListener: AudioObjectPropertyListenerBlock?

    private static let system = AudioObjectID(kAudioObjectSystemObject)
    /// Lists whose change may mean a microphone started or stopped.
    private static let lists = [kAudioHardwarePropertyDevices, kAudioHardwarePropertyProcessObjectList]

    func anyRunning() -> Bool {
        if let processes = Self.objects(Self.system, kAudioHardwarePropertyProcessObjectList) {
            return processes.contains { Self.flag($0, kAudioProcessPropertyIsRunningInput) }
        }
        return Self.inputDevices().contains { Self.flag($0, kAudioDevicePropertyDeviceIsRunningSomewhere) }
    }

    func startObserving(_ onChange: @escaping () -> Void) {
        stopObserving()
        self.onChange = onChange
        let running: AudioObjectPropertyListenerBlock = { [weak self] _, _ in
            MainActor.assumeIsolated { self?.onChange?() }
        }
        let list: AudioObjectPropertyListenerBlock = { [weak self] _, _ in
            MainActor.assumeIsolated {
                self?.syncDevices()
                self?.onChange?()
            }
        }
        runningListener = running
        listListener = list
        for selector in Self.lists {
            var addr = Self.address(selector)
            // The process list does not exist before macOS 14.2; its listener then fails, harmlessly.
            _ = AudioObjectAddPropertyListenerBlock(Self.system, &addr, DispatchQueue.main, list)
        }
        syncDevices()
    }

    func stopObserving() {
        if let listListener {
            for selector in Self.lists {
                var addr = Self.address(selector)
                _ = AudioObjectRemovePropertyListenerBlock(Self.system, &addr, DispatchQueue.main, listListener)
            }
        }
        if let runningListener {
            for id in observed { Self.removeRunningListener(id, runningListener) }
        }
        observed = []
        listListener = nil
        runningListener = nil
        onChange = nil
    }

    /// Re-enumerate input devices: listen on new ones, drop listeners of vanished ones.
    private func syncDevices() {
        guard let runningListener else { return }
        let now = Self.inputDevices()
        for id in observed where !now.contains(id) {
            Self.removeRunningListener(id, runningListener) // may fail for a gone device; ignored
        }
        var kept = observed.filter(now.contains)
        for id in now where !kept.contains(id) {
            var addr = Self.address(kAudioDevicePropertyDeviceIsRunningSomewhere)
            if AudioObjectAddPropertyListenerBlock(id, &addr, DispatchQueue.main, runningListener) == noErr {
                kept.append(id)
            }
        }
        if Set(kept) != Set(observed) {
            Log.info("devices", "\(kept.count) microphone(s) watched")
        }
        observed = kept
    }

    private static func removeRunningListener(_ id: AudioObjectID, _ block: @escaping AudioObjectPropertyListenerBlock) {
        var addr = address(kAudioDevicePropertyDeviceIsRunningSomewhere)
        _ = AudioObjectRemovePropertyListenerBlock(id, &addr, DispatchQueue.main, block)
    }

    /// Audio devices that have input streams.
    private static func inputDevices() -> [AudioObjectID] {
        (objects(system, kAudioHardwarePropertyDevices) ?? []).filter { id in
            var addr = address(kAudioDevicePropertyStreams, scope: kAudioObjectPropertyScopeInput)
            var size: UInt32 = 0
            return AudioObjectGetPropertyDataSize(id, &addr, 0, nil, &size) == noErr && size > 0
        }
    }

    /// An object-list property; `nil` when the property cannot be read (e.g. it does not exist
    /// on this macOS).
    private static func objects(_ id: AudioObjectID, _ selector: AudioObjectPropertySelector) -> [AudioObjectID]? {
        var addr = address(selector)
        var size: UInt32 = 0
        guard AudioObjectGetPropertyDataSize(id, &addr, 0, nil, &size) == noErr else { return nil }
        guard size > 0 else { return [] }
        var ids = [AudioObjectID](repeating: 0, count: Int(size) / MemoryLayout<AudioObjectID>.size)
        guard AudioObjectGetPropertyData(id, &addr, 0, nil, &size, &ids) == noErr else { return nil }
        return Array(ids.prefix(Int(size) / MemoryLayout<AudioObjectID>.size))
    }

    private static func flag(_ id: AudioObjectID, _ selector: AudioObjectPropertySelector) -> Bool {
        var addr = address(selector)
        var value: UInt32 = 0
        var size = UInt32(MemoryLayout<UInt32>.size)
        return AudioObjectGetPropertyData(id, &addr, 0, nil, &size, &value) == noErr && value != 0
    }

    private static func address(
        _ selector: AudioObjectPropertySelector,
        scope: AudioObjectPropertyScope = kAudioObjectPropertyScopeGlobal
    ) -> AudioObjectPropertyAddress {
        AudioObjectPropertyAddress(mSelector: selector, mScope: scope, mElement: kAudioObjectPropertyElementMain)
    }
}
