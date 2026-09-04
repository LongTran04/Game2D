import Combine
import Foundation

protocol AppSessionLocalDataSource {
    func hasCompletedWelcome() -> Bool
    func markWelcomeCompleted()
}

final class UserDefaultsAppSessionLocalDataSource: AppSessionLocalDataSource {
    private let userDefaults: UserDefaults
    private let storageKey = "game2d.hasCompletedWelcome"

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    func hasCompletedWelcome() -> Bool {
        userDefaults.bool(forKey: storageKey)
    }

    func markWelcomeCompleted() {
        userDefaults.set(true, forKey: storageKey)
    }
}
