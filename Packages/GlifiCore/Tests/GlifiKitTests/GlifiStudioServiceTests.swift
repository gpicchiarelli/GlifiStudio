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

@Test("GlifiKit persiste un piano spiegabile da una richiesta JSON minimale")
func servicePlansAnalysisFromStableIntent() async throws {
    let root = FileManager.default.temporaryDirectory.appending(
        path: "GlifiKitPlannerTests-\(UUID().uuidString)",
        directoryHint: .isDirectory
    )
    try FileManager.default.createDirectory(at: root, withIntermediateDirectories: false)
    defer { try? FileManager.default.removeItem(at: root) }
    let projectURL = root.appending(path: "Piano.glifi", directoryHint: .isDirectory)
    let targetURL = root.appending(path: "target.txt")
    let referenceURL = root.appending(path: "reference.md")
    try Data("casa mare".utf8).write(to: targetURL)
    try Data("# Fonte\ncasa città".utf8).write(to: referenceURL)

    let service = GlifiStudioService()
    let session = try await service.createProject(at: projectURL)
    let first = try await session.importText(at: targetURL, format: .plainText)
    let second = try await session.importText(at: referenceURL, format: .markdown)
    let targetID = try #require(first.project.sources.first?.sourceRevisionID)
    let referenceID = try #require(
        second.project.sources.first(where: { $0.sourceRevisionID != targetID })?
            .sourceRevisionID
    )
    let minimalJSON = Data(
        """
        {"intent":"compare.objects","targetSourceRevisionIDs":["\(targetID)"],"referenceSourceRevisionIDs":["\(referenceID)"]}
        """.utf8
    )
    let request = try JSONDecoder().decode(
        GlifiStudioAnalysisPlanRequest.self,
        from: minimalJSON
    )
    let result = try await session.planAnalysis(request)

    #expect(result.sourceGeneration == 2)
    #expect(result.generation == 3)
    #expect(result.artifactID.hasPrefix("artifact:sha256:"))
    #expect(result.analysisNodeID.hasPrefix("analysis-node:sha256:"))
    #expect(result.plan.intent == "compare.objects")
    #expect(result.plan.status == "readyWithCaveats")
    #expect(result.plan.collectionProfile.configuredLanguageCode == "it")
    #expect(result.plan.steps.map(\.role) == ["target", "reference", "comparison"])
    #expect(result.plan.steps.last?.dependencyStepIdentifiers.count == 2)
    #expect(result.plan.decisions.map(\.isIncluded) == [true, true])
    #expect(result.plan.decisions.last?.applicability == "conditional")

    let repeated = try await session.planAnalysis(request)
    #expect(repeated.generation == 3)
    #expect(repeated.artifactID == result.artifactID)
    #expect(try await session.snapshot().artifactCount == 1)
    do {
        _ = try await session.planAnalysis(
            GlifiStudioAnalysisPlanRequest(intent: "intent.non-supportato")
        )
        Issue.record("Era attesa un'intenzione non valida")
    } catch let failure as GlifiStudioFailure {
        #expect(failure.code == "planner.invalid-intent")
        #expect(failure.operation == "plan")
        #expect(failure.retainedState == "lastCommittedGeneration")
    }
    await session.close()

    let reopened = try await service.openProject(at: projectURL)
    let reopenedResult = try await reopened.planAnalysis(request)
    #expect(reopenedResult.artifactID == result.artifactID)
    #expect(reopenedResult.generation == 3)
}

@Test("GlifiKit esegue il piano con uno stream bounded e un solo terminale")
func serviceExecutesAnalysisPlanWithProgress() async throws {
    let root = FileManager.default.temporaryDirectory.appending(
        path: "GlifiKitExecutionTests-\(UUID().uuidString)",
        directoryHint: .isDirectory
    )
    try FileManager.default.createDirectory(at: root, withIntermediateDirectories: false)
    defer { try? FileManager.default.removeItem(at: root) }
    let projectURL = root.appending(path: "Esecuzione.glifi", directoryHint: .isDirectory)
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
    let request = GlifiStudioAnalysisPlanRequest(
        intent: "compare.objects",
        targetSourceRevisionIDs: [targetID],
        referenceSourceRevisionIDs: [referenceID]
    )
    let execution = try await session.executeAnalysisPlan(request)
    do {
        _ = try await session.executeAnalysisPlan(request)
        Issue.record("Era atteso il limite di una esecuzione attiva")
    } catch let failure as GlifiStudioFailure {
        #expect(failure.code == "runtime.operation-limit-exceeded")
        #expect(failure.category == "insufficientResources")
        #expect(failure.operation == "executePlan")
        #expect(failure.arguments["maximumActiveOperationCount"] == "1")
    }
    var progress: [GlifiStudioOperationProgress] = []
    var completions: [GlifiStudioAnalysisExecutionResult] = []
    for try await event in execution.events {
        switch event {
        case let .progress(value):
            progress.append(value)
        case let .completed(value):
            completions.append(value)
        }
    }

    let result = try #require(completions.only)
    #expect(result.operationID == execution.operationID)
    #expect(result.sourceGeneration == 2)
    #expect(result.generation == 7)
    #expect(result.terminalState == "completedWithCaveats")
    #expect(result.operatingProfile == "balanced" || result.operatingProfile == "constrained")
    #expect(result.completedWorkUnits == result.estimatedWorkUnits)
    #expect(result.artifacts.map(\.role) == ["target", "reference", "comparison"])
    #expect(result.interpretationArtifactID.hasPrefix("artifact:sha256:"))
    #expect(result.interpretationAnalysisNodeID.hasPrefix("analysis-node:sha256:"))
    #expect(result.interpretation.planArtifactID == result.planArtifactID)
    #expect(result.interpretation.sourceArtifactIDs.count == 3)
    #expect(result.interpretation.findings.isEmpty)
    #expect(result.interpretation.insufficientEvidence != nil)
    #expect(progress.map(\.revision) == Array(0...7))
    #expect(progress.allSatisfy { $0.operationID == execution.operationID })
    #expect(progress.last?.phase == "finalizing")
    #expect(progress.last?.completed == 1)
    #expect(progress.last?.total == 1)
    #expect(try await session.snapshot().artifactCount == 5)

    execution.cancel()
    await session.close()
    await #expect(throws: GlifiStudioFailure.self) {
        _ = try await session.executeAnalysisPlan(request)
    }
}

@Test("GlifiKit espone l'interpretazione descrittiva con valori tagged validati")
func servicePresentsGroundedCorpusInterpretation() async throws {
    let root = FileManager.default.temporaryDirectory.appending(
        path: "GlifiKitInterpretationTests-\(UUID().uuidString)",
        directoryHint: .isDirectory
    )
    try FileManager.default.createDirectory(at: root, withIntermediateDirectories: false)
    defer { try? FileManager.default.removeItem(at: root) }
    let projectURL = root.appending(path: "Interpretazione.glifi", directoryHint: .isDirectory)
    let sourceURL = root.appending(path: "fonte.txt")
    let sourceData = Data("uno due due".utf8)
    try sourceData.write(to: sourceURL)

    let session = try await GlifiStudioService().createProject(at: projectURL)
    _ = try await session.importText(at: sourceURL, format: .plainText)
    let execution = try await session.executeAnalysisPlan(
        GlifiStudioAnalysisPlanRequest(intent: "understand.collection")
    )
    var completed: GlifiStudioAnalysisExecutionResult?
    for try await event in execution.events {
        if case let .completed(result) = event { completed = result }
    }
    let result = try #require(completed)
    let evidence = try #require(result.interpretation.evidence.only)
    let finding = try #require(result.interpretation.findings.only)
    let tokenCount = try #require(
        evidence.measures.first { $0.identifier == "collection.lexical-token-count" }
    )

    #expect(result.interpretation.insufficientEvidence == nil)
    #expect(finding.messageKey == "finding.collection-profile.summary")
    #expect(finding.assessment.supportClass == "descriptive")
    #expect(finding.evidenceReferences.only?.evidenceID == evidence.id)
    #expect(evidence.sourceReferences.only?.ranges.only?.start == 0)
    #expect(evidence.sourceReferences.only?.ranges.only?.end == sourceData.count)
    #expect(tokenCount.value.type == "integer")
    #expect(tokenCount.value.integerValue == 3)
    #expect(tokenCount.value.decimalValue == nil)
    let encoded = try JSONEncoder().encode(result)
    #expect(
        try JSONDecoder().decode(
            GlifiStudioAnalysisExecutionResult.self,
            from: encoded
        ) == result
    )
    #expect(throws: (any Error).self) {
        _ = try JSONDecoder().decode(
            GlifiStudioEvidenceValue.self,
            from: Data(
                """
                {"type":"integer","integerValue":3,"decimalValue":3.0}
                """.utf8
            )
        )
    }
    await session.close()
}

@Test("GlifiKit conserva indagine, selezioni ramificate e storia dopo una nuova importazione")
func servicePersistsInvestigationHistoryAcrossImportAndReopen() async throws {
    let root = FileManager.default.temporaryDirectory.appending(
        path: "GlifiKitInvestigationTests-\(UUID().uuidString)",
        directoryHint: .isDirectory
    )
    try FileManager.default.createDirectory(at: root, withIntermediateDirectories: false)
    defer { try? FileManager.default.removeItem(at: root) }
    let projectURL = root.appending(path: "Indagine.glifi", directoryHint: .isDirectory)
    let firstSourceURL = root.appending(path: "prima.txt")
    let secondSourceURL = root.appending(path: "seconda.txt")
    try Data("uno due due".utf8).write(to: firstSourceURL)
    try Data("tre quattro".utf8).write(to: secondSourceURL)

    let service = GlifiStudioService()
    let session = try await service.createProject(at: projectURL)
    _ = try await session.importText(at: firstSourceURL, format: .plainText)
    let execution = try await session.executeAnalysisPlan(
        GlifiStudioAnalysisPlanRequest(intent: "understand.collection")
    )
    var completed: GlifiStudioAnalysisExecutionResult?
    for try await event in execution.events {
        if case let .completed(result) = event { completed = result }
    }
    let result = try #require(completed)
    let findingID = try #require(result.interpretation.findings.only?.id)
    let created = try await session.createInvestigation(
        GlifiStudioInvestigationCreationRequest(
            question: "Che cosa caratterizza questa raccolta?",
            interpretationArtifactID: result.interpretationArtifactID
        )
    )
    #expect(created.investigation.languageCode == "it")
    #expect(created.investigation.selectedFindingIDs == [findingID])
    #expect(created.investigation.eventIDs.count == 1)

    let firstBranch = try await session.reviseInvestigationSelection(
        GlifiStudioInvestigationSelectionRequest(
            investigationID: created.investigation.id,
            predecessorEventID: created.investigation.headEventID,
            selectedFindingIDs: [],
            reasonIdentifier: "editorial.omit"
        )
    )
    let secondBranch = try await session.reviseInvestigationSelection(
        GlifiStudioInvestigationSelectionRequest(
            investigationID: created.investigation.id,
            predecessorEventID: created.investigation.headEventID,
            selectedFindingIDs: [findingID],
            reasonIdentifier: "editorial.retain"
        )
    )
    #expect(firstBranch.investigation.selectedFindingIDs.isEmpty)
    #expect(secondBranch.investigation.selectedFindingIDs == [findingID])
    #expect(try await session.investigationHeads().count == 2)

    let exportURL = root.appending(
        path: "Relazione.glifiexport",
        directoryHint: .isDirectory
    )
    let exportReceipt = try await session.exportInvestigation(
        GlifiStudioScientificExportRequest(
            investigationHeadEventID: secondBranch.investigation.headEventID
        ),
        to: exportURL
    )
    #expect(exportReceipt.reportRevisionID.hasPrefix("report-revision:sha256:"))
    #expect(exportReceipt.manifestDigest.hasPrefix("sha256:"))
    #expect(exportReceipt.fileCount == 2)
    #expect(
        FileManager.default.fileExists(
            atPath: exportURL.appending(path: "export-manifest.json").path
        )
    )

    let imported = try await session.importText(at: secondSourceURL, format: .plainText)
    #expect(imported.project.artifactCount == 0)
    #expect(imported.project.investigationEventCount == 3)
    await session.close()

    let reopened = try await service.openProject(at: projectURL)
    let heads = try await reopened.investigationHeads()
    #expect(heads.count == 2)
    #expect(
        Set(heads.map(\.headEventID))
            == Set([
                firstBranch.investigation.headEventID,
                secondBranch.investigation.headEventID,
            ]))
    #expect(try await reopened.snapshot().investigationEventCount == 3)
}

private extension Collection {
    var only: Element? {
        count == 1 ? first : nil
    }
}
