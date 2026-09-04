import Foundation

nonisolated enum TicTacToeMark: Equatable {
    case x
    case o

    var opponent: TicTacToeMark {
        self == .x ? .o : .x
    }

    var label: String {
        self == .x ? "X" : "O"
    }
}

nonisolated enum TicTacToeDifficulty: String, CaseIterable, Identifiable, Equatable {
    case easy
    case normal
    case hard

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .easy: return "Easy"
        case .normal: return "Normal"
        case .hard: return "Hard"
        }
    }
}

nonisolated enum TicTacToePlayMode: Equatable {
    case versusPlayer
    case versusBot(TicTacToeDifficulty)

    var difficulty: TicTacToeDifficulty? {
        if case .versusBot(let difficulty) = self { return difficulty }
        return nil
    }
}

nonisolated enum TicTacToeOutcome: Equatable {
    case win(TicTacToeMark)
    case draw
}

nonisolated struct TicTacToeCell: Identifiable, Equatable {
    let id: Int
    var mark: TicTacToeMark?
}

nonisolated struct TicTacToeSession: Equatable {
    static let boardSize = 3
    static let cellCount = boardSize * boardSize

    private static let winLines: [[Int]] = [
        [0, 1, 2], [3, 4, 5], [6, 7, 8],
        [0, 3, 6], [1, 4, 7], [2, 5, 8],
        [0, 4, 8], [2, 4, 6]
    ]

    var cells: [TicTacToeCell]
    var currentMark: TicTacToeMark
    var mode: TicTacToePlayMode
    var humanMark: TicTacToeMark
    var isPlaying: Bool
    var outcome: TicTacToeOutcome?
    var winningLine: [Int]?

    var botMark: TicTacToeMark { humanMark.opponent }

    var emptyCellIDs: [Int] {
        cells.compactMap { $0.mark == nil ? $0.id : nil }
    }

    var isBotTurn: Bool {
        guard case .versusBot = mode, isPlaying, outcome == nil else { return false }
        return currentMark == botMark
    }

    var isHumanTurn: Bool {
        guard isPlaying, outcome == nil else { return false }
        if case .versusBot = mode {
            return currentMark == humanMark
        }
        return true
    }

    static func make(mode: TicTacToePlayMode, humanMark: TicTacToeMark = .x) -> TicTacToeSession {
        TicTacToeSession(
            cells: (0..<cellCount).map { TicTacToeCell(id: $0, mark: nil) },
            currentMark: .x,
            mode: mode,
            humanMark: humanMark,
            isPlaying: true,
            outcome: nil,
            winningLine: nil
        )
    }

    mutating func place(at cellID: Int) -> Bool {
        guard isPlaying,
              outcome == nil,
              cells.indices.contains(cellID),
              cells[cellID].mark == nil else {
            return false
        }

        cells[cellID].mark = currentMark
        if let line = Self.winningLine(in: cells, for: currentMark) {
            winningLine = line
            outcome = .win(currentMark)
            isPlaying = false
        } else if emptyCellIDs.isEmpty {
            outcome = .draw
            isPlaying = false
        } else {
            currentMark = currentMark.opponent
        }
        return true
    }

    mutating func pause() {
        isPlaying = false
    }

    mutating func resume() {
        guard outcome == nil else { return }
        isPlaying = true
    }

    mutating func stop() {
        isPlaying = false
    }

    static func winningLine(in cells: [TicTacToeCell], for mark: TicTacToeMark) -> [Int]? {
        winLines.first { line in
            line.allSatisfy { cells[$0].mark == mark }
        }
    }
}
