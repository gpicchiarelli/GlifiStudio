// SPDX-License-Identifier: BSD-3-Clause

import Foundation
import Testing

@testable import GlifiCore

@Test("Termini, phrase e KWIC mantengono offset e normalizzazione")
func queryEvaluatorProducesPositionalMatches() throws {
    let source = try imported("Casa, casa sul mare. La casa guarda il mare.")
    let tokenization = try GlifiItalianTokenizer().tokenize(source.text)
    let evaluator = GlifiQueryEvaluator()

    let normalized = try evaluator.evaluate(
        GlifiQueryParser().parse("normalized:casa"),
        in: source,
        tokenization: tokenization
    )
    #expect(normalized.matchedScope)
    #expect(normalized.matches.count == 3)
    #expect(normalized.matches[0].range.text(in: source.text) == "Casa")
    #expect(
        normalized.matches[0].rightContextRange?.text(in: source.text)?.contains("mare") == true)

    let exact = try evaluator.evaluate(
        GlifiQueryParser().parse("form:Casa"),
        in: source,
        tokenization: tokenization
    )
    #expect(exact.matches.count == 1)

    let phrase = try evaluator.evaluate(
        GlifiQueryParser().parse("\"casa sul mare\""),
        in: source,
        tokenization: tokenization
    )
    #expect(phrase.matches.count == 1)
    #expect(phrase.matches[0].range.text(in: source.text) == "casa sul mare")

    let slop = try evaluator.evaluate(
        GlifiQueryParser().parse("\"Casa casa\"~1"),
        in: source,
        tokenization: tokenization
    )
    #expect(slop.matches.first?.range.text(in: source.text) == "Casa, casa")
}

@Test("Booleani e prossimità usano lo scope e l'ordine canonici")
func queryEvaluatorAppliesBooleanAndProximitySemantics() throws {
    let source = try imported("Casa, casa sul mare. La casa guarda il mare.")
    let tokenization = try GlifiItalianTokenizer().tokenize(source.text)
    let evaluator = GlifiQueryEvaluator()

    let selected = try evaluator.evaluate(
        GlifiQueryParser().parse("normalized:casa AND NOT oceano"),
        in: source,
        tokenization: tokenization
    )
    #expect(selected.matchedScope)
    #expect(selected.matches.count == 3)

    let rejected = try evaluator.evaluate(
        GlifiQueryParser().parse("normalized:casa AND NOT normalized:mare"),
        in: source,
        tokenization: tokenization
    )
    #expect(!rejected.matchedScope)
    #expect(rejected.matches.isEmpty)

    let proximity = try evaluator.evaluate(
        GlifiQueryParser().parse("normalized:casa BEFORE/1 normalized:mare"),
        in: source,
        tokenization: tokenization
    )
    #expect(proximity.matches.count == 1)
    #expect(proximity.matches[0].range.text(in: source.text) == "casa sul mare")

    let otherRevision = SourceRevisionID()
    let scoped = GlifiQueryAST(
        root: .within(
            .term(field: .normalized, value: "casa", matchMode: .exact),
            scope: .sourceRevision(otherRevision)
        )
    )
    let scopedResult = try evaluator.evaluate(scoped, in: source, tokenization: tokenization)
    #expect(!scopedResult.matchedScope)
}

@Test("Il sottoinsieme regex bounded evita costrutti di backtracking")
func queryEvaluatorUsesSafeRegexSubset() throws {
    let source = try imported("Casa città casetta mare 123.")
    let tokenization = try GlifiItalianTokenizer().tokenize(source.text)
    let evaluator = GlifiQueryEvaluator()

    let result = try evaluator.evaluate(
        GlifiQueryParser().parse("form:/^ca.*a$/i"),
        in: source,
        tokenization: tokenization
    )
    #expect(result.matches.map { $0.range.text(in: source.text) } == ["Casa", "casetta"])

    let digits = try evaluator.evaluate(
        GlifiQueryParser().parse("form:/^\\d+$/"),
        in: source,
        tokenization: tokenization
    )
    #expect(digits.matches.map { $0.range.text(in: source.text) } == ["123"])

    let rejected = GlifiQueryAST(
        root: .regex(field: .form, pattern: "(a+)+", flags: [])
    )
    #expect(throws: GlifiFailure.self) {
        try evaluator.evaluate(rejected, in: source, tokenization: tokenization)
    }
}

@Test("Il limite risultati marca esplicitamente la troncatura")
func queryEvaluatorMarksTruncation() throws {
    let source = try imported("uno uno uno uno")
    let tokenization = try GlifiItalianTokenizer().tokenize(source.text)
    let limits = GlifiQueryLimits(
        maximumQueryByteCount: 64,
        maximumDepth: 8,
        maximumNodeCount: 16,
        maximumPhraseTokenCount: 8,
        maximumProximityDistance: 8,
        maximumRegexByteCount: 16,
        maximumRegexInputByteCount: 64,
        maximumSourceCount: 4,
        maximumScannedByteCount: 1_024,
        maximumResultCount: 2,
        contextTokenCount: 1
    )
    let result = try GlifiQueryEvaluator().evaluate(
        GlifiQueryParser().parse("uno", limits: limits),
        in: source,
        tokenization: tokenization,
        limits: limits
    )

    #expect(result.matches.count == 2)
    #expect(result.isTruncated)
}

@Test("Campi privi di capability falliscono senza simulare zero risultati")
func queryEvaluatorRejectsUnavailableCapabilities() throws {
    let source = try imported("una casa")
    let tokenization = try GlifiItalianTokenizer().tokenize(source.text)
    let query = GlifiQueryAST(
        root: .term(field: .lemma, value: "casa", matchMode: .exact)
    )

    do {
        _ = try GlifiQueryEvaluator().evaluate(query, in: source, tokenization: tokenization)
        Issue.record("Il campo lemma non disponibile è stato trattato come supportato")
    } catch let failure as GlifiFailure {
        #expect(failure.code == "query.unsupported-field")
        #expect(failure.category == .insufficientData)
    }
}

@Test("Il motore interroga la generazione persistita senza accesso laterale allo store")
func engineQueriesPersistedProject() async throws {
    let root = FileManager.default.temporaryDirectory.appending(
        path: "GlifiProjectQueryTests-\(UUID().uuidString)",
        directoryHint: .isDirectory
    )
    try FileManager.default.createDirectory(at: root, withIntermediateDirectories: false)
    defer { try? FileManager.default.removeItem(at: root) }
    let packageURL = root.appending(path: "Query.glifi", directoryHint: .isDirectory)
    let project = try GlifiProjectPackage.create(at: packageURL)
    let first = try imported("Una casa sul mare.")
    let second = try imported("La casa in città.")
    _ = try await project.importText(
        first,
        sourceID: SourceID(
            uuid: try #require(UUID(uuidString: "20000000-0000-0000-0000-000000000001"))
        )
    )
    _ = try await project.importText(
        second,
        sourceID: SourceID(
            uuid: try #require(UUID(uuidString: "20000000-0000-0000-0000-000000000002"))
        )
    )

    let result = try await GlifiEngine().query("normalized:casa", in: project)
    #expect(result.generation == 2)
    #expect(result.matchedSourceCount == 2)
    #expect(result.matches.count == 2)
    #expect(result.matches.allSatisfy { $0.match.lowercased() == "casa" })
    #expect(result.matches.map(\.sourceRevisionID.canonicalValue).isSorted)
}

private func imported(_ text: String) throws -> GlifiImportedText {
    try GlifiTextImporter().importText(from: Data(text.utf8), format: .plainText)
}

private extension Collection where Element: Comparable {
    var isSorted: Bool {
        zip(self, dropFirst()).allSatisfy(<=)
    }
}
