import CoreGraphics
import Foundation
import SpriteKit

final class GameOverDetector {
    private let dangerDuration: TimeInterval = 1.5
    private let settledSpeedThreshold: CGFloat = 40
    private var timers: [UUID: TimeInterval] = [:]

    var dangerLineY: CGFloat = 0

    func reset() {
        timers.removeAll()
    }

    /// Returns `true` when a settled dropped node has stayed above the danger line long enough.
    func update(items: [MergeItemNode], deltaTime: TimeInterval) -> Bool {
        var activeAbove = Set<UUID>()

        for item in items {
            guard item.isDropped, !item.isPreview, !item.isMerging else { continue }
            guard item.spawnImmunityRemaining <= 0 else { continue }

            let speed = item.physicsBody?.velocity.speed ?? 0
            let aboveLine = item.position.y >= dangerLineY

            guard aboveLine, speed < settledSpeedThreshold else {
                timers[item.itemID] = nil
                continue
            }

            activeAbove.insert(item.itemID)
            let elapsed = (timers[item.itemID] ?? 0) + deltaTime
            timers[item.itemID] = elapsed
            if elapsed >= dangerDuration {
                return true
            }
        }

        timers = timers.filter { activeAbove.contains($0.key) }
        return false
    }
}

private extension CGVector {
    var speed: CGFloat {
        sqrt(dx * dx + dy * dy)
    }
}
