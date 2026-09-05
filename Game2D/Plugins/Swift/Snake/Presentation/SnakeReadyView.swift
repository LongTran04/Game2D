import SwiftUI

struct SnakeReadyView: View {
    let onPlay: () -> Void

    @EnvironmentObject private var theme: ThemeController

    var body: some View {
        VStack(spacing: 12) {
            Text("Snake")
                .font(.system(size: 24, weight: .heavy, design: .rounded))
                .foregroundStyle(theme.colors.textPrimary)

            Text("Swipe or use the D-pad")
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(theme.colors.textSecondary)
                .multilineTextAlignment(.center)

            Button(action: onPlay) {
                Text("Play")
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(theme.colors.accent, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .foregroundStyle(theme.colors.background)
            }
        }
        .padding(18)
        .background(theme.colors.surfaceElevated, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .padding(.horizontal, 28)
    }
}
