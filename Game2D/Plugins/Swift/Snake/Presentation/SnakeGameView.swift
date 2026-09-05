import Combine
import SpriteKit
import SwiftUI

struct SnakeGameView: View {
    @ObservedObject var viewModel: SnakeViewModel
    @EnvironmentObject private var theme: ThemeController
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            theme.colors.background
                .ignoresSafeArea()

            VStack(spacing: 12) {
                SnakeHUDView(
                    title: "Snake",
                    statusText: statusText,
                    score: viewModel.score,
                    highScore: viewModel.highScore,
                    canPause: viewModel.state == .playing,
                    onExit: { viewModel.input.exitTapped.send() },
                    onPause: { viewModel.input.pauseTapped.send() },
                    onSettings: { viewModel.input.settingsTapped.send() }
                )

                GeometryReader { proxy in
                    let side = min(proxy.size.width, proxy.size.height)
                    SpriteView(scene: viewModel.scene, options: [.allowsTransparency])
                        .frame(width: side, height: side)
                        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .strokeBorder(theme.colors.border, lineWidth: 1)
                        )
                        .onAppear {
                            viewModel.updateSceneSize(CGSize(width: side, height: side))
                        }
                        .onChange(of: proxy.size) { _, newSize in
                            let newSide = min(newSize.width, newSize.height)
                            viewModel.updateSceneSize(CGSize(width: newSide, height: newSide))
                        }
                        .overlay {
                            if viewModel.state == .ready {
                                SnakeReadyView(
                                    onPlay: { viewModel.input.playTapped.send() }
                                )
                            }
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                }
                .simultaneousGesture(swipeGesture)

                SnakeControlPanelView(isEnabled: canUseControls) { direction in
                    viewModel.handleDirectionTap(direction)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 8)

            if viewModel.state == .paused {
                SnakePauseView(
                    onResume: { viewModel.input.resumeTapped.send() },
                    onRestart: { viewModel.input.restartTapped.send() },
                    onExit: { viewModel.input.exitTapped.send() }
                )
            } else if viewModel.state == .gameOver {
                SnakeGameOverView(
                    score: viewModel.score,
                    highScore: viewModel.highScore,
                    onRestart: { viewModel.input.restartTapped.send() },
                    onExit: { viewModel.input.exitTapped.send() }
                )
            }
        }
        .onAppear {
            viewModel.scene.setReduceMotion(reduceMotion)
        }
        .onChange(of: reduceMotion) { _, newValue in
            viewModel.scene.setReduceMotion(newValue)
        }
    }

    private var canUseControls: Bool {
        viewModel.state == .playing || viewModel.state == .ready
    }

    private var statusText: String {
        switch viewModel.state {
        case .ready: return "Tap or swipe to start"
        case .playing: return "Playing"
        case .paused: return "Paused"
        case .gameOver: return "Game Over"
        }
    }

    private var swipeGesture: some Gesture {
        DragGesture(minimumDistance: 24)
            .onEnded { value in
                viewModel.handleSwipe(translation: value.translation)
            }
    }
}
