// SPDX-License-Identifier: BSD-3-Clause

import Foundation
import GlifiCore
import Testing

@testable import GlifiKit

// RF-080: GlifiCore e GlifiKit compilano la stessa QueryAST canonica e producono gli stessi
// intervalli nello stesso ordine; app e CLI usano solo `GlifiStudioProjectSession.query`.
private struct QueryFixture: Decodable {
    struct Case: Decodable {
        struct Match: Decodable {
            let start: Int
            let end: Int
        }
        let id: String
        let query: String
        let outcome: String
        let matches: [Match]?
        let failureCode: String?
    }
    let source: String
    let cases: [Case]
}

@Test("Core e Kit producono lo stesso digest, gli stessi intervalli e lo stesso ordine")
func queryParityBetweenCoreAndKit() async throws {
    let fixtureURL = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
        .deletingLastPathComponent().deletingLastPathComponent()
        .appending(path: "Fixtures/Query/v1/cases.json")
    let fixture = try JSONDecoder().decode(QueryFixture.self, from: Data(contentsOf: fixtureURL))
    let root = FileManager.default.temporaryDirectory.appending(
        path: "GlifiQueryParity-\(UUID().uuidString)", directoryHint: .isDirectory)
    try FileManager.default.createDirectory(at: root, withIntermediateDirectories: false)
    defer { try? FileManager.default.removeItem(at: root) }
    let sourceURL = root.appending(path: "fonte.txt")
    try Data(fixture.source.utf8).write(to: sourceURL)
    let session = try await GlifiStudioService().createProject(
        at: root.appending(path: "Q.glifi", directoryHint: .isDirectory))
    _ = try await session.importText(at: sourceURL, format: .plainText)

    let imported = try GlifiTextImporter().importText(
        from: Data(fixture.source.utf8), format: .plainText)
    let tokenization = try GlifiItalianTokenizer().tokenize(imported.text)
    #expect(fixture.cases.count >= 7)
    for testCase in fixture.cases {
        switch testCase.outcome {
        case "succeeded":
            let ast = try GlifiQueryParser().parse(testCase.query)
            let core = try GlifiQueryEvaluator().evaluate(
                ast, in: imported, tokenization: tokenization)
            let kit = try await session.query(testCase.query)
            #expect(kit.queryDigest == (try ast.canonicalDigest()), "\(testCase.id)")
            let coreRanges = core.matches.map { [$0.range.start, $0.range.end] }
            let kitRanges = kit.matches.map { [$0.startUTF8, $0.endUTF8] }
            #expect(kitRanges == coreRanges, "\(testCase.id)")
            #expect(
                kitRanges == (testCase.matches ?? []).map { [$0.start, $0.end] }, "\(testCase.id)")
        default:
            // Il rifiuto può avvenire in parsing o in validazione della valutazione.
            do {
                _ = try GlifiQueryEvaluator().evaluate(
                    try GlifiQueryParser().parse(testCase.query), in: imported,
                    tokenization: tokenization)
                Issue.record("\(testCase.id): Core ha accettato una query rifiutata")
            } catch let failure as GlifiFailure {
                #expect(failure.code == testCase.failureCode, "\(testCase.id)")
            }
            do {
                _ = try await session.query(testCase.query)
                Issue.record("\(testCase.id): Kit ha accettato una query rifiutata")
            } catch let failure as GlifiStudioFailure {
                #expect(failure.code == testCase.failureCode, "\(testCase.id)")
            }
        }
    }
    await session.close()
}
