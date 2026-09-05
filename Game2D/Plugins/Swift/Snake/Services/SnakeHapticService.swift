import UIKit

final class SnakeHapticService {
    private var hapticsEnabled: Bool
    private let light = UIImpactFeedbackGenerator(style: .light)
    private let heavy = UIImpactFeedbackGenerator(style: .heavy)

    init(hapticsEnabled: Bool) {
        self.hapticsEnabled = hapticsEnabled
        light.prepare()
        heavy.prepare()
    }

    func update(hapticsEnabled: Bool) {
        self.hapticsEnabled = hapticsEnabled
    }

    func eat() {
        guard hapticsEnabled else { return }
        light.impactOccurred()
    }

    func turn() {
        guard hapticsEnabled else { return }
        light.impactOccurred()
    }

    func gameOver() {
        guard hapticsEnabled else { return }
        heavy.impactOccurred()
    }
}
