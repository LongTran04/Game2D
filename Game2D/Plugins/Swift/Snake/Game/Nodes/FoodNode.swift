import SpriteKit

final class FoodNode: SKNode {
    private let body: SKShapeNode
    private let highlight: SKShapeNode
    private var palette: SnakePalette

    init(palette: SnakePalette) {
        self.palette = palette
        body = SKShapeNode(circleOfRadius: 8)
        highlight = SKShapeNode(circleOfRadius: 3)
        super.init()
        name = "food"
        zPosition = 2
        body.lineWidth = 1
        highlight.strokeColor = .clear
        addChild(body)
        addChild(highlight)
        apply(palette: palette)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func apply(palette: SnakePalette) {
        self.palette = palette
        body.fillColor = palette.food
        body.strokeColor = palette.foodHighlight
        highlight.fillColor = palette.foodHighlight
    }

    func place(at point: CGPoint, cellSize: CGFloat, animated: Bool, reduceMotion: Bool) {
        let radius = max(5, cellSize * 0.32)
        body.path = CGPath(ellipseIn: CGRect(x: -radius, y: -radius, width: radius * 2, height: radius * 2), transform: nil)
        highlight.path = CGPath(
            ellipseIn: CGRect(x: -radius * 0.28, y: radius * 0.12, width: radius * 0.5, height: radius * 0.5),
            transform: nil
        )
        removeAllActions()
        setScale(1)
        alpha = 1
        position = point

        if animated, !reduceMotion {
            setScale(0.2)
            run(.sequence([
                .scale(to: 1.12, duration: 0.14),
                .scale(to: 1, duration: 0.1)
            ]))
            runPulse()
        } else if !reduceMotion {
            runPulse()
        }
    }

    func playEaten(reduceMotion: Bool) {
        removeAllActions()
        let duration: TimeInterval = reduceMotion ? 0.08 : 0.18
        run(.group([
            .scale(to: reduceMotion ? 1.05 : 1.35, duration: duration),
            .fadeOut(withDuration: duration)
        ])) { [weak self] in
            self?.removeFromParent()
        }
    }

    private func runPulse() {
        run(
            .repeatForever(
                .sequence([
                    .scale(to: 1.08, duration: 0.45),
                    .scale(to: 1, duration: 0.45)
                ])
            ),
            withKey: "pulse"
        )
    }
}
