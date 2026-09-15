// SPDX-License-Identifier: BSD-3-Clause

import Foundation
import Testing

@testable import GlifiKit

@Test("GlifiKit espone lo stato senza rivelare il tipo del motore")
func serviceExposesEngineStatus() async {
    let service = GlifiStudioService()

    #expect(await service.status() == .ready)
}

@Test("GlifiKit profila un file senza esporre i tipi interni del motore")
func serviceProfilesAFile() async throws {
    let fileURL = FileManager.default.temporaryDirectory
        .appending(path: "glifi-kit-profile-\(UUID().uuidString).txt")
    try Data("Uno due due.".utf8).write(to: fileURL, options: .atomic)
    defer { try? FileManager.default.removeItem(at: fileURL) }

    let profile = try await GlifiStudioService().profileText(at: fileURL, format: .plainText)

    #expect(profile.lexicalTokenCount == 3)
    #expect(profile.typeCount == 2)
    #expect(profile.topTerms.first == GlifiStudioTermFrequency(term: "due", count: 2))
}

@Test("GlifiKit espone failure tipizzate e localizzabili")
func serviceMapsFailures() async {
    let missingURL = FileManager.default.temporaryDirectory
        .appending(path: "glifi-missing-\(UUID().uuidString).txt")

    do {
        _ = try await GlifiStudioService().profileText(at: missingURL, format: .plainText)
        Issue.record("Era attesa una failure")
    } catch let failure as GlifiStudioFailure {
        #expect(failure.code == "file.unreadable")
        #expect(failure.category == "transientIO")
        #expect(failure.messageKey == "failure.file.unreadable")
    } catch {
        Issue.record("Tipo di errore inatteso")
    }
}
