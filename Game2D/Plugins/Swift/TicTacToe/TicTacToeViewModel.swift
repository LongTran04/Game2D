import Combine
import Foundation
import UIKit

final class TicTacToeViewModel: ObservableObject {
    struct Input {
        let cellTapped = PassthroughSubject<Int, Never>()
        let modeSelected = PassthroughSubject<TicTacToePlayMode, Never>()
        let playAgainTapped = PassthroughSubject<Void, Never>()
        let changeModeTapped = PassthroughSubject<Void, Never>()
        let pauseTapped = PassthroughSubject<Void, Never>()
        let resumeTapped = PassthroughSubject<Void, Never>()
        let settingsTapped = PassthroughSubject<Void, Never>()
        let exitTapped = PassthroughSubject<Void, Never>()
    }

    let input = Input()

    @Published private(set) var cells: [TicTacToeCell] = []
    @Published private(set) var currentMark: TicTacToeMark = .x
    @Published private(set) var winningLine: [Int] = []
    @Published private(set) var mode: TicTacToePlayMode?
    @Published private(set) var outcome: TicTacToeOutcome?
    @Published private(set) var isPickingMode = true
    @Published private(set) var isPaused = false
    @Published private(set) var isBotThinking = false

    var isComplete: Bool { outcome != nil }

    var statusText: String {
        if isPickingMode { return "Choose a mode" }
        if isPaused { return "Paused" }
        switch outcome {
        case .win(let mark):
            if case .versusBot = mode {
                return mark == .x ? "You win" : "Bot wins"
            }
            return "\(mark.label) wins"
        case .draw:
            return "Draw"
        case nil:
            if isBotThinking { return "Bot is thinking…" }
            if case .versusBot = mode { return "Your turn" }
            return "\(currentMark.label)'s turn"
        }
    }

    var resultTitle: String { statusText }

    var resultDetail: String {
        switch (outcome, mode) {
        case (.win(.x), .versusBot(.easy)): return "Nice — easy bot beaten"
        case (.win(.x), .versusBot(.normal)): return "Solid play against the bot"
        case (.win(.x), .versusBot(.hard)): return "You beat the unbeatable line"
        case (.win(.o), .versusBot): return "The bot took this round"
        case (.win(let mark), .versusPlayer): return "\(mark.label) takes the round"
        case (.draw, .versusBot): return "Nobody claimed the board"
        case (.draw, .versusPlayer): return "Evenly matched"
        case (_, .none), (nil, _): return ""
        }
    }

    private var session: TicTacToeSession?
    private var selectedMode: TicTacToePlayMode?
    private var settings: GameSettings
    private let onEvent: (MiniGamePluginEvent) -> Void
    private var cancellables = Set<AnyCancellable>()
    private var hasReportedResult = false
    private var roundStartedAt: Date?
    private var botWorkItem: DispatchWorkItem?

    init(
        settings: GameSettings,
        hostEvents: AnyPublisher<MiniGameHostEvent, Never>,
        onEvent: @escaping (MiniGamePluginEvent) -> Void
    ) {
        self.settings = settings
        self.onEvent = onEvent
        cells = (0..<TicTacToeSession.cellCount).map { TicTacToeCell(id: $0, mark: nil) }
        bind(hostEvents: hostEvents)
        onEvent(.ready)
    }

    private func bind(hostEvents: AnyPublisher<MiniGameHostEvent, Never>) {
        hostEvents
            .receive(on: DispatchQueue.main)
            .sink { [weak self] event in
                self?.handle(event)
            }
            .store(in: &cancellables)

        input.cellTapped
            .receive(on: DispatchQueue.main)
            .sink { [weak self] cellID in
                self?.placeHuman(at: cellID)
            }
            .store(in: &cancellables)

        input.modeSelected
            .receive(on: DispatchQueue.main)
            .sink { [weak self] mode in
                self?.beginMatch(mode: mode)
            }
            .store(in: &cancellables)

        input.playAgainTapped
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                self?.playAgain()
            }
            .store(in: &cancellables)

        input.changeModeTapped
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                self?.showModePicker()
            }
            .store(in: &cancellables)

        input.pauseTapped
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                self?.pause()
            }
            .store(in: &cancellables)

        input.resumeTapped
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                self?.resume()
            }
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

    private func handle(_ event: MiniGameHostEvent) {
        switch event {
        case .start:
            start()
        case .pause:
            pause()
        case .resume:
            resume()
        case .stop:
            stop()
        case .setting(let settings):
            self.settings = settings
        }
    }

    private func start() {
        isPaused = false
        hasReportedResult = false
        cancelBotMove()
        if let selectedMode {
            beginMatch(mode: selectedMode)
        } else {
            showModePicker()
        }
        onEvent(.started)
    }

    private func beginMatch(mode: TicTacToePlayMode) {
        selectedMode = mode
        hasReportedResult = false
        isPaused = false
        isPickingMode = false
        roundStartedAt = Date()
        apply(TicTacToeSession.make(mode: mode))
        scheduleBotMoveIfNeeded()
    }

    private func playAgain() {
        guard let selectedMode else {
            showModePicker()
            return
        }
        beginMatch(mode: selectedMode)
    }

    private func showModePicker() {
        cancelBotMove()
        isPickingMode = true
        isPaused = false
        isBotThinking = false
        hasReportedResult = false
        session = nil
        outcome = nil
        winningLine = []
        currentMark = .x
        cells = (0..<TicTacToeSession.cellCount).map { TicTacToeCell(id: $0, mark: nil) }
        mode = nil
    }

    private func pause() {
        guard !isPaused, !isComplete, !isPickingMode else { return }
        guard var session, session.isPlaying else { return }
        cancelBotMove()
        session.pause()
        apply(session)
        isPaused = true
        onEvent(.paused)
    }

    private func resume() {
        guard isPaused, !isComplete, !isPickingMode else { return }
        guard var session else { return }
        session.resume()
        apply(session)
        isPaused = false
        onEvent(.resumed)
        scheduleBotMoveIfNeeded()
    }

    private func stop() {
        cancelBotMove()
        if var session {
            session.stop()
            apply(session)
        }
        isPaused = false
        isBotThinking = false
        onEvent(.stopped)
    }

    private func placeHuman(at cellID: Int) {
        guard var session, !isPaused, !isPickingMode, session.isHumanTurn else { return }
        guard session.place(at: cellID) else { return }
        if settings.hapticsEnabled {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }
        apply(session)
        reportResultIfNeeded()
        scheduleBotMoveIfNeeded()
    }

    private func performBotMove() {
        guard var session, !isPaused, session.isBotTurn else { return }
        guard let cellID = TicTacToeBot.moveIndex(in: session) else { return }
        guard session.place(at: cellID) else { return }
        if settings.hapticsEnabled {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        }
        apply(session)
        reportResultIfNeeded()
    }

    private func scheduleBotMoveIfNeeded() {
        cancelBotMove()
        guard let session, session.isBotTurn, !isPaused else { return }
        isBotThinking = true
        let delay: TimeInterval
        switch session.mode {
        case .versusBot(.easy): delay = 0.35
        case .versusBot(.normal): delay = 0.5
        case .versusBot(.hard): delay = 0.7
        case .versusPlayer: return
        }

        let work = DispatchWorkItem { [weak self] in
            self?.isBotThinking = false
            self?.performBotMove()
        }
        botWorkItem = work
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: work)
    }

    private func cancelBotMove() {
        botWorkItem?.cancel()
        botWorkItem = nil
        isBotThinking = false
    }

    private func reportResultIfNeeded() {
        guard let session, let outcome = session.outcome, !hasReportedResult else { return }
        hasReportedResult = true
        onEvent(
            .result(
                MiniGameResult(
                    score: score(for: outcome, mode: session.mode),
                    duration: roundStartedAt.map { Date().timeIntervalSince($0) }
                )
            )
        )
    }

    private func score(for outcome: TicTacToeOutcome, mode: TicTacToePlayMode) -> Int? {
        guard case .versusBot(let difficulty) = mode else { return nil }
        switch outcome {
        case .win(.x):
            switch difficulty {
            case .easy: return 50
            case .normal: return 100
            case .hard: return 200
            }
        case .draw:
            return 25
        case .win(.o):
            return 0
        }
    }

    private func apply(_ session: TicTacToeSession) {
        self.session = session
        cells = session.cells
        currentMark = session.currentMark
        winningLine = session.winningLine ?? []
        mode = session.mode
        outcome = session.outcome
        if !session.isBotTurn {
            isBotThinking = false
        }
    }
}
