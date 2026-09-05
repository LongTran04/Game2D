import Foundation

final class GameEngine {
    private(set) var snake: [GridPosition]
    private(set) var direction: Direction
    private(set) var pendingDirection: Direction
    private(set) var food: GridPosition?
    private(set) var score: Int
    private(set) var state: SnakeGameState
    private(set) var tickInterval: TimeInterval

    let configuration: GameConfiguration
    private let foodSpawner: FoodSpawning

    var length: Int { snake.count }
    var occupiedCells: Set<GridPosition> { Set(snake) }

    init(
        configuration: GameConfiguration = .default,
        foodSpawner: FoodSpawning = RandomFoodSpawner(),
        snake: [GridPosition]? = nil,
        direction: Direction? = nil,
        food: GridPosition? = nil,
        score: Int = 0,
        state: SnakeGameState = .ready
    ) {
        self.configuration = configuration
        self.foodSpawner = foodSpawner
        let initialSnake = snake ?? configuration.initialSnake()
        let initialDirection = direction ?? configuration.initialDirection
        self.snake = initialSnake
        self.direction = initialDirection
        self.pendingDirection = initialDirection
        self.score = score
        self.state = state
        self.tickInterval = configuration.tickInterval(forScore: score)
        if let food {
            self.food = food
        } else {
            self.food = foodSpawner.spawn(
                excluding: Set(initialSnake),
                columns: configuration.columns,
                rows: configuration.rows
            )
        }
    }

    func start() {
        resetBoard(state: .ready)
    }

    func beginPlaying() {
        guard state == .ready else { return }
        state = .playing
    }

    func pause() {
        guard state == .playing else { return }
        state = .paused
    }

    func resume() {
        guard state == .paused else { return }
        state = .playing
    }

    func restart() {
        resetBoard(state: .playing)
    }

    func stop() {
        state = .ready
    }

    func queueDirection(_ newDirection: Direction) {
        guard state == .playing || state == .ready else { return }
        guard newDirection != direction.opposite else { return }
        pendingDirection = newDirection
    }

    @discardableResult
    func tick() -> SnakeTickOutcome? {
        guard state == .playing else { return nil }

        direction = pendingDirection
        let newHead = snake[0].moved(in: direction)

        if !configuration.contains(newHead) {
            state = .gameOver
            return .died(.wall)
        }

        let willEat = food == newHead
        var bodyToCheck = occupiedCells
        if !willEat, let tail = snake.last {
            bodyToCheck.remove(tail)
        }
        if bodyToCheck.contains(newHead) {
            state = .gameOver
            return .died(.selfHit)
        }

        snake.insert(newHead, at: 0)
        if willEat {
            score += configuration.pointsPerFood
            tickInterval = configuration.tickInterval(forScore: score)
            food = spawnFood()
            return .ateFood(score: score, length: snake.count)
        }

        snake.removeLast()
        return .moved
    }

    private func resetBoard(state: SnakeGameState) {
        snake = configuration.initialSnake()
        direction = configuration.initialDirection
        pendingDirection = direction
        score = 0
        tickInterval = configuration.tickInterval(forScore: 0)
        food = spawnFood()
        self.state = state
    }

    private func spawnFood() -> GridPosition? {
        foodSpawner.spawn(
            excluding: occupiedCells,
            columns: configuration.columns,
            rows: configuration.rows
        )
    }
}
