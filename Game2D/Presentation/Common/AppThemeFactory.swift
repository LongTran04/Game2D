import SwiftUI

protocol AppThemeFactory {
    func makeColors() -> ThemeColors
    func makeColorScheme() -> ColorScheme
}

enum AppThemeFactoryProvider {
    static func makeFactory(for appearance: GameSettings.Appearance) -> AppThemeFactory {
        switch appearance {
        case .light:
            LightThemeFactory()
        case .dark:
            DarkThemeFactory()
        }
    }
}

struct LightThemeFactory: AppThemeFactory {
    func makeColors() -> ThemeColors {
        ThemeColors(
            background: Color(hex: 0xF5F5F5),
            surface: Color(hex: 0xFFFFFF),
            surfaceElevated: Color(hex: 0xEBEBEB),
            primary: Color(hex: 0x007AFF),
            secondary: Color(hex: 0x5856D6),
            accent: Color(hex: 0x00A67D),
            textPrimary: Color(hex: 0x1C1C1E),
            textSecondary: Color(hex: 0x636366),
            border: Color(hex: 0xD1D1D6),
            success: Color(hex: 0x34C759),
            warning: Color(hex: 0xFF9500),
            error: Color(hex: 0xFF3B30),
            info: Color(hex: 0x007AFF)
        )
    }

    func makeColorScheme() -> ColorScheme {
        .light
    }
}

struct DarkThemeFactory: AppThemeFactory {
    func makeColors() -> ThemeColors {
        ThemeColors(
            background: Color(hex: 0x0D0D0D),
            surface: Color(hex: 0x161616),
            surfaceElevated: Color(hex: 0x202020),
            primary: Color(hex: 0x0A84FF),
            secondary: Color(hex: 0x5E5CE6),
            accent: Color(hex: 0x30D158),
            textPrimary: Color(hex: 0xF5F5F7),
            textSecondary: Color(hex: 0x98989D),
            border: Color(hex: 0x38383A),
            success: Color(hex: 0x30D158),
            warning: Color(hex: 0xFF9F0A),
            error: Color(hex: 0xFF453A),
            info: Color(hex: 0x64D2FF)
        )
    }

    func makeColorScheme() -> ColorScheme {
        .dark
    }
}
