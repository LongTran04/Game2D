import SwiftUI

struct MiniGameHostView: View {
    @StateObject private var viewModel: MiniGameHostViewModel
    @EnvironmentObject private var theme: ThemeController
    @Environment(\.scenePhase) private var scenePhase

    init(viewModel: MiniGameHostViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        Group {
            if let plugin = viewModel.plugin {
                MiniGameViewControllerRepresentable(
                    plugin: plugin,
                    context: MiniGameLaunchContext(
                        settings: viewModel.settings,
                        theme: theme,
                        hostEvents: viewModel.hostEvents,
                        onEvent: viewModel.handlePluginEvent
                    )
                )
                .ignoresSafeArea()
            } else {
                missingGame
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .onAppear {
            viewModel.hostAppeared()
        }
        .onDisappear {
            viewModel.hostDisappeared()
        }
        .onChange(of: scenePhase) { _, phase in
            switch phase {
            case .active:
                viewModel.hostBecameActive()
            case .inactive, .background:
                viewModel.hostBecameInactive()
            @unknown default:
                break
            }
        }
    }

    private var missingGame: some View {
        ZStack {
            theme.colors.background
                .ignoresSafeArea()
            VStack(spacing: 16) {
                Text("Mini-game unavailable")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(theme.colors.textPrimary)
                Button {
                    viewModel.handlePluginEvent(.exitRequested)
                } label: {
                    Text("Back to Game Board")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundStyle(theme.colors.accent)
                }
            }
        }
    }
}

private struct MiniGameViewControllerRepresentable: UIViewControllerRepresentable {
    let plugin: MiniGamePlugin
    let context: MiniGameLaunchContext

    func makeUIViewController(context: Context) -> UIViewController {
        plugin.makeViewController(context: self.context)
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
}
