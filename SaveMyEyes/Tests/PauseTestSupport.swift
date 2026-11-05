import Foundation
@testable import SaveMyEyes

extension Pause {
    /// A pause for tests that only care how long it holds.
    static func holding(until: Date, label: String = "test") -> Pause {
        Pause(holdsUntil: until, endsAt: until, symbol: "pause", label: L(verbatim: label), next: L(verbatim: ""))
    }
}
