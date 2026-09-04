//
//  Game2DApp.swift
//  Game2D
//
//  Created by Long Tran on 4/9/26.
//

import SwiftUI

@main
struct Game2DApp: App {
    @StateObject private var themeController: ThemeController

    init() {
        _themeController = StateObject(wrappedValue: DependencyContainer.shared.makeThemeController())
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(themeController)
        }
    }
}
