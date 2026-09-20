// SPDX-License-Identifier: BSD-3-Clause

import CryptoKit
import Foundation
import Testing

@testable import GlifiCore

/// Span-level precision, recall and F1 of one layer of boundaries (GS-MET-001-18).
private struct BoundaryAgreement {
    let matched: Int
    let predicted: Int
    let gold: Int

    var precision: Double { predicted == 0 ? 0 : Double(matched) / Double(predicted) }
    var recall: Double { gold == 0 ? 0 : Double(matched) / Double(gold) }
    var f1: Double {
        let denominator = precision + recall
        return denominator == 0 ? 0 : 2 * precision * recall / denominator
    }

    init(predicted: [ClosedRange<Int>], gold: [ClosedRange<Int>]) {
        // Corrispondenza esatta dello span: un confine spostato conta come errore su entrambi i
        // lati, come prescrive GS-MET-001-18, non come mezzo credito.
        let goldSet = Set(gold)
        self.matched = predicted.filter(goldSet.contains).count
        self.predicted = predicted.count
        self.gold = gold.count
    }
}

@Test("La qualità della tokenizzazione non scende sotto la linea di base registrata")
func italianTokenizerMeetsRecordedBaseline() throws {
    let root = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent()
        .deletingLastPathComponent()
        .deletingLastPathComponent()
        .deletingLastPathComponent()
        .deletingLastPathComponent()
    let baselineURL = root.appending(path: "Fixtures/Linguistics/it-gold-v0/baseline.json")
    let baseline = try JSONDecoder().decode(
        TokenizationBaseline.self, from: try Data(contentsOf: baselineURL))
    let corpusData = try Data(contentsOf: root.appending(path: baseline.corpus))

    // La linea di base vale per un corpus preciso: se il corpus cambia, va rimisurata.
    let digest = SHA256.hash(data: corpusData).map { String(format: "%02x", $0) }.joined()
    #expect("sha256:\(digest)" == baseline.corpusDigest)

    let corpus = try JSONDecoder().decode(GoldCorpus.self, from: corpusData)
    #expect(corpus.cases.count == baseline.observed.caseCount)

    let tokenizer = GlifiItalianTokenizer()
    var tokenPredicted: [ClosedRange<Int>] = []
    var tokenGold: [ClosedRange<Int>] = []
    var sentencePredicted: [ClosedRange<Int>] = []
    var sentenceGold: [ClosedRange<Int>] = []
    for goldCase in corpus.cases {
        let result = try tokenizer.tokenize(goldCase.text)
        tokenPredicted += result.tokens.map { $0.range.start...$0.range.end }
        tokenGold += goldCase.tokens.map { $0.start...$0.end }
        sentencePredicted += result.sentences.map { $0.range.start...$0.range.end }
        sentenceGold += goldCase.sentences.map { $0.start...$0.end }
    }
    #expect(tokenGold.count == baseline.observed.goldTokenCount)
    #expect(sentenceGold.count == baseline.observed.goldSentenceCount)

    let tokens = BoundaryAgreement(predicted: tokenPredicted, gold: tokenGold)
    let sentences = BoundaryAgreement(predicted: sentencePredicted, gold: sentenceGold)
    // Una regressione fa fallire il gate; un miglioramento chiede di aggiornare la linea di base.
    #expect(tokens.f1 >= baseline.observed.tokenBoundaryF1 - 1e-12)
    #expect(sentences.f1 >= baseline.observed.sentenceBoundaryF1 - 1e-12)
    #expect(tokens.precision >= 0 && tokens.recall >= 0)
    if tokens.f1 > baseline.observed.tokenBoundaryF1 + 1e-12
        || sentences.f1 > baseline.observed.sentenceBoundaryF1 + 1e-12
    {
        let message =
            "La qualità è migliorata (token F1 \(tokens.f1), frasi F1 \(sentences.f1)): "
            + "aggiorna baseline.json, altrimenti la regressione successiva non verrebbe vista."
        Issue.record(Comment(rawValue: message))
    }
}

private struct TokenizationBaseline: Decodable {
    struct Observed: Decodable {
        let caseCount: Int
        let goldTokenCount: Int
        let goldSentenceCount: Int
        let tokenBoundaryF1: Double
        let sentenceBoundaryF1: Double
    }

    let corpus: String
    let corpusDigest: String
    let observed: Observed
}

private struct GoldCorpus: Decodable {
    struct Span: Decodable {
        let start: Int
        let end: Int
    }

    struct Case: Decodable {
        let id: String
        let text: String
        let tokens: [Span]
        let sentences: [Span]
    }

    let cases: [Case]
}
