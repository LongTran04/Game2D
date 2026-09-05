import SwiftUI

struct SnakeGameOverView: View {
    let score: Int
    let highScore: Int
    let onRestart: () -> Void
    let onExit: () -> Void

    @EnvironmentObject private var theme: ThemeController

    var body: some View {
        ZStack {
            theme.colors.background.opacity(0.72)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                Text("Game Over")
                    .font(.system(size: 28, weight: .heavy, design: .rounded))
                    .foregroundStyle(theme.colors.textPrimary)

                Text("Score \(score)")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(theme.colors.accent)

                Text("Best \(highScore)")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(theme.colors.textSecondary)

                VStack(spacing: 10) {
                    Button(action: onRestart) {
                        Text("Play Again")
                            .font(.system(size: 17, weight: .bold, design: .rounded))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(theme.colors.accent, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                            .foregroundStyle(theme.colors.background)
                    }

                    Button(action: onExit) {
                        Text("Game Board")
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(theme.colors.background, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                            .foregroundStyle(theme.colors.textPrimary)
                    }
                }
            }
            .padding(24)
            .background(theme.colors.surfaceElevated, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
            .padding(.horizontal, 32)
        }
    }
}
