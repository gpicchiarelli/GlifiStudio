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
    #expect(analysis.generation == 1)
    #expect(analysis.analysisIdentifier == "corpus-profile-it-v1")
    #expect(analysis.corpusDigest.hasPrefix("sha256:"))
    #expect(analysis.documentCount == 1)
    #expect(analysis.lexicalTokenCount == 4)
    #expect(analysis.terms.first?.term == "affidabile")
    #expect(analysis.matrix.cells.count == 4)
    await session.close()

    await #expect(throws: GlifiStudioFailure.self) {
        try await session.snapshot()
    }

    let reopened = try await service.openProject(at: projectURL)
    #expect(try await reopened.snapshot() == result.project)
}
