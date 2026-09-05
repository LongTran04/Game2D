import Foundation

struct GridPosition: Equatable, Hashable {
    var x: Int
    var y: Int

    func moved(in direction: Direction) -> GridPosition {
        GridPosition(x: x + direction.deltaX, y: y + direction.deltaY)
    }
}
