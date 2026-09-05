import CoreGraphics
import Foundation

enum DropMergeGameCommand {
    case start
    case aim(xPosition: CGFloat)
    case drop(xPosition: CGFloat)
    case pause
    case resume
    case restart
    case stop
    case applyTheme(isDark: Bool)
}
