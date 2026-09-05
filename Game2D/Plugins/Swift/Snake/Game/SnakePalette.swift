import SpriteKit

struct SnakePalette {
    var boardFill: UIColor
    var boardStroke: UIColor
    var gridLine: UIColor
    var snakeHead: UIColor
    var snakeBody: UIColor
    var snakeStroke: UIColor
    var food: UIColor
    var foodHighlight: UIColor

    static func make(isDark: Bool) -> SnakePalette {
        if isDark {
            return SnakePalette(
                boardFill: UIColor(hex: 0x161616),
                boardStroke: UIColor(hex: 0x38383A),
                gridLine: UIColor(hex: 0x2C2C2E),
                snakeHead: UIColor(hex: 0x30D158),
                snakeBody: UIColor(hex: 0x248A3D),
                snakeStroke: UIColor.white.withAlphaComponent(0.18),
                food: UIColor(hex: 0xFF453A),
                foodHighlight: UIColor.white.withAlphaComponent(0.35)
            )
        }
        return SnakePalette(
            boardFill: UIColor(hex: 0xFFFFFF),
            boardStroke: UIColor(hex: 0xD1D1D6),
            gridLine: UIColor(hex: 0xEBEBEB),
            snakeHead: UIColor(hex: 0x00A67D),
            snakeBody: UIColor(hex: 0x1F7A5C),
            snakeStroke: UIColor.white.withAlphaComponent(0.28),
            food: UIColor(hex: 0xFF3B30),
            foodHighlight: UIColor.white.withAlphaComponent(0.45)
        )
    }
}

private extension UIColor {
    convenience init(hex: UInt32, alpha: CGFloat = 1) {
        self.init(
            red: CGFloat((hex >> 16) & 0xFF) / 255,
            green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255,
            alpha: alpha
        )
    }
}
