import Foundation

protocol SnakeHighScoreStoring {
    func load() -> Int
    func saveIfHigher(_ score: Int) -> Int
}

final class SnakeHighScoreStore: SnakeHighScoreStoring {
    private let key = "game2d.snake.highScore"
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func load() -> Int {
        defaults.integer(forKey: key)
    }

    @discardableResult
    func saveIfHigher(_ score: Int) -> Int {
        let current = load()
        let best = max(current, score)
        defaults.set(best, forKey: key)
        return best
    }
}
