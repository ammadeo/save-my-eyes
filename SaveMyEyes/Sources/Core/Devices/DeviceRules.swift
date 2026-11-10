// Pure rules for device detection. No system APIs here.

import Foundation

enum DeviceRules {
    /// A device cannot say when it will go off, so while one is in use the break is held this
    /// long and the scheduler asks again (after a `refresh()`). Once every device is off the
    /// shared `Pause.afterMeeting` takes over.
    static let recheck: TimeInterval = 30
}
