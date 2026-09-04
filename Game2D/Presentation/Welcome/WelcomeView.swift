import Combine
import SwiftUI

struct WelcomeView: View {
    @ObservedObject var viewModel: WelcomeViewModel
    @EnvironmentObject private var theme: ThemeController

    var body: some View {
        ZStack {
            theme.colors.background
                .ignoresSafeArea()

            VStack(spacing: 0) {
                TabView(selection: Binding(
                    get: { viewModel.pageIndex },
                    set: { viewModel.input.pageChanged.send($0) }
                )) {
                    ForEach(viewModel.pages) { page in
                        welcomePage(page)
                            .tag(page.id)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

                VStack(spacing: 18) {
                    pageIndicator

                    Button {
                        if viewModel.isLastPage {
                            viewModel.input.getStartedTapped.send()
                        } else {
                            viewModel.input.nextTapped.send()
                        }
                    } label: {
                        Text(viewModel.isLastPage ? "Get Started" : "Next")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(theme.colors.accent, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                            .foregroundStyle(theme.colors.background)
                    }
                }
                .padding(.horizontal, 28)
                .padding(.bottom, 40)
            }
        }
    }

    private func welcomePage(_ page: WelcomePage) -> some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: page.symbolName)
                .font(.system(size: 54, weight: .semibold))
                .foregroundStyle(theme.colors.accent)
                .symbolRenderingMode(.hierarchical)

            Text(page.title)
                .font(.system(size: 34, weight: .heavy, design: .rounded))
                .foregroundStyle(theme.colors.textPrimary)

            Text(page.message)
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundStyle(theme.colors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 28)
            Spacer()
        }
    }

    private var pageIndicator: some View {
        HStack(spacing: 8) {
            ForEach(viewModel.pages) { page in
                Capsule()
                    .fill(page.id == viewModel.pageIndex ? theme.colors.accent : theme.colors.textSecondary.opacity(0.35))
                    .frame(width: page.id == viewModel.pageIndex ? 22 : 8, height: 8)
                    .animation(.easeInOut(duration: 0.2), value: viewModel.pageIndex)
            }
        }
    }
}
