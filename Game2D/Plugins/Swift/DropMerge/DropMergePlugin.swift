import SwiftUI
import UIKit

/// Drop & Merge — Swift SpriteKit mini-game plugin.
final class DropMergePlugin: MiniGamePlugin {

    var miniGame: MiniGame = MiniGame(
        id: MiniGameID(rawValue: "swift.drop-merge"),
        title: "Drop & Merge",
        subtitle: "Drop orbs · merge to grow",
        engine: MiniGameEngine.swift,
        symbolName: "circle.hexagongrid.fill",
        isAvailable: true
    )

    func makeViewController(context: MiniGameLaunchContext) -> UIViewController {
        let viewModel = DropMergeViewModel(
            settings: context.settings,
            hostEvents: context.hostEvents,
            onEvent: context.onEvent
        )
        let controller = UIHostingController(
            rootView: DropMergeView(viewModel: viewModel)
                .environmentObject(context.theme)
        )
        controller.view.backgroundColor = .clear
        return controller
    }
}
