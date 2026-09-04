import Foundation

final class DependencyContainer {
    static let shared = DependencyContainer()

    private let settingsLocalDataSource: SettingsLocalDataSource
    private let appSessionLocalDataSource: AppSessionLocalDataSource
    let settingsRepository: SettingsRepository
    let appSessionRepository: AppSessionRepository
    let miniGameRepository: MiniGameRepository
    let pluginRegistry: MiniGamePluginRegistry

    private init(
        settingsLocalDataSource: SettingsLocalDataSource = UserDefaultsSettingsLocalDataSource(),
        appSessionLocalDataSource: AppSessionLocalDataSource = UserDefaultsAppSessionLocalDataSource()
    ) {
        self.settingsLocalDataSource = settingsLocalDataSource
        self.appSessionLocalDataSource = appSessionLocalDataSource
        self.settingsRepository = SettingsRepositoryImpl(localDataSource: settingsLocalDataSource)
        self.appSessionRepository = AppSessionRepositoryImpl(localDataSource: appSessionLocalDataSource)

        let registry = MiniGamePluginRegistry()
        self.pluginRegistry = registry
        self.miniGameRepository = MiniGameRepositoryImpl(registry: registry)
		
		self.registerBundledPlugins()
    }

	func registerBundledPlugins() {
		pluginRegistry.register(TicTacToePlugin())
    }

    func makeGetSettingsUseCase() -> GetSettingsUseCase {
        DefaultGetSettingsUseCase(repository: settingsRepository)
    }

    func makeSaveSettingsUseCase() -> SaveSettingsUseCase {
        DefaultSaveSettingsUseCase(repository: settingsRepository)
    }

    func makeResolveLaunchRouteUseCase() -> ResolveLaunchRouteUseCase {
        DefaultResolveLaunchRouteUseCase(appSessionRepository: appSessionRepository)
    }

    func makeCompleteWelcomeUseCase() -> CompleteWelcomeUseCase {
        DefaultCompleteWelcomeUseCase(appSessionRepository: appSessionRepository)
    }

    func makeGetMiniGamesUseCase() -> GetMiniGamesUseCase {
        DefaultGetMiniGamesUseCase(repository: miniGameRepository)
    }

    func makeThemeController() -> ThemeController {
        ThemeController(getSettingsUseCase: makeGetSettingsUseCase())
    }

    func makeSplashViewModel(coordinator: AppCoordinating) -> SplashViewModel {
        SplashViewModel(
            resolveLaunchRouteUseCase: makeResolveLaunchRouteUseCase(),
            coordinator: coordinator
        )
    }

    func makeWelcomeViewModel(coordinator: AppCoordinating) -> WelcomeViewModel {
        WelcomeViewModel(
            completeWelcomeUseCase: makeCompleteWelcomeUseCase(),
            coordinator: coordinator
        )
    }

    func makeGameBoardViewModel(coordinator: AppCoordinating) -> GameBoardViewModel {
        GameBoardViewModel(
            getMiniGamesUseCase: makeGetMiniGamesUseCase(),
            coordinator: coordinator
        )
    }

    func makeSettingViewModel() -> SettingViewModel {
        SettingViewModel(
            getSettingsUseCase: makeGetSettingsUseCase(),
            saveSettingsUseCase: makeSaveSettingsUseCase()
        )
    }

    func makeMiniGameHostViewModel(
        id: MiniGameID,
        coordinator: AppCoordinating
    ) -> MiniGameHostViewModel {
        MiniGameHostViewModel(
            miniGameID: id,
            registry: pluginRegistry,
            getSettingsUseCase: makeGetSettingsUseCase(),
            coordinator: coordinator
        )
    }
}
