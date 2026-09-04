import Foundation

protocol AppCoordinating: AnyObject {
    func completeSplash(route: AppLaunchRoute)
    func completeWelcome()
    func showSettings()
    func launchMiniGame(id: MiniGameID)
    func pop()
}
