import Combine
import Foundation

protocol GetSettingsUseCase {
    func execute() -> AnyPublisher<GameSettings, Never>
    func observe() -> AnyPublisher<GameSettings, Never>
}

final class DefaultGetSettingsUseCase: GetSettingsUseCase {
    private let repository: SettingsRepository

    init(repository: SettingsRepository) {
        self.repository = repository
    }

    func execute() -> AnyPublisher<GameSettings, Never> {
        repository.fetchSettings()
    }

    func observe() -> AnyPublisher<GameSettings, Never> {
        repository.observeSettings()
    }
}
