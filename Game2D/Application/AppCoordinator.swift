import Combine
import SwiftUI

final class AppCoordinator: ObservableObject, AppCoordinating {
    @Published var flow: AppFlow = .splash
    @Published var path = NavigationPath()

    func completeSplash(route: AppLaunchRoute) {
        withAnimation(.easeInOut(duration: 0.35)) {
            switch route {
            case .welcome:
                flow = .welcome
            case .gameBoard:
                flow = .gameBoard
            }
        }
    }

    func completeWelcome() {
        withAnimation(.easeInOut(duration: 0.35)) {
            path = NavigationPath()
            flow = .gameBoard
        }
    }

    func showSettings() {
        path.append(AppRoute.setting)
    }

    func launchMiniGame(id: MiniGameID) {
        path.append(AppRoute.miniGame(id))
    }

    func pop() {
        guard !path.isEmpty else { return }
        path.removeLast()
    }
}
