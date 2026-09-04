import Combine
import Foundation

final class MiniGameRepositoryImpl: MiniGameRepository {
    private let registry: MiniGamePluginRegistry

    init(registry: MiniGamePluginRegistry) {
        self.registry = registry
    }

    func fetchCatalog() -> AnyPublisher<[MiniGame], Never> {
        Just(registry.allMiniGames())
            .eraseToAnyPublisher()
    }

    func fetchMiniGame(id: MiniGameID) -> AnyPublisher<MiniGame, DomainError> {
        if let miniGame = registry.miniGame(for: id) {
            return Just(miniGame)
                .setFailureType(to: DomainError.self)
                .eraseToAnyPublisher()
        }

        return Fail(error: .miniGameNotFound)
            .eraseToAnyPublisher()
    }
}
