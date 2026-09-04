import Combine
import Foundation

protocol CompleteWelcomeUseCase {
    func execute() -> AnyPublisher<Void, Never>
}

final class DefaultCompleteWelcomeUseCase: CompleteWelcomeUseCase {
    private let appSessionRepository: AppSessionRepository

    init(appSessionRepository: AppSessionRepository) {
        self.appSessionRepository = appSessionRepository
    }

    func execute() -> AnyPublisher<Void, Never> {
        appSessionRepository.markWelcomeCompleted()
    }
}
