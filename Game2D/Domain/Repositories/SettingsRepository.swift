import Combine
import Foundation

protocol SettingsRepository {
    func fetchSettings() -> AnyPublisher<GameSettings, Never>
    func observeSettings() -> AnyPublisher<GameSettings, Never>
    func saveSettings(_ settings: GameSettings) -> AnyPublisher<Void, DomainError>
}
