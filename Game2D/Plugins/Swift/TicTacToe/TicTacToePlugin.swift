import SwiftUI
import UIKit

/// Sample Swift mini-game. Extract this folder into its own XCFramework later
/// and register `TicTacToePlugin()` from the host after `import TicTacToe`.
final class TicTacToePlugin: MiniGamePlugin {

    var miniGame: MiniGame = MiniGame(
        id: MiniGameID(rawValue: "swift.tic-tac-toe"),
        title: "Tic Tac Toe",
        subtitle: "3×3 · player or bot",
        engine: MiniGameEngine.swift,
        symbolName: "square.grid.3x3.fill",
        isAvailable: true
    )

    func makeViewController(context: MiniGameLaunchContext) -> UIViewController {
        let viewModel = TicTacToeViewModel(
            settings: context.settings,
            hostEvents: context.hostEvents,
            onEvent: context.onEvent
        )
        let controller = UIHostingController(
            rootView: TicTacToeView(viewModel: viewModel)
                .environmentObject(context.theme)
        )
        controller.view.backgroundColor = .clear
        return controller
    }
}
