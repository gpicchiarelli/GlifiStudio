// SPDX-License-Identifier: BSD-3-Clause

import Foundation
import GlifiCore

/// Represents a stable, presentation-independent status exposed by GlifiKit.
public enum GlifiStudioStatus: String, Sendable, Equatable {
    /// The engine is ready to accept work.
    case ready
}

/// Text formats supported by the first product ingestion slice.
public enum GlifiStudioTextFormat: String, Codable, Sendable {
    case plainText
    case markdown
}

/// A bounded term-frequency row ready for presentation or machine clients.
public struct GlifiStudioTermFrequency: Equatable, Identifiable, Sendable {
    /// Stable row identity derived from the normalized term.
    public var id: String { term }
    /// Normalized term.
    public let term: String
    /// Exact occurrence count.
    public let count: Int

    /// Creates an immutable term-frequency row.
    public init(term: String, count: Int) {
        self.term = term
        self.count = count
    }
}

/// Presentation-independent summary of a text profile.
public struct GlifiStudioTextProfile: Equatable, Sendable {
    /// Digest of the exact source bytes.
    public let contentDigest: String
    /// Number of decoded UTF-8 bytes.
    public let utf8ByteCount: Int
    /// Number of extended grapheme clusters.
    public let characterCount: Int
    /// Number of detected sentences.
    public let sentenceCount: Int
    /// Number of surface tokens, including punctuation.
    public let surfaceTokenCount: Int
    /// Number of tokens included in lexical statistics.
    public let lexicalTokenCount: Int
    /// Number of distinct normalized forms.
    public let typeCount: Int
    /// Bounded, deterministically ordered leading frequencies.
    public let topTerms: [GlifiStudioTermFrequency]

    init(_ profile: GlifiTextProfile, maximumTermCount: Int = 100) {
        contentDigest = profile.contentDigest
        utf8ByteCount = profile.utf8ByteCount
        characterCount = profile.characterCount
        sentenceCount = profile.sentenceCount
        surfaceTokenCount = profile.surfaceTokenCount
        lexicalTokenCount = profile.lexicalTokenCount
        typeCount = profile.typeCount
        topTerms = profile.frequencies.prefix(maximumTermCount).map {
            GlifiStudioTermFrequency(term: $0.term, count: $0.count)
        }
    }
}

/// Stable, localizable failure exposed without leaking implementation errors.
public struct GlifiStudioFailure: Error, Equatable, Sendable {
    /// Stable machine-readable failure code.
    public let code: String
    /// Stable failure category.
    public let category: String
    /// Stable operation that observed the failure.
    public let operation: String
    /// Stable condition under which retry can be meaningful.
    public let retryDisposition: String
    /// Stable description of the state retained after failure.
    public let retainedState: String
    /// Localization key for presentation clients.
    public let messageKey: String
    /// Non-sensitive localization arguments.
    public let arguments: [String: String]

    /// Creates a stable failure value for a presentation or machine boundary.
    public init(
        code: String,
        category: String,
        operation: String,
        retryDisposition: String,
        retainedState: String,
        messageKey: String,
        arguments: [String: String] = [:]
    ) {
        self.code = code
        self.category = category
        self.operation = operation
        self.retryDisposition = retryDisposition
        self.retainedState = retainedState
        self.messageKey = messageKey
        self.arguments = arguments
    }

    init(_ failure: GlifiFailure) {
        code = failure.code
        category = failure.category.rawValue
        operation = failure.operation.rawValue
        retryDisposition = failure.retryDisposition.rawValue
        retainedState = failure.retainedState.rawValue
        messageKey = failure.messageKey
        arguments = failure.arguments
    }
}

/// Presentation-independent view of an authoritative project generation.
public struct GlifiStudioProjectSnapshot: Equatable, Sendable {
    /// Stable opaque project identifier.
    public let projectID: String
    /// Monotonic authoritative generation.
    public let generation: Int
    /// Number of incorporated immutable source revisions.
    public let sourceCount: Int

    init(_ snapshot: GlifiProjectSnapshot) {
        projectID = snapshot.projectID.canonicalValue
        generation = snapshot.generation
        sourceCount = snapshot.sources.count
    }
}

/// Durable project state and profile returned by a successful source import.
public struct GlifiStudioProjectImportResult: Equatable, Sendable {
    /// Newly committed project generation.
    public let project: GlifiStudioProjectSnapshot
    /// Profile derived from the exact incorporated source revision.
    public let profile: GlifiStudioTextProfile

    init(_ result: GlifiProjectTextImportResult) {
        project = GlifiStudioProjectSnapshot(result.project)
        profile = GlifiStudioTextProfile(result.profile)
    }
}

/// One bounded concordance row ready for native or machine presentation.
public struct GlifiStudioQueryMatch: Equatable, Identifiable, Sendable {
    /// Stable row identity within a query result.
    public var id: String { "\(sourceRevisionID):\(startUTF8):\(endUTF8)" }
    /// Opaque source revision identity.
    public let sourceRevisionID: String
    /// Coordinate space used by `startUTF8` and `endUTF8`.
    public let coordinateSpace: String
    /// Inclusive UTF-8 byte offset in the extracted representation.
    public let startUTF8: Int
    /// Exclusive UTF-8 byte offset in the extracted representation.
    public let endUTF8: Int
    /// Ordered half-open ranges in the immutable source bytes.
    public let sourceRanges: [GlifiStudioUTF8Range]
    /// Bounded source text before the match.
    public let leftContext: String
    /// Exact matched source surface.
    public let match: String
    /// Bounded source text after the match.
    public let rightContext: String

    init(_ match: GlifiProjectQueryMatch) {
        sourceRevisionID = match.sourceRevisionID.canonicalValue
        coordinateSpace = GlifiTextCoordinateSpace.extractedUTF8.rawValue
        startUTF8 = match.range.start
        endUTF8 = match.range.end
        sourceRanges = match.sourceRanges.map(GlifiStudioUTF8Range.init)
        leftContext = match.leftContext
        self.match = match.match
        rightContext = match.rightContext
    }
}

/// One half-open source-byte interval suitable for presentation and JSON clients.
public struct GlifiStudioUTF8Range: Codable, Equatable, Sendable {
    /// Inclusive byte offset.
    public let start: Int
    /// Exclusive byte offset.
    public let end: Int

    init(_ range: GlifiUTF8Range) {
        start = range.start
        end = range.end
    }
}

/// Deterministic bounded query result for one authoritative project generation.
public struct GlifiStudioProjectQueryResult: Equatable, Sendable {
    /// Opaque project identity.
    public let projectID: String
    /// Exact authoritative generation queried.
    public let generation: Int
    /// Digest of the canonical QueryAST.
    public let queryDigest: String
    /// Number of source scopes selected by the predicate.
    public let matchedSourceCount: Int
    /// Canonically ordered concordance rows.
    public let matches: [GlifiStudioQueryMatch]
    /// Whether a declared bound curtailed result materialization.
    public let isTruncated: Bool

    init(_ result: GlifiProjectQueryResult) {
        projectID = result.projectID.canonicalValue
        generation = result.generation
        queryDigest = result.queryDigest
        matchedSourceCount = result.matchedSourceCount
        matches = result.matches.map(GlifiStudioQueryMatch.init)
        isTruncated = result.isTruncated
    }
}

/// Actor-isolated lifecycle for one verified `.glifi` project.
public actor GlifiStudioProjectSession {
    private let engine: GlifiEngine
    private let project: GlifiProjectPackage
    private var isClosed = false

    init(engine: GlifiEngine, project: GlifiProjectPackage) {
        self.engine = engine
        self.project = project
    }

    /// Returns the current verified generation while the session is open.
    public func snapshot() async throws -> GlifiStudioProjectSnapshot {
        try ensureOpen()
        return GlifiStudioProjectSnapshot(await project.snapshot())
    }

    /// Validates, profiles, and incorporates one user-authorized text source.
    public func importText(
        at url: URL,
        format: GlifiStudioTextFormat
    ) async throws -> GlifiStudioProjectImportResult {
        try ensureOpen()
        do {
            return try await GlifiStudioProjectImportResult(
                engine.importText(at: url, format: format.coreValue, into: project)
            )
        } catch {
            throw Self.map(error, operation: .importText)
        }
    }

    /// Parses and executes one bounded textual query against the current generation.
    public func query(_ text: String) async throws -> GlifiStudioProjectQueryResult {
        try ensureOpen()
        do {
            return try await GlifiStudioProjectQueryResult(engine.query(text, in: project))
        } catch {
            throw Self.map(error, operation: .query)
        }
    }

    /// Closes this logical session idempotently and rejects subsequent operations.
    public func close() {
        isClosed = true
    }

    private func ensureOpen() throws {
        guard !isClosed else {
            throw GlifiStudioFailure(
                GlifiFailure(
                    code: "project.session-closed",
                    category: .invalidInput,
                    operation: .persistProject,
                    retryDisposition: .never,
                    retainedState: .lastCommittedGeneration,
                    messageKey: "failure.project.session-closed"
                )
            )
        }
    }

    private static func map(_ error: Error, operation: GlifiOperationKind) -> GlifiStudioFailure {
        if let failure = error as? GlifiFailure {
            return GlifiStudioFailure(failure)
        }
        return GlifiStudioFailure(
            GlifiFailure(
                code: "internal.unexpected",
                category: .invariantViolation,
                operation: operation,
                retryDisposition: .never,
                retainedState: .validityUnknown,
                messageKey: "failure.internal.unexpected"
            )
        )
    }
}

/// Exposes the public application-facing contract for GlifiCore.
public struct GlifiStudioService: Sendable {
    private let engine: GlifiEngine

    /// Creates a service backed by a new GlifiCore engine.
    public init() {
        engine = GlifiEngine()
    }

    /// Returns a presentation-independent description of the engine state.
    public func status() async -> GlifiStudioStatus {
        let engineStatus = await engine.status()

        switch engineStatus {
        case .ready:
            return .ready
        }
    }

    /// Profiles one user-authorized UTF-8 file using the same GlifiCore path as headless clients.
    public func profileText(
        at url: URL,
        format: GlifiStudioTextFormat
    ) async throws -> GlifiStudioTextProfile {
        do {
            let profile = try await engine.profileText(
                at: url,
                format: format.coreValue
            )
            return GlifiStudioTextProfile(profile)
        } catch let failure as GlifiFailure {
            throw GlifiStudioFailure(failure)
        } catch {
            throw GlifiStudioFailure(
                GlifiFailure(
                    code: "internal.unexpected",
                    category: .invariantViolation,
                    operation: .profileCollection,
                    retryDisposition: .never,
                    retainedState: .validityUnknown,
                    messageKey: "failure.internal.unexpected"
                )
            )
        }
    }

    /// Creates and opens an empty `.glifi` project at a user-authorized destination.
    public func createProject(at url: URL) async throws -> GlifiStudioProjectSession {
        do {
            let project = try await engine.createProject(at: url)
            return GlifiStudioProjectSession(engine: engine, project: project)
        } catch {
            throw map(error, operation: .persistProject)
        }
    }

    /// Opens an existing `.glifi` project after complete integrity verification.
    public func openProject(at url: URL) async throws -> GlifiStudioProjectSession {
        do {
            let project = try await engine.openProject(at: url)
            return GlifiStudioProjectSession(engine: engine, project: project)
        } catch {
            throw map(error, operation: .persistProject)
        }
    }

    private func map(_ error: Error, operation: GlifiOperationKind) -> GlifiStudioFailure {
        if let failure = error as? GlifiFailure {
            return GlifiStudioFailure(failure)
        }
        return GlifiStudioFailure(
            GlifiFailure(
                code: "internal.unexpected",
                category: .invariantViolation,
                operation: operation,
                retryDisposition: .never,
                retainedState: .validityUnknown,
                messageKey: "failure.internal.unexpected"
            )
        )
    }
}

extension GlifiStudioTextFormat {
    var coreValue: GlifiTextFormat {
        switch self {
        case .plainText:
            .plainText
        case .markdown:
            .markdown
        }
    }
}
