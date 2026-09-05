import CoreGraphics
import Foundation

enum MergeCatalog {
	/// Eleven original Lumen orbs — distinct hues/radii, no fruit naming.
	static let items: [MergeItemDefinition] = [
		MergeItemDefinition(level: 1, name: "Orb", radius: 22, colorHex: 0x7BDFF2, symbolName: "circle.fill", score: 1, mass: 0.55),
		MergeItemDefinition(level: 2, name: "Shard", radius: 27, colorHex: 0x70D6FF, symbolName: "triangle.fill", score: 2, mass: 0.7),
		MergeItemDefinition(level: 3, name: "Cube", radius: 32, colorHex: 0x48BFE3, symbolName: "square.fill", score: 4, mass: 0.9),
		MergeItemDefinition(level: 4, name: "Gem", radius: 38, colorHex: 0x5E60CE, symbolName: "diamond.fill", score: 8, mass: 1.1),
		MergeItemDefinition(level: 5, name: "Penta", radius: 44, colorHex: 0x9B5DE5, symbolName: "pentagon.fill", score: 16, mass: 1.35),
		MergeItemDefinition(level: 6, name: "Hexa", radius: 52, colorHex: 0xC77DFF, symbolName: "hexagon.fill", score: 32, mass: 1.65),
		MergeItemDefinition(level: 7, name: "Octa", radius: 60, colorHex: 0xF15BB5, symbolName: "octagon.fill", score: 64, mass: 2.0),
		MergeItemDefinition(level: 8, name: "Crest", radius: 70, colorHex: 0xFF7096, symbolName: "seal.fill", score: 128, mass: 2.4),
		MergeItemDefinition(level: 9, name: "Star", radius: 82, colorHex: 0xF4D35E, symbolName: "star.fill", score: 256, mass: 2.9),
		MergeItemDefinition(level: 10, name: "Nova", radius: 96, colorHex: 0xFF9F1C, symbolName: "sparkles", score: 512, mass: 3.5),
	]
	
	static let maxLevel = items.count
	static let droppableMaxLevel = 5
	
	static func definition(for level: Int) -> MergeItemDefinition? {
		items.first { $0.level == level }
	}
	
	static func nextLevel(after level: Int) -> MergeItemDefinition? {
		definition(for: level + 1)
	}
}
