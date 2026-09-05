import SpriteKit

final class SnakeNode: SKNode {
    private var segments: [SKShapeNode] = []
    private var eyeNodes: [SKShapeNode] = []
    private var palette: SnakePalette
    private var cellSize: CGFloat = 0

    init(palette: SnakePalette) {
        self.palette = palette
        super.init()
        name = "snake"
        zPosition = 2
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func apply(palette: SnakePalette) {
        self.palette = palette
        for (index, segment) in segments.enumerated() {
            segment.fillColor = index == 0 ? palette.snakeHead : palette.snakeBody
            segment.strokeColor = palette.snakeStroke
        }
        for eye in eyeNodes {
            eye.fillColor = UIColor.white
            eye.strokeColor = .clear
        }
    }

    func sync(
        snake: [GridPosition],
        direction: Direction,
        cellSize: CGFloat,
        pointFor: (GridPosition) -> CGPoint
    ) {
        self.cellSize = cellSize
        let inset = max(1.2, cellSize * 0.08)
        let radius = max(3, (cellSize - inset * 2) * 0.28)

        while segments.count > snake.count {
            segments.removeLast().removeFromParent()
        }
        while segments.count < snake.count {
            let node = SKShapeNode()
            node.lineWidth = 1
            node.zPosition = 1
            addChild(node)
            segments.append(node)
        }

        for (index, position) in snake.enumerated() {
            let node = segments[index]
            let size = cellSize - inset * 2
            node.path = CGPath(
                roundedRect: CGRect(x: -size / 2, y: -size / 2, width: size, height: size),
                cornerWidth: radius,
                cornerHeight: radius,
                transform: nil
            )
            node.fillColor = index == 0 ? palette.snakeHead : palette.snakeBody
            node.strokeColor = palette.snakeStroke
            node.position = pointFor(position)
            node.zPosition = index == 0 ? 3 : 1
        }

        syncEyes(direction: direction, cellSize: cellSize)
    }

    func flashGameOver(reduceMotion: Bool) {
        let duration: TimeInterval = reduceMotion ? 0.08 : 0.18
        for (index, segment) in segments.enumerated() {
            let wait = SKAction.wait(forDuration: reduceMotion ? 0 : 0.03 * TimeInterval(index))
            let tint = SKAction.customAction(withDuration: duration) { node, _ in
                (node as? SKShapeNode)?.fillColor = UIColor(red: 0.9, green: 0.28, blue: 0.25, alpha: 1)
            }
            segment.run(.sequence([wait, tint]))
        }
    }

    private func syncEyes(direction: Direction, cellSize: CGFloat) {
        eyeNodes.forEach { $0.removeFromParent() }
        eyeNodes.removeAll()
        guard let head = segments.first else { return }

        let offset = cellSize * 0.16
        let eyeRadius = max(1.6, cellSize * 0.07)
        let pupilRadius = eyeRadius * 0.45
        let pairs: [(CGFloat, CGFloat)]
        switch direction {
        case .up:
            pairs = [(-offset, offset), (offset, offset)]
        case .down:
            pairs = [(-offset, -offset), (offset, -offset)]
        case .left:
            pairs = [(-offset, offset), (-offset, -offset)]
        case .right:
            pairs = [(offset, offset), (offset, -offset)]
        }

        for (dx, dy) in pairs {
            let eye = SKShapeNode(circleOfRadius: eyeRadius)
            eye.fillColor = .white
            eye.strokeColor = .clear
            eye.position = CGPoint(x: dx, y: dy)
            eye.zPosition = 4
            head.addChild(eye)

            let pupil = SKShapeNode(circleOfRadius: pupilRadius)
            pupil.fillColor = UIColor(white: 0.12, alpha: 1)
            pupil.strokeColor = .clear
            pupil.position = CGPoint(x: dx * 0.18, y: dy * 0.18)
            pupil.zPosition = 5
            eye.addChild(pupil)
            eyeNodes.append(eye)
        }
    }
}
