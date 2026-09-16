// SPDX-License-Identifier: BSD-3-Clause

/// Stable failure categories shared by every headless operation.
public enum GlifiFailureCategory: String, Codable, Sendable, CaseIterable {
    case invalidInput
    case unsupportedFormat
    case insufficientData
    case transientIO
    case authorizationDenied
    case insufficientResources
    case cancelled
    case staleArtifact
    case incompatibleVersion
    case corruption
    case invariantViolation
}

/// Describes when retrying a failed operation can be meaningful.
public enum GlifiRetryDisposition: String, Codable, Sendable {
    case never
    case afterCorrection
    case afterUserAction
    case afterConditionsChange
    case transientBackoff
    case newRequest
}

/// Describes which state remains authoritative after a failure.
public enum GlifiRetainedState: String, Codable, Sendable {
    case unchanged
    case lastCommittedGeneration
    case validatedCheckpoint
    case readOnlyRecovery
    case validityUnknown
}

/// Identifies an operation without exposing paths or corpus content.
public enum GlifiOperationKind: String, Codable, Sendable {
    case serviceStatus
    case importText
    case tokenize
    case profileCollection
    case query
    case plan
    case executePlan
    case investigate
    case export
    case analyze
    case persistProject
}

/// A privacy-safe, localizable failure crossing a GlifiCore boundary.
public struct GlifiFailure: Error, Codable, Equatable, Sendable {
    /// Stable machine-readable code.
    public let code: String
    /// Broad failure category shared by API and CLI.
    public let category: GlifiFailureCategory
    /// Operation that observed the failure.
    public let operation: GlifiOperationKind
    /// Conditions under which a retry is meaningful.
    public let retryDisposition: GlifiRetryDisposition
    /// Authoritative state retained after the failure.
    public let retainedState: GlifiRetainedState
    /// Localization key for human-facing clients.
    public let messageKey: String
    /// Non-sensitive localization arguments.
    public let arguments: [String: String]

    /// Creates a fully classified failure without retaining an underlying error.
    public init(
        code: String,
        category: GlifiFailureCategory,
        operation: GlifiOperationKind,
        retryDisposition: GlifiRetryDisposition,
        retainedState: GlifiRetainedState,
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
}
