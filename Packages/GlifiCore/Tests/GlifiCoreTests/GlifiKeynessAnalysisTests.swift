// SPDX-License-Identifier: BSD-3-Clause

import Foundation
import Testing

@testable import GlifiCore

@Test("GTest, effect size e Benjamini-Hochberg coincidono con il caso noto")
func keynessProducesSpecifiedValues() throws {
    let target = try corpusProfile(
        text: "casa casa mare",
        revision: "00000000-0000-0000-0000-000000000001"
    )
    let reference = try corpusProfile(
        text: "casa città città",
        revision: "00000000-0000-0000-0000-000000000002"
    )

    let comparison = try GlifiKeynessAnalyzer().compare(
        target: target,
        reference: reference
    )
    let repeated = try GlifiKeynessAnalyzer().compare(
        target: target,
        reference: reference
    )

    #expect(comparison == repeated)
    #expect(comparison.comparisonIdentifier == "keyness-gtest-ha-bh-v1")
    #expect(comparison.comparisonDigest.hasPrefix("sha256:"))
    #expect(comparison.testIdentifier == "GTest-v1")
    #expect(comparison.correctionIdentifier == "BenjaminiHochberg-v1")
    #expect(comparison.oddsRatioIdentifier == "OddsRatio-HA-v1")
    #expect(comparison.logRatioIdentifier == "LogRatio-HA-v1-base2")
    #expect(comparison.targetTokenCount == 3)
    #expect(comparison.referenceTokenCount == 3)
    #expect(comparison.terms.map(\.term) == ["città", "mare", "casa"])

    let city = comparison.terms[0]
    #expect(city.targetFrequency == 0)
    #expect(city.referenceFrequency == 2)
    #expect(abs(city.gStatistic - 3.8190850097688767) < 1e-12)
    #expect(abs(city.pValue - 0.05067190234699019) < 1e-12)
    #expect(abs(city.qValue - 0.15201570704097056) < 1e-12)
    #expect(abs(city.log2RatioHaldaneAnscombe - (-2.321928094887362)) < 1e-12)
    #expect(abs(city.oddsRatioHaldaneAnscombe - 0.0857142857142857) < 1e-12)
    #expect(city.direction == .reference)
    #expect(city.minimumExpectedCount == 1)
    #expect(city.hasLowExpectedCount)

    let sea = comparison.terms[1]
    #expect(abs(sea.qValue - 0.3114934152876009) < 1e-12)
    #expect(sea.direction == .target)
    let house = comparison.terms[2]
    #expect(abs(house.qValue - 0.4097258240633153) < 1e-12)
    #expect(house.direction == .target)
}

@Test("Keyness rifiuta gruppi sovrapposti, degeneri e famiglie oltre limite")
func keynessRejectsInvalidPopulations() throws {
    let target = try corpusProfile(
        text: "casa mare",
        revision: "00000000-0000-0000-0000-000000000001"
    )
    let overlapping = try corpusProfile(
        text: "casa città",
        revision: "00000000-0000-0000-0000-000000000001"
    )
    try expectKeynessFailure(code: "keyness.overlapping-groups") {
        _ = try GlifiKeynessAnalyzer().compare(target: target, reference: overlapping)
    }

    let empty = try corpusProfile(
        text: "",
        revision: "00000000-0000-0000-0000-000000000002"
    )
    try expectKeynessFailure(code: "keyness.empty-token-population") {
        _ = try GlifiKeynessAnalyzer().compare(target: target, reference: empty)
    }

    let singleTypeTarget = try corpusProfile(
        text: "casa casa",
        revision: "00000000-0000-0000-0000-000000000003"
    )
    let singleTypeReference = try corpusProfile(
        text: "casa",
        revision: "00000000-0000-0000-0000-000000000004"
    )
    try expectKeynessFailure(code: "keyness.degenerate-margin") {
        _ = try GlifiKeynessAnalyzer().compare(
            target: singleTypeTarget,
            reference: singleTypeReference
        )
    }

    let reference = try corpusProfile(
        text: "casa città",
        revision: "00000000-0000-0000-0000-000000000005"
    )
    try expectKeynessFailure(code: "keyness.hypothesis-limit-exceeded") {
        _ = try GlifiKeynessAnalyzer().compare(
            target: target,
            reference: reference,
            options: try GlifiKeynessOptions(
                maximumHypothesisCount: 2,
                lowExpectedCountThreshold: 5
            )
        )
    }
    try expectKeynessFailure(code: "keyness.invalid-options") {
        _ = try GlifiKeynessOptions(
            maximumHypothesisCount: -1,
            lowExpectedCountThreshold: .nan
        )
    }
}

private func corpusProfile(text: String, revision: String) throws -> GlifiCorpusAnalysis {
    let imported = try GlifiTextImporter().importText(
        from: Data(text.utf8),
        format: .plainText,
        sourceRevisionID: SourceRevisionID(
            uuid: try #require(UUID(uuidString: revision))
        )
    )
    return try GlifiCorpusAnalyzer().analyze(
        [imported],
        options: try GlifiCorpusAnalysisOptions(
            diversityWindowSize: 2,
            ngramSizes: [],
            maximumDocumentCount: 1,
            maximumSourceByteCount: 1_024,
            maximumVocabularySize: 10,
            maximumDistinctNGramCount: 0,
            maximumNonZeroCellCount: 10
        )
    )
}

private func expectKeynessFailure(
    code: String,
    _ operation: () throws -> Void
) throws {
    do {
        try operation()
        Issue.record("Era attesa la failure \(code)")
    } catch let failure as GlifiFailure {
        #expect(failure.code == code)
        #expect(failure.operation == .analyze)
    }
}
