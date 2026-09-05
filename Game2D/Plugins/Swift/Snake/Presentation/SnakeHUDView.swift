import SwiftUI

struct SnakeHUDView: View {
    let title: String
    let statusText: String
    let score: Int
    let highScore: Int
    let canPause: Bool
    let onExit: () -> Void
    let onPause: () -> Void
    let onSettings: () -> Void

    @EnvironmentObject private var theme: ThemeController

    var body: some View {
        VStack(spacing: 12) {
            header
            scoreBar
        }
    }

    private var header: some View {
        HStack(spacing: 12) {
            Button(action: onExit) {
                Image(systemName: "xmark")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(theme.colors.textPrimary)
                    .frame(width: 40, height: 40)
                    .background(theme.colors.surface, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .accessibilityLabel("Exit")

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(theme.colors.textSecondary)
                Text(statusText)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(theme.colors.textPrimary)
                    .lineLimit(1)
            }

            Spacer()

            Button(action: onPause) {
                Image(systemName: "pause.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(theme.colors.textPrimary)
                    .frame(width: 40, height: 40)
                    .background(theme.colors.surface, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .disabled(!canPause)
            .opacity(canPause ? 1 : 0.4)
            .accessibilityLabel("Pause")

            Button(action: onSettings) {
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
            scoreChip(title: "Score", value: "\(score)")
            scoreChip(title: "Best", value: "\(highScore)")
            Spacer(minLength: 0)
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
}
