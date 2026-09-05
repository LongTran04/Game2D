import UIKit

final class DropMergeHapticService {
    private var hapticsEnabled: Bool
    private let light = UIImpactFeedbackGenerator(style: .light)
    private let medium = UIImpactFeedbackGenerator(style: .medium)
    private let heavy = UIImpactFeedbackGenerator(style: .heavy)

    init(hapticsEnabled: Bool) {
        self.hapticsEnabled = hapticsEnabled
        light.prepare()
        medium.prepare()
        heavy.prepare()
    }

    func update(hapticsEnabled: Bool) {
        self.hapticsEnabled = hapticsEnabled
    }

    func drop() {
        guard hapticsEnabled else { return }
        light.impactOccurred()
    }

    func merge() {
        guard hapticsEnabled else { return }
        medium.impactOccurred()
    }

    func gameOver() {
        guard hapticsEnabled else { return }
        heavy.impactOccurred()
    }
}
