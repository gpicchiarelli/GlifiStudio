// SPDX-License-Identifier: BSD-3-Clause

import Darwin
import Foundation
import GlifiKit

@main
enum GlifiCLI {
    static func main() async {
        var commandName = "unknown"
        do {
            let request = try CLIRequest(arguments: Array(CommandLine.arguments.dropFirst()))
            commandName = request.command.name
            try await execute(request)
        } catch is CLIUsageError {
            writeStandardError(CLIRequest.usage)
            exit(2)
        } catch let failure as GlifiStudioFailure {
            writeFailure(failure, command: commandName)
            exit(exitCode(for: failure.category))
        } catch {
            let failure = CLIError.internalFailure
            writeFailure(failure, command: commandName)
            exit(70)
        }
    }

    private static func execute(_ request: CLIRequest) async throws {
        let service = GlifiStudioService()
        switch request.command {
        case .status:
            let status = await service.status()
            switch request.format {
            case .text:
                print("GlifiCore pronto")
            case .json:
                try writeJSON(
                    SuccessEnvelope(
                        command: request.command.name, result: StatusResult(status: status))
                )
            }
        case let .projectCreate(projectURL):
            let session = try await service.createProject(at: projectURL)
            let snapshot = try await session.snapshot()
            await session.close()
            try writeProjectResult(snapshot, request: request, action: "creato")
        case let .projectInfo(projectURL):
            let session = try await service.openProject(at: projectURL)
            let snapshot = try await session.snapshot()
            await session.close()
            try writeProjectResult(snapshot, request: request, action: "valido")
        case let .projectValidate(projectURL):
            let session = try await service.openProject(at: projectURL)
            let snapshot = try await session.snapshot()
            await session.close()
            switch request.format {
            case .text:
                print("Progetto valido · generazione \(snapshot.generation)")
            case .json:
                try writeJSON(
                    SuccessEnvelope(
                        command: request.command.name,
                        result: ProjectValidationResult(project: snapshot, status: "valid")
                    )
                )
            }
        case let .importSources(projectURL, sourceURLs):
            let session = try await service.openProject(at: projectURL)
            var lastResult: GlifiStudioProjectImportResult?
            for sourceURL in sourceURLs {
                try Task.checkCancellation()
                lastResult = try await session.importText(
                    at: sourceURL,
                    format: sourceURL.pathExtension.lowercased() == "txt" ? .plainText : .markdown
                )
            }
            await session.close()
            guard let lastResult else {
                throw CLIUsageError.invalidArguments
            }
            switch request.format {
            case .text:
                print(
                    "Importazione completata · generazione \(lastResult.project.generation) · \(lastResult.project.sourceCount) fonti"
                )
            case .json:
                try writeJSON(
                    SuccessEnvelope(
                        command: request.command.name,
                        result: ImportResult(
                            project: lastResult.project,
                            importedSourceCount: sourceURLs.count,
                            lastProfile: lastResult.profile
                        )
                    )
                )
            }
        case let .query(projectURL, queryText):
            let session = try await service.openProject(at: projectURL)
            let result = try await session.query(queryText)
            await session.close()
            switch request.format {
            case .text:
                for match in result.matches {
                    print("\(match.leftContext)\t\(match.match)\t\(match.rightContext)")
                }
                if result.isTruncated {
                    writeStandardError("Risultati troncati dal limite dichiarato.\n")
                }
            case .json:
                try writeJSON(
                    SuccessEnvelope(
                        command: request.command.name,
                        result: QueryResult(result)
                    )
                )
            }
        case let .plan(projectURL, requestURL):
            let planRequest = try readPlanRequest(at: requestURL)
            let session = try await service.openProject(at: projectURL)
            let result = try await session.planAnalysis(planRequest)
            await session.close()
            switch request.format {
            case .text:
                print(
                    "Piano \(result.plan.status) · generazione \(result.generation) · \(result.plan.steps.count) passi · costo stimato \(result.plan.totalEstimatedWorkUnits)"
                )
                for decision in result.plan.decisions {
                    print(
                        "\(decision.capabilityIdentifier)\t\(decision.applicability)\t\(decision.reasonIdentifiers.joined(separator: ","))"
                    )
                }
            case .json:
                try writeJSON(
                    SuccessEnvelope(command: request.command.name, result: result)
                )
            }
        case let .executePlan(projectURL, requestURL):
            let planRequest = try readPlanRequest(at: requestURL, operation: "executePlan")
            let session = try await service.openProject(at: projectURL)
            do {
                let execution = try await session.executeAnalysisPlan(planRequest)
                var completedResult: GlifiStudioAnalysisExecutionResult?
                for try await event in execution.events {
                    switch event {
                    case let .progress(progress):
                        if request.format == .text, request.showsProgress {
                            writeExecutionProgress(progress)
                        }
                    case let .completed(result):
                        guard completedResult == nil else {
                            throw CLIError.internalFailure
                        }
                        completedResult = result
                    }
                }
                guard let completedResult else {
                    throw CLIError.internalFailure
                }
                await session.close()
                switch request.format {
                case .text:
                    let interpretationSummary =
                        completedResult.interpretation.insufficientEvidence == nil
                        ? "\(completedResult.interpretation.findings.count) Finding"
                        : "evidenza insufficiente"
                    print(
                        "Piano eseguito · \(completedResult.terminalState) · generazione \(completedResult.generation) · \(completedResult.artifacts.count) Artifact analitici · \(interpretationSummary)"
                    )
                case .json:
                    try writeJSON(
                        SuccessEnvelope(
                            command: request.command.name,
                            result: completedResult
                        )
                    )
                }
            } catch {
                await session.close()
                throw error
            }
        case let .investigationCreate(projectURL, requestURL):
            let creationRequest: GlifiStudioInvestigationCreationRequest = try readRequest(
                at: requestURL,
                operation: "investigate"
            )
            let session = try await service.openProject(at: projectURL)
            let result = try await session.createInvestigation(creationRequest)
            await session.close()
            switch request.format {
            case .text:
                print(
                    "Indagine creata · generazione \(result.generation) · \(result.investigation.selectedFindingIDs.count) finding selezionati"
                )
            case .json:
                try writeJSON(SuccessEnvelope(command: request.command.name, result: result))
            }
        case let .investigationSelect(projectURL, requestURL):
            let selectionRequest: GlifiStudioInvestigationSelectionRequest = try readRequest(
                at: requestURL,
                operation: "investigate"
            )
            let session = try await service.openProject(at: projectURL)
            let result = try await session.reviseInvestigationSelection(selectionRequest)
            await session.close()
            switch request.format {
            case .text:
                print(
                    "Selezione aggiornata · generazione \(result.generation) · \(result.investigation.selectedFindingIDs.count) finding"
                )
            case .json:
                try writeJSON(SuccessEnvelope(command: request.command.name, result: result))
            }
        case let .investigationList(projectURL):
            let session = try await service.openProject(at: projectURL)
            let heads = try await session.investigationHeads()
            await session.close()
            switch request.format {
            case .text:
                for head in heads {
                    print("\(head.id)\t\(head.headEventID)\t\(head.question)")
                }
            case .json:
                try writeJSON(SuccessEnvelope(command: request.command.name, result: heads))
            }
        case let .exportInvestigation(projectURL, requestURL, outputURL):
            let exportRequest: GlifiStudioScientificExportRequest = try readRequest(
                at: requestURL,
                operation: "export"
            )
            let session = try await service.openProject(at: projectURL)
            do {
                let receipt = try await session.exportInvestigation(
                    exportRequest,
                    to: outputURL
                )
                await session.close()
                switch request.format {
                case .text:
                    print(
                        "Esportazione verificata · \(receipt.fileCount) file · manifest \(receipt.manifestDigest)"
                    )
                case .json:
                    try writeJSON(
                        SuccessEnvelope(command: request.command.name, result: receipt)
                    )
                }
            } catch {
                await session.close()
                throw error
            }
        case let .analyze(projectURL):
            let session = try await service.openProject(at: projectURL)
            let result = try await session.analyzeCorpus()
            await session.close()
            switch request.format {
            case .text:
                print(
                    "Corpus analizzato · generazione \(result.generation) · \(result.documentCount) documenti · \(result.sentenceCount) frasi · \(result.lexicalTokenCount) token · \(result.typeCount) type"
                )
                for term in result.terms.prefix(20) {
                    print(
                        "\(term.term)\t\(term.frequency)\tdf=\(term.documentFrequency)\tDP=\(term.griesDP)"
                    )
                }
            case .json:
                try writeJSON(
                    SuccessEnvelope(command: request.command.name, result: result)
                )
            }
        case let .keyness(projectURL, targetSourceRevisionIDs, referenceSourceRevisionIDs):
            let session = try await service.openProject(at: projectURL)
            let result = try await session.compareKeyness(
                targetSourceRevisionIDs: targetSourceRevisionIDs,
                referenceSourceRevisionIDs: referenceSourceRevisionIDs
            )
            await session.close()
            switch request.format {
            case .text:
                print(
                    "Keyness calcolata · generazione \(result.generation) · \(result.targetTokenCount) token target · \(result.referenceTokenCount) token riferimento"
                )
                for term in result.terms.prefix(20) {
                    print(
                        "\(term.term)\tG=\(term.gStatistic)\tp=\(term.pValue)\tq=\(term.qValue)\tlog2=\(term.log2RatioHaldaneAnscombe)\t\(term.direction)"
                    )
                }
            case .json:
                try writeJSON(
                    SuccessEnvelope(command: request.command.name, result: result)
                )
            }
        }
    }

    private static func writeProjectResult(
        _ snapshot: GlifiStudioProjectSnapshot,
        request: CLIRequest,
        action: String
    ) throws {
        switch request.format {
        case .text:
            print(
                "Progetto \(action) · generazione \(snapshot.generation) · \(snapshot.sourceCount) fonti"
            )
        case .json:
            try writeJSON(
                SuccessEnvelope(
                    command: request.command.name,
                    result: ProjectResult(project: snapshot)
                )
            )
        }
    }

    private static func readPlanRequest(
        at url: URL,
        operation: String = "plan"
    ) throws -> GlifiStudioAnalysisPlanRequest {
        let maximumByteCount = 1_048_576
        do {
            let values = try url.resourceValues(forKeys: [.fileSizeKey, .isRegularFileKey])
            guard values.isRegularFile == true else {
                throw planRequestFailure(
                    code: "planner.request-not-regular-file",
                    category: "invalidInput",
                    retryDisposition: "afterCorrection",
                    operation: operation
                )
            }
            guard let fileSize = values.fileSize, fileSize <= maximumByteCount else {
                throw planRequestFailure(
                    code: "planner.request-too-large",
                    category: "insufficientResources",
                    retryDisposition: "afterCorrection",
                    operation: operation
                )
            }
            let data = try Data(contentsOf: url, options: .mappedIfSafe)
            guard data.count <= maximumByteCount else {
                throw planRequestFailure(
                    code: "planner.request-too-large",
                    category: "insufficientResources",
                    retryDisposition: "afterCorrection",
                    operation: operation
                )
            }
            do {
                return try JSONDecoder().decode(GlifiStudioAnalysisPlanRequest.self, from: data)
            } catch {
                throw planRequestFailure(
                    code: "planner.request-invalid",
                    category: "invalidInput",
                    retryDisposition: "afterCorrection",
                    operation: operation
                )
            }
        } catch let failure as GlifiStudioFailure {
            throw failure
        } catch {
            throw planRequestFailure(
                code: "planner.request-unreadable",
                category: "transientIO",
                retryDisposition: "transientBackoff",
                operation: operation
            )
        }
    }

    private static func readRequest<Value: Decodable>(
        at url: URL,
        operation: String
    ) throws -> Value {
        let maximumByteCount = 1_048_576
        do {
            let values = try url.resourceValues(forKeys: [.fileSizeKey, .isRegularFileKey])
            guard values.isRegularFile == true,
                let fileSize = values.fileSize,
                fileSize <= maximumByteCount
            else {
                throw planRequestFailure(
                    code: "request.invalid-file",
                    category: "invalidInput",
                    retryDisposition: "afterCorrection",
                    operation: operation
                )
            }
            let data = try Data(contentsOf: url, options: .mappedIfSafe)
            guard data.count <= maximumByteCount else {
                throw planRequestFailure(
                    code: "request.too-large",
                    category: "insufficientResources",
                    retryDisposition: "afterCorrection",
                    operation: operation
                )
            }
            return try JSONDecoder().decode(Value.self, from: data)
        } catch let failure as GlifiStudioFailure {
            throw failure
        } catch {
            throw planRequestFailure(
                code: "request.invalid",
                category: "invalidInput",
                retryDisposition: "afterCorrection",
                operation: operation
            )
        }
    }

    private static func planRequestFailure(
        code: String,
        category: String,
        retryDisposition: String,
        operation: String = "plan"
    ) -> GlifiStudioFailure {
        GlifiStudioFailure(
            code: code,
            category: category,
            operation: operation,
            retryDisposition: retryDisposition,
            retainedState: "lastCommittedGeneration",
            messageKey: "failure.\(code)"
        )
    }

    private static func writeFailure(_ failure: GlifiStudioFailure, command: String) {
        let arguments = Array(failure.arguments).sorted { $0.key < $1.key }.map {
            FailureArgument(key: $0.key, value: $0.value)
        }
        let envelope = FailureEnvelope(
            command: command,
            failure: FailureResult(
                code: failure.code,
                category: failure.category,
                operation: failure.operation,
                retryDisposition: failure.retryDisposition,
                retainedState: failure.retainedState,
                messageKey: failure.messageKey,
                arguments: arguments
            )
        )
        if let data = try? encodedJSON(envelope) {
            FileHandle.standardError.write(data)
        } else {
            writeStandardError("Errore interno non serializzabile\n")
        }
    }

    private static func writeJSON(_ value: some Encodable) throws {
        FileHandle.standardOutput.write(try encodedJSON(value))
    }

    private static func encodedJSON(_ value: some Encodable) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
        var data = try encoder.encode(value)
        data.append(0x0A)
        return data
    }

    private static func writeStandardError(_ message: String) {
        FileHandle.standardError.write(Data(message.utf8))
    }

    private static func writeExecutionProgress(_ progress: GlifiStudioOperationProgress) {
        let total = progress.total.map(String.init) ?? "?"
        let step = progress.planStepIdentifier.map { " · \($0)" } ?? ""
        writeStandardError(
            "\(progress.phase) · \(progress.completed)/\(total) \(progress.unit)\(step)\n"
        )
    }

    private static func exitCode(for category: String) -> Int32 {
        switch category {
        case "invalidInput": 3
        case "unsupportedFormat": 4
        case "insufficientData": 5
        case "transientIO", "authorizationDenied": 6
        case "insufficientResources": 7
        case "cancelled": 8
        case "staleArtifact": 9
        case "incompatibleVersion": 10
        case "corruption": 11
        default: 70
        }
    }
}

private struct CLIRequest {
    static let usage = """
        Uso:
          glifi [--format text|json] [--no-progress] status
          glifi [--format text|json] [--no-progress] project create <progetto.glifi>
          glifi [--format text|json] [--no-progress] project info <progetto.glifi>
          glifi [--format text|json] [--no-progress] project validate <progetto.glifi>
          glifi [--format text|json] [--no-progress] import <progetto.glifi> <fonte.txt>...
          glifi [--format text|json] [--no-progress] query <progetto.glifi> --text <query>
          glifi [--format text|json] [--no-progress] plan <progetto.glifi> --request <richiesta.json>
          glifi [--format text|json] [--no-progress] execute <progetto.glifi> --request <richiesta.json>
          glifi [--format text|json] [--no-progress] investigation create <progetto.glifi> --request <richiesta.json>
          glifi [--format text|json] [--no-progress] investigation select <progetto.glifi> --request <richiesta.json>
          glifi [--format text|json] [--no-progress] investigation list <progetto.glifi>
          glifi [--format text|json] [--no-progress] export <progetto.glifi> --request <richiesta.json> --output <cartella>
          glifi [--format text|json] [--no-progress] analyze <progetto.glifi>
          glifi [--format text|json] [--no-progress] keyness <progetto.glifi> --target <source-revision-id,...> --reference <source-revision-id,...>
        """ + "\n"

    let format: CLIOutputFormat
    let showsProgress: Bool
    let command: CLICommand

    init(arguments: [String]) throws {
        if arguments.isEmpty {
            format = .text
            showsProgress = true
            command = .status
            return
        }

        var remaining = arguments
        var resolvedFormat = CLIOutputFormat.text
        var resolvedShowsProgress = true
        var didResolveFormat = false
        var didResolveProgress = false
        while let option = remaining.first, option.hasPrefix("--") {
            switch option {
            case "--format":
                guard !didResolveFormat, remaining.count >= 2,
                    let candidate = CLIOutputFormat(rawValue: remaining[1])
                else {
                    throw CLIUsageError.invalidArguments
                }
                resolvedFormat = candidate
                didResolveFormat = true
                remaining.removeFirst(2)
            case "--no-progress":
                guard !didResolveProgress else {
                    throw CLIUsageError.invalidArguments
                }
                resolvedShowsProgress = false
                didResolveProgress = true
                remaining.removeFirst()
            default:
                throw CLIUsageError.invalidArguments
            }
        }

        if remaining == ["status"] {
            command = .status
        } else if remaining.count == 3, remaining[0] == "project", remaining[1] == "create" {
            command = .projectCreate(URL(fileURLWithPath: remaining[2]).standardizedFileURL)
        } else if remaining.count == 3, remaining[0] == "project", remaining[1] == "info" {
            command = .projectInfo(URL(fileURLWithPath: remaining[2]).standardizedFileURL)
        } else if remaining.count == 3,
            remaining[0] == "project",
            remaining[1] == "validate"
        {
            command = .projectValidate(URL(fileURLWithPath: remaining[2]).standardizedFileURL)
        } else if remaining.count >= 3, remaining.first == "import" {
            let projectURL = URL(fileURLWithPath: remaining[1]).standardizedFileURL
            let sourceURLs = remaining.dropFirst(2).map {
                URL(fileURLWithPath: $0).standardizedFileURL
            }
            guard
                sourceURLs.allSatisfy({
                    ["txt", "md", "markdown"].contains($0.pathExtension.lowercased())
                })
            else {
                throw CLIUsageError.invalidArguments
            }
            command = .importSources(projectURL, sourceURLs)
        } else if remaining.count == 4,
            remaining[0] == "query",
            remaining[2] == "--text"
        {
            command = .query(
                URL(fileURLWithPath: remaining[1]).standardizedFileURL,
                remaining[3]
            )
        } else if remaining.count == 2, remaining[0] == "analyze" {
            command = .analyze(URL(fileURLWithPath: remaining[1]).standardizedFileURL)
        } else if remaining.count == 4,
            remaining[0] == "plan",
            remaining[2] == "--request"
        {
            command = .plan(
                URL(fileURLWithPath: remaining[1]).standardizedFileURL,
                URL(fileURLWithPath: remaining[3]).standardizedFileURL
            )
        } else if remaining.count == 4,
            remaining[0] == "execute",
            remaining[2] == "--request"
        {
            command = .executePlan(
                URL(fileURLWithPath: remaining[1]).standardizedFileURL,
                URL(fileURLWithPath: remaining[3]).standardizedFileURL
            )
        } else if remaining.count == 5,
            remaining[0] == "investigation",
            remaining[1] == "create",
            remaining[3] == "--request"
        {
            command = .investigationCreate(
                URL(fileURLWithPath: remaining[2]).standardizedFileURL,
                URL(fileURLWithPath: remaining[4]).standardizedFileURL
            )
        } else if remaining.count == 5,
            remaining[0] == "investigation",
            remaining[1] == "select",
            remaining[3] == "--request"
        {
            command = .investigationSelect(
                URL(fileURLWithPath: remaining[2]).standardizedFileURL,
                URL(fileURLWithPath: remaining[4]).standardizedFileURL
            )
        } else if remaining.count == 3,
            remaining[0] == "investigation",
            remaining[1] == "list"
        {
            command = .investigationList(
                URL(fileURLWithPath: remaining[2]).standardizedFileURL
            )
        } else if remaining.count == 6, remaining[0] == "export" {
            let values: (request: String, output: String)
            if remaining[2] == "--request", remaining[4] == "--output" {
                values = (remaining[3], remaining[5])
            } else if remaining[2] == "--output", remaining[4] == "--request" {
                values = (remaining[5], remaining[3])
            } else {
                throw CLIUsageError.invalidArguments
            }
            command = .exportInvestigation(
                URL(fileURLWithPath: remaining[1]).standardizedFileURL,
                URL(fileURLWithPath: values.request).standardizedFileURL,
                URL(fileURLWithPath: values.output).standardizedFileURL
            )
        } else if remaining.count == 6, remaining[0] == "keyness" {
            let groups: (target: String, reference: String)
            if remaining[2] == "--target", remaining[4] == "--reference" {
                groups = (remaining[3], remaining[5])
            } else if remaining[2] == "--reference", remaining[4] == "--target" {
                groups = (remaining[5], remaining[3])
            } else {
                throw CLIUsageError.invalidArguments
            }
            command = .keyness(
                URL(fileURLWithPath: remaining[1]).standardizedFileURL,
                try Self.identifiers(groups.target),
                try Self.identifiers(groups.reference)
            )
        } else {
            throw CLIUsageError.invalidArguments
        }
        format = resolvedFormat
        showsProgress = resolvedShowsProgress
    }

    private static func identifiers(_ value: String) throws -> [String] {
        let identifiers = value.split(separator: ",", omittingEmptySubsequences: false).map(
            String.init
        )
        guard !identifiers.isEmpty, identifiers.allSatisfy({ !$0.isEmpty }) else {
            throw CLIUsageError.invalidArguments
        }
        return identifiers
    }
}

private enum CLICommand {
    case status
    case projectCreate(URL)
    case projectInfo(URL)
    case projectValidate(URL)
    case importSources(URL, [URL])
    case query(URL, String)
    case plan(URL, URL)
    case executePlan(URL, URL)
    case investigationCreate(URL, URL)
    case investigationSelect(URL, URL)
    case investigationList(URL)
    case exportInvestigation(URL, URL, URL)
    case analyze(URL)
    case keyness(URL, [String], [String])

    var name: String {
        switch self {
        case .status: "status"
        case .projectCreate: "project.create"
        case .projectInfo: "project.info"
        case .projectValidate: "project.validate"
        case .importSources: "import"
        case .query: "query"
        case .plan: "plan"
        case .executePlan: "execute"
        case .investigationCreate: "investigation.create"
        case .investigationSelect: "investigation.select"
        case .investigationList: "investigation.list"
        case .exportInvestigation: "export"
        case .analyze: "analyze"
        case .keyness: "keyness"
        }
    }
}

private enum CLIOutputFormat: String {
    case text
    case json
}

private enum CLIUsageError: Error {
    case invalidArguments
}

private enum CLIError {
    static let internalFailure = GlifiStudioFailure(
        code: "internal.unexpected",
        category: "invariantViolation",
        operation: "serviceStatus",
        retryDisposition: "never",
        retainedState: "validityUnknown",
        messageKey: "failure.internal.unexpected",
        arguments: [:]
    )
}

private struct SuccessEnvelope<Result: Encodable>: Encodable {
    let cliProtocolVersion = 1
    let command: String
    let outcome = "succeeded"
    let result: Result
}

private struct FailureEnvelope: Encodable {
    let cliProtocolVersion = 1
    let command: String
    let outcome = "failed"
    let failure: FailureResult
}

private struct FailureResult: Encodable {
    let code: String
    let category: String
    let operation: String
    let retryDisposition: String
    let retainedState: String
    let messageKey: String
    let arguments: [FailureArgument]
}

private struct FailureArgument: Encodable {
    let key: String
    let value: String
}

private struct StatusResult: Encodable {
    let status: String

    init(status: GlifiStudioStatus) {
        self.status = status.rawValue
    }
}

private struct ProjectResult: Encodable {
    let project: ProjectSnapshotResult

    init(project: GlifiStudioProjectSnapshot) {
        self.project = ProjectSnapshotResult(project)
    }
}

private struct ProjectValidationResult: Encodable {
    let project: ProjectSnapshotResult
    let status: String

    init(project: GlifiStudioProjectSnapshot, status: String) {
        self.project = ProjectSnapshotResult(project)
        self.status = status
    }
}

private struct ProjectSnapshotResult: Encodable {
    let projectID: String
    let generation: Int
    let sourceCount: Int
    let artifactCount: Int
    let investigationEventCount: Int
    let sources: [ProjectSourceResult]

    init(_ project: GlifiStudioProjectSnapshot) {
        projectID = project.projectID
        generation = project.generation
        sourceCount = project.sourceCount
        artifactCount = project.artifactCount
        investigationEventCount = project.investigationEventCount
        sources = project.sources.map(ProjectSourceResult.init)
    }
}

private struct ProjectSourceResult: Encodable {
    let sourceID: String
    let sourceRevisionID: String
    let format: String
    let contentDigest: String
    let byteCount: Int

    init(_ source: GlifiStudioProjectSource) {
        sourceID = source.sourceID
        sourceRevisionID = source.sourceRevisionID
        format = source.format.rawValue
        contentDigest = source.contentDigest
        byteCount = source.byteCount
    }
}

private struct ImportResult: Encodable {
    let project: ProjectSnapshotResult
    let importedSourceCount: Int
    let lastProfile: TextProfileResult

    init(
        project: GlifiStudioProjectSnapshot,
        importedSourceCount: Int,
        lastProfile: GlifiStudioTextProfile
    ) {
        self.project = ProjectSnapshotResult(project)
        self.importedSourceCount = importedSourceCount
        self.lastProfile = TextProfileResult(lastProfile)
    }
}

private struct TextProfileResult: Encodable {
    let contentDigest: String
    let characterCount: Int
    let sentenceCount: Int
    let lexicalTokenCount: Int
    let typeCount: Int

    init(_ profile: GlifiStudioTextProfile) {
        contentDigest = profile.contentDigest
        characterCount = profile.characterCount
        sentenceCount = profile.sentenceCount
        lexicalTokenCount = profile.lexicalTokenCount
        typeCount = profile.typeCount
    }
}

private struct QueryResult: Encodable {
    let projectID: String
    let generation: Int
    let queryDigest: String
    let matchedSourceCount: Int
    let matches: [QueryMatchResult]
    let isTruncated: Bool

    init(_ result: GlifiStudioProjectQueryResult) {
        projectID = result.projectID
        generation = result.generation
        queryDigest = result.queryDigest
        matchedSourceCount = result.matchedSourceCount
        matches = result.matches.map(QueryMatchResult.init)
        isTruncated = result.isTruncated
    }
}

private struct QueryMatchResult: Encodable {
    let sourceRevisionID: String
    let coordinateSpace: String
    let startUTF8: Int
    let endUTF8: Int
    let sourceRanges: [GlifiStudioUTF8Range]
    let leftContext: String
    let match: String
    let rightContext: String

    init(_ match: GlifiStudioQueryMatch) {
        sourceRevisionID = match.sourceRevisionID
        coordinateSpace = match.coordinateSpace
        startUTF8 = match.startUTF8
        endUTF8 = match.endUTF8
        sourceRanges = match.sourceRanges
        leftContext = match.leftContext
        self.match = match.match
        rightContext = match.rightContext
    }
}
