import AVFoundation
import Foundation

/// Plays the short/long break cue from `Resources/Sounds` when UI sounds are on.
/// `play` returns once the cue ended (or at once when sounds are off or the file fails).
@MainActor
final class SoundPlayer: NSObject, AVAudioPlayerDelegate {
    /// Read at play time so a settings change applies to the next cue.
    var isEnabled: () -> Bool = { true }

    private var players: [ObjectIdentifier: (AVAudioPlayer, CheckedContinuation<Void, Never>)] = [:]

    func play(long: Bool) async {
        guard isEnabled() else { return }
        let name = long ? "long" : "short"
        guard let url = Bundle.main.url(forResource: name, withExtension: "mp3", subdirectory: "Sounds")
            ?? Bundle.main.url(forResource: name, withExtension: "mp3") else {
            Log.warn("sound", "\(name).mp3 not in bundle")
            return
        }
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            do {
                let player = try AVAudioPlayer(contentsOf: url)
                player.delegate = self
                players[ObjectIdentifier(player)] = (player, continuation)
                if !player.play() {
                    players.removeValue(forKey: ObjectIdentifier(player))
                    continuation.resume()
                } else {
                    Log.info("sound", "playing \(name).mp3")
                }
            } catch {
                Log.warn("sound", "cannot play \(name).mp3: \(error)")
                continuation.resume()
            }
        }
    }

    nonisolated func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        Task { @MainActor in self.finish(player) }
    }

    nonisolated func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        Task { @MainActor in self.finish(player) }
    }

    private func finish(_ player: AVAudioPlayer) {
        if let (_, continuation) = players.removeValue(forKey: ObjectIdentifier(player)) {
            continuation.resume()
        }
    }
}
