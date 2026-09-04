import Combine
import Foundation

final class SplashViewModel: ObservableObject {
    struct Input {
        let viewDidAppear = PassthroughSubject<Void, Never>()
    }

    let input = Input()

    @Published private(set) var title = "GAME 2D"
    @Published private(set) var subtitle = "Mini-games · Swift & Unity"

    private let resolveLaunchRouteUseCase: ResolveLaunchRouteUseCase
    private weak var coordinator: AppCoordinating?
    private var cancellables = Set<AnyCancellable>()

    init(
        resolveLaunchRouteUseCase: ResolveLaunchRouteUseCase,
        coordinator: AppCoordinating
    ) {
        self.resolveLaunchRouteUseCase = resolveLaunchRouteUseCase
        self.coordinator = coordinator
        bind()
    }

    private func bind() {
        input.viewDidAppear
            .prefix(1)
            .flatMap { [resolveLaunchRouteUseCase] in
                Publishers.Zip(
                    Just(()).delay(for: .milliseconds(1600), scheduler: DispatchQueue.main),
                    resolveLaunchRouteUseCase.execute()
                )
            }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _, route in
                self?.coordinator?.completeSplash(route: route)
            }
            .store(in: &cancellables)
    }
}
