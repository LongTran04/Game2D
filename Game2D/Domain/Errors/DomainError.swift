import Foundation

nonisolated enum DomainError: Error, Equatable {
    case persistenceFailed
    case miniGameNotFound
}
