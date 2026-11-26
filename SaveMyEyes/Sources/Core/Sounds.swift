import AVFoundation
import Foundation

/// Plays the short/long break cue from `Resources/Sounds` when UI sounds are on.
/// `play` returns once the cue ended, after `timeout` at the latest, or at once when sounds
/// are off or the file fails.
///
/// `AVAudioPlayer.play()` starts the audio device synchronously and can block for a long time:
/// on a dark wake with the lid closed it never returned, the cover watchdog saw a stuck main
/// thread and crashed the app. So the player lives on its own queue, and a break never waits
/// on a cue for more than `timeout`.
final class SoundPlayer: NSObject, AVAudioPlayerDelegate, @unchecked Sendable {
    /// Both cues are under 2 s.
    static let timeout: TimeInterval = 5

    /// Read at play time so a settings change applies to the next cue.
    @MainActor var isEnabled: () -> Bool = { true }

    private let queue = DispatchQueue(label: "com.ammadeo.savemyeyes.sound", qos: .userInitiated)
    /// Touched only on `queue`.
    private var players: [ObjectIdentifier: (AVAudioPlayer, Once)] = [:]

    @MainActor
    func play(long: Bool) async {
        guard isEnabled() else { return }
        let name = long ? "long" : "short"
        guard let url = Bundle.main.url(forResource: name, withExtension: "mp3", subdirectory: "Sounds")
            ?? Bundle.main.url(forResource: name, withExtension: "mp3") else {
            Log.warn("sound", "\(name).mp3 not in bundle")
            return
        }
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            let once = Once(continuation)
            queue.async { [self] in start(url, name: name, once: once) }
            DispatchQueue.main.asyncAfter(deadline: .now() + Self.timeout) {
                if once.resume() { Log.warn("sound", "\(name).mp3 did not finish in \(Self.timeout) s") }
            }
        }
    }

    private func start(_ url: URL, name: String, once: Once) {
        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.delegate = self
            players[ObjectIdentifier(player)] = (player, once)
            if player.play() {
                Log.info("sound", "playing \(name).mp3")
            } else {
                players.removeValue(forKey: ObjectIdentifier(player))
                once.resume()
            }
        } catch {
            Log.warn("sound", "cannot play \(name).mp3: \(error)")
            once.resume()
        }
    }

    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        queue.async { [self] in finish(player) }
    }

    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        queue.async { [self] in finish(player) }
    }

    private func finish(_ player: AVAudioPlayer) {
        players.removeValue(forKey: ObjectIdentifier(player))?.1.resume()
    }
}

/// Resumes a continuation exactly once, whichever of the cue's end and the timeout comes first.
private final class Once: @unchecked Sendable {
    private let lock = NSLock()
    private var continuation: CheckedContinuation<Void, Never>?

    init(_ continuation: CheckedContinuation<Void, Never>) { self.continuation = continuation }

    /// True if this call resumed it.
    @discardableResult
    func resume() -> Bool {
        lock.lock()
        let pending = continuation
        continuation = nil
        lock.unlock()
        pending?.resume()
        return pending != nil
    }
}
