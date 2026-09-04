import SwiftUI

struct RootView: View {
    @StateObject private var coordinator: AppCoordinator
    @StateObject private var splashViewModel: SplashViewModel
    @StateObject private var welcomeViewModel: WelcomeViewModel
    @StateObject private var gameBoardViewModel: GameBoardViewModel
    @EnvironmentObject private var theme: ThemeController

    private let container: DependencyContainer

    init(container: DependencyContainer = .shared) {
        let coordinator = AppCoordinator()
        self.container = container
        _coordinator = StateObject(wrappedValue: coordinator)
        _splashViewModel = StateObject(wrappedValue: container.makeSplashViewModel(coordinator: coordinator))
        _welcomeViewModel = StateObject(wrappedValue: container.makeWelcomeViewModel(coordinator: coordinator))
        _gameBoardViewModel = StateObject(wrappedValue: container.makeGameBoardViewModel(coordinator: coordinator))
    }

    var body: some View {
        Group {
            switch coordinator.flow {
            case .splash:
                SplashView(viewModel: splashViewModel)
            case .welcome:
                WelcomeView(viewModel: welcomeViewModel)
            case .gameBoard:
                NavigationStack(path: $coordinator.path) {
                    GameBoardView(viewModel: gameBoardViewModel)
                        .navigationDestination(for: AppRoute.self) { route in
                            switch route {
                            case .setting:
                                SettingView(viewModel: container.makeSettingViewModel())
                            case .miniGame(let id):
                                MiniGameHostView(
                                    viewModel: container.makeMiniGameHostViewModel(
                                        id: id,
                                        coordinator: coordinator
                                    )
                                )
                            }
                        }
                }
            }
        }
        .tint(theme.colors.accent)
        .preferredColorScheme(theme.preferredColorScheme)
    }
}

#Preview {
    RootView()
        .environmentObject(DependencyContainer.shared.makeThemeController())
}
