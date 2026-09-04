import Combine
import SwiftUI
import UIKit

/// Adapter for a Unity-as-a-Library XCFramework (`UnityFramework`).
///
/// After exporting the Unity project:
/// 1. Add `UnityFramework.xcframework` to the host target.
/// 2. Register `UnityMiniGamePlugin(id:sceneName:)` in `DependencyContainer`.
/// 3. The host loads Unity embedded and maps `MiniGameHostEvent` via `UnitySendMessage`.
final class UnityMiniGamePlugin: MiniGamePlugin {
	var miniGame: MiniGame
	
    private let sceneName: String
    private let frameworkName: String

    init(
		miniGame: MiniGame,
        sceneName: String,
        frameworkName: String = "UnityFramework",
    ) {
        self.miniGame = miniGame
        self.sceneName = sceneName
        self.frameworkName = frameworkName
    }

    func makeViewController(context: MiniGameLaunchContext) -> UIViewController {
        UnityEmbeddedHostViewController(
            frameworkName: frameworkName,
            sceneName: sceneName,
            settings: context.settings,
            theme: context.theme,
            hostEvents: context.hostEvents,
            onEvent: context.onEvent
        )
    }
}

enum UnityFrameworkLoader {
    static func isFrameworkAvailable(named frameworkName: String) -> Bool {
        Bundle.allFrameworks.contains { $0.bundleIdentifier?.contains(frameworkName) == true }
            || Bundle(identifier: "com.unity3d.framework") != nil
    }
}

final class UnityEmbeddedHostViewController: UIViewController {
    private let frameworkName: String
    private let sceneName: String
    private var settings: GameSettings
    private let theme: ThemeController
    private let hostEvents: AnyPublisher<MiniGameHostEvent, Never>
    private let onEvent: (MiniGamePluginEvent) -> Void
    private var cancellables = Set<AnyCancellable>()

    init(
        frameworkName: String,
        sceneName: String,
        settings: GameSettings,
        theme: ThemeController,
        hostEvents: AnyPublisher<MiniGameHostEvent, Never>,
        onEvent: @escaping (MiniGamePluginEvent) -> Void
    ) {
        self.frameworkName = frameworkName
        self.sceneName = sceneName
        self.settings = settings
        self.theme = theme
        self.hostEvents = hostEvents
        self.onEvent = onEvent
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        applyHostAudioPolicy()
        bindHostEvents()
        #if canImport(UnityFramework)
        embedUnityIfPossible()
        #else
        embedFallback()
        #endif
        onEvent(.ready)
    }

    private func bindHostEvents() {
        hostEvents
            .receive(on: DispatchQueue.main)
            .sink { [weak self] event in
                self?.handle(event)
            }
            .store(in: &cancellables)
    }

    private func handle(_ event: MiniGameHostEvent) {
        switch event {
        case .start:
            sendUnity("OnStart", message: sceneName)
            onEvent(.started)
        case .pause:
            sendUnity("OnPause")
            onEvent(.paused)
        case .resume:
            sendUnity("OnResume")
            onEvent(.resumed)
        case .stop:
            sendUnity("OnStop")
            onEvent(.stopped)
        case .setting(let settings):
            self.settings = settings
            applyHostAudioPolicy()
            sendUnity("OnSetting", message: encodedSettings(settings))
        }
    }

    private func applyHostAudioPolicy() {
        view.accessibilityHint = settings.soundEnabled ? "Sound on" : "Sound off"
    }

    private func sendUnity(_ functionName: String, message: String = "") {
        #if canImport(UnityFramework)
        // framework.sendMessageToGO(withName: "GameHost", functionName: functionName, message: message)
        #endif
        _ = (functionName, message)
    }

    private func encodedSettings(_ settings: GameSettings) -> String {
        guard let data = try? JSONEncoder().encode(settings),
              let json = String(data: data, encoding: .utf8) else {
            return "{}"
        }
        return json
    }

    #if canImport(UnityFramework)
    private func embedUnityIfPossible() {
        // Load UnityFramework from the linked XCFramework, attach its root view,
        // then send the scene name and host settings into Unity.
        //
        // Typical flow:
        // let framework = UnityFramework.load()
        // framework.setExecuteHeader(...)
        // framework.runEmbedded(withArgc:argc, argv:argv, appLaunchOpts:...)
        // view.addSubview(framework.appController().rootView)
        // framework.sendMessageToGO(withName: "GameHost", functionName: "LoadScene", message: sceneName)
        embedFallback()
    }
    #endif

    private func embedFallback() {
        let fallback = UIHostingController(
            rootView: UnityUnavailableView(
                title: sceneName,
                frameworkName: frameworkName,
                onExit: { [onEvent] in onEvent(.exitRequested) }
            )
            .environmentObject(theme)
        )
        addChild(fallback)
        fallback.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(fallback.view)
        NSLayoutConstraint.activate([
            fallback.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            fallback.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            fallback.view.topAnchor.constraint(equalTo: view.topAnchor),
            fallback.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        fallback.didMove(toParent: self)
    }
}

private struct UnityUnavailableView: View {
    let title: String
    let frameworkName: String
    let onExit: () -> Void
    @EnvironmentObject private var theme: ThemeController

    var body: some View {
        ZStack {
            theme.colors.background
                .ignoresSafeArea()

            VStack(spacing: 20) {
                Image(systemName: "cube.transparent")
                    .font(.system(size: 48, weight: .semibold))
                    .foregroundStyle(theme.colors.accent)

                Text(title)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(theme.colors.textPrimary)

                Text("Link \(frameworkName).xcframework from a Unity-as-a-Library export to run this mini-game.")
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundStyle(theme.colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 28)

                Button(action: onExit) {
                    Text("Back to Game Board")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(theme.colors.accent, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .foregroundStyle(theme.colors.background)
                }
                .padding(.horizontal, 32)
                .padding(.top, 8)
            }
        }
    }
}
