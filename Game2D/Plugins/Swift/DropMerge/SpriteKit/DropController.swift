import Foundation

/// Bag randomizer over the lowest droppable levels to avoid unfair streaks.
final class DropBagRandomizer {
    private let maxLevel: Int
    private var bag: [Int] = []

    init(maxLevel: Int = MergeCatalog.droppableMaxLevel) {
        self.maxLevel = max(1, min(maxLevel, MergeCatalog.maxLevel))
        refill()
    }

    func nextLevel() -> Int {
        if bag.isEmpty {
            refill()
        }
        return bag.removeFirst()
    }

    func peekNextLevel() -> Int {
        if bag.isEmpty {
            refill()
        }
        return bag[0]
    }

    func reset() {
        bag.removeAll()
        refill()
    }

    private func refill() {
        var levels = Array(1...maxLevel)
        // Double-weight the lowest three for gentler early game.
        levels.append(contentsOf: 1...min(3, maxLevel))
        bag = levels.shuffled()
    }
}
