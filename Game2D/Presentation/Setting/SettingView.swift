import Combine
import SwiftUI

struct SettingView: View {
    @StateObject private var viewModel: SettingViewModel
    @EnvironmentObject private var theme: ThemeController

    init(viewModel: SettingViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        ZStack {
            theme.colors.background
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    header

                    sectionCard(title: "Theme") {
                        labeledRow("Appearance", systemImage: "circle.lefthalf.filled") {
                            Picker("Appearance", selection: Binding(
                                get: { viewModel.appearance },
                                set: { viewModel.input.appearanceChanged.send($0) }
                            )) {
                                ForEach(GameSettings.Appearance.allCases) { appearance in
                                    Text(appearance.displayName).tag(appearance)
                                }
                            }
                            .pickerStyle(.segmented)
                        }
                    }

                    sectionCard(title: "Sound") {
                        toggleRow(
                            title: "Sound Effects",
                            systemImage: "speaker.wave.2.fill",
                            isOn: Binding(
                                get: { viewModel.soundEnabled },
                                set: { viewModel.input.soundChanged.send($0) }
                            )
                        )
                        divider
                        toggleRow(
                            title: "Music",
                            systemImage: "music.note",
                            isOn: Binding(
                                get: { viewModel.musicEnabled },
                                set: { viewModel.input.musicChanged.send($0) }
                            )
                        )
                    }

                    sectionCard(title: "Feedback") {
                        toggleRow(
                            title: "Haptics",
                            systemImage: "iphone.radiowaves.left.and.right",
                            isOn: Binding(
                                get: { viewModel.hapticsEnabled },
                                set: { viewModel.input.hapticsChanged.send($0) }
                            )
                        )
                    }

                    if viewModel.showsSavedHint {
                        Text("Saved")
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundStyle(theme.colors.accent)
                            .frame(maxWidth: .infinity)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 32)
            }
        }
        .navigationTitle("Settings All")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(theme.colors.background, for: .navigationBar)
        .toolbarColorScheme(theme.preferredColorScheme, for: .navigationBar)
        .onAppear {
            viewModel.input.viewDidAppear.send()
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Global settings")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(theme.colors.textPrimary)
            Text("Theme and sound apply to every Swift and Unity mini-game.")
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(theme.colors.textSecondary)
        }
        .padding(.bottom, 4)
    }

    private func sectionCard<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(title.uppercased())
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundStyle(theme.colors.textSecondary)
                .tracking(1)

            VStack(alignment: .leading, spacing: 0) {
                content()
            }
            .padding(16)
            .background(theme.colors.surface, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
    }

    private func labeledRow<Content: View>(_ title: String, systemImage: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(title, systemImage: systemImage)
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundStyle(theme.colors.textPrimary)
            content()
        }
    }

    private func toggleRow(title: String, systemImage: String, isOn: Binding<Bool>) -> some View {
        Toggle(isOn: isOn) {
            Label(title, systemImage: systemImage)
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundStyle(theme.colors.textPrimary)
        }
        .tint(theme.colors.accent)
        .padding(.vertical, 4)
    }

    private var divider: some View {
        Rectangle()
            .fill(theme.colors.border)
            .frame(height: 1)
            .padding(.vertical, 8)
    }
}
