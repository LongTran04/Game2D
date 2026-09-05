import Combine
import SpriteKit

final class SnakeScene: SKScene {
    let events = PassthroughSubject<SnakeGameEvent, Never>()

    private let engine: GameEngine
    private var snakeNode: SnakeNode?
    private var foodNode: FoodNode?
    private var boardNode: SKShapeNode?
    private var gridNode: SKNode?

    private var palette = SnakePalette.make(isDark: false)
    private var isDarkTheme = false
    private var reduceMotion = false
    private var cellSize: CGFloat = 0
    private var boardOrigin = CGPoint.zero
    private var lastUpdateTime: TimeInterval = 0
    private var accumulator: TimeInterval = 0
    private var pendingStart: Bool?

    private var hasValidPlayfield: Bool {
        size.width > 1 && size.height > 1
    }

    init(size: CGSize, engine: GameEngine = GameEngine()) {
        self.engine = engine
        super.init(size: size)
        scaleMode = .resizeFill
        backgroundColor = .clear
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func didMove(to view: SKView) {
        backgroundColor = .clear
        scaleMode = .resizeFill
        if hasValidPlayfield {
            rebuildLayout()
            flushPendingStartIfNeeded()
        }
    }

    override func didChangeSize(_ oldSize: CGSize) {
        guard hasValidPlayfield else { return }
        guard abs(size.width - oldSize.width) > 0.5 || abs(size.height - oldSize.height) > 0.5 else {
            flushPendingStartIfNeeded()
            return
        }
        rebuildLayout()
        flushPendingStartIfNeeded()
    }

    func updatePlayfieldSize(_ newSize: CGSize) {
        guard newSize.width > 1, newSize.height > 1 else { return }
        let changed = abs(size.width - newSize.width) > 0.5 || abs(size.height - newSize.height) > 0.5
        if changed {
            size = newSize
        } else {
            flushPendingStartIfNeeded()
        }
    }

    func setReduceMotion(_ enabled: Bool) {
        reduceMotion = enabled
        if let food = engine.food {
            foodNode?.place(at: point(for: food), cellSize: cellSize, animated: false, reduceMotion: enabled)
        }
    }

    func handle(_ command: SnakeGameCommand) {
        switch command {
        case .start:
            requestStart(restart: false)
        case .restart:
            requestStart(restart: true)
        case .beginPlaying:
            beginPlaying()
        case .pause:
            pauseGame()
        case .resume:
            resumeGame()
        case .stop:
            pendingStart = nil
            stopGame()
        case .queueDirection(let direction):
            queueDirection(direction)
        case .applyTheme(let isDark):
            isDarkTheme = isDark
            palette = SnakePalette.make(isDark: isDark)
            applyPalette()
        }
    }

    override func update(_ currentTime: TimeInterval) {
        defer { lastUpdateTime = currentTime }
        guard engine.state == .playing, !isPaused else { return }
        let delta = lastUpdateTime == 0 ? 0 : currentTime - lastUpdateTime
        guard delta > 0, delta < 1 else { return }

        accumulator += delta
        let interval = max(engine.tickInterval, 0.04)
        while accumulator >= interval {
            accumulator -= interval
            applyTick()
            if engine.state != .playing { break }
        }
    }

    // MARK: - Commands

    private func requestStart(restart: Bool) {
        guard hasValidPlayfield else {
            pendingStart = restart
            return
        }
        startGame(restart: restart)
    }

    private func flushPendingStartIfNeeded() {
        guard hasValidPlayfield, let restart = pendingStart else { return }
        pendingStart = nil
        startGame(restart: restart)
    }

    private func startGame(restart: Bool) {
        isPaused = false
        lastUpdateTime = 0
        accumulator = 0
        if restart {
            engine.restart()
        } else {
            engine.start()
        }
        rebuildLayout()
        publishSnapshot()
        events.send(.stateChanged(engine.state))
    }

    private func beginPlaying() {
        guard engine.state == .ready else { return }
        engine.beginPlaying()
        isPaused = false
        lastUpdateTime = 0
        accumulator = 0
        events.send(.stateChanged(engine.state))
    }

    private func pauseGame() {
        guard engine.state == .playing else { return }
        engine.pause()
        isPaused = true
        events.send(.stateChanged(engine.state))
    }

    private func resumeGame() {
        guard engine.state == .paused else { return }
        engine.resume()
        isPaused = false
        lastUpdateTime = 0
        events.send(.stateChanged(engine.state))
    }

    private func stopGame() {
        isPaused = true
        engine.stop()
        events.send(.stateChanged(engine.state))
    }

    private func queueDirection(_ direction: Direction) {
        let wasReady = engine.state == .ready
        engine.queueDirection(direction)
        if wasReady {
            beginPlaying()
        }
        snakeNode?.sync(
            snake: engine.snake,
            direction: engine.pendingDirection,
            cellSize: cellSize,
            pointFor: point(for:)
        )
    }

    private func applyTick() {
        guard let outcome = engine.tick() else { return }
        switch outcome {
        case .moved:
            renderSnake(animated: true)
        case .ateFood(let score, let length):
            playEatEffect()
            renderSnake(animated: true)
            spawnFood(animated: true)
            events.send(.scoreChanged(score))
            events.send(.ateFood(score: score, length: length))
            events.send(.tickIntervalChanged(engine.tickInterval))
        case .died(let reason):
            snakeNode?.flashGameOver(reduceMotion: reduceMotion)
            events.send(.stateChanged(.gameOver))
            events.send(.gameOver(finalScore: engine.score, reason: reason))
        }
    }

    // MARK: - Layout

    private func rebuildLayout() {
        guard hasValidPlayfield else { return }
        removeAllChildren()
        snakeNode = nil
        foodNode = nil
        boardNode = nil
        gridNode = nil

        let columns = CGFloat(engine.configuration.columns)
        let rows = CGFloat(engine.configuration.rows)
        let inset: CGFloat = 8
        let available = min(size.width, size.height) - inset * 2
        cellSize = floor(min(available / columns, available / rows) * 2) / 2
        let boardWidth = cellSize * columns
        let boardHeight = cellSize * rows
        boardOrigin = CGPoint(
            x: (size.width - boardWidth) / 2,
            y: (size.height - boardHeight) / 2
        )

        let board = SKShapeNode(
            rectOf: CGSize(width: boardWidth, height: boardHeight),
            cornerRadius: 16
        )
        board.position = CGPoint(x: size.width / 2, y: size.height / 2)
        board.lineWidth = 1.5
        board.zPosition = 0
        addChild(board)
        boardNode = board

        let grid = SKNode()
        grid.zPosition = 1
        let path = CGMutablePath()
        for column in 1..<engine.configuration.columns {
            let x = boardOrigin.x + CGFloat(column) * cellSize
            path.move(to: CGPoint(x: x, y: boardOrigin.y))
            path.addLine(to: CGPoint(x: x, y: boardOrigin.y + boardHeight))
        }
        for row in 1..<engine.configuration.rows {
            let y = boardOrigin.y + CGFloat(row) * cellSize
            path.move(to: CGPoint(x: boardOrigin.x, y: y))
            path.addLine(to: CGPoint(x: boardOrigin.x + boardWidth, y: y))
        }
        let lines = SKShapeNode(path: path)
        lines.lineWidth = 0.5
        lines.fillColor = .clear
        grid.addChild(lines)
        addChild(grid)
        gridNode = grid

        let snake = SnakeNode(palette: palette)
        addChild(snake)
        snakeNode = snake

        applyPalette()
        renderSnake(animated: false)
        spawnFood(animated: false)
    }

    private func applyPalette() {
        boardNode?.fillColor = palette.boardFill
        boardNode?.strokeColor = palette.boardStroke
        if let lines = gridNode?.children.first as? SKShapeNode {
            lines.strokeColor = palette.gridLine
        }
        snakeNode?.apply(palette: palette)
        foodNode?.apply(palette: palette)
    }

    private func renderSnake(animated: Bool) {
        let facing = engine.state == .playing ? engine.direction : engine.pendingDirection
        snakeNode?.sync(
            snake: engine.snake,
            direction: facing,
            cellSize: cellSize,
            pointFor: point(for:)
        )
        guard animated, !reduceMotion else { return }
        snakeNode?.children.first?.run(.sequence([
            .scale(to: 1.06, duration: 0.05),
            .scale(to: 1, duration: 0.08)
        ]))
    }

    private func spawnFood(animated: Bool) {
        foodNode?.removeFromParent()
        foodNode = nil
        guard let food = engine.food else { return }
        let node = FoodNode(palette: palette)
        addChild(node)
        node.place(at: point(for: food), cellSize: cellSize, animated: animated, reduceMotion: reduceMotion)
        foodNode = node
    }

    private func playEatEffect() {
        guard let foodNode else { return }
        let burst = SKShapeNode(circleOfRadius: max(6, cellSize * 0.28))
        burst.position = foodNode.position
        burst.fillColor = .clear
        burst.strokeColor = palette.food
        burst.lineWidth = 2
        burst.zPosition = 8
        addChild(burst)
        let duration: TimeInterval = reduceMotion ? 0.08 : 0.22
        burst.run(.group([
            .scale(to: reduceMotion ? 1.1 : 1.8, duration: duration),
            .fadeOut(withDuration: duration)
        ])) {
            burst.removeFromParent()
        }
        foodNode.playEaten(reduceMotion: reduceMotion)
        self.foodNode = nil
    }

    private func publishSnapshot() {
        events.send(.scoreChanged(engine.score))
        events.send(.tickIntervalChanged(engine.tickInterval))
    }

    private func point(for position: GridPosition) -> CGPoint {
        CGPoint(
            x: boardOrigin.x + (CGFloat(position.x) + 0.5) * cellSize,
            y: boardOrigin.y + (CGFloat(position.y) + 0.5) * cellSize
        )
    }
}
