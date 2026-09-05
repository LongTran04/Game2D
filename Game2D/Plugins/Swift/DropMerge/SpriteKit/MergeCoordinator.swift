import CoreGraphics
import Foundation
import SpriteKit

struct PendingMerge {
    let firstID: UUID
    let secondID: UUID
    let level: Int
    let midpoint: CGPoint
}

final class MergeCoordinator {
    private var pending: [PendingMerge] = []
    private var claimedIDs = Set<UUID>()

    var hasPending: Bool { !pending.isEmpty }

    @discardableResult
    func enqueueIfPossible(
        first: MergeItemNode,
        second: MergeItemNode,
        ignoringSpawnImmunity: Bool = false
    ) -> Bool {
        guard first.canParticipateInMerge(ignoringSpawnImmunity: ignoringSpawnImmunity),
              second.canParticipateInMerge(ignoringSpawnImmunity: ignoringSpawnImmunity)
        else { return false }
        guard first.level == second.level else { return false }
        guard first.level < MergeCatalog.maxLevel else { return false }
        guard !claimedIDs.contains(first.itemID), !claimedIDs.contains(second.itemID) else { return false }

        first.isMerging = true
        second.isMerging = true
        claimedIDs.insert(first.itemID)
        claimedIDs.insert(second.itemID)

        let midpoint = CGPoint(
            x: (first.position.x + second.position.x) / 2,
            y: (first.position.y + second.position.y) / 2
        )
        pending.append(
            PendingMerge(
                firstID: first.itemID,
                secondID: second.itemID,
                level: first.level,
                midpoint: midpoint
            )
        )
        return true
    }

    func drainPending() -> [PendingMerge] {
        let result = pending
        pending.removeAll()
        for merge in result {
            claimedIDs.remove(merge.firstID)
            claimedIDs.remove(merge.secondID)
        }
        return result
    }

    func reset() {
        pending.removeAll()
        claimedIDs.removeAll()
    }
}
