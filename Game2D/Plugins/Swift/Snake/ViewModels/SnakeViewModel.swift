import Combine
import Foundation
import SpriteKit
import SwiftUI

final class SnakeViewModel: ObservableObject {
    struct Input {
        let playTapped = PassthroughSubject<Void, Never>()
        let pauseTapped = PassthroughSubject<Void, Never>()
        let resumeTapped = PassthroughSubject<Void, Never>()
        let restartTapped = PassthroughSubject<Void, Never>()
        let settingsTapped = PassthroughSubject<Void, Never>()
        let exitTapped = PassthroughSubject<Void, Never>()
        let swipe = PassthroughSubject<Direction, Never>()
    }

    let input = Input()
    let scene: SnakeScene

    @Published private(set) var score = 0
    @Published private(set) var highScore = 0
    @Published private(set) var state: SnakeGameState = .ready

    private var settings: GameSettings
    private let onEvent: (MiniGamePluginEvent) -> Void
    private let commands = PassthroughSubject<SnakeGameCommand, Never>()
    private let highScoreStore: SnakeHighScoreStoring
    private let audioService: SnakeAudioService
    private let hapticService: SnakeHapticService
    private var cancellables = Set<AnyCancellable>()
    private var hasReportedResult = false
    private var userPaused = false

    init(
        settings: GameSettings,
        hostEvents: AnyPublisher<MiniGameHostEvent, Never>,
        onEvent: @escaping (MiniGamePluginEvent) -> Void,
        highScoreStore: SnakeHighScoreStoring = SnakeHighScoreStore(),
        scene: SnakeScene = SnakeScene(size: .zero)
    ) {
        self.settings = settings
        self.onEvent = onEvent
        self.highScoreStore = highScoreStore
        self.scene = scene
        self.audioService = SnakeAudioService(soundEnabled: settings.soundEnabled)
        self.hapticService = SnakeHapticService(hapticsEnabled: settings.hapticsEnabled)
        self.highScore = highScoreStore.load()

        scene.scaleMode = .resizeFill
        scene.backgroundColor = .clear

        bind(hostEvents: hostEvents)
        onEvent(.ready)
    }

    func updateSceneSize(_ size: CGSize) {
        scene.updatePlayfieldSize(size)
    }

    func handleSwipe(translation: CGSize) {
        guard let direction = Direction.fromSwipe(translation) else { return }
        queueDirection(direction)
    }

    func handleDirectionTap(_ direction: Direction) {
        hapticService.turn()
        queueDirection(direction)
    }

    private func queueDirection(_ direction: Direction) {
        guard state == .playing || state == .ready else { return }
        input.swipe.send(direction)
    }

    private func bind(hostEvents: AnyPublisher<MiniGameHostEvent, Never>) {
        hostEvents
            .receive(on: DispatchQueue.main)
            .sink { [weak self] event in
                self?.handleHost(event)
            }
            .store(in: &cancellables)

        commands
            .receive(on: DispatchQueue.main)
            .sink { [weak self] command in
                self?.scene.handle(command)
            }
            .store(in: &cancellables)

        scene.events
            .receive(on: DispatchQueue.main)
            .sink { [weak self] event in
                self?.handleScene(event)
            }
            .store(in: &cancellables)

        input.playTapped
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.commands.send(.beginPlaying) }
            .store(in: &cancellables)

        input.pauseTapped
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.pause(userInitiated: true) }
            .store(in: &cancellables)

        input.resumeTapped
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.resume(userInitiated: true) }
            .store(in: &cancellables)

        input.restartTapped
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.restart() }
            .store(in: &cancellables)

        input.settingsTapped
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                self?.onEvent(.settingRequested)
            }
            .store(in: &cancellables)

        input.exitTapped
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                self?.onEvent(.exitRequested)
            }
            .store(in: &cancellables)

        input.swipe
            .receive(on: DispatchQueue.main)
            .sink { [weak self] direction in
                self?.commands.send(.queueDirection(direction))
            }
            .store(in: &cancellables)
    }

    private func handleHost(_ event: MiniGameHostEvent) {
        switch event {
        case .start:
            start()
        case .pause:
            pause(userInitiated: false)
        case .resume:
            resume(userInitiated: false)
        case .stop:
            stop()
        case .setting(let settings):
            applySettings(settings)
        }
    }

    private func start() {
        userPaused = false
        hasReportedResult = false
        applySettings(settings)
        commands.send(.start)
        onEvent(.started)
    }

    private func restart() {
        userPaused = false
        hasReportedResult = false
        commands.send(.restart)
        onEvent(.started)
    }

    private func pause(userInitiated: Bool) {
        guard state == .playing else { return }
        if userInitiated {
            userPaused = true
        }
        commands.send(.pause)
        onEvent(.paused)
    }

    private func resume(userInitiated: Bool) {
        if userInitiated {
            userPaused = false
        } else if userPaused {
            return
        }
        guard state == .paused else { return }
        commands.send(.resume)
        onEvent(.resumed)
    }

    private func stop() {
        commands.send(.stop)
        userPaused = false
        onEvent(.stopped)
    }

    private func applySettings(_ settings: GameSettings) {
        self.settings = settings
        audioService.update(soundEnabled: settings.soundEnabled)
        hapticService.update(hapticsEnabled: settings.hapticsEnabled)
        commands.send(.applyTheme(isDark: settings.appearance == .dark))
        scene.setReduceMotion(UIAccessibility.isReduceMotionEnabled)
    }

    private func handleScene(_ event: SnakeGameEvent) {
        switch event {
        case .scoreChanged(let value):
            score = value
            highScore = highScoreStore.saveIfHigher(value)
        case .stateChanged(let state):
            self.state = state
        case .ateFood(let score, _):
            self.score = score
            highScore = highScoreStore.saveIfHigher(score)
            audioService.playEat()
            hapticService.eat()
        case .gameOver(let finalScore, _):
            score = finalScore
            highScore = highScoreStore.saveIfHigher(finalScore)
            state = .gameOver
            audioService.playGameOver()
            hapticService.gameOver()
            reportResultIfNeeded(finalScore: finalScore)
        case .tickIntervalChanged:
            break
        }
    }

    private func reportResultIfNeeded(finalScore: Int) {
        guard !hasReportedResult else { return }
        hasReportedResult = true
        onEvent(.result(MiniGameResult(score: finalScore)))
    }
}

private extension Direction {
    static func fromSwipe(_ translation: CGSize, threshold: CGFloat = 24) -> Direction? {
        let dx = translation.width
        let dy = translation.height
        guard max(abs(dx), abs(dy)) >= threshold else { return nil }
        if abs(dx) > abs(dy) {
            return dx > 0 ? .right : .left
        }
        return dy > 0 ? .down : .up
    }
}
