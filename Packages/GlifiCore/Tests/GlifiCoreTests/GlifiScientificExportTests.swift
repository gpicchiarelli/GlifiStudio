// SPDX-License-Identifier: BSD-3-Clause

import Foundation
import PDFKit
import Testing

@testable import GlifiCore

@Test("L'export scientifico inventaria JSON/Markdown/CSV/PDF e rileva manomissioni")
func scientificExportIsCanonicalAndTamperEvident() async throws {
    let fixture = try await exportFixture()
    defer { try? FileManager.default.removeItem(at: fixture.root) }
    let destination = fixture.root.appending(
        path: "Relazione.glifiexport",
        directoryHint: .isDirectory
    )
    let exporter = GlifiScientificExporter()
    let receipt = try exporter.export(
        snapshot: fixture.snapshot,
        investigation: fixture.investigation,
        interpretationRecord: fixture.interpretationRecord,
        interpretation: fixture.interpretation,
        request: try GlifiScientificExportRequest(
            investigationHeadEventID: fixture.investigation.headEventID,
            formats: GlifiScientificExportFormat.allCases
        ),
        to: destination,
        environment: deterministicEnvironment,
        exportID: try #require(UUID(uuidString: "90000000-0000-0000-0000-000000000001")),
        createdAt: Date(timeIntervalSince1970: 1_700_000_000)
    )
    let manifest = try GlifiScientificExporter.verifyExport(at: destination)
    #expect(manifest.exportID == "90000000-0000-0000-0000-000000000001")
    #expect(
        manifest.files.map(\.path)
            == ["evidence.csv", "findings.csv", "report.json", "report.md", "report.pdf"])
    #expect(
        manifest.selection.selectedFindingIDs
            == fixture.investigation.selectedFindingIDs.map(\.canonicalValue))
    #expect(manifest.corpus.sources.count == 1)
    #expect(manifest.corpus.sources[0].contentDigest == fixture.snapshot.sources[0].contentDigest)
    #expect(manifest.analysis.descriptorDigest == fixture.interpretationRecord.descriptorDigest)
    #expect(manifest.validation.status == "candidate")
    #expect(receipt.reportRevisionID.canonicalValue == manifest.selection.reportRevisionID)
    #expect(receipt.fileCount == 5)

    let reportData = try Data(contentsOf: destination.appending(path: "report.json"))
    let report = try JSONDecoder().decode(GlifiReportRevision.self, from: reportData)
    #expect(report.findings.map(\.id) == fixture.investigation.selectedFindingIDs)
    #expect(
        Set(report.evidence.map(\.id))
            == Set(report.findings.flatMap { $0.evidenceReferences.map(\.evidenceID) }))
    #expect(!String(decoding: reportData, as: UTF8.self).contains("uno due due"))

    let markdown = try String(contentsOf: destination.appending(path: "report.md"), encoding: .utf8)
    #expect(markdown.contains("# Relazione di indagine"))
    #expect(markdown.contains("\\# corpus"))

    let findingsCSV = try String(
        contentsOf: destination.appending(path: "findings.csv"),
        encoding: .utf8
    )
    let evidenceCSV = try String(
        contentsOf: destination.appending(path: "evidence.csv"),
        encoding: .utf8
    )
    #expect(findingsCSV.hasPrefix("\"ordinal\",\"finding_id\","))
    #expect(findingsCSV.contains("\r\n"))
    #expect(!findingsCSV.contains("uno due due"))
    #expect(!evidenceCSV.contains("uno due due"))

    let pdfData = try Data(contentsOf: destination.appending(path: "report.pdf"))
    let pdf = try #require(PDFDocument(data: pdfData))
    #expect(pdf.pageCount >= 1)
    #expect(pdf.string?.contains("Relazione di indagine") == true)
    #expect(pdf.string?.contains("Tracciabilità") == true)
    #expect(pdf.string?.contains("uno due due") != true)

    let manifestData = try Data(contentsOf: destination.appending(path: "export-manifest.json"))
    var alteredManifest = try #require(
        JSONSerialization.jsonObject(with: manifestData) as? [String: Any]
    )
    var alteredCorpus = try #require(alteredManifest["corpus"] as? [String: Any])
    alteredCorpus["digest"] = "sha256:" + String(repeating: "0", count: 64)
    alteredManifest["corpus"] = alteredCorpus
    #expect(throws: (any Error).self) {
        _ = try JSONDecoder().decode(
            GlifiExportManifest.self,
            from: JSONSerialization.data(withJSONObject: alteredManifest)
        )
    }

    try (manifestData + Data("\n".utf8)).write(
        to: destination.appending(path: "export-manifest.json")
    )
    #expect(throws: GlifiFailure.self) {
        _ = try GlifiScientificExporter.verifyExport(at: destination)
    }
    try manifestData.write(to: destination.appending(path: "export-manifest.json"))

    try Data("manomissione".utf8).append(to: destination.appending(path: "report.json"))
    do {
        _ = try GlifiScientificExporter.verifyExport(at: destination)
        Issue.record("Era attesa la rilevazione della manomissione")
    } catch let failure as GlifiFailure {
        #expect(failure.code == "export.invalid-file" || failure.code == "export.digest-mismatch")
    }
}

@Test(
    "Un'interruzione export non pubblica una destinazione parziale",
    arguments: [
        GlifiExportInterruption.payloadsWritten,
        .manifestWritten,
        .stagingValidated,
    ]
)
func scientificExportInterruptionPreservesDestination(
    interruption: GlifiExportInterruption
) async throws {
    let fixture = try await exportFixture()
    defer { try? FileManager.default.removeItem(at: fixture.root) }
    let destination = fixture.root.appending(
        path: "Interrotto-\(String(describing: interruption)).glifiexport",
        directoryHint: .isDirectory
    )

    #expect(throws: GlifiFailure.self) {
        _ = try GlifiScientificExporter().export(
            snapshot: fixture.snapshot,
            investigation: fixture.investigation,
            interpretationRecord: fixture.interpretationRecord,
            interpretation: fixture.interpretation,
            request: try GlifiScientificExportRequest(
                investigationHeadEventID: fixture.investigation.headEventID
            ),
            to: destination,
            environment: deterministicEnvironment,
            exportID: UUID(),
            createdAt: Date(timeIntervalSince1970: 1_700_000_000),
            interruption: interruption
        )
    }
    #expect(!FileManager.default.fileExists(atPath: destination.path))
    let leftovers = try FileManager.default.contentsOfDirectory(atPath: fixture.root.path)
    #expect(!leftovers.contains { $0.contains(".exporting-") })
}

@Test("Il PDF pagina un rapporto lungo senza perdere testo o struttura")
func scientificPDFPaginatesLongReport() async throws {
    let question = String(
        repeating:
            "Quali caratteristiche emergono dalla raccolta e quali limiti vanno conservati? ",
        count: 180
    )
    let fixture = try await exportFixture(question: question)
    defer { try? FileManager.default.removeItem(at: fixture.root) }
    let destination = fixture.root.appending(
        path: "Relazione-lunga.glifiexport",
        directoryHint: .isDirectory
    )

    let receipt = try GlifiScientificExporter().export(
        snapshot: fixture.snapshot,
        investigation: fixture.investigation,
        interpretationRecord: fixture.interpretationRecord,
        interpretation: fixture.interpretation,
        request: try GlifiScientificExportRequest(
            investigationHeadEventID: fixture.investigation.headEventID,
            formats: [.pdf]
        ),
        to: destination,
        environment: deterministicEnvironment,
        exportID: try #require(UUID(uuidString: "90000000-0000-0000-0000-000000000002")),
        createdAt: Date(timeIntervalSince1970: 1_700_000_000)
    )

    #expect(receipt.fileCount == 1)
    let pdfData = try Data(contentsOf: destination.appending(path: "report.pdf"))
    let pdf = try #require(PDFDocument(data: pdfData))
    #expect(pdf.pageCount > 1)
    #expect(pdf.string?.contains("Quali caratteristiche emergono") == true)
    _ = try GlifiScientificExporter.verifyExport(at: destination)
}

private struct ExportFixture {
    let root: URL
    let snapshot: GlifiProjectSnapshot
    let investigation: GlifiInvestigation
    let interpretationRecord: GlifiProjectArtifactRecord
    let interpretation: GlifiAnalysisInterpretation
}

private func exportFixture(
    question: String = "# corpus: quali caratteristiche emergono?"
) async throws -> ExportFixture {
    let root = FileManager.default.temporaryDirectory.appending(
        path: "GlifiExportTests-\(UUID().uuidString)",
        directoryHint: .isDirectory
    )
    try FileManager.default.createDirectory(at: root, withIntermediateDirectories: false)
    do {
        let projectURL = root.appending(path: "Export.glifi", directoryHint: .isDirectory)
        let project = try GlifiProjectPackage.create(at: projectURL)
        let imported = try GlifiTextImporter().importText(
            from: Data("uno due due".utf8),
            format: .plainText
        )
        _ = try await project.importText(imported)
        let engine = GlifiEngine()
        let execution = try await engine.executeAnalysisPlan(
            in: project,
            request: GlifiAnalysisPlanRequest(intent: .understandCollection)
        )
        let created = try await engine.createInvestigation(
            in: project,
            request: try GlifiInvestigationCreationRequest(
                question: question,
                interpretationArtifactID: execution.interpretationArtifactID
            )
        )
        let snapshot = await project.snapshot()
        let record = try #require(
            snapshot.artifacts.first { $0.artifactID == execution.interpretationArtifactID }
        )
        let payload = try JSONDecoder().decode(
            GlifiAnalysisInterpretationArtifactPayload.self,
            from: await project.artifactData(for: record.artifactID)
        )
        return ExportFixture(
            root: root,
            snapshot: snapshot,
            investigation: created.investigation,
            interpretationRecord: record,
            interpretation: payload.interpretation
        )
    } catch {
        try? FileManager.default.removeItem(at: root)
        throw error
    }
}

private let deterministicEnvironment = GlifiExportEnvironment(
    software: .init(
        name: "Glifi Studio",
        version: "0.1.0",
        build: "1",
        sourceRevision: "test"
    ),
    platform: .init(
        system: "macOS",
        version: "27.0",
        architecture: "arm64",
        toolchain: "Apple Swift 6.4 / Xcode 27"
    )
)

private extension Data {
    func append(to url: URL) throws {
        let handle = try FileHandle(forWritingTo: url)
        defer { try? handle.close() }
        try handle.seekToEnd()
        try handle.write(contentsOf: self)
    }
}
