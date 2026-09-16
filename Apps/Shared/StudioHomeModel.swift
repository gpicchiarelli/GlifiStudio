// SPDX-License-Identifier: BSD-3-Clause

import Foundation
import GlifiKit
import Observation
import UniformTypeIdentifiers

extension UTType {
    /// Package document type for `.glifi` projects (`studio.glifi.project`).
    static var glifiProject: UTType {
        UTType(exportedAs: "studio.glifi.project", conformingTo: .package)
    }
}

enum EnginePresentationState: Sendable {
    case checking
    case ready
}

enum StudioBusyState: Sendable, Equatable {
    case idle
    case working(messageKey: String)
}

enum StudioIntentOption: String, CaseIterable, Identifiable, Sendable {
    case understandCollection = "understand.collection"
    case discoverContents = "discover.contents"
    case compareObjects = "compare.objects"
    case searchSources = "search.sources"
    case reviewCompletely = "review.completely"

    var id: String { rawValue }

    var titleKey: String {
        "intent.\(rawValue.replacingOccurrences(of: ".", with: "-"))"
    }
}

@MainActor
@Observable
final class StudioHomeModel {
    private(set) var engineState: EnginePresentationState = .checking
    private(set) var busyState: StudioBusyState = .idle
    private(set) var failureMessageKey: String?
    private(set) var projectURL: URL?
    private(set) var snapshot: GlifiStudioProjectSnapshot?
    private(set) var lastProfile: GlifiStudioTextProfile?
    private(set) var lastImportedFileName: String?
    private(set) var planResult: GlifiStudioAnalysisPlanResult?
    private(set) var executionResult: GlifiStudioAnalysisExecutionResult?
    private(set) var executionProgress: GlifiStudioOperationProgress?
    private(set) var investigation: GlifiStudioInvestigation?
    private(set) var investigationHeads: [GlifiStudioInvestigation] = []
    private(set) var queryResult: GlifiStudioProjectQueryResult?
    private(set) var selectedQueryMatchID: String?
    private(set) var sourceText: GlifiStudioSourceText?
    private(set) var exportReceipt: GlifiStudioExportReceipt?
    private(set) var selectedFindingID: String?
    private(set) var editorialSelectedFindingIDs: Set<String> = []
    private(set) var lastProjectBookmark: Data?

    var projectNameDraft = "Indagine"
    var questionDraft = "Che cosa contiene questa raccolta?"
    var selectedIntent: StudioIntentOption = .understandCollection
    var queryDraft = ""
    var selectedTargetRevisionIDs: Set<String> = []
    var selectedReferenceRevisionIDs: Set<String> = []

    private let service: GlifiStudioService
    private var session: GlifiStudioProjectSession?
    private var activeExecution: GlifiStudioAnalysisExecution?

    init(service: GlifiStudioService = GlifiStudioService()) {
        self.service = service
    }

    var isBusy: Bool {
        if case .working = busyState {
            return true
        }
        return false
    }

    var findings: [GlifiStudioFinding] {
        executionResult?.interpretation.findings ?? []
    }

    var insufficientEvidence: GlifiStudioInsufficientEvidenceOutcome? {
        executionResult?.interpretation.insufficientEvidence
    }

    var selectedFinding: GlifiStudioFinding? {
        guard let selectedFindingID else {
            return findings.first
        }
        return findings.first { $0.id == selectedFindingID } ?? findings.first
    }

    var evidenceForSelectedFinding: [GlifiStudioEvidence] {
        guard let finding = selectedFinding else {
            return []
        }
        let ids = Set(finding.evidenceReferences.map(\.evidenceID))
        return (executionResult?.interpretation.evidence ?? []).filter { ids.contains($0.id) }
    }

    var selectedQueryMatch: GlifiStudioQueryMatch? {
        guard let selectedQueryMatchID else {
            return queryResult?.matches.first
        }
        return queryResult?.matches.first { $0.id == selectedQueryMatchID }
            ?? queryResult?.matches.first
    }

    var canCancelExecution: Bool {
        activeExecution != nil
    }

    func prepare() async {
        let status = await service.status()
        guard !Task.isCancelled else {
            return
        }
        switch status {
        case .ready:
            engineState = .ready
        }
    }

    func createProject() async {
        await run(messageKey: "progress.creating-project") {
            let root = try Self.projectsRoot()
            try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
            let sanitized = Self.sanitizeFileName(projectNameDraft)
            let url = root.appending(path: "\(sanitized).glifi", directoryHint: .isDirectory)
            try await initializePackage(at: url, replaceExisting: true)
        }
    }

    func attachDocument(at url: URL?, needsPackageInitialization: Bool) async {
        guard let url else {
            return
        }
        if needsPackageInitialization {
            await run(messageKey: "progress.creating-project") {
                try await initializePackage(at: url, replaceExisting: true)
            }
        } else if projectURL != url {
            await openProject(at: url)
        }
    }

    func openProject(at url: URL) async {
        await run(messageKey: "progress.opening-project") {
            let accessGranted = url.startAccessingSecurityScopedResource()
            defer {
                if accessGranted {
                    url.stopAccessingSecurityScopedResource()
                }
            }
            await closeSession()
            let opened = try await service.openProject(at: url)
            session = opened
            projectURL = url
            rememberProject(url)
            snapshot = try await opened.snapshot()
            clearAnalysisState()
            let heads = try await opened.investigationHeads()
            investigationHeads = heads
            investigation = heads.first
            if let investigation {
                editorialSelectedFindingIDs = Set(investigation.selectedFindingIDs)
            }
        }
    }

    func reopenLastProject() async {
        guard let lastProjectBookmark else {
            failureMessageKey = "failure.project.none-open"
            return
        }
        var isStale = false
        do {
            let url = try URL(
                resolvingBookmarkData: lastProjectBookmark,
                options: [.withoutUI, .withSecurityScope],
                relativeTo: nil,
                bookmarkDataIsStale: &isStale
            )
            await openProject(at: url)
        } catch {
            failureMessageKey = "failure.project.invalid-package"
        }
    }

    func importSource(at url: URL) async {
        await importSources(at: [url])
    }

    func importSources(at urls: [URL]) async {
        await run(messageKey: "progress.importing") {
            let active = try requireSession()
            var lastResult: GlifiStudioProjectImportResult?
            for url in urls {
                let accessGranted = url.startAccessingSecurityScopedResource()
                defer {
                    if accessGranted {
                        url.stopAccessingSecurityScopedResource()
                    }
                }
                let format: GlifiStudioTextFormat =
                    ["md", "markdown"].contains(url.pathExtension.lowercased())
                    ? .markdown : .plainText
                lastResult = try await active.importText(at: url, format: format)
                lastImportedFileName = url.lastPathComponent
            }
            if let lastResult {
                snapshot = lastResult.project
                lastProfile = lastResult.profile
            }
        }
    }

    func planInvestigation() async {
        await run(messageKey: "progress.planning") {
            let active = try requireSession()
            let request = makePlanRequest()
            let planned = try await active.planAnalysis(request)
            planResult = planned
            executionResult = nil
            executionProgress = nil
            investigation = nil
            exportReceipt = nil
            selectedFindingID = nil
        }
    }

    func executePlan() async {
        await run(messageKey: "progress.executing") {
            let active = try requireSession()
            let request = makePlanRequest()
            let execution = try active.executeAnalysisPlan(request)
            activeExecution = execution
            defer { activeExecution = nil }
            for try await event in execution.events {
                switch event {
                case let .progress(progress):
                    executionProgress = progress
                case let .completed(result):
                    executionResult = result
                    executionProgress = nil
                    snapshot = try await active.snapshot()
                    selectedFindingID = result.interpretation.findings.first?.id
                    editorialSelectedFindingIDs = Set(result.interpretation.findings.map(\.id))
                }
            }
        }
    }

    func cancelExecution() {
        activeExecution?.cancel()
        activeExecution = nil
        executionProgress = nil
        busyState = .idle
    }

    func createInvestigationFromExecution() async {
        await run(messageKey: "progress.investigating") {
            let active = try requireSession()
            guard let executionResult else {
                throw presentationFailure(messageKey: "failure.investigation.missing-execution")
            }
            let selected =
                editorialSelectedFindingIDs.isEmpty
                ? nil
                : Array(editorialSelectedFindingIDs).sorted()
            let request = GlifiStudioInvestigationCreationRequest(
                question: questionDraft,
                languageCode: "it",
                interpretationArtifactID: executionResult.interpretationArtifactID,
                selectedFindingIDs: selected
            )
            let result = try await active.createInvestigation(request)
            investigation = result.investigation
            editorialSelectedFindingIDs = Set(result.investigation.selectedFindingIDs)
            investigationHeads = try await active.investigationHeads()
            snapshot = try await active.snapshot()
        }
    }

    func selectInvestigationHead(_ head: GlifiStudioInvestigation) {
        investigation = head
        editorialSelectedFindingIDs = Set(head.selectedFindingIDs)
    }

    func refreshInvestigationHeads() async {
        await run(messageKey: "progress.investigating") {
            let active = try requireSession()
            investigationHeads = try await active.investigationHeads()
            if let current = investigation {
                investigation =
                    investigationHeads.first { $0.headEventID == current.headEventID }
                    ?? investigationHeads.first
            } else {
                investigation = investigationHeads.first
            }
            if let investigation {
                editorialSelectedFindingIDs = Set(investigation.selectedFindingIDs)
            }
        }
    }

    func reviseEditorialSelection() async {
        await run(messageKey: "progress.revising-selection") {
            let active = try requireSession()
            guard let investigation else {
                throw presentationFailure(messageKey: "failure.export.missing-investigation")
            }
            let request = GlifiStudioInvestigationSelectionRequest(
                investigationID: investigation.id,
                predecessorEventID: investigation.headEventID,
                selectedFindingIDs: Array(editorialSelectedFindingIDs).sorted(),
                reasonIdentifier: "editorial.focus"
            )
            let result = try await active.reviseInvestigationSelection(request)
            self.investigation = result.investigation
            editorialSelectedFindingIDs = Set(result.investigation.selectedFindingIDs)
            investigationHeads = try await active.investigationHeads()
            snapshot = try await active.snapshot()
        }
    }

    func runQuery() async {
        await run(messageKey: "progress.querying") {
            let active = try requireSession()
            let trimmed = queryDraft.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else {
                throw presentationFailure(messageKey: "failure.query.empty")
            }
            let result = try await active.query(trimmed)
            queryResult = result
            selectedQueryMatchID = result.matches.first?.id
            sourceText = nil
            if let match = result.matches.first {
                sourceText = try await active.sourceText(sourceRevisionID: match.sourceRevisionID)
            }
        }
    }

    func selectQueryMatch(_ match: GlifiStudioQueryMatch) async {
        selectedQueryMatchID = match.id
        await run(messageKey: "progress.loading-source") {
            let active = try requireSession()
            sourceText = try await active.sourceText(sourceRevisionID: match.sourceRevisionID)
        }
    }

    func exportInvestigation(to destinationDirectory: URL) async {
        await run(messageKey: "progress.exporting") {
            let active = try requireSession()
            guard let investigation else {
                throw presentationFailure(messageKey: "failure.export.missing-investigation")
            }
            let accessGranted = destinationDirectory.startAccessingSecurityScopedResource()
            defer {
                if accessGranted {
                    destinationDirectory.stopAccessingSecurityScopedResource()
                }
            }
            let request = GlifiStudioScientificExportRequest(
                investigationHeadEventID: investigation.headEventID,
                formats: ["json", "markdown", "csv", "pdf"]
            )
            exportReceipt = try await active.exportInvestigation(
                request,
                to: destinationDirectory
            )
            snapshot = try await active.snapshot()
        }
    }

    func reportOpenFailure() {
        failureMessageKey = "failure.project.invalid-package"
    }

    func selectFinding(id: String) {
        selectedFindingID = id
    }

    func toggleEditorialSelection(id: String) {
        if editorialSelectedFindingIDs.contains(id) {
            editorialSelectedFindingIDs.remove(id)
        } else {
            editorialSelectedFindingIDs.insert(id)
        }
    }

    func toggleTarget(_ revisionID: String) {
        if selectedTargetRevisionIDs.contains(revisionID) {
            selectedTargetRevisionIDs.remove(revisionID)
        } else {
            selectedTargetRevisionIDs.insert(revisionID)
            selectedReferenceRevisionIDs.remove(revisionID)
        }
    }

    func toggleReference(_ revisionID: String) {
        if selectedReferenceRevisionIDs.contains(revisionID) {
            selectedReferenceRevisionIDs.remove(revisionID)
        } else {
            selectedReferenceRevisionIDs.insert(revisionID)
            selectedTargetRevisionIDs.remove(revisionID)
        }
    }

    private func makePlanRequest() -> GlifiStudioAnalysisPlanRequest {
        GlifiStudioAnalysisPlanRequest(
            intent: selectedIntent.rawValue,
            scopeSourceRevisionIDs: [],
            targetSourceRevisionIDs: Array(selectedTargetRevisionIDs).sorted(),
            referenceSourceRevisionIDs: Array(selectedReferenceRevisionIDs).sorted()
        )
    }

    private func initializePackage(at url: URL, replaceExisting: Bool) async throws {
        if replaceExisting, FileManager.default.fileExists(atPath: url.path) {
            let manifest = url.appending(path: "manifest.json")
            let isEmptyPackage =
                (try? FileManager.default.contentsOfDirectory(atPath: url.path))?.isEmpty == true
            let isIncomplete = !FileManager.default.fileExists(atPath: manifest.path)
            if isEmptyPackage || isIncomplete {
                try FileManager.default.removeItem(at: url)
            } else if replaceExisting {
                try FileManager.default.removeItem(at: url)
            }
        }
        await closeSession()
        let created = try await service.createProject(at: url)
        session = created
        projectURL = url
        rememberProject(url)
        snapshot = try await created.snapshot()
        clearAnalysisState()
    }

    private func requireSession() throws -> GlifiStudioProjectSession {
        guard let session else {
            throw presentationFailure(messageKey: "failure.project.none-open")
        }
        return session
    }

    private func clearAnalysisState() {
        lastProfile = nil
        lastImportedFileName = nil
        planResult = nil
        executionResult = nil
        executionProgress = nil
        investigation = nil
        investigationHeads = []
        queryResult = nil
        selectedQueryMatchID = nil
        sourceText = nil
        exportReceipt = nil
        selectedFindingID = nil
        selectedTargetRevisionIDs = []
        selectedReferenceRevisionIDs = []
        editorialSelectedFindingIDs = []
        failureMessageKey = nil
    }

    private func rememberProject(_ url: URL) {
        lastProjectBookmark = try? url.bookmarkData(
            options: [.withSecurityScope, .minimalBookmark],
            includingResourceValuesForKeys: nil,
            relativeTo: nil
        )
    }

    private func closeSession() async {
        activeExecution?.cancel()
        activeExecution = nil
        await session?.close()
        session = nil
    }

    private func run(messageKey: String, operation: () async throws -> Void) async {
        busyState = .working(messageKey: messageKey)
        failureMessageKey = nil
        defer { busyState = .idle }
        do {
            try await operation()
        } catch let failure as GlifiStudioFailure {
            failureMessageKey = failure.messageKey
        } catch {
            failureMessageKey = "failure.internal.unexpected"
        }
    }

    private func presentationFailure(messageKey: String) -> GlifiStudioFailure {
        GlifiStudioFailure(
            code: "ui.\(messageKey)",
            category: "invalidInput",
            operation: "present",
            retryDisposition: "afterCorrection",
            retainedState: "lastCommittedGeneration",
            messageKey: messageKey
        )
    }

    private static func projectsRoot() throws -> URL {
        let base = try FileManager.default.url(
            for: .documentDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        return base.appending(path: "Glifi Studio", directoryHint: .isDirectory)
    }

    private static func sanitizeFileName(_ raw: String) -> String {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-_ "))
        let filtered = String(trimmed.unicodeScalars.map { allowed.contains($0) ? Character($0) : "-" })
        let collapsed = filtered
            .split(whereSeparator: { $0 == "-" || $0 == " " })
            .joined(separator: "-")
        return collapsed.isEmpty ? "Progetto" : String(collapsed.prefix(64))
    }
}
