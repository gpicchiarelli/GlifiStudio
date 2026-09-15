// SPDX-License-Identifier: BSD-3-Clause

import GlifiKit
import Observation

enum EnginePresentationState: Sendable {
    case checking
    case ready
}

@MainActor
@Observable
final class StudioHomeModel {
    private(set) var engineState: EnginePresentationState = .checking

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
}
