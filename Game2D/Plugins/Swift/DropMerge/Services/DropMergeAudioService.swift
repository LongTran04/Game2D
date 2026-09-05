import AudioToolbox
import Foundation

final class DropMergeAudioService {
    private var soundEnabled: Bool

    init(soundEnabled: Bool) {
        self.soundEnabled = soundEnabled
    }

    func update(soundEnabled: Bool) {
        self.soundEnabled = soundEnabled
    }

    func playDrop() {
        play(systemSoundID: 1104)
    }

    func playMerge() {
        play(systemSoundID: 1057)
    }

    func playGameOver() {
        play(systemSoundID: 1053)
    }

    private func play(systemSoundID: SystemSoundID) {
        guard soundEnabled else { return }
        AudioServicesPlaySystemSound(systemSoundID)
    }
}
