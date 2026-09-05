import Foundation

enum Direction: Equatable {
    case up
    case down
    case left
    case right

    var opposite: Direction {
        switch self {
        case .up: return .down
        case .down: return .up
        case .left: return .right
        case .right: return .left
        }
    }

    var deltaX: Int {
        switch self {
        case .left: return -1
        case .right: return 1
        case .up, .down: return 0
        }
    }

    var deltaY: Int {
        switch self {
        case .up: return 1
        case .down: return -1
        case .left, .right: return 0
        }
    }

    var symbolName: String {
        switch self {
        case .up: return "chevron.up"
        case .down: return "chevron.down"
        case .left: return "chevron.left"
        case .right: return "chevron.right"
        }
    }

    var accessibilityLabel: String {
        switch self {
        case .up: return "Up"
        case .down: return "Down"
        case .left: return "Left"
        case .right: return "Right"
        }
    }
}
