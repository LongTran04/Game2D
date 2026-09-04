import Foundation

enum AppRoute: Hashable {
    case setting
    case miniGame(MiniGameID)
}

enum AppFlow: Equatable {
    case splash
    case welcome
    case gameBoard
}
