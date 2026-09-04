import Combine
import Foundation

final class MiniGameHostViewModel: ObservableObject {
    @Published private(set) var plugin: MiniGamePlugin?
    @Published private(set) var settings: GameSettings = .default
    @Published private(set) var lastResult: MiniGameResult?

    private let hostEventSubject = PassthroughSubject<MiniGameHostEvent, Never>()
    private let miniGameID: MiniGameID
    private let registry: MiniGamePluginRegistry
    private let getSettingsUseCase: GetSettingsUseCase
    private weak var coordinator: AppCoordinating?
    private var cancellables = Set<AnyCancellable>()
    private var hasStarted = false
    private var isHostVisible = false

    init(
        miniGameID: MiniGameID,
        registry: MiniGamePluginRegistry,
        getSettingsUseCase: GetSettingsUseCase,
        coordinator: AppCoordinating
    ) {
        self.miniGameID = miniGameID
        self.registry = registry
        self.getSettingsUseCase = getSettingsUseCase
        self.coordinator = coordinator
        load()
    }

    var hostEvents: AnyPublisher<MiniGameHostEvent, Never> {
        hostEventSubject.eraseToAnyPublisher()
    }

    func handlePluginEvent(_ event: MiniGamePluginEvent) {
        switch event {
        case .ready:
            send(.setting(settings))
            send(hasStarted ? .resume : .start)
        case .started:
            hasStarted = true
        case .paused, .resumed:
            break
        case .stopped:
            hasStarted = false
        case .result(let result):
            lastResult = result
        case .settingRequested:
            send(.pause)
            coordinator?.showSettings()
        case .exitRequested:
            stopAndLeave()
        }
    }

    func hostAppeared() {
        isHostVisible = true
        guard hasStarted else { return }
        send(.setting(settings))
        send(.resume)
    }

    func hostDisappeared() {
        isHostVisible = false
        guard hasStarted else { return }
        send(.pause)
    }

    func hostBecameActive() {
        guard hasStarted, isHostVisible else { return }
        send(.resume)
    }

    func hostBecameInactive() {
        guard hasStarted, isHostVisible else { return }
        send(.pause)
    }

    private func load() {
        plugin = registry.plugin(for: miniGameID)
        getSettingsUseCase.observe()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] settings in
                guard let self else { return }
                self.settings = settings
                guard self.hasStarted else { return }
                self.send(.setting(settings))
            }
            .store(in: &cancellables)
    }

    private func stopAndLeave() {
        send(.stop)
        coordinator?.pop()
    }

    private func send(_ event: MiniGameHostEvent) {
        hostEventSubject.send(event)
    }
}
