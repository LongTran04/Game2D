import Combine
import SwiftUI
import UIKit

final class StubMiniGamePlugin: MiniGamePlugin {
	var miniGame: MiniGame

    init(miniGame: MiniGame) {
        self.miniGame = miniGame
    }

    func makeViewController(context: MiniGameLaunchContext) -> UIViewController {
        UIHostingController(
            rootView: ComingSoonMiniGameView(
				title: miniGame.title,
				engine: miniGame.engine,
                hostEvents: context.hostEvents,
                onEvent: context.onEvent
            )
            .environmentObject(context.theme)
        )
    }
}

private struct ComingSoonMiniGameView: View {
    let title: String
    let engine: MiniGameEngine
    let hostEvents: AnyPublisher<MiniGameHostEvent, Never>
    let onEvent: (MiniGamePluginEvent) -> Void
    @EnvironmentObject private var theme: ThemeController

    var body: some View {
        ZStack {
            theme.colors.background
                .ignoresSafeArea()

            VStack(spacing: 18) {
                Image(systemName: "lock.fill")
                    .font(.system(size: 40, weight: .semibold))
                    .foregroundStyle(theme.colors.accent)

                Text(title)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(theme.colors.textPrimary)

                Text("\(engine.displayName) mini-game · coming soon")
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundStyle(theme.colors.textSecondary)

                Button {
                    onEvent(.exitRequested)
                } label: {
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
        .onAppear {
            onEvent(.ready)
        }
        .onReceive(hostEvents) { event in
            switch event {
            case .start:
                onEvent(.started)
            case .pause:
                onEvent(.paused)
            case .resume:
                onEvent(.resumed)
            case .stop:
                onEvent(.stopped)
            case .setting:
                break
            }
        }
    }
}
