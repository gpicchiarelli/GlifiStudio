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

@Test("GlifiKit profila Markdown attraverso la rappresentazione estratta")
func serviceProfilesMarkdown() async throws {
    let fileURL = FileManager.default.temporaryDirectory
        .appending(path: "glifi-kit-profile-\(UUID().uuidString).md")
    try Data("# Titolo\nUna **fonte** affidabile.".utf8).write(to: fileURL, options: .atomic)
    defer { try? FileManager.default.removeItem(at: fileURL) }

    let profile = try await GlifiStudioService().profileText(at: fileURL, format: .markdown)

    #expect(profile.lexicalTokenCount == 4)
    #expect(profile.typeCount == 4)
    #expect(profile.topTerms.contains(GlifiStudioTermFrequency(term: "fonte", count: 1)))
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

    do {
        _ = try GlifiStudioCorpusAnalysisOptions(
            diversityWindowSize: 0,
            ngramSizes: [6],
            maximumDocumentCount: 1,
            maximumSourceByteCount: 1,
            maximumVocabularySize: 1,
            maximumDistinctNGramCount: 1,
            maximumNonZeroCellCount: 1
        )
        Issue.record("Erano attese opzioni analitiche non valide")
    } catch let failure as GlifiStudioFailure {
        #expect(failure.code == "analysis.invalid-options")
        #expect(failure.category == "invalidInput")
        #expect(failure.operation == "analyze")
    } catch {
        Issue.record("Tipo di errore inatteso")
    }
}

@Test("GlifiKit crea, importa, riapre e chiude una sessione di progetto")
func serviceProjectSessionRoundTrip() async throws {
    let root = FileManager.default.temporaryDirectory.appending(
        path: "GlifiKitProjectTests-\(UUID().uuidString)",
        directoryHint: .isDirectory
    )
    try FileManager.default.createDirectory(at: root, withIntermediateDirectories: false)
    defer { try? FileManager.default.removeItem(at: root) }
    let projectURL = root.appending(path: "Progetto.glifi", directoryHint: .isDirectory)
    let sourceURL = root.appending(path: "fonte.txt")
    try Data("Una fonte italiana affidabile.".utf8).write(to: sourceURL)

    let service = GlifiStudioService()
    let session = try await service.createProject(at: projectURL)
    #expect(try await session.snapshot().generation == 0)

    let result = try await session.importText(at: sourceURL, format: .plainText)
    #expect(result.project.generation == 1)
    #expect(result.project.sourceCount == 1)
    #expect(result.project.artifactCount == 0)
    #expect(result.profile.lexicalTokenCount == 4)

    let query = try await session.query("normalized:fonte")
    #expect(query.generation == 1)
    #expect(query.matchedSourceCount == 1)
    #expect(query.matches.count == 1)
    #expect(query.matches[0].match == "fonte")
    #expect(query.matches[0].coordinateSpace == "extractedUTF8")
    #expect(query.matches[0].sourceRanges.count == 1)
    #expect(query.matches[0].sourceRanges[0].start == 4)
    #expect(query.matches[0].sourceRanges[0].end == 9)

    let analysis = try await session.analyzeCorpus()
    #expect(analysis.projectID == result.project.projectID)
    #expect(analysis.sourceGeneration == 1)
    #expect(analysis.generation == 2)
    #expect(analysis.artifactID.hasPrefix("artifact:sha256:"))
    #expect(analysis.analysisNodeID.hasPrefix("analysis-node:sha256:"))
    #expect(analysis.analysisIdentifier == "corpus-profile-it-v1")
    #expect(analysis.corpusDigest.hasPrefix("sha256:"))
    #expect(analysis.documentCount == 1)
    #expect(analysis.lexicalTokenCount == 4)
    #expect(analysis.terms.first?.term == "affidabile")
    #expect(analysis.matrix.cells.count == 4)
    let analyzedSnapshot = try await session.snapshot()
    #expect(analyzedSnapshot.generation == 2)
    #expect(analyzedSnapshot.artifactCount == 1)
    await session.close()

    await #expect(throws: GlifiStudioFailure.self) {
        try await session.snapshot()
    }

    let reopened = try await service.openProject(at: projectURL)
    #expect(try await reopened.snapshot() == analyzedSnapshot)
}

@Test("GlifiKit confronta due gruppi espliciti senza esporre dettagli del package")
func serviceComparesExplicitSourceGroups() async throws {
    let root = FileManager.default.temporaryDirectory.appending(
        path: "GlifiKitKeynessTests-\(UUID().uuidString)",
        directoryHint: .isDirectory
    )
    try FileManager.default.createDirectory(at: root, withIntermediateDirectories: false)
    defer { try? FileManager.default.removeItem(at: root) }
    let projectURL = root.appending(path: "Confronto.glifi", directoryHint: .isDirectory)
    let targetURL = root.appending(path: "target.txt")
    let referenceURL = root.appending(path: "reference.txt")
    try Data("casa casa mare".utf8).write(to: targetURL)
    try Data("casa città città".utf8).write(to: referenceURL)

    let session = try await GlifiStudioService().createProject(at: projectURL)
    let first = try await session.importText(at: targetURL, format: .plainText)
    let second = try await session.importText(at: referenceURL, format: .plainText)
    let targetID = try #require(first.project.sources.first?.sourceRevisionID)
    let referenceID = try #require(
        second.project.sources.first(where: { $0.sourceRevisionID != targetID })?
            .sourceRevisionID
    )

    let result = try await session.compareKeyness(
        targetSourceRevisionIDs: [targetID],
        referenceSourceRevisionIDs: [referenceID]
    )

    #expect(result.projectID == second.project.projectID)
    #expect(result.sourceGeneration == 2)
    #expect(result.generation == 5)
    #expect(result.artifactID.hasPrefix("artifact:sha256:"))
    #expect(result.analysisNodeID.hasPrefix("analysis-node:sha256:"))
    #expect(result.comparisonIdentifier == "keyness-gtest-ha-bh-v1")
    #expect(result.comparisonDigest.hasPrefix("sha256:"))
    #expect(result.targetTokenCount == 3)
    #expect(result.referenceTokenCount == 3)
    #expect(result.terms.map(\.term) == ["città", "mare", "casa"])
    #expect(result.terms.allSatisfy { 0...1 ~= $0.qValue })
    #expect(result.terms.allSatisfy { $0.hasLowExpectedCount })

    do {
        _ = try await session.compareKeyness(
            targetSourceRevisionIDs: ["source-revision:00000000-0000-0000-0000-000000000099"],
            referenceSourceRevisionIDs: [referenceID]
        )
        Issue.record("Era attesa una revisione assente")
    } catch let failure as GlifiStudioFailure {
        #expect(failure.code == "keyness.source-not-found")
        #expect(failure.retainedState == "lastCommittedGeneration")
    }

    do {
        _ = try await session.compareKeyness(
            targetSourceRevisionIDs: ["non-valido"],
            referenceSourceRevisionIDs: [referenceID]
        )
        Issue.record("Era atteso un identificatore non valido")
    } catch let failure as GlifiStudioFailure {
        #expect(failure.code == "keyness.invalid-source-identifier")
        #expect(failure.operation == "analyze")
    }
    let finalSnapshot = try await session.snapshot()
    #expect(finalSnapshot.generation == 5)
    #expect(finalSnapshot.sourceCount == second.project.sourceCount)
    #expect(finalSnapshot.artifactCount == 3)
}
