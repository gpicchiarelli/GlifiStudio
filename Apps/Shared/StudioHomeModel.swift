// SPDX-License-Identifier: BSD-3-Clause

import Foundation
import GlifiKit
import Observation

enum EnginePresentationState: Sendable {
    case checking
    case ready
}

enum TextProfilePresentationState: Sendable {
    case empty
    case loading
    case ready(GlifiStudioTextProfile)
    case failed(messageKey: String)
}

@MainActor
@Observable
final class StudioHomeModel {
    private(set) var engineState: EnginePresentationState = .checking
    private(set) var profileState: TextProfilePresentationState = .empty
    private(set) var importedFileName: String?

    private let service: GlifiStudioService

    init(service: GlifiStudioService = GlifiStudioService()) {
        self.service = service
    }

    func prepare() async {
        let status = await service.status()

        guard !Task.isCancelled else {
            return
        }

        switch status {
        case .ready:
            engineState = .ready
        }
    }

    func profileFile(at url: URL) async {
        profileState = .loading
        importedFileName = url.lastPathComponent
        let accessGranted = url.startAccessingSecurityScopedResource()
        defer {
            if accessGranted {
                url.stopAccessingSecurityScopedResource()
            }
        }

        do {
            let format: GlifiStudioTextFormat =
                ["md", "markdown"].contains(url.pathExtension.lowercased())
                ? .markdown : .plainText
            let profile = try await service.profileText(at: url, format: format)
            guard !Task.isCancelled else {
                return
            }
            profileState = .ready(profile)
        } catch let failure as GlifiStudioFailure {
            guard !Task.isCancelled else {
                return
            }
            profileState = .failed(messageKey: failure.messageKey)
        } catch {
            guard !Task.isCancelled else {
                return
            }
            profileState = .failed(messageKey: "failure.internal.unexpected")
        }
    }
}
