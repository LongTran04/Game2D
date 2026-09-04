import Combine
import Foundation

final class SettingViewModel: ObservableObject {
    struct Input {
        let viewDidAppear = PassthroughSubject<Void, Never>()
        let soundChanged = PassthroughSubject<Bool, Never>()
        let musicChanged = PassthroughSubject<Bool, Never>()
        let hapticsChanged = PassthroughSubject<Bool, Never>()
        let appearanceChanged = PassthroughSubject<GameSettings.Appearance, Never>()
    }

    let input = Input()

    @Published private(set) var soundEnabled = GameSettings.default.soundEnabled
    @Published private(set) var musicEnabled = GameSettings.default.musicEnabled
    @Published private(set) var hapticsEnabled = GameSettings.default.hapticsEnabled
    @Published private(set) var appearance = GameSettings.default.appearance
    @Published private(set) var showsSavedHint = false

    private let getSettingsUseCase: GetSettingsUseCase
    private let saveSettingsUseCase: SaveSettingsUseCase
    private let persistTrigger = PassthroughSubject<GameSettings, Never>()
    private var cancellables = Set<AnyCancellable>()

    init(
        getSettingsUseCase: GetSettingsUseCase,
        saveSettingsUseCase: SaveSettingsUseCase
    ) {
        self.getSettingsUseCase = getSettingsUseCase
        self.saveSettingsUseCase = saveSettingsUseCase
        bind()
    }

    private func bind() {
        input.viewDidAppear
            .flatMap { [getSettingsUseCase] in
                getSettingsUseCase.execute()
            }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] settings in
                self?.apply(settings)
            }
            .store(in: &cancellables)

        input.soundChanged
            .sink { [weak self] value in
                guard let self else { return }
                self.soundEnabled = value
                self.persistTrigger.send(self.currentSettings)
            }
            .store(in: &cancellables)

        input.musicChanged
            .sink { [weak self] value in
                guard let self else { return }
                self.musicEnabled = value
                self.persistTrigger.send(self.currentSettings)
            }
            .store(in: &cancellables)

        input.hapticsChanged
            .sink { [weak self] value in
                guard let self else { return }
                self.hapticsEnabled = value
                self.persistTrigger.send(self.currentSettings)
            }
            .store(in: &cancellables)

        input.appearanceChanged
            .sink { [weak self] value in
                guard let self else { return }
                self.appearance = value
                self.persistTrigger.send(self.currentSettings)
            }
            .store(in: &cancellables)

        persistTrigger
            .removeDuplicates()
            .debounce(for: .milliseconds(200), scheduler: DispatchQueue.main)
            .flatMap { [saveSettingsUseCase] settings in
                saveSettingsUseCase.execute(settings)
                    .catch { _ in Empty() }
            }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                self?.showsSavedHint = true
            }
            .store(in: &cancellables)

        $showsSavedHint
            .filter { $0 }
            .delay(for: .seconds(1.2), scheduler: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.showsSavedHint = false
            }
            .store(in: &cancellables)
    }

    private var currentSettings: GameSettings {
        GameSettings(
            soundEnabled: soundEnabled,
            musicEnabled: musicEnabled,
            hapticsEnabled: hapticsEnabled,
            appearance: appearance
        )
    }

    private func apply(_ settings: GameSettings) {
        soundEnabled = settings.soundEnabled
        musicEnabled = settings.musicEnabled
        hapticsEnabled = settings.hapticsEnabled
        appearance = settings.appearance
    }
}
