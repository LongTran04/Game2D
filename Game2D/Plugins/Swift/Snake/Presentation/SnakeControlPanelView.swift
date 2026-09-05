import SwiftUI

struct SnakeControlPanelView: View {
    let isEnabled: Bool
    let onDirection: (Direction) -> Void

    @EnvironmentObject private var theme: ThemeController

    private let buttonSize: CGFloat = 56
    private let spacing: CGFloat = 8

    var body: some View {
        VStack(spacing: spacing) {
            directionButton(.up)
            HStack(spacing: spacing) {
                directionButton(.left)
                centerPad
                directionButton(.right)
            }
            directionButton(.down)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity)
        .background(theme.colors.surface, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(theme.colors.border, lineWidth: 1)
        )
        .opacity(isEnabled ? 1 : 0.45)
        .allowsHitTesting(isEnabled)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Direction pad")
    }

    private var centerPad: some View {
        RoundedRectangle(cornerRadius: 14, style: .continuous)
            .fill(theme.colors.surfaceElevated)
            .frame(width: buttonSize, height: buttonSize)
            .overlay {
                Image(systemName: "circle.fill")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(theme.colors.textSecondary.opacity(0.45))
            }
            .accessibilityHidden(true)
    }

    private func directionButton(_ direction: Direction) -> some View {
        Button {
            onDirection(direction)
        } label: {
            Image(systemName: direction.symbolName)
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(theme.colors.textPrimary)
                .frame(width: buttonSize, height: buttonSize)
                .background(theme.colors.surfaceElevated, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(theme.colors.border, lineWidth: 1)
                )
        }
        .buttonStyle(SnakePadButtonStyle(accent: theme.colors.accent))
        .accessibilityLabel(direction.accessibilityLabel)
        .accessibilityHint("Turn the snake")
    }
}

private struct SnakePadButtonStyle: ButtonStyle {
    let accent: Color

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.92 : 1)
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(accent.opacity(configuration.isPressed ? 0.22 : 0))
            }
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}
