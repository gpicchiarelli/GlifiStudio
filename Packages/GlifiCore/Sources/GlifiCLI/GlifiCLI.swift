// SPDX-License-Identifier: BSD-3-Clause

import Darwin
import Foundation
import GlifiKit

@main
enum GlifiCLI {
    static func main() async {
        do {
            let request = try CLIRequest(arguments: Array(CommandLine.arguments.dropFirst()))
            try await execute(request)
        } catch is CLIUsageError {
            writeStandardError(CLIRequest.usage)
            exit(2)
        } catch let failure as GlifiStudioFailure {
            writeFailure(failure)
            exit(exitCode(for: failure.category))
        } catch {
            let failure = CLIError.internalFailure
            writeFailure(failure)
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

    private static func writeFailure(_ failure: GlifiStudioFailure) {
        let arguments = Array(failure.arguments).sorted { $0.key < $1.key }.map {
            FailureArgument(key: $0.key, value: $0.value)
        }
        let envelope = FailureEnvelope(
            command: "unknown",
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
          glifi [--format text|json] status
          glifi [--format text|json] project create <progetto.glifi>
          glifi [--format text|json] project info <progetto.glifi>
          glifi [--format text|json] project validate <progetto.glifi>
          glifi [--format text|json] import <progetto.glifi> <fonte.txt>...
        """ + "\n"

    let format: CLIOutputFormat
    let command: CLICommand

    init(arguments: [String]) throws {
        if arguments.isEmpty {
            format = .text
            command = .status
            return
        }

        var remaining = arguments
        var resolvedFormat = CLIOutputFormat.text
        if remaining.first == "--format" {
            guard remaining.count >= 3,
                let candidate = CLIOutputFormat(rawValue: remaining[1])
            else {
                throw CLIUsageError.invalidArguments
            }
            resolvedFormat = candidate
            remaining.removeFirst(2)
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
        } else {
            throw CLIUsageError.invalidArguments
        }
        format = resolvedFormat
    }
}

private enum CLICommand {
    case status
    case projectCreate(URL)
    case projectInfo(URL)
    case projectValidate(URL)
    case importSources(URL, [URL])

    var name: String {
        switch self {
        case .status: "status"
        case .projectCreate: "project.create"
        case .projectInfo: "project.info"
        case .projectValidate: "project.validate"
        case .importSources: "import"
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

    init(_ project: GlifiStudioProjectSnapshot) {
        projectID = project.projectID
        generation = project.generation
        sourceCount = project.sourceCount
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
