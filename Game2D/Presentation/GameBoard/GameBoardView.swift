import Combine
import SwiftUI

struct GameBoardView: View {
    @ObservedObject var viewModel: GameBoardViewModel
    @EnvironmentObject private var theme: ThemeController

    private let columns = [
        GridItem(.flexible(), spacing: 14),
        GridItem(.flexible(), spacing: 14)
    ]

    var body: some View {
        ZStack {
            theme.colors.background
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    header
                    LazyVGrid(columns: columns, spacing: 14) {
                        ForEach(viewModel.miniGames) { game in
                            MiniGameCard(game: game) {
                                viewModel.input.miniGameTapped.send(game.id)
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 32)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .onAppear {
            viewModel.input.viewDidAppear.send()
        }
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 6) {
                Text(viewModel.title)
                    .font(.system(size: 32, weight: .heavy, design: .rounded))
                    .foregroundStyle(theme.colors.textPrimary)
                Text(viewModel.subtitle)
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundStyle(theme.colors.textSecondary)
            }

            Spacer()

            Button {
                viewModel.input.settingsTapped.send()
            } label: {
                Image(systemName: "slider.horizontal.3")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(theme.colors.textPrimary)
                    .frame(width: 44, height: 44)
                    .background(theme.colors.surface, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .accessibilityLabel("Settings All")
        }
    }
}

private struct MiniGameCard: View {
    let game: MiniGame
    let onTap: () -> Void
    @EnvironmentObject private var theme: ThemeController

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Image(systemName: game.symbolName)
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(theme.colors.accent)
                    Spacer()
                    Text(game.engine.displayName)
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundStyle(theme.colors.accent)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(theme.colors.accent.opacity(0.14), in: Capsule())
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(game.title)
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .foregroundStyle(theme.colors.textPrimary)
                        .multilineTextAlignment(.leading)
                    Text(game.subtitle)
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(theme.colors.textSecondary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }

                Spacer(minLength: 0)

                Text(game.isAvailable ? "Play" : "Framework needed")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(game.isAvailable ? theme.colors.accent : theme.colors.textSecondary)
            }
            .padding(16)
            .frame(maxWidth: .infinity, minHeight: 168, alignment: .leading)
            .background(theme.colors.surface, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .strokeBorder(theme.colors.border, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}
