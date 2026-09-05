import Foundation

enum SnakeGameEvent {
    case scoreChanged(Int)
    case stateChanged(SnakeGameState)
    case ateFood(score: Int, length: Int)
    case gameOver(finalScore: Int, reason: SnakeCollision)
    case tickIntervalChanged(TimeInterval)
}
