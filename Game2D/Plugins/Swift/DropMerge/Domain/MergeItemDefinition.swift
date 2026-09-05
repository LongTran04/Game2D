import CoreGraphics
import Foundation

struct MergeItemDefinition: Equatable, Identifiable {
    let level: Int
    let name: String
    let radius: CGFloat
    let colorHex: UInt32
    let symbolName: String
    let score: Int
    let mass: CGFloat

    var id: Int { level }
}
