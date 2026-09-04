import SwiftUI

struct ThemeColors: Equatable {
    let background: Color
    let surface: Color
    let surfaceElevated: Color
    let primary: Color
    let secondary: Color
    let accent: Color
    let textPrimary: Color
    let textSecondary: Color
    let border: Color
    let success: Color
    let warning: Color
    let error: Color
    let info: Color
}

extension Color {
    init(hex: UInt32) {
        self.init(
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255
        )
    }
}
