import Combine
import SwiftUI

struct SplashView: View {
    @ObservedObject var viewModel: SplashViewModel
    @EnvironmentObject private var theme: ThemeController

    @State private var isVisible = false

    var body: some View {
        ZStack {
            theme.colors.background
                .ignoresSafeArea()

            VStack(spacing: 18) {
                Image(systemName: "square.grid.3x3.fill")
                    .font(.system(size: 58, weight: .semibold))
                    .foregroundStyle(theme.colors.accent)
                    .symbolRenderingMode(.hierarchical)
                    .scaleEffect(isVisible ? 1 : 0.86)

                Text(viewModel.title)
                    .font(.system(size: 42, weight: .heavy, design: .rounded))
                    .foregroundStyle(theme.colors.textPrimary)
                    .tracking(4)

                Text(viewModel.subtitle)
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundStyle(theme.colors.textSecondary)
            }
            .opacity(isVisible ? 1 : 0)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.55)) {
                isVisible = true
            }
            viewModel.input.viewDidAppear.send()
        }
    }
}
