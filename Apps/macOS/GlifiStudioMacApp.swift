// SPDX-License-Identifier: BSD-3-Clause

import SwiftUI

@main
struct GlifiStudioMacApp: App {
    var body: some Scene {
        WindowGroup {
            StudioHomeView()
        }
        .defaultSize(width: 1000, height: 700)
    }
}
