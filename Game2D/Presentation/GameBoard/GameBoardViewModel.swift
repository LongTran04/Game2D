import Combine
import Foundation

final class GameBoardViewModel: ObservableObject {
    struct Input {
        let viewDidAppear = PassthroughSubject<Void, Never>()
        let settingsTapped = PassthroughSubject<Void, Never>()
        let miniGameTapped = PassthroughSubject<MiniGameID, Never>()
    }

    let input = Input()

    @Published private(set) var title = "Game Board"
    @Published private(set) var subtitle = "Choose a mini-game"
    @Published private(set) var miniGames: [MiniGame] = []

    private let getMiniGamesUseCase: GetMiniGamesUseCase
    private weak var coordinator: AppCoordinating?
    private var cancellables = Set<AnyCancellable>()

    init(
        getMiniGamesUseCase: GetMiniGamesUseCase,
        coordinator: AppCoordinating
    ) {
        self.getMiniGamesUseCase = getMiniGamesUseCase
        self.coordinator = coordinator
        bind()
    }

    private func bind() {
        input.viewDidAppear
            .flatMap { [getMiniGamesUseCase] in
                getMiniGamesUseCase.execute()
            }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] games in
                self?.miniGames = games
            }
            .store(in: &cancellables)

        input.settingsTapped
            .sink { [weak self] in
                self?.coordinator?.showSettings()
            }
            .store(in: &cancellables)

        input.miniGameTapped
            .sink { [weak self] id in
                self?.coordinator?.launchMiniGame(id: id)
            }
            .store(in: &cancellables)
    }
}
