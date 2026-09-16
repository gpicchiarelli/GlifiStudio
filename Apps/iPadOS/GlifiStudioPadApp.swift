// SPDX-License-Identifier: BSD-3-Clause

import SwiftUI

@main
struct GlifiStudioPadApp: App {
    var body: some Scene {
        DocumentGroup(newDocument: GlifiStudioDocument.init) { file in
            StudioHomeView(
                documentURL: file.fileURL,
                needsPackageInitialization: file.document.needsPackageInitialization
            )
        }
    }
}
