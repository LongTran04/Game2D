import Combine
import SwiftUI

struct TicTacToeView: View {
    @ObservedObject var viewModel: TicTacToeViewModel
    @EnvironmentObject private var theme: ThemeController

    private let spacing: CGFloat = 10

    var body: some View {
        ZStack {
            theme.colors.background
                .ignoresSafeArea()

            VStack(spacing: 20) {
                header
                board
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)

            if viewModel.isPickingMode && !viewModel.isPaused {
                modePickerOverlay
            } else if viewModel.isComplete {
                completionOverlay
            } else if viewModel.isPaused {
                pauseOverlay
            }
        }
    }

    private var header: some View {
        HStack(spacing: 12) {
            Button {
                viewModel.input.exitTapped.send()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(theme.colors.textPrimary)
                    .frame(width: 40, height: 40)
                    .background(theme.colors.surface, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(modeCaption)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(theme.colors.textSecondary)
                Text(viewModel.statusText)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(theme.colors.textPrimary)
                    .lineLimit(1)
            }

            Spacer()

            Button {
                viewModel.input.pauseTapped.send()
            } label: {
                Image(systemName: "pause.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(theme.colors.textPrimary)
                    .frame(width: 40, height: 40)
                    .background(theme.colors.surface, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .disabled(viewModel.isComplete || viewModel.isPaused || viewModel.isPickingMode)
            .opacity(viewModel.isComplete || viewModel.isPaused || viewModel.isPickingMode ? 0.4 : 1)

            Button {
                viewModel.input.settingsTapped.send()
            } label: {
                Image(systemName: "slider.horizontal.3")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(theme.colors.textPrimary)
                    .frame(width: 40, height: 40)
                    .background(theme.colors.surface, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .accessibilityLabel("Settings")
        }
    }

    private var modeCaption: String {
        switch viewModel.mode {
        case .versusPlayer: return "Player vs Player"
        case .versusBot(let difficulty): return "Bot · \(difficulty.displayName)"
        case nil: return "Tic Tac Toe"
        }
    }

    private var board: some View {
        GeometryReader { proxy in
            let size = min(proxy.size.width, proxy.size.height)
            let cellSize = (size - spacing * 2) / 3

            LazyVGrid(
                columns: Array(repeating: GridItem(.fixed(cellSize), spacing: spacing), count: 3),
                spacing: spacing
            ) {
                ForEach(viewModel.cells) { cell in
                    Button {
                        viewModel.input.cellTapped.send(cell.id)
                    } label: {
                        ZStack {
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(fill(for: cell))
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .strokeBorder(theme.colors.border, lineWidth: 1)

                            if let mark = cell.mark {
                                Text(mark.label)
                                    .font(.system(size: cellSize * 0.48, weight: .heavy, design: .rounded))
                                    .foregroundStyle(color(for: mark))
                            }
                        }
                        .frame(width: cellSize, height: cellSize)
                    }
                    .disabled(
                        cell.mark != nil
                            || viewModel.isComplete
                            || viewModel.isPaused
                            || viewModel.isPickingMode
                            || viewModel.isBotThinking
                    )
                    .animation(.easeInOut(duration: 0.16), value: cell.mark)
                    .animation(.easeInOut(duration: 0.16), value: viewModel.winningLine)
                }
            }
            .frame(width: size, height: size)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private var modePickerOverlay: some View {
        ZStack {
            theme.colors.background.opacity(0.72)
                .ignoresSafeArea()

            VStack(spacing: 18) {
                Text("Tic Tac Toe")
                    .font(.system(size: 28, weight: .heavy, design: .rounded))
                    .foregroundStyle(theme.colors.textPrimary)

                Text("3×3 · you are X")
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundStyle(theme.colors.textSecondary)

                Button {
                    viewModel.input.modeSelected.send(.versusPlayer)
                } label: {
                    modeButtonLabel("Player vs Player", subtitle: "Two players, one device")
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text("PLAYER VS BOT")
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundStyle(theme.colors.textSecondary)
                        .tracking(1)

                    HStack(spacing: 8) {
                        ForEach(TicTacToeDifficulty.allCases) { difficulty in
                            Button {
                                viewModel.input.modeSelected.send(.versusBot(difficulty))
                            } label: {
                                Text(difficulty.displayName)
                                    .font(.system(size: 15, weight: .bold, design: .rounded))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                                    .background(theme.colors.accent, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                                    .foregroundStyle(theme.colors.background)
                            }
                        }
                    }
                }

                Button {
                    viewModel.input.exitTapped.send()
                } label: {
                    overlaySecondaryButton("Game Board")
                }
            }
            .padding(24)
            .background(theme.colors.surfaceElevated, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
            .padding(.horizontal, 28)
        }
    }

    private func modeButtonLabel(_ title: String, subtitle: String) -> some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.system(size: 17, weight: .bold, design: .rounded))
            Text(subtitle)
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundStyle(theme.colors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(theme.colors.background, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .foregroundStyle(theme.colors.textPrimary)
    }

    private var pauseOverlay: some View {
        ZStack {
            theme.colors.background.opacity(0.72)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                Text("Paused")
                    .font(.system(size: 28, weight: .heavy, design: .rounded))
                    .foregroundStyle(theme.colors.textPrimary)

                VStack(spacing: 10) {
                    Button {
                        viewModel.input.resumeTapped.send()
                    } label: {
                        Text("Resume")
                            .font(.system(size: 17, weight: .bold, design: .rounded))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(theme.colors.accent, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                            .foregroundStyle(theme.colors.background)
                    }

                    Button {
                        viewModel.input.settingsTapped.send()
                    } label: {
                        overlaySecondaryButton("Settings")
                    }

                    Button {
                        viewModel.input.exitTapped.send()
                    } label: {
                        overlaySecondaryButton("Game Board")
                    }
                }
            }
            .padding(24)
            .background(theme.colors.surfaceElevated, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
            .padding(.horizontal, 32)
        }
    }

    private var completionOverlay: some View {
        ZStack {
            theme.colors.background.opacity(0.72)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                Text(viewModel.resultTitle)
                    .font(.system(size: 28, weight: .heavy, design: .rounded))
                    .foregroundStyle(theme.colors.textPrimary)

                if !viewModel.resultDetail.isEmpty {
                    Text(viewModel.resultDetail)
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundStyle(theme.colors.accent)
                        .multilineTextAlignment(.center)
                }

                VStack(spacing: 10) {
                    Button {
                        viewModel.input.playAgainTapped.send()
                    } label: {
                        Text("Play Again")
                            .font(.system(size: 17, weight: .bold, design: .rounded))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(theme.colors.accent, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                            .foregroundStyle(theme.colors.background)
                    }

                    Button {
                        viewModel.input.changeModeTapped.send()
                    } label: {
                        overlaySecondaryButton("Change Mode")
                    }

                    Button {
                        viewModel.input.exitTapped.send()
                    } label: {
                        overlaySecondaryButton("Game Board")
                    }
                }
            }
            .padding(24)
            .background(theme.colors.surfaceElevated, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
            .padding(.horizontal, 32)
        }
    }

    private func overlaySecondaryButton(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 16, weight: .semibold, design: .rounded))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(theme.colors.background, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .foregroundStyle(theme.colors.textPrimary)
    }

    private func fill(for cell: TicTacToeCell) -> Color {
        if viewModel.winningLine.contains(cell.id) {
            return theme.colors.accent.opacity(0.22)
        }
        return theme.colors.surface
    }

    private func color(for mark: TicTacToeMark) -> Color {
        mark == .x ? theme.colors.accent : theme.colors.secondary
    }
}
