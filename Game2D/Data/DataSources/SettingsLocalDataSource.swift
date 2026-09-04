import Combine
import Foundation

protocol SettingsLocalDataSource {
    func currentSettings() -> GameSettings
    func load() -> AnyPublisher<GameSettings, Never>
    func save(_ settings: GameSettings) -> AnyPublisher<Void, DomainError>
}

final class UserDefaultsSettingsLocalDataSource: SettingsLocalDataSource {
    private let userDefaults: UserDefaults
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder
    private let storageKey = "game2d.settings.v2"

    init(
        userDefaults: UserDefaults = .standard,
        encoder: JSONEncoder = JSONEncoder(),
        decoder: JSONDecoder = JSONDecoder()
    ) {
        self.userDefaults = userDefaults
        self.encoder = encoder
        self.decoder = decoder
    }

    func currentSettings() -> GameSettings {
        guard let data = userDefaults.data(forKey: storageKey),
              let settings = try? decoder.decode(GameSettings.self, from: data) else {
            return .default
        }
        return settings
    }

    func load() -> AnyPublisher<GameSettings, Never> {
        Just(currentSettings())
            .eraseToAnyPublisher()
    }

    func save(_ settings: GameSettings) -> AnyPublisher<Void, DomainError> {
        Deferred {
            Future<Void, DomainError> { [weak self] promise in
                guard let self else {
                    promise(.failure(.persistenceFailed))
                    return
                }

                do {
                    let data = try self.encoder.encode(settings)
                    self.userDefaults.set(data, forKey: self.storageKey)
                    promise(.success(()))
                } catch {
                    promise(.failure(.persistenceFailed))
                }
            }
        }
        .eraseToAnyPublisher()
    }
}
