import Foundation

enum ScoreRules {
    static let baseScore = 1

    /// Points for creating an item: base × 2^(level − 1).
    static func points(for level: Int) -> Int {
        guard level >= 1 else { return 0 }
        return baseScore * (1 << (level - 1))
    }

    static func points(for definition: MergeItemDefinition) -> Int {
        points(for: definition.level)
    }
}
