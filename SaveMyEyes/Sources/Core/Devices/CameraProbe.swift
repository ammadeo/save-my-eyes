// Is any camera in use by any app right now? Read through CoreMediaIO
// (`kCMIODevicePropertyDeviceIsRunningSomewhere` on every device). That only says whether a
// device is running, never opens it, and needs no camera permission, so it never prompts.
// AVFoundation is deliberately not used: its in-use checks go through the camera TCC check.

import CoreMediaIO
import Foundation

/// CoreMediaIO-backed probe: listeners on the system object's device list and on each
/// device's IsRunningSomewhere, all delivered on the main queue.
@MainActor
final class CMIOCameraProbe: DeviceProbe {
    private var onChange: (() -> Void)?
    /// Devices that currently carry `runningListener`.
    private var observed: [CMIOObjectID] = []
    // The same block instances must be passed to `CMIOObjectRemovePropertyListenerBlock`.
    private var devicesListener: CMIOObjectPropertyListenerBlock?
    private var runningListener: CMIOObjectPropertyListenerBlock?

    private static let system = CMIOObjectID(kCMIOObjectSystemObject)

    func anyRunning() -> Bool {
        Self.devices().contains(where: Self.isRunningSomewhere)
    }

    func startObserving(_ onChange: @escaping () -> Void) {
        stopObserving()
        self.onChange = onChange
        let running: CMIOObjectPropertyListenerBlock = { [weak self] _, _ in
            MainActor.assumeIsolated { self?.onChange?() }
        }
        let devices: CMIOObjectPropertyListenerBlock = { [weak self] _, _ in
            MainActor.assumeIsolated {
                self?.syncDevices()
                self?.onChange?()
            }
        }
        runningListener = running
        devicesListener = devices
        var addr = Self.address(kCMIOHardwarePropertyDevices)
        let status = CMIOObjectAddPropertyListenerBlock(Self.system, &addr, DispatchQueue.main, devices)
        if status != noErr {
            Log.warn("devices", "cannot watch the camera list (CMIO \(status)), relying on refresh")
        }
        syncDevices()
    }

    func stopObserving() {
        if let devicesListener {
            var addr = Self.address(kCMIOHardwarePropertyDevices)
            _ = CMIOObjectRemovePropertyListenerBlock(Self.system, &addr, DispatchQueue.main, devicesListener)
        }
        if let runningListener {
            for id in observed { Self.removeRunningListener(id, runningListener) }
        }
        observed = []
        devicesListener = nil
        runningListener = nil
        onChange = nil
    }

    /// Re-enumerate devices: listen on new ones, drop listeners of vanished ones.
    private func syncDevices() {
        guard let runningListener else { return }
        let now = Self.devices()
        for id in observed where !now.contains(id) {
            Self.removeRunningListener(id, runningListener) // may fail for a gone device; ignored
        }
        var kept = observed.filter(now.contains)
        for id in now where !kept.contains(id) {
            var addr = Self.address(kCMIODevicePropertyDeviceIsRunningSomewhere)
            let status = CMIOObjectAddPropertyListenerBlock(id, &addr, DispatchQueue.main, runningListener)
            if status == noErr {
                kept.append(id)
            } else {
                Log.warn("devices", "cannot watch camera \(id) (CMIO \(status)), relying on refresh")
            }
        }
        if Set(kept) != Set(observed) {
            Log.info("devices", "\(kept.count) camera(s) watched")
        }
        observed = kept
    }

    private static func removeRunningListener(_ id: CMIOObjectID, _ block: @escaping CMIOObjectPropertyListenerBlock) {
        var addr = address(kCMIODevicePropertyDeviceIsRunningSomewhere)
        _ = CMIOObjectRemovePropertyListenerBlock(id, &addr, DispatchQueue.main, block)
    }

    private static func devices() -> [CMIOObjectID] {
        var addr = address(kCMIOHardwarePropertyDevices)
        var size: UInt32 = 0
        guard CMIOObjectGetPropertyDataSize(system, &addr, 0, nil, &size) == noErr, size > 0 else { return [] }
        var ids = [CMIOObjectID](repeating: 0, count: Int(size) / MemoryLayout<CMIOObjectID>.size)
        var used: UInt32 = 0
        guard CMIOObjectGetPropertyData(system, &addr, 0, nil, size, &used, &ids) == noErr else { return [] }
        return Array(ids.prefix(Int(used) / MemoryLayout<CMIOObjectID>.size))
    }

    private static func isRunningSomewhere(_ id: CMIOObjectID) -> Bool {
        var addr = address(kCMIODevicePropertyDeviceIsRunningSomewhere)
        var running: UInt32 = 0
        var used: UInt32 = 0
        let status = CMIOObjectGetPropertyData(id, &addr, 0, nil, UInt32(MemoryLayout<UInt32>.size), &used, &running)
        return status == noErr && running != 0
    }

    private static func address(_ selector: Int) -> CMIOObjectPropertyAddress {
        CMIOObjectPropertyAddress(
            mSelector: CMIOObjectPropertySelector(selector),
            mScope: CMIOObjectPropertyScope(kCMIOObjectPropertyScopeGlobal),
            mElement: CMIOObjectPropertyElement(kCMIOObjectPropertyElementMain)
        )
    }
}
