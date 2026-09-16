// SPDX-License-Identifier: BSD-3-Clause

import SwiftUI

@main
struct GlifiStudioMacApp: App {
    var body: some Scene {
        DocumentGroup(newDocument: GlifiStudioDocument.init) { file in
            StudioHomeView(
                documentURL: file.fileURL,
                needsPackageInitialization: file.document.needsPackageInitialization
            )
        }
        .defaultSize(width: 1100, height: 740)
    }
}
