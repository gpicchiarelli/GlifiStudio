// SPDX-License-Identifier: BSD-3-Clause

import Testing

@testable import GlifiKit

@Test("GlifiKit espone lo stato senza rivelare il tipo del motore")
func serviceExposesEngineStatus() async {
    let service = GlifiStudioService()

    #expect(await service.status() == .ready)
}
