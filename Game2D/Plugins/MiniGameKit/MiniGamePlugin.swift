import Combine
import UIKit

/// Contract every mini-game XCFramework must expose.
///
/// Swift frameworks: implement this type in the public module and register it from the host.
/// Unity frameworks: wrap `UnityFramework` with `UnityMiniGamePlugin` (or a thin Swift adapter XCFramework).
///
/// Lifecycle is event-driven:
/// 1. Plugin UI loads and sends `.ready`.
/// 2. Host sends `.setting` then `.start`.
/// 3. Host may send `.pause` / `.resume` / `.setting` while running.
/// 4. Plugin sends `.result` when the round ends, `.exitRequested` to leave, or `.settingRequested` for host settings.
/// 5. Host sends `.stop` before tearing the session down.
protocol MiniGamePlugin: AnyObject {
	var miniGame: MiniGame { get }
    func makeViewController(context: MiniGameLaunchContext) -> UIViewController
}

/// Commands the host sends into a running mini-game.
enum MiniGameHostEvent: Equatable {
    case start
    case pause
    case resume
    case stop
    case setting(GameSettings)
}

/// Events a mini-game emits back to the host.
enum MiniGamePluginEvent: Equatable {
    case ready
    case started
    case paused
    case resumed
    case stopped
    case result(MiniGameResult)
    case settingRequested
    case exitRequested
}

struct MiniGameResult: Equatable {
    let score: Int?
    let level: Int?
    let duration: TimeInterval?
	
	init(score: Int? = nil, level: Int? = nil, duration: TimeInterval? = nil) {
		self.score = score
		self.level = level
		self.duration = duration
	}
}

struct MiniGameLaunchContext {
    let settings: GameSettings
    let theme: ThemeController
    let hostEvents: AnyPublisher<MiniGameHostEvent, Never>
    let onEvent: (MiniGamePluginEvent) -> Void
}
