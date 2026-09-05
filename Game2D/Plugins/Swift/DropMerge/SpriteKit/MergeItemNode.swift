import SpriteKit
import UIKit

final class MergeItemNode: SKNode {
    let itemID: UUID
    let level: Int
    let definition: MergeItemDefinition
    var isMerging = false
    var isPreview = false
    var isDropped = false
    var spawnImmunityRemaining: TimeInterval = 0

    private let bodyNode: SKShapeNode
    private let symbolNode: SKSpriteNode?

    init(definition: MergeItemDefinition, isPreview: Bool = false) {
        self.itemID = UUID()
        self.level = definition.level
        self.definition = definition
        self.isPreview = isPreview

        let radius = definition.radius
        bodyNode = SKShapeNode(circleOfRadius: radius)
        bodyNode.fillColor = UIColor(hex: definition.colorHex)
        bodyNode.strokeColor = UIColor.white.withAlphaComponent(0.35)
        bodyNode.lineWidth = 2
        bodyNode.glowWidth = 0
        bodyNode.zPosition = 1

        if let image = UIImage(systemName: definition.symbolName)?.withTintColor(
            .white.withAlphaComponent(0.85),
            renderingMode: .alwaysOriginal
        ) {
            let texture = SKTexture(image: image)
            let symbolSize = radius * 0.9
            let symbol = SKSpriteNode(texture: texture, size: CGSize(width: symbolSize, height: symbolSize))
            symbol.zPosition = 2
            symbolNode = symbol
        } else {
            symbolNode = nil
        }

        super.init()
        name = "mergeItem"
        addChild(bodyNode)
        if let symbolNode {
            addChild(symbolNode)
        }

        if isPreview {
            configureAsPreview()
        } else {
            configurePhysics()
        }
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configureAsPreview() {
        isPreview = true
        isDropped = false
        physicsBody = nil
        alpha = 0.92
    }

    func configurePhysics() {
        isPreview = false
        // Match visual radius so stacked orbs sit flush (merge range uses separate scan logic).
        let body = SKPhysicsBody(circleOfRadius: definition.radius)
        body.isDynamic = true
        body.affectedByGravity = true
        body.allowsRotation = true
        body.restitution = 0.05
        body.friction = 0.45
        body.linearDamping = 0.2
        body.angularDamping = 0.25
        body.mass = definition.mass
        body.categoryBitMask = PhysicsCategory.item
        body.collisionBitMask = PhysicsCategory.item | PhysicsCategory.wall
        body.contactTestBitMask = PhysicsCategory.item | PhysicsCategory.dangerSensor
        body.usesPreciseCollisionDetection = true
        physicsBody = body
        alpha = 1
    }

    func activateAsDropped() {
        configurePhysics()
        isDropped = true
        spawnImmunityRemaining = 0.15
    }

    func markSpawnedFromMerge() {
        configurePhysics()
        isDropped = true
        isMerging = false
        spawnImmunityRemaining = 0.2
    }

    func canParticipateInMerge(ignoringSpawnImmunity: Bool = false) -> Bool {
        isDropped
            && !isPreview
            && !isMerging
            && (ignoringSpawnImmunity || spawnImmunityRemaining <= 0)
    }
}

private extension UIColor {
    convenience init(hex: UInt32) {
        self.init(
            red: CGFloat((hex >> 16) & 0xFF) / 255,
            green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255,
            alpha: 1
        )
    }
}
