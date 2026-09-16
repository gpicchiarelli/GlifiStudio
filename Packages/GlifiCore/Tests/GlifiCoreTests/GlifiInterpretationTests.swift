// SPDX-License-Identifier: BSD-3-Clause

import Foundation
import Testing

@testable import GlifiCore

@Test("Il profilo descrittivo produce Evidence e Finding content-addressed con lineage completo")
func corpusInterpretationIsStableAndGrounded() throws {
    let revisionID = try sourceRevision("00000000-0000-0000-0000-000000000001")
    let imported = try GlifiTextImporter().importText(
        from: Data("casa mare casa".utf8),
        format: .plainText,
        sourceRevisionID: revisionID
    )
    let analysis = try GlifiCorpusAnalyzer().analyze([imported])
    let plan = try GlifiAnalysisPlanner().plan(
        request: GlifiAnalysisPlanRequest(intent: .understandCollection),
        sourceRootDigest: testDigest("a"),
        configuredLanguageCode: "it",
        sources: [
            try GlifiPlanningSource(
                sourceRevisionID: revisionID,
                format: .plainText,
                byteCount: imported.bytes.count
            )
        ]
    )
    let step = try #require(plan.steps.only)
    let input = GlifiInterpretationArtifactInput(
        planStepIdentifier: step.identifier,
        role: step.role,
        artifactID: try ArtifactID(digest: testDigest("b")),
        analysisNodeID: try AnalysisNodeID(digest: testDigest("c")),
        descriptorDigest: testDigest("d"),
        content: .corpusProfile(analysis)
    )
    let sources = [sourceRecord(revisionID, byteCount: imported.bytes.count)]
    let engine = GlifiInterpretationEngine()
    let first = try engine.interpret(
        planArtifactID: try ArtifactID(digest: testDigest("e")),
        planAnalysisNodeID: try AnalysisNodeID(digest: testDigest("f")),
        plan: plan,
        artifacts: [input],
        sources: sources
    )
    let repeated = try engine.interpret(
        planArtifactID: first.planArtifactID,
        planAnalysisNodeID: first.planAnalysisNodeID,
        plan: plan,
        artifacts: [input],
        sources: sources
    )

    #expect(first == repeated)
    #expect(first.evidence.count == 1)
    #expect(first.findings.count == 1)
    #expect(first.insufficientEvidence == nil)
    #expect(first.evidence[0].artifactIDs == [input.artifactID])
    #expect(first.evidence[0].sourceReferences[0].sourceRevisionID == revisionID)
    #expect(first.evidence[0].sourceReferences[0].ranges[0].count == imported.bytes.count)
    #expect(first.findings[0].evidenceReferences[0].evidenceID == first.evidence[0].id)
    #expect(first.findings[0].assessment.supportClass == .descriptive)
    #expect(first.findings[0].epistemicCategory == .deterministicallyInterpreted)
    #expect(first.findings[0].rankFactors.stability == nil)
    #expect(first.findings[0].rankFactors.novelty == nil)

    let wrongRole = GlifiInterpretationArtifactInput(
        planStepIdentifier: step.identifier,
        role: .target,
        artifactID: input.artifactID,
        analysisNodeID: input.analysisNodeID,
        descriptorDigest: input.descriptorDigest,
        content: input.content
    )
    #expect(throws: GlifiFailure.self) {
        _ = try engine.interpret(
            planArtifactID: first.planArtifactID,
            planAnalysisNodeID: first.planAnalysisNodeID,
            plan: plan,
            artifacts: [wrongRole],
            sources: sources
        )
    }
}

@Test("La policy keyness ordina per famiglia, espone le cautele e limita i risultati")
func keynessInterpretationUsesExplicitSupportAndRanking() throws {
    let targetID = try sourceRevision("00000000-0000-0000-0000-000000000011")
    let referenceID = try sourceRevision("00000000-0000-0000-0000-000000000012")
    let plan = try comparisonPlan(targetID: targetID, referenceID: referenceID)
    let target = try corpus(text: "alfa alfa beta", revisionID: targetID)
    let reference = try corpus(text: "gamma gamma beta", revisionID: referenceID)
    let comparison = keynessComparison(targetID: targetID, referenceID: referenceID)
    let inputs = try plan.steps.enumerated().map { index, step in
        let content: GlifiInterpretationArtifactContent
        switch step.role {
        case .target:
            content = .corpusProfile(target)
        case .reference:
            content = .corpusProfile(reference)
        case .comparison:
            content = .keyness(comparison)
        case .scope:
            Issue.record("Ruolo scope inatteso nel piano comparativo")
            content = .corpusProfile(target)
        }
        return GlifiInterpretationArtifactInput(
            planStepIdentifier: step.identifier,
            role: step.role,
            artifactID: try ArtifactID(digest: testDigest(Character(String(index + 1)))),
            analysisNodeID: try AnalysisNodeID(
                digest: testDigest(Character(String(index + 4)))
            ),
            descriptorDigest: testDigest(Character(String(index + 7))),
            content: content
        )
    }
    let sources = [
        sourceRecord(targetID, byteCount: 14),
        sourceRecord(referenceID, byteCount: 16),
    ]
    let engine = GlifiInterpretationEngine()
    let all = try engine.interpret(
        planArtifactID: try ArtifactID(digest: testDigest("a")),
        planAnalysisNodeID: try AnalysisNodeID(digest: testDigest("b")),
        plan: plan,
        artifacts: inputs,
        sources: sources,
        options: try GlifiInterpretationOptions(
            maximumFindingCount: 3,
            moderateMaximumQValue: 0.05,
            strongMaximumQValue: 0.01,
            moderateMinimumAbsoluteLog2Ratio: 1,
            strongMinimumAbsoluteLog2Ratio: 2
        )
    )

    #expect(all.findings.map(\.assessment.supportClass) == [.strong, .moderate, .caution])
    #expect(all.findings.map { $0.messageArguments["term"] } == ["forte", "moderato", "cauto"])
    #expect(all.evidence[2].validity == .limited)
    #expect(all.evidence[2].caveats.contains { $0.severity == .warning })
    #expect(
        all.suppressionSummaries.contains {
            $0.reasonIdentifier == "interpretation.support-insufficient" && $0.count == 1
        }
    )

    let capped = try engine.interpret(
        planArtifactID: all.planArtifactID,
        planAnalysisNodeID: all.planAnalysisNodeID,
        plan: plan,
        artifacts: inputs,
        sources: sources,
        options: try GlifiInterpretationOptions(
            maximumFindingCount: 2,
            moderateMaximumQValue: 0.05,
            strongMaximumQValue: 0.01,
            moderateMinimumAbsoluteLog2Ratio: 1,
            strongMinimumAbsoluteLog2Ratio: 2
        )
    )
    #expect(capped.findings.count == 2)
    #expect(
        capped.suppressionSummaries.contains {
            $0.reasonIdentifier == "interpretation.finding-limit-exceeded" && $0.count == 1
        }
    )
}

@Test("Il payload revalida le identità e le opzioni rifiutano policy non monotone")
func interpretationPayloadFailsClosed() throws {
    #expect(throws: GlifiFailure.self) {
        _ = try GlifiInterpretationOptions(
            maximumFindingCount: -1,
            moderateMaximumQValue: 0.01,
            strongMaximumQValue: 0.05,
            moderateMinimumAbsoluteLog2Ratio: 2,
            strongMinimumAbsoluteLog2Ratio: 1
        )
    }

    let revisionID = try sourceRevision("00000000-0000-0000-0000-000000000021")
    let imported = try GlifiTextImporter().importText(
        from: Data("testo".utf8),
        format: .plainText,
        sourceRevisionID: revisionID
    )
    let analysis = try GlifiCorpusAnalyzer().analyze([imported])
    let plan = try GlifiAnalysisPlanner().plan(
        request: GlifiAnalysisPlanRequest(intent: .understandCollection),
        sourceRootDigest: testDigest("c"),
        configuredLanguageCode: "it",
        sources: [
            try GlifiPlanningSource(
                sourceRevisionID: revisionID,
                format: .plainText,
                byteCount: imported.bytes.count
            )
        ]
    )
    let step = try #require(plan.steps.only)
    let interpretation = try GlifiInterpretationEngine().interpret(
        planArtifactID: try ArtifactID(digest: testDigest("d")),
        planAnalysisNodeID: try AnalysisNodeID(digest: testDigest("e")),
        plan: plan,
        artifacts: [
            GlifiInterpretationArtifactInput(
                planStepIdentifier: step.identifier,
                role: step.role,
                artifactID: try ArtifactID(digest: testDigest("f")),
                analysisNodeID: try AnalysisNodeID(digest: testDigest("1")),
                descriptorDigest: testDigest("2"),
                content: .corpusProfile(analysis)
            )
        ],
        sources: [sourceRecord(revisionID, byteCount: imported.bytes.count)]
    )
    let nodeID = try AnalysisNodeID(digest: testDigest("3"))
    let payload = try GlifiAnalysisInterpretationArtifactPayload(
        analysisNodeID: nodeID,
        interpretation: interpretation
    )
    let encoded = try GlifiArtifactCanonicalJSON.encode(payload)
    #expect(
        try JSONDecoder().decode(
            GlifiAnalysisInterpretationArtifactPayload.self,
            from: encoded
        ) == payload
    )

    var object = try #require(
        JSONSerialization.jsonObject(with: encoded) as? [String: Any]
    )
    var storedInterpretation = try #require(object["interpretation"] as? [String: Any])
    var evidence = try #require(storedInterpretation["evidence"] as? [[String: Any]])
    evidence[0]["id"] = "evidence:\(testDigest("9"))"
    storedInterpretation["evidence"] = evidence
    object["interpretation"] = storedInterpretation
    let tampered = try JSONSerialization.data(withJSONObject: object, options: [.sortedKeys])
    #expect(throws: (any Error).self) {
        _ = try JSONDecoder().decode(
            GlifiAnalysisInterpretationArtifactPayload.self,
            from: tampered
        )
    }
}

private func comparisonPlan(
    targetID: SourceRevisionID,
    referenceID: SourceRevisionID
) throws -> GlifiAnalysisPlan {
    try GlifiAnalysisPlanner().plan(
        request: GlifiAnalysisPlanRequest(
            intent: .compareObjects,
            targetSourceRevisionIDs: [targetID],
            referenceSourceRevisionIDs: [referenceID]
        ),
        sourceRootDigest: testDigest("0"),
        configuredLanguageCode: "it",
        sources: [
            try GlifiPlanningSource(
                sourceRevisionID: targetID,
                format: .plainText,
                byteCount: 14
            ),
            try GlifiPlanningSource(
                sourceRevisionID: referenceID,
                format: .plainText,
                byteCount: 16
            ),
        ]
    )
}

private func corpus(
    text: String,
    revisionID: SourceRevisionID
) throws -> GlifiCorpusAnalysis {
    try GlifiCorpusAnalyzer().analyze([
        try GlifiTextImporter().importText(
            from: Data(text.utf8),
            format: .plainText,
            sourceRevisionID: revisionID
        )
    ])
}

private func keynessComparison(
    targetID: SourceRevisionID,
    referenceID: SourceRevisionID
) -> GlifiKeynessComparison {
    GlifiKeynessComparison(
        comparisonIdentifier: GlifiKeynessAnalyzer.comparisonIdentifier,
        comparisonDigest: testDigest("4"),
        targetCorpusDigest: testDigest("5"),
        referenceCorpusDigest: testDigest("6"),
        targetSourceRevisionIDs: [targetID],
        referenceSourceRevisionIDs: [referenceID],
        targetTokenCount: 100,
        referenceTokenCount: 100,
        testIdentifier: "GTest-v1",
        pValueIdentifier: "ChiSquareSurvival-df1-erfc-v1",
        correctionIdentifier: "BenjaminiHochberg-v1",
        oddsRatioIdentifier: "OddsRatio-HA-v1",
        logRatioIdentifier: "LogRatio-HA-v1-base2",
        diagnosticIdentifier: "asymptotic-minimum-expected-count-v1",
        lowExpectedCountThreshold: 5,
        floatingPointDeterminismClass: "D1",
        numericPolicyIdentifier: "IEEE-754-binary64-ordered-reduction-v1",
        referenceAbsoluteTolerance: 1e-12,
        orderingIdentifier: "absolute-log-ratio-descending-term-ascending-v1",
        terms: [
            keynessTerm("forte", qValue: 0.001, log2Ratio: 3, lowExpected: false),
            keynessTerm("moderato", qValue: 0.03, log2Ratio: 1.5, lowExpected: false),
            keynessTerm("cauto", qValue: 0.001, log2Ratio: 4, lowExpected: true),
            keynessTerm("escluso", qValue: 0.2, log2Ratio: 5, lowExpected: false),
        ]
    )
}

private func keynessTerm(
    _ term: String,
    qValue: Double,
    log2Ratio: Double,
    lowExpected: Bool
) -> GlifiKeynessTermResult {
    GlifiKeynessTermResult(
        term: term,
        targetFrequency: 20,
        referenceFrequency: 2,
        targetRelativeFrequency: 0.2,
        referenceRelativeFrequency: 0.02,
        gStatistic: 12,
        degreesOfFreedom: 1,
        pValue: min(qValue, 0.001),
        qValue: qValue,
        oddsRatioHaldaneAnscombe: pow(2, log2Ratio),
        log2RatioHaldaneAnscombe: log2Ratio,
        direction: .target,
        minimumExpectedCount: lowExpected ? 1 : 10,
        hasLowExpectedCount: lowExpected
    )
}

private func sourceRecord(
    _ revisionID: SourceRevisionID,
    byteCount: Int
) -> GlifiProjectSourceRecord {
    GlifiProjectSourceRecord(
        sourceID: SourceID(),
        sourceRevisionID: revisionID,
        format: .plainText,
        contentDigest: testDigest("8"),
        byteCount: byteCount,
        objectPath: ".objects/test"
    )
}

private func sourceRevision(_ value: String) throws -> SourceRevisionID {
    SourceRevisionID(uuid: try #require(UUID(uuidString: value)))
}

private func testDigest(_ character: Character) -> String {
    "sha256:" + String(repeating: character, count: 64)
}

private extension Collection {
    var only: Element? { count == 1 ? first : nil }
}
