import Combine
import Foundation

protocol SaveSettingsUseCase {
    func execute(_ settings: GameSettings) -> AnyPublisher<Void, DomainError>
}

final class DefaultSaveSettingsUseCase: SaveSettingsUseCase {
    private let repository: SettingsRepository

    init(repository: SettingsRepository) {
        self.repository = repository
    }

    func execute(_ settings: GameSettings) -> AnyPublisher<Void, DomainError> {
        repository.saveSettings(settings)
    }
}
