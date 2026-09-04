import Combine
import Foundation

final class AppSessionRepositoryImpl: AppSessionRepository {
    private let localDataSource: AppSessionLocalDataSource

    init(localDataSource: AppSessionLocalDataSource) {
        self.localDataSource = localDataSource
    }

    func hasCompletedWelcome() -> AnyPublisher<Bool, Never> {
        Just(localDataSource.hasCompletedWelcome())
            .eraseToAnyPublisher()
    }

    func markWelcomeCompleted() -> AnyPublisher<Void, Never> {
        Deferred {
            Future<Void, Never> { [weak self] promise in
                self?.localDataSource.markWelcomeCompleted()
                promise(.success(()))
            }
        }
        .eraseToAnyPublisher()
    }
}
