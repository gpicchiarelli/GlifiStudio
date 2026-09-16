// SPDX-License-Identifier: BSD-3-Clause

import Foundation
import SwiftUI
import UniformTypeIdentifiers

/// Lightweight document shell around an on-disk `.glifi` package owned by GlifiKit.
struct GlifiStudioDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.glifiProject] }
    static var writableContentTypes: [UTType] { [.glifiProject] }

    /// Whether this document still needs `createProject` before opening.
    var needsPackageInitialization: Bool

    init() {
        needsPackageInitialization = true
    }

    init(configuration: ReadConfiguration) throws {
        guard configuration.file.isDirectory else {
            throw CocoaError(.fileReadCorruptFile)
        }
        needsPackageInitialization = false
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        if let existing = configuration.existingFile, existing.isDirectory {
            return existing
        }
        let wrapper = FileWrapper(directoryWithFileWrappers: [:])
        wrapper.preferredFilename = "Progetto.glifi"
        return wrapper
    }
}
