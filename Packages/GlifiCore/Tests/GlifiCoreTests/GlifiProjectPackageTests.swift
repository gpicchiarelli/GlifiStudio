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

@Test("Artifact e descriptor persistono con DAG e lettura verificati")
func projectPackagePersistsVerifiedAnalysisArtifact() async throws {
    try await withTemporaryProject { packageURL in
        let project = try GlifiProjectPackage.create(at: packageURL)
        let initial = await project.snapshot()
        let descriptor = try projectDescriptor(
            named: "profile",
            corpusDigest: initial.sourceRootDigest
        )
        let payload = ProjectTestArtifactPayload(value: "tre token")

        do {
            _ = try await project.storeArtifact(
                ProjectWrongArtifactPayload(value: "schema errato"),
                descriptor: descriptor
            )
            Issue.record("Il payload con schema diverso dal descriptor non è stato rifiutato")
        } catch let failure as GlifiFailure {
            #expect(failure.code == "project.artifact-schema-mismatch")
            #expect(failure.category == .invalidInput)
        }
        #expect(await project.snapshot() == initial)

        let staleDescriptor = try projectDescriptor(
            named: "stale",
            corpusDigest: "sha256:" + String(repeating: "0", count: 64)
        )
        do {
            _ = try await project.storeArtifact(payload, descriptor: staleDescriptor)
            Issue.record("Il descriptor legato a un altro corpus non è stato rifiutato")
        } catch let failure as GlifiFailure {
            #expect(failure.code == "project.artifact-corpus-mismatch")
            #expect(failure.category == .staleArtifact)
        }
        #expect(await project.snapshot() == initial)

        let committed = try await project.storeArtifact(payload, descriptor: descriptor)
        #expect(committed.generation == 1)
        #expect(committed.artifacts.count == 1)
        let artifact = try #require(committed.artifacts.first)
        let expectedNodeID = try descriptor.nodeID()
        #expect(artifact.node.id == expectedNodeID)
        #expect(artifact.artifactID.digest == artifact.contentDigest)

        let idempotent = try await project.storeArtifact(payload, descriptor: descriptor)
        #expect(idempotent == committed)

        let reopened = try GlifiProjectPackage.open(at: packageURL)
        #expect(await reopened.snapshot() == committed)
        let persistedData = try await reopened.artifactData(for: artifact.artifactID)
        #expect(
            try JSONDecoder().decode(ProjectTestArtifactPayload.self, from: persistedData)
                == payload
        )
        let graph = try await reopened.analysisGraph()
        #expect(graph.nodes.map(\.id) == [artifact.node.id])
    }
}

@Test("La sostituzione invalida i soli discendenti e un nuovo corpus tutti gli Artifact")
func projectPackageInvalidatesPersistedArtifacts() async throws {
    try await withTemporaryProject { packageURL in
        let project = try GlifiProjectPackage.create(at: packageURL)
        let corpusDigest = await project.snapshot().sourceRootDigest
        let rootDescriptor = try projectDescriptor(named: "root", corpusDigest: corpusDigest)
        let firstRoot = try await project.storeArtifact(
            ProjectTestArtifactPayload(value: "prima"),
            descriptor: rootDescriptor
        )
        let root = try #require(firstRoot.artifacts.first)
        let childDescriptor = try projectDescriptor(
            named: "child",
            corpusDigest: corpusDigest,
            dependencies: [
                try GlifiAnalysisDependency(
                    nodeID: root.node.id,
                    artifactDigest: root.contentDigest,
                    outputSchemaIdentifier: root.node.descriptor.outputSchemaIdentifier
                )
            ]
        )
        let withChild = try await project.storeArtifact(
            ProjectTestArtifactPayload(value: "figlio"),
            descriptor: childDescriptor
        )
        #expect(withChild.artifacts.count == 2)

        let replaced = try await project.storeArtifact(
            ProjectTestArtifactPayload(value: "seconda"),
            descriptor: rootDescriptor
        )
        #expect(replaced.artifacts.count == 1)
        #expect(replaced.artifacts.first?.node.id == root.node.id)
        #expect(replaced.artifacts.first?.contentDigest != root.contentDigest)

        let imported = try GlifiTextImporter().importText(
            from: Data("Nuovo corpus".utf8),
            format: .plainText
        )
        let afterImport = try await project.importText(imported)
        #expect(afterImport.artifacts.isEmpty)
        #expect(try await project.analysisGraph().nodes.isEmpty)
    }
}

@Test("Un Artifact alterato rende il package corrotto")
func projectPackageRejectsCorruptedArtifact() async throws {
    try await withTemporaryProject { packageURL in
        let project = try GlifiProjectPackage.create(at: packageURL)
        let descriptor = try projectDescriptor(
            named: "corrupt",
            corpusDigest: await project.snapshot().sourceRootDigest
        )
        let snapshot = try await project.storeArtifact(
            ProjectTestArtifactPayload(value: "integro"),
            descriptor: descriptor
        )
        let artifact = try #require(snapshot.artifacts.first)
        try Data("alterato".utf8).write(
            to: packageURL.appending(path: artifact.objectPath)
        )

        do {
            _ = try GlifiProjectPackage.open(at: packageURL)
            Issue.record("Il package con Artifact corrotto non è stato rifiutato")
        } catch let failure as GlifiFailure {
            #expect(failure.category == .corruption)
            #expect(failure.retainedState == .readOnlyRecovery)
        }
    }
}

@Test(
    "Il commit Artifact mantiene l'autorità prima e dopo il commit point",
    arguments: GlifiProjectCommitInterruption.allCases
)
func artifactCommitInterruptionMaintainsAuthority(
    interruption: GlifiProjectCommitInterruption
) async throws {
    try await withTemporaryProject { packageURL in
        let project = try GlifiProjectPackage.create(at: packageURL)
        let descriptor = try projectDescriptor(
            named: "interrupted",
            corpusDigest: await project.snapshot().sourceRootDigest
        )
        await #expect(throws: GlifiFailure.self) {
            try await project.storeArtifact(
                ProjectTestArtifactPayload(value: "risultato"),
                descriptor: descriptor,
                interruption: interruption
            )
        }

        let reopened = try GlifiProjectPackage.open(at: packageURL)
        let snapshot = await reopened.snapshot()
        let isAfterCommitPoint =
            interruption == .manifestReplaced || interruption == .databaseCommitted
        #expect(snapshot.generation == (isAfterCommitPoint ? 1 : 0))
        #expect(snapshot.artifacts.count == (isAfterCommitPoint ? 1 : 0))
        if !isAfterCommitPoint {
            #expect(
                try await reopened.storeArtifact(
                    ProjectTestArtifactPayload(value: "risultato"),
                    descriptor: descriptor
                ).generation == 1
            )
        }
    }
}

@Test("Il motore persiste analisi e keyness sulla generazione verificata")
func enginePersistsVerifiedProjectAnalysis() async throws {
    try await withTemporaryProject { packageURL in
        let project = try GlifiProjectPackage.create(at: packageURL)
        let first = try GlifiTextImporter().importText(
            from: Data("casa casa mare".utf8),
            format: .plainText,
            sourceRevisionID: SourceRevisionID(
                uuid: try #require(UUID(uuidString: "00000000-0000-0000-0000-000000000001"))
            )
        )
        let second = try GlifiTextImporter().importText(
            from: Data("casa città".utf8),
            format: .plainText,
            sourceRevisionID: SourceRevisionID(
                uuid: try #require(UUID(uuidString: "00000000-0000-0000-0000-000000000002"))
            )
        )
        _ = try await project.importText(first)
        let committed = try await project.importText(second)

        let tokenizer = CountingProjectTokenizer()
        let engine = GlifiEngine(tokenizer: tokenizer)
        let analysisOptions = try GlifiCorpusAnalysisOptions(
            diversityWindowSize: 2,
            ngramSizes: [2],
            maximumDocumentCount: 2,
            maximumSourceByteCount: 1_024,
            maximumVocabularySize: 10,
            maximumDistinctNGramCount: 10,
            maximumNonZeroCellCount: 10
        )
        let result = try await engine.analyzeCorpus(
            in: project,
            options: analysisOptions
        )

        #expect(result.projectID == committed.projectID)
        #expect(result.sourceGeneration == 2)
        #expect(result.generation == 3)
        #expect(result.analysisNodeID.canonicalValue.hasPrefix("analysis-node:sha256:"))
        #expect(result.artifactID.canonicalValue.hasPrefix("artifact:sha256:"))
        #expect(result.analysis.documentCount == 2)
        #expect(result.analysis.lexicalTokenCount == 5)
        #expect(tokenizer.invocationCount == 2)
        let profileData = try await project.artifactData(for: result.artifactID)
        #expect(
            try JSONDecoder().decode(
                GlifiCorpusAnalysisArtifactPayload.self,
                from: profileData
            ).analysis == result.analysis
        )
        var futurePayload = try #require(
            JSONSerialization.jsonObject(with: profileData) as? [String: Any]
        )
        futurePayload["schemaIdentifier"] = "studio.glifi.artifact.corpus-profile.v2"
        let futureData = try JSONSerialization.data(withJSONObject: futurePayload)
        #expect(throws: DecodingError.self) {
            _ = try JSONDecoder().decode(
                GlifiCorpusAnalysisArtifactPayload.self,
                from: futureData
            )
        }
        let reusedProfile = try await engine.analyzeCorpus(
            in: project,
            options: analysisOptions
        )
        #expect(reusedProfile.sourceGeneration == 3)
        #expect(reusedProfile.generation == 3)
        #expect(reusedProfile.artifactID == result.artifactID)
        #expect(tokenizer.invocationCount == 2)

        let comparison = try await engine.compareKeyness(
            in: project,
            targetSourceRevisionIDs: [first.sourceRevisionID],
            referenceSourceRevisionIDs: [second.sourceRevisionID]
        )
        #expect(comparison.projectID == committed.projectID)
        #expect(comparison.sourceGeneration == 3)
        #expect(comparison.generation == 6)
        #expect(comparison.comparison.targetTokenCount == 3)
        #expect(comparison.comparison.referenceTokenCount == 2)
        #expect(comparison.comparison.terms.count == 3)
        let keynessData = try await project.artifactData(for: comparison.artifactID)
        #expect(
            try JSONDecoder().decode(GlifiKeynessArtifactPayload.self, from: keynessData)
                .comparison == comparison.comparison
        )
        let finalSnapshot = await project.snapshot()
        #expect(finalSnapshot.generation == 6)
        #expect(finalSnapshot.sources == committed.sources)
        #expect(finalSnapshot.artifacts.count == 4)
        #expect(try await project.analysisGraph().nodes.count == 4)
        #expect(tokenizer.invocationCount == 4)

        let reusedComparison = try await engine.compareKeyness(
            in: project,
            targetSourceRevisionIDs: [first.sourceRevisionID],
            referenceSourceRevisionIDs: [second.sourceRevisionID]
        )
        #expect(reusedComparison.sourceGeneration == 6)
        #expect(reusedComparison.generation == 6)
        #expect(reusedComparison.artifactID == comparison.artifactID)
        #expect(await project.snapshot().artifacts.count == 4)
        #expect(tokenizer.invocationCount == 4)

        let reopened = try GlifiProjectPackage.open(at: packageURL)
        let reopenedTokenizer = CountingProjectTokenizer()
        let reopenedEngine = GlifiEngine(tokenizer: reopenedTokenizer)
        let reopenedProfile = try await reopenedEngine.analyzeCorpus(
            in: reopened,
            options: analysisOptions
        )
        let reopenedComparison = try await reopenedEngine.compareKeyness(
            in: reopened,
            targetSourceRevisionIDs: [first.sourceRevisionID],
            referenceSourceRevisionIDs: [second.sourceRevisionID]
        )
        #expect(reopenedProfile.artifactID == result.artifactID)
        #expect(reopenedComparison.artifactID == comparison.artifactID)
        #expect(reopenedTokenizer.invocationCount == 0)
        #expect(await reopened.snapshot().generation == 6)

        let incompatibleOptions = try GlifiCorpusAnalysisOptions(
            diversityWindowSize: 3,
            ngramSizes: [2],
            maximumDocumentCount: 2,
            maximumSourceByteCount: 1_024,
            maximumVocabularySize: 10,
            maximumDistinctNGramCount: 10,
            maximumNonZeroCellCount: 10
        )
        let reopenedSnapshot = await reopened.snapshot()
        let incompatibleDescriptor = try GlifiAnalysisArtifactDescriptorFactory.corpusProfile(
            projectID: reopenedSnapshot.projectID,
            sourceRootDigest: reopenedSnapshot.sourceRootDigest,
            sourceRevisionIDs: reopenedSnapshot.sources.map(\.sourceRevisionID),
            tokenizationContractIdentifier: reopenedTokenizer.tokenizationContractIdentifier,
            options: incompatibleOptions
        )
        _ = try await reopened.storeArtifact(
            GlifiCorpusAnalysisArtifactPayload(
                analysisNodeID: result.analysisNodeID,
                analysis: result.analysis
            ),
            descriptor: incompatibleDescriptor
        )
        do {
            _ = try await reopenedEngine.analyzeCorpus(
                in: reopened,
                options: incompatibleOptions
            )
            Issue.record("Era atteso un payload legato a un altro nodo")
        } catch let failure as GlifiFailure {
            #expect(failure.code == "analysis.payload-node-mismatch")
            #expect(failure.category == .invariantViolation)
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

private func projectDescriptor(
    named name: String,
    corpusDigest: String,
    dependencies: [GlifiAnalysisDependency] = []
) throws -> GlifiAnalysisDescriptor {
    try GlifiAnalysisDescriptor(
        artifactTypeIdentifier: "artifact.\(name)",
        algorithmIdentifier: "algorithm.\(name)",
        algorithmVersion: "1",
        corpusIdentifier: "project-source-root-v1",
        corpusVersionDigest: corpusDigest,
        selectionIdentifier: "selection.all.v1",
        analyticalUnitIdentifier: "source-revision.v1",
        preprocessingIdentifiers: ["extract-v1", "it-token-v1"],
        linguisticProfileIdentifiers: ["it-token-v1"],
        representationIdentifier: "representation.test.v1",
        resolvedParameters: ["resolved": .boolean(true)],
        seedPolicyIdentifier: "none-v1",
        backendIdentifier: "swift-reference-v1",
        numericPolicyIdentifier: "IEEE-754-binary64-ordered-reduction-v1",
        determinismClass: .d1,
        outputSchemaIdentifier: ProjectTestArtifactPayload.outputSchemaIdentifier,
        softwareIdentifier: "GlifiCore-0.1",
        dependencies: dependencies
    )
}

private struct ProjectTestArtifactPayload: GlifiAnalysisArtifactPayload, Equatable {
    static let outputSchemaIdentifier = "studio.glifi.test-artifact.v1"

    let value: String
}

private struct ProjectWrongArtifactPayload: GlifiAnalysisArtifactPayload {
    static let outputSchemaIdentifier = "studio.glifi.wrong-artifact.v1"

    let value: String
}

private final class CountingProjectTokenizer: GlifiTokenizing, @unchecked Sendable {
    private let lock = NSLock()
    private var count = 0

    var tokenizationContractIdentifier: String { GlifiItalianTokenizer.contractIdentifier }

    var invocationCount: Int {
        lock.withLock { count }
    }

    func tokenize(_ text: String) throws -> GlifiTokenization {
        lock.withLock { count += 1 }
        return try GlifiItalianTokenizer().tokenize(text)
    }
}
