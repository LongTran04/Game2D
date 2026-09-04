import Foundation

/// Host-side registry for bundled and linked mini-game XCFrameworks.
///
/// Registration happens at app launch:
/// ```
/// import TicTacToe
/// registry.register(TicTacToePlugin())
/// registry.register(UnityMiniGamePlugin(sceneName: "OrbitRun"))
/// ```
final class MiniGamePluginRegistry {
    private var plugins: [MiniGameID: MiniGamePlugin] = [:]

    func register(_ plugin: MiniGamePlugin) {
		plugins[plugin.miniGame.id] = plugin
    }

    func plugin(for id: MiniGameID) -> MiniGamePlugin? {
        plugins[id]
    }

    func allPlugins() -> [MiniGamePlugin] {
		plugins.values.sorted { $0.miniGame.title < $1.miniGame.title }
    }

    func allMiniGames() -> [MiniGame] {
        allPlugins().map(catalogItem(for:))
    }

    func miniGame(for id: MiniGameID) -> MiniGame? {
        plugin(for: id).map(catalogItem(for:))
    }

    private func catalogItem(for plugin: MiniGamePlugin) -> MiniGame {
        MiniGame(
			id: plugin.miniGame.id,
			title: plugin.miniGame.title,
			subtitle: plugin.miniGame.subtitle,
			engine: plugin.miniGame.engine,
			symbolName: plugin.miniGame.symbolName,
			isAvailable: plugin.miniGame.isAvailable
        )
    }
}
