import Foundation

nonisolated struct MiniGameID: Hashable, RawRepresentable {
    let rawValue: String
}

nonisolated enum MiniGameEngine: String, Equatable {
    case swift
    case unity

    var displayName: String {
        switch self {
        case .swift: return "Swift"
        case .unity: return "Unity"
        }
    }
}

nonisolated struct MiniGame: Identifiable, Equatable {
    let id: MiniGameID
    let title: String
    let subtitle: String
    let engine: MiniGameEngine
    let symbolName: String
    let isAvailable: Bool
}

nonisolated enum AppLaunchRoute: Equatable {
    case welcome
    case gameBoard
}
