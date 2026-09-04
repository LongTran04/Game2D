import Combine
import Foundation

struct WelcomePage: Equatable, Identifiable {
    let id: Int
    let symbolName: String
    let title: String
    let message: String
}

final class WelcomeViewModel: ObservableObject {
    struct Input {
        let nextTapped = PassthroughSubject<Void, Never>()
        let getStartedTapped = PassthroughSubject<Void, Never>()
        let pageChanged = PassthroughSubject<Int, Never>()
    }

    let input = Input()

    let pages: [WelcomePage] = [
        WelcomePage(
            id: 0,
            symbolName: "sparkles",
            title: "Welcome",
            message: "A board of mini-games, built in Swift or Unity and plugged in as frameworks."
        ),
        WelcomePage(
            id: 1,
            symbolName: "square.grid.2x2.fill",
            title: "Pick a game",
            message: "The Game Board is your hub. Choose a Swift game now, or a Unity game once its XCFramework is linked."
        ),
        WelcomePage(
            id: 2,
            symbolName: "slider.horizontal.3",
            title: "Make it yours",
            message: "Theme, sound, music, and haptics live in Settings All — they apply across every mini-game."
        )
    ]

    @Published var pageIndex = 0
    @Published private(set) var isLastPage = false

    private let completeWelcomeUseCase: CompleteWelcomeUseCase
    private weak var coordinator: AppCoordinating?
    private var cancellables = Set<AnyCancellable>()

    init(
        completeWelcomeUseCase: CompleteWelcomeUseCase,
        coordinator: AppCoordinating
    ) {
        self.completeWelcomeUseCase = completeWelcomeUseCase
        self.coordinator = coordinator
        bind()
    }

    private func bind() {
        input.pageChanged
            .receive(on: DispatchQueue.main)
            .sink { [weak self] index in
                self?.pageIndex = index
                self?.isLastPage = index == (self?.pages.count ?? 1) - 1
            }
            .store(in: &cancellables)

        input.nextTapped
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                guard let self else { return }
                if self.pageIndex < self.pages.count - 1 {
                    self.pageIndex += 1
                    self.isLastPage = self.pageIndex == self.pages.count - 1
                }
            }
            .store(in: &cancellables)

        input.getStartedTapped
            .flatMap { [completeWelcomeUseCase] in
                completeWelcomeUseCase.execute()
            }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                self?.coordinator?.completeWelcome()
            }
            .store(in: &cancellables)

        isLastPage = pageIndex == pages.count - 1
    }
}
