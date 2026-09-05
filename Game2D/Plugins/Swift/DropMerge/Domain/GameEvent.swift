import Foundation

enum DropMergeGameEvent {
    case scoreChanged(Int)
    case nextItemChanged(MergeItemDefinition)
    case currentItemChanged(MergeItemDefinition)
    case itemDropped
    case merged(level: Int, points: Int)
    case gameOver(finalScore: Int)
    case stateChanged(DropMergeGameState)
}
