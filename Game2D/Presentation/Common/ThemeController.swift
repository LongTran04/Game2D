import Combine
import SwiftUI

final class ThemeController: ObservableObject {
    @Published private(set) var colors: ThemeColors
    @Published private(set) var preferredColorScheme: ColorScheme
    @Published private(set) var appearance: GameSettings.Appearance

    private var cancellables = Set<AnyCancellable>()

    init(getSettingsUseCase: GetSettingsUseCase) {
        let initial = GameSettings.default
        self.appearance = initial.appearance

        let factory = AppThemeFactoryProvider.makeFactory(for: initial.appearance)
        self.preferredColorScheme = factory.makeColorScheme()
        self.colors = factory.makeColors()

        getSettingsUseCase.observe()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] settings in
                self?.apply(settings)
            }
            .store(in: &cancellables)
    }

    private func apply(_ settings: GameSettings) {
        appearance = settings.appearance
        let factory = AppThemeFactoryProvider.makeFactory(for: settings.appearance)
        preferredColorScheme = factory.makeColorScheme()
        colors = factory.makeColors()
    }
}
