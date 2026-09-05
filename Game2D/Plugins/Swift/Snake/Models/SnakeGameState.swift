import Foundation

enum SnakeGameState: Equatable {
    case ready
    case playing
    case paused
    case gameOver
}

enum SnakeCollision: Equatable {
    case wall
    case selfHit
}

enum SnakeTickOutcome: Equatable {
    case moved
    case ateFood(score: Int, length: Int)
    case died(SnakeCollision)
}
