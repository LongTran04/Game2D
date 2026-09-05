import SwiftUI

struct SnakePauseView: View {
    let onResume: () -> Void
    let onRestart: () -> Void
    let onExit: () -> Void

    @EnvironmentObject private var theme: ThemeController

    var body: some View {
        ZStack {
            theme.colors.background.opacity(0.72)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                Text("Paused")
                    .font(.system(size: 28, weight: .heavy, design: .rounded))
                    .foregroundStyle(theme.colors.textPrimary)

                VStack(spacing: 10) {
                    Button(action: onResume) {
                        Text("Resume")
                            .font(.system(size: 17, weight: .bold, design: .rounded))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(theme.colors.accent, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                            .foregroundStyle(theme.colors.background)
                    }

                    Button(action: onRestart) {
                        Text("Restart")
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(theme.colors.background, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                            .foregroundStyle(theme.colors.textPrimary)
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
