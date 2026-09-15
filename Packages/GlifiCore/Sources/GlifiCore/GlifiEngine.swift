// SPDX-License-Identifier: BSD-3-Clause

import Foundation

/// Describes the operational state of the GlifiCore engine.
public enum GlifiEngineStatus: String, Sendable, Equatable {
    /// The engine is available to accept work.
    case ready
}

/// Provides the headless entry point to GlifiCore capabilities.
public actor GlifiEngine {
    private let defaultLanguageConfiguration: GlifiLanguageConfiguration
    private let textImporter: GlifiTextImporter
    private let textAnalyzer: GlifiTextAnalyzer
    private var hasReportedReady = false

    /// Creates an engine with no persistent project attached.
    ///
    /// - Parameters:
    ///   - defaultLanguageConfiguration: Language used when a project has no explicit setting.
    ///   - textImporter: Strict, bounded ingestion implementation.
    ///   - tokenizer: Replaceable linguistic tokenizer.
    public init(
        defaultLanguageConfiguration: GlifiLanguageConfiguration = .italian,
        textImporter: GlifiTextImporter = GlifiTextImporter(),
        tokenizer: any GlifiTokenizing = GlifiItalianTokenizer()
    ) {
        self.defaultLanguageConfiguration = defaultLanguageConfiguration
        self.textImporter = textImporter
        textAnalyzer = GlifiTextAnalyzer(tokenizer: tokenizer)
    }

    /// Returns the language used when a project has no explicit configuration.
    public func languageConfiguration() -> GlifiLanguageConfiguration {
        defaultLanguageConfiguration
    }

    /// Returns the current operational state of the engine.
    public func status() -> GlifiEngineStatus {
        if !hasReportedReady {
            let conditions = GlifiSystemConditions.current()
            let recommendation = GlifiRuntimePolicy.recommendation(
                for: .interactive,
                conditions: conditions
            )
            GlifiDiagnostics.record(.engineReady(profile: recommendation.profile))
            hasReportedReady = true
        }

        return .ready
    }

    /// Imports and profiles one bounded UTF-8 text snapshot off the presentation actor.
    public func profileText(
        data: Data,
        format: GlifiTextFormat,
        limits: GlifiTextImportLimits = .standard
    ) throws -> GlifiTextProfile {
        do {
            try Task.checkCancellation()
            let importedText = try GlifiDiagnostics.measure(.importSources) {
                try textImporter.importText(from: data, format: format, limits: limits)
            }
            let profile = try GlifiDiagnostics.measure(.tokenize) {
                try textAnalyzer.profile(importedText)
            }
            try Task.checkCancellation()
            return profile
        } catch is CancellationError {
            throw GlifiFailure(
                code: "operation.cancelled",
                category: .cancelled,
                operation: .profileCollection,
                retryDisposition: .newRequest,
                retainedState: .unchanged,
                messageKey: "failure.operation.cancelled"
            )
        }
    }

    /// Reads and profiles one user-authorized file while keeping file I/O off the Main Actor.
    public func profileText(
        at url: URL,
        format: GlifiTextFormat,
        limits: GlifiTextImportLimits = .standard
    ) throws -> GlifiTextProfile {
        do {
            try Task.checkCancellation()
            let values = try url.resourceValues(forKeys: [
                .fileSizeKey,
                .isRegularFileKey,
                .isSymbolicLinkKey,
            ])
            guard values.isRegularFile == true, values.isSymbolicLink != true else {
                throw GlifiFailure(
                    code: "file.not-regular",
                    category: .invalidInput,
                    operation: .importText,
                    retryDisposition: .afterCorrection,
                    retainedState: .unchanged,
                    messageKey: "failure.file.not-regular"
                )
            }
            if let fileSize = values.fileSize, fileSize > limits.maximumByteCount {
                throw GlifiFailure(
                    code: "text.byte-limit-exceeded",
                    category: .insufficientResources,
                    operation: .importText,
                    retryDisposition: .afterCorrection,
                    retainedState: .unchanged,
                    messageKey: "failure.text.byte-limit-exceeded",
                    arguments: ["maximumByteCount": String(limits.maximumByteCount)]
                )
            }

            let data = try GlifiDiagnostics.measure(.importSources) {
                try Data(contentsOf: url, options: [.mappedIfSafe, .uncached])
            }
            return try profileText(data: data, format: format, limits: limits)
        } catch let failure as GlifiFailure {
            throw failure
        } catch is CancellationError {
            throw GlifiFailure(
                code: "operation.cancelled",
                category: .cancelled,
                operation: .profileCollection,
                retryDisposition: .newRequest,
                retainedState: .unchanged,
                messageKey: "failure.operation.cancelled"
            )
        } catch {
            throw GlifiFailure(
                code: "file.unreadable",
                category: .transientIO,
                operation: .importText,
                retryDisposition: .transientBackoff,
                retainedState: .unchanged,
                messageKey: "failure.file.unreadable"
            )
        }
    }
}
