// SPDX-License-Identifier: BSD-3-Clause

import Foundation
import Testing

@testable import GlifiCore

@Test("Il package .glifi conserva una fonte e riapre la stessa generazione")
func projectPackageRoundTrip() async throws {
    try await withTemporaryProject { packageURL in
        let projectID = ProjectID(
            uuid: try #require(UUID(uuidString: "10000000-0000-0000-0000-000000000001"))
        )
        let sourceID = SourceID(
            uuid: try #require(UUID(uuidString: "20000000-0000-0000-0000-000000000002"))
        )
        let revisionID = SourceRevisionID(
            uuid: try #require(UUID(uuidString: "30000000-0000-0000-0000-000000000003"))
        )
        let imported = try GlifiTextImporter().importText(
            from: Data("Una città affidabile.".utf8),
            format: .plainText,
            sourceRevisionID: revisionID
        )
        let project = try GlifiProjectPackage.create(at: packageURL, projectID: projectID)

        let committed = try await project.importText(imported, sourceID: sourceID)
        #expect(committed.generation == 1)
        #expect(committed.sources.count == 1)
        #expect(committed.sources[0].sourceID == sourceID)

        let reopened = try GlifiProjectPackage.open(at: packageURL)
        #expect(await reopened.snapshot() == committed)
        #expect(try await reopened.sourceData(for: revisionID) == imported.bytes)
    }
}

@Test(
    "Prima del commit point resta autorevole la generazione precedente",
    arguments: [
        GlifiProjectCommitInterruption.staged,
        .objectPromoted,
        .databasePrepared,
        .manifestPrepared,
    ]
)
func interruptionBeforeManifestPreservesPreviousGeneration(
    interruption: GlifiProjectCommitInterruption
) async throws {
    try await withTemporaryProject { packageURL in
        let project = try GlifiProjectPackage.create(at: packageURL)
        let imported = try GlifiTextImporter().importText(
            from: Data("Prima del commit.".utf8),
            format: .plainText
        )

        await #expect(throws: GlifiFailure.self) {
            try await project.importText(
                imported,
                sourceID: SourceID(),
                interruption: interruption
            )
        }
        let reopened = try GlifiProjectPackage.open(at: packageURL)
        #expect(await reopened.snapshot().generation == 0)
        #expect(await reopened.snapshot().sources.isEmpty)

        let retrySnapshot = try await reopened.importText(imported)
        #expect(retrySnapshot.generation == 1)
        #expect(retrySnapshot.sources.count == 1)
    }
}

@Test(
    "Dopo il commit point la nuova generazione resta autorevole",
    arguments: [
        GlifiProjectCommitInterruption.manifestReplaced,
        .databaseCommitted,
    ]
)
func interruptionAfterManifestPreservesNewGeneration(
    interruption: GlifiProjectCommitInterruption
) async throws {
    try await withTemporaryProject { packageURL in
        let project = try GlifiProjectPackage.create(at: packageURL)
        let imported = try GlifiTextImporter().importText(
            from: Data("Dopo il commit.".utf8),
            format: .plainText
        )

        await #expect(throws: GlifiFailure.self) {
            try await project.importText(
                imported,
                sourceID: SourceID(),
                interruption: interruption
            )
        }
        let reopened = try GlifiProjectPackage.open(at: packageURL)
        #expect(await reopened.snapshot().generation == 1)
        #expect(await reopened.snapshot().sources.count == 1)
    }
}

@Test("Un oggetto alterato rende il package corrotto senza modificarlo")
func projectPackageRejectsCorruptedObject() async throws {
    try await withTemporaryProject { packageURL in
        let project = try GlifiProjectPackage.create(at: packageURL)
        let imported = try GlifiTextImporter().importText(
            from: Data("Integrità".utf8),
            format: .plainText
        )
        let snapshot = try await project.importText(imported)
        let objectURL = packageURL.appending(path: try #require(snapshot.sources.first).objectPath)
        try Data("Alterato".utf8).write(to: objectURL)

        do {
            _ = try GlifiProjectPackage.open(at: packageURL)
            Issue.record("Il package corrotto non è stato rifiutato")
        } catch let failure as GlifiFailure {
            #expect(failure.category == .corruption)
            #expect(failure.retainedState == .readOnlyRecovery)
        }
    }
}

private func withTemporaryProject(
    _ body: (URL) async throws -> Void
) async throws {
    let root = FileManager.default.temporaryDirectory.appending(
        path: "GlifiProjectPackageTests-\(UUID().uuidString)",
        directoryHint: .isDirectory
    )
    try FileManager.default.createDirectory(at: root, withIntermediateDirectories: false)
    defer { try? FileManager.default.removeItem(at: root) }
    try await body(root.appending(path: "Test.glifi", directoryHint: .isDirectory))
}
