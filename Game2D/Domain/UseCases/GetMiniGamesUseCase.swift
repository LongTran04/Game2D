import Combine
import Foundation

protocol GetMiniGamesUseCase {
    func execute() -> AnyPublisher<[MiniGame], Never>
}

final class DefaultGetMiniGamesUseCase: GetMiniGamesUseCase {
    private let repository: MiniGameRepository

    init(repository: MiniGameRepository) {
        self.repository = repository
    }

    func execute() -> AnyPublisher<[MiniGame], Never> {
        repository.fetchCatalog()
    }
}
