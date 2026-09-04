import Foundation

nonisolated struct GameSettings: Equatable, Codable {
    var soundEnabled: Bool
    var musicEnabled: Bool
    var hapticsEnabled: Bool
    var appearance: Appearance

    enum Appearance: String, CaseIterable, Codable, Identifiable {
        case light
        case dark

        var id: String { rawValue }

        var displayName: String {
            switch self {
            case .light: return "Light"
            case .dark: return "Dark"
            }
        }
    }

    static let `default` = GameSettings(
        soundEnabled: true,
        musicEnabled: true,
        hapticsEnabled: true,
        appearance: .light
    )
}
