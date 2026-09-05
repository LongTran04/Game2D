import Foundation

struct GameConfiguration: Equatable {
    var columns: Int
    var rows: Int
    var initialSnakeLength: Int
    var initialDirection: Direction
    var initialTickInterval: TimeInterval
    var minimumTickInterval: TimeInterval
    var tickReductionPerMilestone: TimeInterval
    var speedMilestoneScore: Int
    var pointsPerFood: Int

    static let `default` = GameConfiguration(
        columns: 20,
        rows: 20,
        initialSnakeLength: 3,
        initialDirection: .right,
        initialTickInterval: 0.20,
        minimumTickInterval: 0.08,
        tickReductionPerMilestone: 0.012,
        speedMilestoneScore: 5,
        pointsPerFood: 1
    )

    var cellCount: Int { columns * rows }

    func contains(_ position: GridPosition) -> Bool {
        position.x >= 0
            && position.y >= 0
            && position.x < columns
            && position.y < rows
    }

    func tickInterval(forScore score: Int) -> TimeInterval {
        let milestones = max(0, score) / speedMilestoneScore
        let reduced = initialTickInterval - TimeInterval(milestones) * tickReductionPerMilestone
        return max(minimumTickInterval, reduced)
    }

    func initialSnake() -> [GridPosition] {
        let head = GridPosition(x: columns / 2, y: rows / 2)
        let opposite = initialDirection.opposite
        return (0..<initialSnakeLength).map { offset in
            var position = head
            for _ in 0..<offset {
                position = position.moved(in: opposite)
            }
            return position
        }
    }
}

protocol FoodSpawning {
    func spawn(
        excluding occupied: Set<GridPosition>,
        columns: Int,
        rows: Int
    ) -> GridPosition?
}

struct RandomFoodSpawner: FoodSpawning {
    func spawn(
        excluding occupied: Set<GridPosition>,
        columns: Int,
        rows: Int
    ) -> GridPosition? {
        var empty: [GridPosition] = []
        empty.reserveCapacity(max(0, columns * rows - occupied.count))
        for y in 0..<rows {
            for x in 0..<columns {
                let position = GridPosition(x: x, y: y)
                if !occupied.contains(position) {
                    empty.append(position)
                }
            }
        }
        return empty.randomElement()
    }
}
