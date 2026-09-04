import Combine
import Foundation

protocol MiniGameRepository {
    func fetchCatalog() -> AnyPublisher<[MiniGame], Never>
    func fetchMiniGame(id: MiniGameID) -> AnyPublisher<MiniGame, DomainError>
}
