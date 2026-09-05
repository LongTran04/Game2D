import Combine
import SpriteKit
import SwiftUI

struct DropMergeView: View {
    @ObservedObject var viewModel: DropMergeViewModel
    @EnvironmentObject private var theme: ThemeController
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            theme.colors.background
                .ignoresSafeArea()

            VStack(spacing: 12) {
                header
                scoreBar
                GeometryReader { proxy in
                    SpriteView(scene: viewModel.scene, options: [.allowsTransparency])
                        .frame(width: proxy.size.width, height: proxy.size.height)
                        .onAppear {
                            viewModel.updateSceneSize(proxy.size)
                        }
                        .onChange(of: proxy.size) { _, newSize in
                            viewModel.updateSceneSize(newSize)
                        }
                }
                .ignoresSafeArea(edges: .bottom)
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .strokeBorder(theme.colors.border, lineWidth: 1)
                )
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)

            if viewModel.gameState == .paused {
                pauseOverlay
            } else if viewModel.gameState == .gameOver {
                gameOverOverlay
            }
        }
        .onAppear {
            viewModel.scene.setReduceMotion(reduceMotion)
        }
        .onChange(of: reduceMotion) { _, newValue in
            viewModel.scene.setReduceMotion(newValue)
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
            .accessibilityLabel("Exit")

            VStack(alignment: .leading, spacing: 2) {
                Text("Drop & Merge")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(theme.colors.textSecondary)
                Text(statusText)
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
            .disabled(viewModel.gameState != .playing)
            .opacity(viewModel.gameState != .playing ? 0.4 : 1)
            .accessibilityLabel("Pause")

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

    private var scoreBar: some View {
        HStack(spacing: 12) {
            scoreChip(title: "Score", value: "\(viewModel.score)")
            scoreChip(title: "Best", value: "\(viewModel.highScore)")

            Spacer(minLength: 8)

            nextPreview
        }
        .accessibilityElement(children: .combine)
    }

    private func scoreChip(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundStyle(theme.colors.textSecondary)
            Text(value)
                .font(.system(size: 20, weight: .heavy, design: .rounded))
                .foregroundStyle(theme.colors.textPrimary)
                .monospacedDigit()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(theme.colors.surface, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private var nextPreview: some View {
        HStack(spacing: 10) {
            VStack(alignment: .trailing, spacing: 2) {
                Text("Next")
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundStyle(theme.colors.textSecondary)
                Text(viewModel.nextItem?.name ?? "—")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(theme.colors.textPrimary)
            }

            ZStack {
                Circle()
                    .fill(orbColor(viewModel.nextItem))
                    .frame(width: 36, height: 36)
                if let symbol = viewModel.nextItem?.symbolName {
                    Image(systemName: symbol)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.9))
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(theme.colors.surface, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .accessibilityLabel("Next orb \(viewModel.nextItem?.name ?? "unknown")")
    }

    private var statusText: String {
        switch viewModel.gameState {
        case .ready: return "Get ready"
        case .playing: return currentItemName
        case .paused: return "Paused"
        case .gameOver: return "Game Over"
        }
    }

    private var currentItemName: String {
        if let name = viewModel.currentItem?.name {
            return "Drop \(name)"
        }
        return "Playing"
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
                        primaryButton("Resume")
                    }

                    Button {
                        viewModel.input.restartTapped.send()
                    } label: {
                        secondaryButton("Restart")
                    }

                    Button {
                        viewModel.input.exitTapped.send()
                    } label: {
                        secondaryButton("Game Board")
                    }
                }
            }
            .padding(24)
            .background(theme.colors.surfaceElevated, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
            .padding(.horizontal, 32)
        }
    }

    private var gameOverOverlay: some View {
        ZStack {
            theme.colors.background.opacity(0.72)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                Text("Game Over")
                    .font(.system(size: 28, weight: .heavy, design: .rounded))
                    .foregroundStyle(theme.colors.textPrimary)

                Text("Score \(viewModel.score)")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(theme.colors.accent)

                Text("Best \(viewModel.highScore)")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(theme.colors.textSecondary)

                VStack(spacing: 10) {
                    Button {
                        viewModel.input.restartTapped.send()
                    } label: {
                        primaryButton("Play Again")
                    }

                    Button {
                        viewModel.input.exitTapped.send()
                    } label: {
                        secondaryButton("Game Board")
                    }
                }
            }
            .padding(24)
            .background(theme.colors.surfaceElevated, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
            .padding(.horizontal, 32)
        }
    }

    private func primaryButton(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 17, weight: .bold, design: .rounded))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(theme.colors.accent, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .foregroundStyle(theme.colors.background)
    }

    private func secondaryButton(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 16, weight: .semibold, design: .rounded))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(theme.colors.background, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .foregroundStyle(theme.colors.textPrimary)
    }

    private func orbColor(_ item: MergeItemDefinition?) -> Color {
        guard let item else { return theme.colors.surfaceElevated }
        return Color(hex: item.colorHex)
    }
}
