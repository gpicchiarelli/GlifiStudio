// SPDX-License-Identifier: BSD-3-Clause

import Foundation

/// Describes the operational state of the GlifiCore engine.
public enum GlifiEngineStatus: String, Sendable, Equatable {
    /// The engine is available to accept work.
    case ready
}

/// Durable project snapshot and descriptive profile produced by one import.
public struct GlifiProjectTextImportResult: Equatable, Sendable {
    /// Verified generation committed by the import.
    public let project: GlifiProjectSnapshot
    /// Deterministic profile derived from the same immutable source bytes.
    public let profile: GlifiTextProfile

    /// Creates an import outcome whose project and profile share the same source revision.
    public init(project: GlifiProjectSnapshot, profile: GlifiTextProfile) {
        self.project = project
        self.profile = profile
    }
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
            let profile = try profile(importedText)
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
            let importedText = try GlifiDiagnostics.measure(.importSources) {
                try importText(at: url, format: format, limits: limits)
            }
            return try profile(importedText)
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

    /// Creates an empty verified `.glifi` package.
    public func createProject(at url: URL) throws -> GlifiProjectPackage {
        try GlifiProjectPackage.create(at: url)
    }

    /// Opens an existing `.glifi` package after complete root verification.
    public func openProject(at url: URL) throws -> GlifiProjectPackage {
        try GlifiProjectPackage.open(at: url)
    }

    /// Validates, profiles, and transactionally incorporates one text source.
    public func importText(
        at url: URL,
        format: GlifiTextFormat,
        into project: GlifiProjectPackage,
        limits: GlifiTextImportLimits = .standard
    ) async throws -> GlifiProjectTextImportResult {
        do {
            try Task.checkCancellation()
            let importedText = try GlifiDiagnostics.measure(.importSources) {
                try importText(at: url, format: format, limits: limits)
            }
            let textProfile = try profile(importedText)
            try Task.checkCancellation()
            let snapshot = try await project.importText(importedText)
            return GlifiProjectTextImportResult(project: snapshot, profile: textProfile)
        } catch let failure as GlifiFailure {
            throw failure
        } catch is CancellationError {
            throw cancellationFailure()
        } catch {
            throw unreadableFileFailure()
        }
    }

    private func importText(
        at url: URL,
        format: GlifiTextFormat,
        limits: GlifiTextImportLimits
    ) throws -> GlifiImportedText {
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
        let data = try Data(contentsOf: url, options: [.mappedIfSafe, .uncached])
        return try textImporter.importText(from: data, format: format, limits: limits)
    }

    private func profile(_ importedText: GlifiImportedText) throws -> GlifiTextProfile {
        try GlifiDiagnostics.measure(.tokenize) {
            try textAnalyzer.profile(importedText)
        }
    }

    private func cancellationFailure() -> GlifiFailure {
        GlifiFailure(
            code: "operation.cancelled",
            category: .cancelled,
            operation: .profileCollection,
            retryDisposition: .newRequest,
            retainedState: .unchanged,
            messageKey: "failure.operation.cancelled"
        )
    }

    private func unreadableFileFailure() -> GlifiFailure {
        GlifiFailure(
            code: "file.unreadable",
            category: .transientIO,
            operation: .importText,
            retryDisposition: .transientBackoff,
            retainedState: .unchanged,
            messageKey: "failure.file.unreadable"
        )
    }
}
