import Foundation

enum PhysicsCategory {
    static let none: UInt32 = 0
    static let item: UInt32 = 0b1
    static let wall: UInt32 = 0b10
    static let dangerSensor: UInt32 = 0b100
}
