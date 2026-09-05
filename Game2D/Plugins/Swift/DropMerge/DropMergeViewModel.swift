import Combine
import Foundation
import SpriteKit
import SwiftUI

final class DropMergeViewModel: ObservableObject {
    struct Input {
        let pauseTapped = PassthroughSubject<Void, Never>()
        let resumeTapped = PassthroughSubject<Void, Never>()
        let restartTapped = PassthroughSubject<Void, Never>()
        let settingsTapped = PassthroughSubject<Void, Never>()
        let exitTapped = PassthroughSubject<Void, Never>()
    }

    let input = Input()
    let scene: DropMergeScene

    @Published private(set) var score = 0
    @Published private(set) var highScore = 0
    @Published private(set) var currentItem: MergeItemDefinition?
    @Published private(set) var nextItem: MergeItemDefinition?
    @Published private(set) var gameState: DropMergeGameState = .ready

    private var settings: GameSettings
    private let onEvent: (MiniGamePluginEvent) -> Void
    private let commands = PassthroughSubject<DropMergeGameCommand, Never>()
    private let highScoreStore: HighScoreStoring
    private let audioService: DropMergeAudioService
    private let hapticService: DropMergeHapticService
    private var cancellables = Set<AnyCancellable>()
    private var hasReportedResult = false
    private var roundStartedAt: Date?
    private var userPaused = false

    init(
        settings: GameSettings,
        hostEvents: AnyPublisher<MiniGameHostEvent, Never>,
        onEvent: @escaping (MiniGamePluginEvent) -> Void,
        highScoreStore: HighScoreStoring = HighScoreStore(),
        // Size is assigned from DropMergeView once SpriteView has a real layout.
        scene: DropMergeScene = DropMergeScene(size: .zero)
    ) {
        self.settings = settings
        self.onEvent = onEvent
        self.highScoreStore = highScoreStore
        self.scene = scene
        self.audioService = DropMergeAudioService(soundEnabled: settings.soundEnabled)
        self.hapticService = DropMergeHapticService(hapticsEnabled: settings.hapticsEnabled)
        self.highScore = highScoreStore.load()

        scene.scaleMode = .resizeFill
        scene.backgroundColor = .clear

        bind(hostEvents: hostEvents)
        onEvent(.ready)
    }

    /// Called when the SwiftUI playfield gets a non-zero size after appear/layout.
    func updateSceneSize(_ size: CGSize) {
        scene.updatePlayfieldSize(size)
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
        roundStartedAt = Date()
        applySettings(settings)
        commands.send(.start)
        onEvent(.started)
    }

    private func restart() {
        userPaused = false
        hasReportedResult = false
        roundStartedAt = Date()
        commands.send(.restart)
        onEvent(.started)
    }

    private func pause(userInitiated: Bool) {
        guard gameState == .playing else { return }
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
            // Host resume while user still has pause overlay up — stay paused.
            return
        }
        guard gameState == .paused else { return }
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

    private func handleScene(_ event: DropMergeGameEvent) {
        switch event {
        case .scoreChanged(let value):
            score = value
            highScore = highScoreStore.saveIfHigher(value)
        case .nextItemChanged(let item):
            nextItem = item
        case .currentItemChanged(let item):
            currentItem = item
        case .itemDropped:
            audioService.playDrop()
            hapticService.drop()
        case .merged(_, _):
            audioService.playMerge()
            hapticService.merge()
        case .gameOver(let finalScore):
            score = finalScore
            highScore = highScoreStore.saveIfHigher(finalScore)
            gameState = .gameOver
            audioService.playGameOver()
            hapticService.gameOver()
            reportResultIfNeeded(finalScore: finalScore)
        case .stateChanged(let state):
            gameState = state
        }
    }

    private func reportResultIfNeeded(finalScore: Int) {
        guard !hasReportedResult else { return }
        hasReportedResult = true
        onEvent(
            .result(
                MiniGameResult(
                    score: finalScore,
                )
            )
        )
    }
}
