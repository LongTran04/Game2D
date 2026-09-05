import Foundation

enum SnakeGameCommand {
    case start
    case beginPlaying
    case pause
    case resume
    case restart
    case stop
    case queueDirection(Direction)
    case applyTheme(isDark: Bool)
}
