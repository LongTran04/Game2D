import Combine
import SpriteKit
import UIKit

final class DropMergeScene: SKScene, SKPhysicsContactDelegate {
  let events = PassthroughSubject<DropMergeGameEvent, Never>()

  private let mergeCoordinator = MergeCoordinator()
  private let gameOverDetector = GameOverDetector()
  private let randomizer = DropBagRandomizer()

  private var binNode: SKShapeNode?
  private var dangerLineNode: SKShapeNode?
  private var previewNode: MergeItemNode?
  private var wallBodies: [SKNode] = []

  private var score = 0
  private var gameState: DropMergeGameState = .ready
  private var currentDefinition: MergeItemDefinition?
  private var nextDefinition: MergeItemDefinition?

  private var dropCooldownRemaining: TimeInterval = 0
  private let dropCooldown: TimeInterval = 0.4
  private var lastUpdateTime: TimeInterval = 0
  private var isDarkTheme = false
  private var reduceMotion = false
  private var hasEnded = false

  private var binFrame = CGRect.zero
  private var dropY: CGFloat = 0
  /// Host may send `.start` before SpriteView lays out a non-zero size.
  private var pendingStart: Bool?
  private var hasValidPlayfield: Bool {
    size.width > 1 && size.height > 1
  }

  // MARK: - Lifecycle

  override func didMove(to view: SKView) {
    backgroundColor = .clear
    physicsWorld.gravity = CGVector(dx: 0, dy: -22)
    physicsWorld.contactDelegate = self
    scaleMode = .resizeFill
    if hasValidPlayfield {
      rebuildLayout()
      flushPendingStartIfNeeded()
    }
  }

  override func didChangeSize(_ oldSize: CGSize) {
    guard hasValidPlayfield else { return }
    // Skip no-op updates (floating noise from layout).
    guard abs(size.width - oldSize.width) > 0.5 || abs(size.height - oldSize.height) > 0.5 else {
      flushPendingStartIfNeeded()
      return
    }
    rebuildLayout()
    flushPendingStartIfNeeded()
  }

  /// Applied from SwiftUI once the playfield GeometryReader has a real size.
  func updatePlayfieldSize(_ newSize: CGSize) {
    guard newSize.width > 1, newSize.height > 1 else { return }
    let changed = abs(size.width - newSize.width) > 0.5 || abs(size.height - newSize.height) > 0.5
    if changed {
      size = newSize
      // `didChangeSize` handles rebuild + pending start.
    } else {
      flushPendingStartIfNeeded()
    }
  }

  func handle(_ command: DropMergeGameCommand) {
    switch command {
    case .start:
      requestStart(restart: false)
    case .restart:
      requestStart(restart: true)
    case .aim(let x):
      aimPreview(at: x)
    case .drop(let x):
      drop(at: x)
    case .pause:
      pauseGame()
    case .resume:
      resumeGame()
    case .stop:
      pendingStart = nil
      stopGame()
    case .applyTheme(let isDark):
      isDarkTheme = isDark
      applyThemeColors()
    }
  }

  func setReduceMotion(_ enabled: Bool) {
    reduceMotion = enabled
  }

  // MARK: - Layout

  private func requestStart(restart: Bool) {
    guard hasValidPlayfield else {
      pendingStart = restart
      return
    }
    startGame(restart: restart)
  }

  private func flushPendingStartIfNeeded() {
    guard hasValidPlayfield, let restart = pendingStart else { return }
    pendingStart = nil
    startGame(restart: restart)
  }

  private func rebuildLayout() {
    guard hasValidPlayfield else { return }

    // Preserve dropped orbs across size changes; only rebuild static bin chrome.
    let preservedItems = children.compactMap { $0 as? MergeItemNode }
    let preview = previewNode
    previewNode = nil

    children
      .filter { !($0 is MergeItemNode) }
      .forEach { $0.removeFromParent() }
    wallBodies.removeAll()

    let insetX: CGFloat = 0
    let topInset: CGFloat = 10
    let bottomInset: CGFloat = 28

    binFrame = CGRect(
      x: insetX,
      y: bottomInset,
      width: size.width - insetX * 2,
      height: size.height - topInset - bottomInset
    )
    // Preview hangs near the rim; danger line sits just below it.
    dropY = binFrame.maxY - 28
    gameOverDetector.dangerLineY = binFrame.maxY - 56

    buildBin()
    buildDangerLine()
    applyThemeColors()

    for item in preservedItems {
      item.position.x = clampX(item.position.x, radius: item.definition.radius)
      if item.position.y < binFrame.minY + item.definition.radius {
        item.position.y = binFrame.minY + item.definition.radius
      }
    }

    if let preview {
      preview.position = CGPoint(
        x: clampX(preview.position.x, radius: preview.definition.radius),
        y: dropY
      )
      previewNode = preview
    } else if gameState == .playing || gameState == .paused {
      spawnPreviewIfNeeded()
    }
  }

  private func buildBin() {
    // Full-bleed playfield so the SpriteView container has no empty letterbox.
    let backdrop = SKShapeNode(rectOf: CGSize(width: size.width, height: size.height))
    backdrop.position = CGPoint(x: size.width / 2, y: size.height / 2)
    backdrop.fillColor = UIColor.black.withAlphaComponent(isDarkTheme ? 0.18 : 0.05)
    backdrop.strokeColor = .clear
    backdrop.zPosition = -1
    backdrop.name = "backdrop"
    addChild(backdrop)

    // Floor stroke only — no left/right wall visuals.
    let floorPath = CGMutablePath()
    floorPath.move(to: CGPoint(x: binFrame.minX, y: binFrame.minY))
    floorPath.addLine(to: CGPoint(x: binFrame.maxX, y: binFrame.minY))

    let bin = SKShapeNode(path: floorPath)
    bin.strokeColor = UIColor.white.withAlphaComponent(0.55)
    bin.lineWidth = 3
    bin.fillColor = .clear
    bin.zPosition = 0
    addChild(bin)
    binNode = bin

    let wallThickness: CGFloat = 8
    // Invisible edge colliders flush to the scene (no side padding).
    addWall(
      rect: CGRect(
        x: -wallThickness / 2,
        y: binFrame.minY,
        width: wallThickness,
        height: binFrame.height
      )
    )
    addWall(
      rect: CGRect(
        x: size.width - wallThickness / 2,
        y: binFrame.minY,
        width: wallThickness,
        height: binFrame.height
      )
    )
    addWall(
      rect: CGRect(
        x: binFrame.minX,
        y: binFrame.minY - wallThickness / 2,
        width: binFrame.width,
        height: wallThickness
      )
    )

    let sensor = SKNode()
    sensor.position = CGPoint(x: binFrame.midX, y: gameOverDetector.dangerLineY)
    let sensorBody = SKPhysicsBody(
      rectangleOf: CGSize(width: binFrame.width, height: 4)
    )
    sensorBody.isDynamic = false
    sensorBody.categoryBitMask = PhysicsCategory.dangerSensor
    sensorBody.collisionBitMask = PhysicsCategory.none
    sensorBody.contactTestBitMask = PhysicsCategory.item
    sensor.physicsBody = sensorBody
    sensor.name = "dangerSensor"
    addChild(sensor)
    wallBodies.append(sensor)
  }

  private func addWall(rect: CGRect) {
    let wall = SKNode()
    wall.position = CGPoint(x: rect.midX, y: rect.midY)
    let body = SKPhysicsBody(rectangleOf: rect.size)
    body.isDynamic = false
    body.friction = 0.4
    body.restitution = 0.05
    body.categoryBitMask = PhysicsCategory.wall
    body.collisionBitMask = PhysicsCategory.item
    body.contactTestBitMask = PhysicsCategory.none
    wall.physicsBody = body
    wall.name = "wall"
    addChild(wall)
    wallBodies.append(wall)
  }

  private func buildDangerLine() {
    let line = SKShapeNode(rectOf: CGSize(width: binFrame.width, height: 2))
    line.position = CGPoint(x: binFrame.midX, y: gameOverDetector.dangerLineY)
    line.fillColor = UIColor.systemRed.withAlphaComponent(0.55)
    line.strokeColor = .clear
    line.zPosition = 5
    line.name = "dangerLine"
    addChild(line)
    dangerLineNode = line

    let pulse = SKAction.sequence([
      SKAction.fadeAlpha(to: 0.25, duration: 0.7),
      SKAction.fadeAlpha(to: 0.7, duration: 0.7),
    ])
    line.run(SKAction.repeatForever(pulse), withKey: "pulse")
  }

  private func applyThemeColors() {
    let stroke =
      isDarkTheme
      ? UIColor.white.withAlphaComponent(0.45)
      : UIColor.black.withAlphaComponent(0.25)
    let fill =
      isDarkTheme
      ? UIColor.white.withAlphaComponent(0.05)
      : UIColor.black.withAlphaComponent(0.04)
    binNode?.strokeColor = stroke
    binNode?.fillColor = fill
    if let backdrop = childNode(withName: "backdrop") as? SKShapeNode {
      backdrop.fillColor = UIColor.black.withAlphaComponent(isDarkTheme ? 0.22 : 0.06)
    }
  }

  // MARK: - Game flow

  private func startGame(restart: Bool) {
    pendingStart = nil
    guard hasValidPlayfield else {
      pendingStart = restart
      return
    }

    clearItems()
    mergeCoordinator.reset()
    gameOverDetector.reset()
    randomizer.reset()
    score = 0
    dropCooldownRemaining = 0
    hasEnded = false
    isPaused = false
    physicsWorld.speed = 1
    gameState = .playing

    let first = MergeCatalog.definition(for: randomizer.nextLevel())!
    let second = MergeCatalog.definition(for: randomizer.nextLevel())!
    currentDefinition = first
    nextDefinition = second

    events.send(.scoreChanged(0))
    events.send(.currentItemChanged(first))
    events.send(.nextItemChanged(second))
    events.send(.stateChanged(.playing))

    spawnPreviewIfNeeded()
    _ = restart
  }

  private func pauseGame() {
    guard gameState == .playing else { return }
    gameState = .paused
    isPaused = true
    physicsWorld.speed = 0
    events.send(.stateChanged(.paused))
  }

  private func resumeGame() {
    guard gameState == .paused else { return }
    gameState = .playing
    isPaused = false
    physicsWorld.speed = 1
    events.send(.stateChanged(.playing))
  }

  private func stopGame() {
    gameState = .ready
    isPaused = true
    physicsWorld.speed = 0
    clearItems()
    mergeCoordinator.reset()
    gameOverDetector.reset()
    events.send(.stateChanged(.ready))
  }

  private func endGame() {
    guard !hasEnded else { return }
    hasEnded = true
    gameState = .gameOver
    isPaused = true
    physicsWorld.speed = 0
    previewNode?.removeFromParent()
    previewNode = nil
    events.send(.gameOver(finalScore: score))
    events.send(.stateChanged(.gameOver))
  }

  private func clearItems() {
    children
      .compactMap { $0 as? MergeItemNode }
      .forEach { $0.removeFromParent() }
    previewNode = nil
  }

  // MARK: - Drop pipeline

  private func spawnPreviewIfNeeded() {
    guard hasValidPlayfield else { return }
    guard gameState == .playing || gameState == .paused else { return }
    guard previewNode == nil, let currentDefinition else { return }

    let node = MergeItemNode(definition: currentDefinition, isPreview: true)
    node.position = CGPoint(x: binFrame.midX, y: dropY)
    node.zPosition = 10
    addChild(node)
    previewNode = node
  }

  private func aimPreview(at sceneX: CGFloat) {
    guard gameState == .playing, let preview = previewNode, let def = currentDefinition else {
      return
    }
    let clamped = clampX(sceneX, radius: def.radius)
    preview.position = CGPoint(x: clamped, y: dropY)
  }

  private func drop(at sceneX: CGFloat) {
    guard gameState == .playing else { return }
    guard dropCooldownRemaining <= 0 else { return }
    guard let preview = previewNode, let current = currentDefinition else { return }

    let clamped = clampX(sceneX, radius: current.radius)
    preview.position = CGPoint(x: clamped, y: dropY)
    preview.activateAsDropped()
    previewNode = nil

    dropCooldownRemaining = dropCooldown
    events.send(.itemDropped)
    advanceQueue()
    scheduleNextPreview()
  }

  private func advanceQueue() {
    currentDefinition = nextDefinition
    let nextLevel = randomizer.nextLevel()
    nextDefinition = MergeCatalog.definition(for: nextLevel)
    if let currentDefinition {
      events.send(.currentItemChanged(currentDefinition))
    }
    if let nextDefinition {
      events.send(.nextItemChanged(nextDefinition))
    }
  }

  private func scheduleNextPreview() {
    // Preview appears after cooldown via update loop when ready.
  }

  private func clampX(_ x: CGFloat, radius: CGFloat) -> CGFloat {
    let minX = binFrame.minX + radius
    let maxX = binFrame.maxX - radius
    return min(max(x, minX), maxX)
  }

  // MARK: - Touch

  override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
    guard let touch = touches.first else { return }
    aimPreview(at: touch.location(in: self).x)
  }

  override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
    guard let touch = touches.first else { return }
    aimPreview(at: touch.location(in: self).x)
  }

  override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
    guard let touch = touches.first else { return }
    let x = touch.location(in: self).x
    aimPreview(at: x)
    drop(at: x)
  }

  override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
    touchesEnded(touches, with: event)
  }

  // MARK: - Update / merge

  override func update(_ currentTime: TimeInterval) {
    let dt: TimeInterval
    if lastUpdateTime == 0 {
      dt = 1.0 / 60.0
    } else {
      dt = min(currentTime - lastUpdateTime, 1.0 / 30.0)
    }
    lastUpdateTime = currentTime

    guard gameState == .playing, !isPaused else { return }

    if dropCooldownRemaining > 0 {
      dropCooldownRemaining -= dt
      if dropCooldownRemaining <= 0, previewNode == nil {
        spawnPreviewIfNeeded()
      }
    }

    let items = children.compactMap { $0 as? MergeItemNode }
    for item in items where item.spawnImmunityRemaining > 0 {
      item.spawnImmunityRemaining -= dt
    }

    resolveChainMerges()

    if gameOverDetector.update(items: items, deltaTime: dt) {
      endGame()
    }
  }

  /// How far beyond touching distance two orbs can be and still chain-merge.
  private let mergeRangeMultiplier: CGFloat = 1.35

  /// Resolves merges in a loop until no adjacent same-level pairs remain queued.
  /// Each pass executes pending merges, then scans newly created orbs for chain reactions.
  private func resolveChainMerges() {
    let maxPasses = 32
    var pass = 0

    while pass < maxPasses {
      guard mergeCoordinator.hasPending else { break }
      pass += 1

      let created = processPendingMergesBatch()
      guard !created.isEmpty else { break }

      for item in created {
        enqueueAdjacentMerges(around: item)
      }
    }
  }

  /// Executes one batch of queued merges. Returns nodes created this pass.
  @discardableResult
  private func processPendingMergesBatch() -> [MergeItemNode] {
    let merges = mergeCoordinator.drainPending()
    guard !merges.isEmpty else { return [] }

    let nodesByID = Dictionary(
      uniqueKeysWithValues:
        children
        .compactMap { $0 as? MergeItemNode }
        .map { ($0.itemID, $0) }
    )

    var createdNodes: [MergeItemNode] = []

    for merge in merges {
      guard let first = nodesByID[merge.firstID],
        let second = nodesByID[merge.secondID],
        let nextDef = MergeCatalog.nextLevel(after: merge.level)
      else {
        nodesByID[merge.firstID]?.isMerging = false
        nodesByID[merge.secondID]?.isMerging = false
        continue
      }

      let mid = merge.midpoint
      first.removeFromParent()
      second.removeFromParent()

      let created = MergeItemNode(definition: nextDef)
      created.position = mid
      created.markSpawnedFromMerge()
      created.zPosition = 2
      addChild(created)
      createdNodes.append(created)

      let points = ScoreRules.points(for: nextDef)
      score += points
      events.send(.scoreChanged(score))
      events.send(.merged(level: nextDef.level, points: points))

      playMergeJuice(
        at: mid,
        color: UIColor(hex: nextDef.colorHex),
        radius: nextDef.radius,
        points: points
      )
    }

    return createdNodes
  }

  /// After a merge, check overlapping same-level neighbors and queue the next chain link.
  private func enqueueAdjacentMerges(around item: MergeItemNode) {
    let neighbors = children.compactMap { $0 as? MergeItemNode }
    for other in neighbors where other.itemID != item.itemID {
      guard areWithinMergeDistance(item, other) else { continue }
      mergeCoordinator.enqueueIfPossible(
        first: item,
        second: other,
        ignoringSpawnImmunity: true
      )
    }
  }

  private func areWithinMergeDistance(_ first: MergeItemNode, _ second: MergeItemNode) -> Bool {
    let dx = first.position.x - second.position.x
    let dy = first.position.y - second.position.y
    let distance = sqrt(dx * dx + dy * dy)
    let threshold = (first.definition.radius + second.definition.radius) * mergeRangeMultiplier
    return distance <= threshold
  }

  private func playMergeJuice(at point: CGPoint, color: UIColor, radius: CGFloat, points: Int) {
    guard !reduceMotion else { return }

    let pop = SKShapeNode(circleOfRadius: radius * 0.85)
    pop.fillColor = color.withAlphaComponent(0.45)
    pop.strokeColor = .clear
    pop.position = point
    pop.zPosition = 20
    pop.setScale(0.4)
    addChild(pop)
    pop.run(
      SKAction.sequence([
        SKAction.group([
          SKAction.scale(to: 1.35, duration: 0.18),
          SKAction.fadeOut(withDuration: 0.18),
        ]),
        SKAction.removeFromParent(),
      ])
    )

    if let emitter = makeMergeEmitter(color: color) {
      emitter.position = point
      emitter.zPosition = 21
      addChild(emitter)
      emitter.run(
        SKAction.sequence([
          SKAction.wait(forDuration: 0.45),
          SKAction.removeFromParent(),
        ]))
    }

    let label = SKLabelNode(fontNamed: "AvenirNext-Bold")
    label.text = "+\(points)"
    label.fontSize = 18
    label.fontColor = .white
    label.position = CGPoint(x: point.x, y: point.y + radius + 8)
    label.zPosition = 22
    addChild(label)
    label.run(
      SKAction.sequence([
        SKAction.group([
          SKAction.moveBy(x: 0, y: 28, duration: 0.45),
          SKAction.fadeOut(withDuration: 0.45),
        ]),
        SKAction.removeFromParent(),
      ])
    )

    // Mild bin nudge as screen-shake substitute.
    if let binNode {
      let shake = SKAction.sequence([
        SKAction.moveBy(x: 2, y: 0, duration: 0.03),
        SKAction.moveBy(x: -4, y: 0, duration: 0.03),
        SKAction.moveBy(x: 2, y: 0, duration: 0.03),
      ])
      binNode.run(shake, withKey: "shake")
    }
  }

  private func makeMergeEmitter(color: UIColor) -> SKEmitterNode? {
    let emitter = SKEmitterNode()
    emitter.particleBirthRate = 80
    emitter.numParticlesToEmit = 18
    emitter.particleLifetime = 0.35
    emitter.particleLifetimeRange = 0.15
    emitter.particlePositionRange = CGVector(dx: 8, dy: 8)
    emitter.emissionAngleRange = .pi * 2
    emitter.particleSpeed = 90
    emitter.particleSpeedRange = 40
    emitter.particleAlpha = 0.9
    emitter.particleAlphaSpeed = -2.2
    emitter.particleScale = 0.08
    emitter.particleScaleRange = 0.04
    emitter.particleColor = color
    emitter.particleColorBlendFactor = 1
    emitter.particleBlendMode = .add

    let circle = SKShapeNode(circleOfRadius: 6)
    circle.fillColor = .white
    if let texture = view?.texture(from: circle) {
      emitter.particleTexture = texture
    }
    return emitter
  }

  // MARK: - Contacts

  func didBegin(_ contact: SKPhysicsContact) {
    guard gameState == .playing else { return }

    let a = contact.bodyA.node
    let b = contact.bodyB.node

    if let first = a as? MergeItemNode, let second = b as? MergeItemNode {
      mergeCoordinator.enqueueIfPossible(first: first, second: second)
      return
    }

    // Danger sensor contacts are handled via position checks in GameOverDetector.
    _ = (a, b)
  }
}

extension UIColor {
  fileprivate convenience init(hex: UInt32) {
    self.init(
      red: CGFloat((hex >> 16) & 0xFF) / 255,
      green: CGFloat((hex >> 8) & 0xFF) / 255,
      blue: CGFloat(hex & 0xFF) / 255,
      alpha: 1
    )
  }
}
