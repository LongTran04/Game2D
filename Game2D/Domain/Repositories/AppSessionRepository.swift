import Combine
import Foundation

protocol AppSessionRepository {
    func hasCompletedWelcome() -> AnyPublisher<Bool, Never>
    func markWelcomeCompleted() -> AnyPublisher<Void, Never>
}
