// SPDX-License-Identifier: BSD-3-Clause

import Darwin
import Foundation
import GlifiKit

@main
enum GlifiCLI {
    static func main() async {
        do {
            let request = try CLIRequest(arguments: Array(CommandLine.arguments.dropFirst()))
            let status = await GlifiStudioService().status()
            switch request.format {
            case .text:
                switch status {
                case .ready:
                    print("GlifiCore pronto")
                }
            case .json:
                try writeJSON(StatusEnvelope(status: status))
            }
        } catch {
            writeStandardError("Uso: glifi [--format text|json] status\n")
            exit(2)
        }
    }

    private static func writeJSON(_ value: some Encodable) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
        var data = try encoder.encode(value)
        data.append(0x0A)
        FileHandle.standardOutput.write(data)
    }

    private static func writeStandardError(_ message: String) {
        FileHandle.standardError.write(Data(message.utf8))
    }
}

private struct CLIRequest {
    let format: CLIOutputFormat

    init(arguments: [String]) throws {
        if arguments.isEmpty {
            format = .text
            return
        }

        var resolvedFormat = CLIOutputFormat.text
        var command: String?
        var index = 0
        while index < arguments.count {
            switch arguments[index] {
            case "--format":
                guard index + 1 < arguments.count,
                    let candidate = CLIOutputFormat(rawValue: arguments[index + 1])
                else {
                    throw CLIUsageError.invalidArguments
                }
                resolvedFormat = candidate
                index += 2
            case "status" where command == nil:
                command = "status"
                index += 1
            default:
                throw CLIUsageError.invalidArguments
            }
        }

        guard command == "status" else {
            throw CLIUsageError.invalidArguments
        }
        format = resolvedFormat
    }
}

private enum CLIOutputFormat: String {
    case text
    case json
}

private enum CLIUsageError: Error {
    case invalidArguments
}

private struct StatusEnvelope: Encodable {
    let cliProtocolVersion = 1
    let command = "status"
    let outcome = "succeeded"
    let result: StatusResult

    init(status: GlifiStudioStatus) {
        result = StatusResult(status: status.rawValue)
    }
}

private struct StatusResult: Encodable {
    let status: String
}
