import Combine
import Foundation

final class SettingsRepositoryImpl: SettingsRepository {
    private let localDataSource: SettingsLocalDataSource
    private let settingsSubject: CurrentValueSubject<GameSettings, Never>

    init(localDataSource: SettingsLocalDataSource) {
        self.localDataSource = localDataSource
        self.settingsSubject = CurrentValueSubject(localDataSource.currentSettings())
    }

    func fetchSettings() -> AnyPublisher<GameSettings, Never> {
        Just(settingsSubject.value)
            .eraseToAnyPublisher()
    }

    func observeSettings() -> AnyPublisher<GameSettings, Never> {
        settingsSubject
            .eraseToAnyPublisher()
    }

    func saveSettings(_ settings: GameSettings) -> AnyPublisher<Void, DomainError> {
        localDataSource.save(settings)
            .handleEvents(receiveOutput: { [weak self] in
                self?.settingsSubject.send(settings)
            })
            .eraseToAnyPublisher()
    }
}
