import Combine
import SnakeEngine
import UIKit

final class SnakePlugin: MiniGamePlugin {
    let miniGame = MiniGame(
        id: MiniGameID(rawValue: "swift.snake"),
        title: "Snake",
        subtitle: "Swipe · eat · grow",
        engine: .swift,
        symbolName: "arrow.triangle.turn.up.right.diamond.fill",
        isAvailable: true
    )

    func makeViewController(context: MiniGameLaunchContext) -> UIViewController {
        let events = context.hostEvents
            .map(GameEngineHostEvent.init)
            .eraseToAnyPublisher()

        return SnakeGameEngine(
            settings: GameEngineSettings(context.settings),
            hostEvents: events,
            onEvent: {
                if let event = MiniGamePluginEvent($0) {
                    context.onEvent(event)
                }
            }
        ).makeViewController()
    }
}

private extension GameEngineSettings {
    nonisolated init(_ settings: GameSettings) {
        self.init(
            soundEnabled: settings.soundEnabled,
            musicEnabled: settings.musicEnabled,
            hapticsEnabled: settings.hapticsEnabled,
            appearance: settings.appearance == .dark ? .dark : .light
        )
    }
}

private extension GameEngineHostEvent {
    nonisolated init(_ event: MiniGameHostEvent) {
        switch event {
        case .start: self = .start
        case .pause: self = .pause
        case .resume: self = .resume
        case .stop: self = .stop
        case .setting(let settings): self = .setting(GameEngineSettings(settings))
        }
    }
}

private extension MiniGamePluginEvent {
    nonisolated init?(_ event: GameEngineEvent) {
        switch event {
        case .ready: self = .ready
        case .started: self = .started
        case .paused: self = .paused
        case .resumed: self = .resumed
        case .stopped: self = .stopped
        case .result(let result):
            self = .result(
                MiniGameResult(
                    score: result.score,
                    level: result.level,
                    duration: result.duration
                )
            )
        case .settingRequested: self = .settingRequested
        case .exitRequested: self = .exitRequested
        @unknown default: return nil
        }
    }
}
