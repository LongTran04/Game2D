import AudioToolbox
import Foundation

final class SnakeAudioService {
    private var soundEnabled: Bool

    init(soundEnabled: Bool) {
        self.soundEnabled = soundEnabled
    }

    func update(soundEnabled: Bool) {
        self.soundEnabled = soundEnabled
    }

    func playEat() {
        play(systemSoundID: 1104)
    }

    func playGameOver() {
        play(systemSoundID: 1053)
    }

    private func play(systemSoundID: SystemSoundID) {
        guard soundEnabled else { return }
        AudioServicesPlaySystemSound(systemSoundID)
    }
}
