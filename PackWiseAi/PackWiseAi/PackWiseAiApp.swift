//
//  PackWiseAiApp.swift
//  PackWiseAi
//
//  Created by Yusuf Efe SOLAK on 12.05.2026.
//

import SwiftUI

@main
struct PackWiseAiApp: App {
    @AppStorage("packwise_is_light_theme") private var isLightTheme = false

    var body: some Scene {
        WindowGroup {
            SplashScreenView()
                .preferredColorScheme(isLightTheme ? .light : .dark)
        }
    }
}
