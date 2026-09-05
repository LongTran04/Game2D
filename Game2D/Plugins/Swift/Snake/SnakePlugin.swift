import SwiftUI
import UIKit

final class SnakePlugin: MiniGamePlugin {

    var miniGame: MiniGame = MiniGame(
        id: MiniGameID(rawValue: "swift.snake"),
        title: "Snake",
        subtitle: "Swipe · eat · grow",
        engine: MiniGameEngine.swift,
        symbolName: "arrow.triangle.turn.up.right.diamond.fill",
        isAvailable: true
    )

    func makeViewController(context: MiniGameLaunchContext) -> UIViewController {
        let viewModel = SnakeViewModel(
            settings: context.settings,
            hostEvents: context.hostEvents,
            onEvent: context.onEvent
        )
        let controller = UIHostingController(
            rootView: SnakeGameView(viewModel: viewModel)
                .environmentObject(context.theme)
        )
        controller.view.backgroundColor = .clear
        return controller
    }
}
