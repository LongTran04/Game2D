import Combine
import Foundation

protocol ResolveLaunchRouteUseCase {
    func execute() -> AnyPublisher<AppLaunchRoute, Never>
}

final class DefaultResolveLaunchRouteUseCase: ResolveLaunchRouteUseCase {
    private let appSessionRepository: AppSessionRepository

    init(appSessionRepository: AppSessionRepository) {
        self.appSessionRepository = appSessionRepository
    }

    func execute() -> AnyPublisher<AppLaunchRoute, Never> {
        appSessionRepository.hasCompletedWelcome()
            .map { hasCompletedWelcome in
                hasCompletedWelcome ? .gameBoard : .welcome
            }
            .eraseToAnyPublisher()
    }
}
