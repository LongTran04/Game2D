import Foundation

enum TicTacToeBot {
    static func moveIndex(in session: TicTacToeSession) -> Int? {
        let empties = session.emptyCellIDs
        guard !empties.isEmpty, case .versusBot(let difficulty) = session.mode else {
            return nil
        }

        switch difficulty {
        case .easy:
            return empties.randomElement()
        case .normal:
            return normalMove(in: session, empties: empties)
        case .hard:
            return hardMove(in: session, empties: empties)
        }
    }

    /// Takes a winning move, blocks the player, otherwise plays at random.
    private static func normalMove(in session: TicTacToeSession, empties: [Int]) -> Int {
        if let win = finishingMove(for: session.botMark, in: session) {
            return win
        }
        if let block = finishingMove(for: session.humanMark, in: session) {
            return block
        }
        return empties.randomElement() ?? 0
    }

    private static func finishingMove(for mark: TicTacToeMark, in session: TicTacToeSession) -> Int? {
        for cellID in session.emptyCellIDs {
            var copy = session
            copy.currentMark = mark
            _ = copy.place(at: cellID)
            if case .win(mark) = copy.outcome {
                return cellID
            }
        }
        return nil
    }

    private static func hardMove(in session: TicTacToeSession, empties: [Int]) -> Int {
        var bestScore = Int.min
        var bestMoves: [Int] = []

        for cellID in empties {
            var copy = session
            _ = copy.place(at: cellID)
            let score = minimax(
                session: copy,
                depth: 1,
                alpha: Int.min,
                beta: Int.max,
                maximizing: false,
                bot: session.botMark
            )
            if score > bestScore {
                bestScore = score
                bestMoves = [cellID]
            } else if score == bestScore {
                bestMoves.append(cellID)
            }
        }

        return bestMoves.randomElement() ?? empties[0]
    }

    private static func minimax(
        session: TicTacToeSession,
        depth: Int,
        alpha: Int,
        beta: Int,
        maximizing: Bool,
        bot: TicTacToeMark
    ) -> Int {
        if let outcome = session.outcome {
            switch outcome {
            case .win(let mark):
                return mark == bot ? 10 - depth : depth - 10
            case .draw:
                return 0
            }
        }

        var alpha = alpha
        var beta = beta
        let empties = session.emptyCellIDs

        if maximizing {
            var best = Int.min
            for cellID in empties {
                var copy = session
                _ = copy.place(at: cellID)
                best = max(best, minimax(session: copy, depth: depth + 1, alpha: alpha, beta: beta, maximizing: false, bot: bot))
                alpha = max(alpha, best)
                if beta <= alpha { break }
            }
            return best
        }

        var best = Int.max
        for cellID in empties {
            var copy = session
            _ = copy.place(at: cellID)
            best = min(best, minimax(session: copy, depth: depth + 1, alpha: alpha, beta: beta, maximizing: true, bot: bot))
            beta = min(beta, best)
            if beta <= alpha { break }
        }
        return best
    }
}
