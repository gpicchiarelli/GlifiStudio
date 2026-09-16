// SPDX-License-Identifier: BSD-3-Clause

import CryptoKit
import Darwin
import Foundation

/// One immutable source revision reachable from a project generation.
public struct GlifiProjectSourceRecord: Codable, Equatable, Sendable {
    /// Logical identity of the source.
    public let sourceID: SourceID
    /// Identity of the immutable source snapshot.
    public let sourceRevisionID: SourceRevisionID
    /// Validated source format.
    public let format: GlifiTextFormat
    /// Digest of the exact source bytes.
    public let contentDigest: String
    /// Exact number of source bytes.
    public let byteCount: Int
    /// Generated relative path of the content-addressed object.
    public let objectPath: String

    /// Creates a fully identified immutable source record.
    public init(
        sourceID: SourceID,
        sourceRevisionID: SourceRevisionID,
        format: GlifiTextFormat,
        contentDigest: String,
        byteCount: Int,
        objectPath: String
    ) {
        self.sourceID = sourceID
        self.sourceRevisionID = sourceRevisionID
        self.format = format
        self.contentDigest = contentDigest
        self.byteCount = byteCount
        self.objectPath = objectPath
    }
}

/// One immutable analytical result reachable from a project generation.
public struct GlifiProjectArtifactRecord: Codable, Equatable, Sendable {
    /// Content identity of the exact output bytes.
    public let artifactID: ArtifactID
    /// Semantic producer node and complete descriptor.
    public let node: GlifiAnalysisNode
    /// Digest of the canonical descriptor.
    public let descriptorDigest: String
    /// Exact descriptor byte count.
    public let descriptorByteCount: Int
    /// Generated relative path of the content-addressed descriptor.
    public let descriptorObjectPath: String
    /// Digest of the exact output bytes.
    public let contentDigest: String
    /// Exact output byte count.
    public let byteCount: Int
    /// Generated relative path of the content-addressed output.
    public let objectPath: String

    init(
        artifactID: ArtifactID,
        node: GlifiAnalysisNode,
        descriptorDigest: String,
        descriptorByteCount: Int,
        descriptorObjectPath: String,
        contentDigest: String,
        byteCount: Int,
        objectPath: String
    ) {
        self.artifactID = artifactID
        self.node = node
        self.descriptorDigest = descriptorDigest
        self.descriptorByteCount = descriptorByteCount
        self.descriptorObjectPath = descriptorObjectPath
        self.contentDigest = contentDigest
        self.byteCount = byteCount
        self.objectPath = objectPath
    }

    var reference: GlifiAnalysisArtifactReference {
        get throws {
            try GlifiAnalysisArtifactReference(
                nodeID: node.id,
                descriptorDigest: descriptorDigest,
                artifactDigest: contentDigest,
                outputSchemaIdentifier: node.descriptor.outputSchemaIdentifier,
                state: .valid
            )
        }
    }
}

/// One immutable investigation-history event reachable from a project generation.
public struct GlifiProjectInvestigationEventRecord: Codable, Equatable, Sendable {
    /// Content identity of the canonical event.
    public let eventID: InvestigationEventID
    /// Aggregate that owns the event.
    public let investigationID: InvestigationID
    /// Previous event on the same branch.
    public let predecessorEventID: InvestigationEventID?
    /// SHA-256 digest of the exact canonical bytes.
    public let contentDigest: String
    /// Exact canonical byte count.
    public let byteCount: Int
    /// Generated relative content-addressed path.
    public let objectPath: String

    init(
        eventID: InvestigationEventID,
        investigationID: InvestigationID,
        predecessorEventID: InvestigationEventID?,
        contentDigest: String,
        byteCount: Int,
        objectPath: String
    ) {
        self.eventID = eventID
        self.investigationID = investigationID
        self.predecessorEventID = predecessorEventID
        self.contentDigest = contentDigest
        self.byteCount = byteCount
        self.objectPath = objectPath
    }
}

/// Verified authoritative view of one committed project generation.
public struct GlifiProjectSnapshot: Equatable, Sendable {
    /// Stable identity of the project aggregate.
    public let projectID: ProjectID
    /// Monotonic authoritative generation selected by the root manifest.
    public let generation: Int
    /// Digest of the authoritative generation record selected by the manifest.
    public let generationRecordDigest: String
    /// Ordered source revisions reachable from this generation.
    public let sources: [GlifiProjectSourceRecord]
    /// Digest of the canonical ordered source root.
    public let sourceRootDigest: String
    /// Ordered analytical artifacts reachable from this generation.
    public let artifacts: [GlifiProjectArtifactRecord]
    /// Digest of the canonical ordered analytical-artifact root.
    public let artifactRootDigest: String
    /// Ordered append-only cognitive events reachable from this generation.
    public let investigationEvents: [GlifiProjectInvestigationEventRecord]
    /// Digest of the canonical ordered investigation-history root.
    public let investigationRootDigest: String

    /// Creates an immutable verified snapshot.
    public init(
        projectID: ProjectID,
        generation: Int,
        generationRecordDigest: String,
        sources: [GlifiProjectSourceRecord],
        sourceRootDigest: String,
        artifacts: [GlifiProjectArtifactRecord],
        artifactRootDigest: String,
        investigationEvents: [GlifiProjectInvestigationEventRecord],
        investigationRootDigest: String
    ) {
        self.projectID = projectID
        self.generation = generation
        self.generationRecordDigest = generationRecordDigest
        self.sources = sources
        self.sourceRootDigest = sourceRootDigest
        self.artifacts = artifacts
        self.artifactRootDigest = artifactRootDigest
        self.investigationEvents = investigationEvents
        self.investigationRootDigest = investigationRootDigest
    }
}

/// Bounded root manifest whose replacement is the project commit point.
public struct GlifiProjectManifest: Codable, Equatable, Sendable {
    /// Stable schema identifier.
    public static let schema = "studio.glifi.project-manifest"
    /// Current manifest schema version.
    public static let schemaVersion = 3
    static let previousSchemaVersion = 2
    static let emptyInvestigationRootDigest =
        "sha256:4f53cda18c2baa0c0354bb5f9a3ecbe5ed12ab4d8e11ba873c2f11161202b945"
    /// Current package format major.
    public static let formatVersion = 1

    /// Stable schema identifier encoded in the document.
    public let schema: String
    /// Version of the root-manifest schema.
    public let schemaVersion: Int
    /// Major version of the package format.
    public let formatVersion: Int
    /// Oldest reader capable of opening this package.
    public let minimumReaderVersion: Int
    /// Stable identity of the project.
    public let projectID: ProjectID
    /// Authoritative generation selected by this manifest.
    public let generation: Int
    /// Previously authoritative generation, absent for generation zero.
    public let baseGeneration: Int?
    /// Digest of the prepared generation record in SQLite.
    public let generationRecordDigest: String
    /// Digest of the canonical ordered source root.
    public let sourceRootDigest: String
    /// Exact number of source records reachable from the generation.
    public let sourceCount: Int
    /// Digest of the canonical ordered analytical-artifact root.
    public let artifactRootDigest: String
    /// Exact number of analytical artifacts reachable from the generation.
    public let artifactCount: Int
    /// Digest of the append-only investigation-history root.
    public let investigationRootDigest: String
    /// Exact number of immutable investigation events reachable from the generation.
    public let investigationEventCount: Int

    init(
        projectID: ProjectID,
        generation: Int,
        baseGeneration: Int?,
        generationRecordDigest: String,
        sourceRootDigest: String,
        sourceCount: Int,
        artifactRootDigest: String,
        artifactCount: Int,
        investigationRootDigest: String,
        investigationEventCount: Int
    ) {
        schema = Self.schema
        schemaVersion = Self.schemaVersion
        formatVersion = Self.formatVersion
        minimumReaderVersion = Self.formatVersion
        self.projectID = projectID
        self.generation = generation
        self.baseGeneration = baseGeneration
        self.generationRecordDigest = generationRecordDigest
        self.sourceRootDigest = sourceRootDigest
        self.sourceCount = sourceCount
        self.artifactRootDigest = artifactRootDigest
        self.artifactCount = artifactCount
        self.investigationRootDigest = investigationRootDigest
        self.investigationEventCount = investigationEventCount
    }

    private enum CodingKeys: String, CodingKey {
        case schema, schemaVersion, formatVersion, minimumReaderVersion, projectID
        case generation, baseGeneration, generationRecordDigest, sourceRootDigest
        case sourceCount, artifactRootDigest, artifactCount
        case investigationRootDigest, investigationEventCount
    }

    /// Decodes schema 3 and the additive schema 2 compatibility projection.
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        schema = try container.decode(String.self, forKey: .schema)
        schemaVersion = try container.decode(Int.self, forKey: .schemaVersion)
        formatVersion = try container.decode(Int.self, forKey: .formatVersion)
        minimumReaderVersion = try container.decode(Int.self, forKey: .minimumReaderVersion)
        projectID = try container.decode(ProjectID.self, forKey: .projectID)
        generation = try container.decode(Int.self, forKey: .generation)
        baseGeneration = try container.decodeIfPresent(Int.self, forKey: .baseGeneration)
        generationRecordDigest = try container.decode(
            String.self,
            forKey: .generationRecordDigest
        )
        sourceRootDigest = try container.decode(String.self, forKey: .sourceRootDigest)
        sourceCount = try container.decode(Int.self, forKey: .sourceCount)
        artifactRootDigest = try container.decode(String.self, forKey: .artifactRootDigest)
        artifactCount = try container.decode(Int.self, forKey: .artifactCount)
        if schemaVersion == Self.previousSchemaVersion {
            investigationRootDigest =
                try container.decodeIfPresent(
                    String.self,
                    forKey: .investigationRootDigest
                ) ?? Self.emptyInvestigationRootDigest
            investigationEventCount =
                try container.decodeIfPresent(
                    Int.self,
                    forKey: .investigationEventCount
                ) ?? 0
        } else {
            investigationRootDigest = try container.decode(
                String.self,
                forKey: .investigationRootDigest
            )
            investigationEventCount = try container.decode(
                Int.self,
                forKey: .investigationEventCount
            )
        }
    }
}

/// Owns transactional reads and writes for one local `.glifi` package.
public actor GlifiProjectPackage {
    /// Maximum accepted root-manifest size before decoding.
    public static let maximumManifestByteCount = 1_048_576
    /// Maximum accepted canonical descriptor size.
    public static let maximumDescriptorByteCount = 1_048_576
    /// Maximum accepted output-artifact size for the current local slice.
    public static let maximumArtifactByteCount = 67_108_864
    /// Maximum accepted bytes for one immutable cognitive-history event.
    public static let maximumInvestigationEventByteCount = 1_048_576

    private let packageURL: URL
    private var currentSnapshot: GlifiProjectSnapshot

    private init(packageURL: URL, snapshot: GlifiProjectSnapshot) {
        self.packageURL = packageURL
        currentSnapshot = snapshot
    }

    /// Creates and verifies a new empty package without overwriting an existing item.
    public static func create(
        at packageURL: URL,
        projectID: ProjectID = ProjectID()
    ) throws -> GlifiProjectPackage {
        try GlifiProjectPackageIO.validateDestination(packageURL)
        let fileManager = FileManager.default
        let parentURL = packageURL.deletingLastPathComponent()
        let stagingURL = parentURL.appending(
            path: ".\(packageURL.lastPathComponent).creating-\(UUID().uuidString)",
            directoryHint: .isDirectory
        )

        do {
            try fileManager.createDirectory(at: stagingURL, withIntermediateDirectories: false)
            try GlifiProjectPackageIO.createDirectories(in: stagingURL)
            let databaseURL = GlifiProjectPackageIO.databaseURL(in: stagingURL)
            let database = try GlifiSQLiteProjectStore.create(
                at: databaseURL,
                projectID: projectID
            )
            let sources: [GlifiProjectSourceRecord] = []
            let sourceRootDigest = try GlifiProjectPackageIO.sourceRootDigest(sources)
            let artifacts: [GlifiProjectArtifactRecord] = []
            let artifactRootDigest = try GlifiProjectPackageIO.artifactRootDigest(artifacts)
            let investigationEvents: [GlifiProjectInvestigationEventRecord] = []
            let investigationRootDigest = try GlifiProjectPackageIO.investigationRootDigest(
                investigationEvents
            )
            let recordDigest = try GlifiProjectPackageIO.generationRecordDigest(
                projectID: projectID,
                generation: 0,
                baseGeneration: nil,
                sourceRootDigest: sourceRootDigest,
                sourceCount: 0,
                artifactRootDigest: artifactRootDigest,
                artifactCount: 0,
                investigationRootDigest: investigationRootDigest,
                investigationEventCount: 0
            )
            try database.insertInitialGeneration(
                recordDigest: recordDigest,
                sourceRootDigest: sourceRootDigest,
                artifactRootDigest: artifactRootDigest,
                investigationRootDigest: investigationRootDigest
            )
            let manifest = GlifiProjectManifest(
                projectID: projectID,
                generation: 0,
                baseGeneration: nil,
                generationRecordDigest: recordDigest,
                sourceRootDigest: sourceRootDigest,
                sourceCount: 0,
                artifactRootDigest: artifactRootDigest,
                artifactCount: 0,
                investigationRootDigest: investigationRootDigest,
                investigationEventCount: 0
            )
            try GlifiProjectPackageIO.writeManifest(manifest, in: stagingURL)
            _ = try GlifiProjectPackageIO.openVerified(at: stagingURL)
            try fileManager.moveItem(at: stagingURL, to: packageURL)
        } catch {
            try? fileManager.removeItem(at: stagingURL)
            throw GlifiProjectPackageIO.classify(error, operation: .persistProject)
        }

        let snapshot = try GlifiProjectPackageIO.openVerified(at: packageURL)
        return GlifiProjectPackage(packageURL: packageURL, snapshot: snapshot)
    }

    /// Opens a package only after validating its manifest, store, roots, and objects.
    public static func open(at packageURL: URL) throws -> GlifiProjectPackage {
        let snapshot = try GlifiProjectPackageIO.openVerified(at: packageURL)
        return GlifiProjectPackage(packageURL: packageURL, snapshot: snapshot)
    }

    /// Returns the last generation verified by this package session.
    public func snapshot() -> GlifiProjectSnapshot {
        currentSnapshot
    }

    /// Incorporates one already validated immutable text snapshot transactionally.
    @discardableResult
    public func importText(
        _ importedText: GlifiImportedText,
        sourceID: SourceID = SourceID()
    ) throws -> GlifiProjectSnapshot {
        try importText(importedText, sourceID: sourceID, interruption: nil)
    }

    /// Reads a source only after checking its identity, size, and digest again.
    public func sourceData(for sourceRevisionID: SourceRevisionID) throws -> Data {
        guard
            let source = currentSnapshot.sources.first(where: {
                $0.sourceRevisionID == sourceRevisionID
            })
        else {
            throw GlifiFailure(
                code: "project.source-not-found",
                category: .insufficientData,
                operation: .persistProject,
                retryDisposition: .afterCorrection,
                retainedState: .lastCommittedGeneration,
                messageKey: "failure.project.source-not-found"
            )
        }
        let objectURL = try GlifiProjectPackageIO.validatedObjectURL(
            for: source,
            in: packageURL
        )
        return try GlifiProjectPackageIO.readValidatedObject(objectURL, source: source)
    }

    /// Returns the fully verified analysis DAG selected by the current generation.
    public func analysisGraph() throws -> GlifiAnalysisGraph {
        try GlifiAnalysisGraph(currentSnapshot.artifacts.map(\.node))
    }

    /// Reads immutable artifact bytes after checking path, size, digest, and identity again.
    public func artifactData(for artifactID: ArtifactID) throws -> Data {
        guard let artifact = currentSnapshot.artifacts.first(where: { $0.artifactID == artifactID })
        else {
            throw GlifiFailure(
                code: "project.artifact-not-found",
                category: .insufficientData,
                operation: .persistProject,
                retryDisposition: .afterCorrection,
                retainedState: .lastCommittedGeneration,
                messageKey: "failure.project.artifact-not-found"
            )
        }
        return try GlifiProjectPackageIO.readValidatedArtifact(artifact, in: packageURL)
    }

    /// Reads and validates one immutable investigation-history event.
    public func investigationEvent(
        for eventID: InvestigationEventID
    ) throws -> GlifiInvestigationEvent {
        guard
            let record = currentSnapshot.investigationEvents.first(where: {
                $0.eventID == eventID
            })
        else {
            throw GlifiFailure(
                code: "project.investigation-event-not-found",
                category: .insufficientData,
                operation: .investigate,
                retryDisposition: .afterCorrection,
                retainedState: .lastCommittedGeneration,
                messageKey: "failure.project.investigation-event-not-found"
            )
        }
        return try GlifiProjectPackageIO.readValidatedInvestigationEvent(
            record,
            in: packageURL
        )
    }

    /// Appends one immutable cognitive event in a recoverable project transaction.
    @discardableResult
    func appendInvestigationEvent(
        _ event: GlifiInvestigationEvent
    ) throws -> GlifiProjectSnapshot {
        let expectedSnapshot = currentSnapshot
        var coordinatedError: Error?
        var result: GlifiProjectSnapshot?
        var coordinationError: NSError?
        let coordinator = NSFileCoordinator()
        coordinator.coordinate(
            writingItemAt: packageURL,
            options: .forMerging,
            error: &coordinationError
        ) { coordinatedURL in
            do {
                result = try GlifiProjectPackageIO.commitInvestigationEvent(
                    event,
                    at: coordinatedURL,
                    expectedSnapshot: expectedSnapshot
                )
            } catch {
                coordinatedError = error
            }
        }
        if let coordinatedError { throw coordinatedError }
        if let coordinationError { throw coordinationError }
        guard let result else {
            throw GlifiFailure(
                code: "project.coordination-failed",
                category: .transientIO,
                operation: .persistProject,
                retryDisposition: .transientBackoff,
                retainedState: .lastCommittedGeneration,
                messageKey: "failure.project.coordination-failed"
            )
        }
        currentSnapshot = result
        return result
    }

    /// Commits one typed immutable analytical result and its canonical descriptor.
    @discardableResult
    public func storeArtifact<Payload: GlifiAnalysisArtifactPayload>(
        _ payload: Payload,
        descriptor: GlifiAnalysisDescriptor
    ) throws -> GlifiProjectSnapshot {
        try storeArtifact(payload, descriptor: descriptor, interruption: nil)
    }

    @discardableResult
    func importText(
        _ importedText: GlifiImportedText,
        sourceID: SourceID,
        interruption: GlifiProjectCommitInterruption?
    ) throws -> GlifiProjectSnapshot {
        let expectedSnapshot = currentSnapshot
        var coordinatedError: Error?
        var result: GlifiProjectSnapshot?
        var coordinationError: NSError?
        let coordinator = NSFileCoordinator()

        coordinator.coordinate(
            writingItemAt: packageURL,
            options: .forMerging,
            error: &coordinationError
        ) { coordinatedURL in
            do {
                result = try GlifiProjectPackageIO.commitImport(
                    importedText,
                    sourceID: sourceID,
                    at: coordinatedURL,
                    expectedSnapshot: expectedSnapshot,
                    interruption: interruption
                )
            } catch {
                coordinatedError = error
            }
        }

        if let coordinationError {
            throw GlifiFailure(
                code: "project.coordination-failed",
                category: .transientIO,
                operation: .persistProject,
                retryDisposition: .transientBackoff,
                retainedState: .lastCommittedGeneration,
                messageKey: "failure.project.coordination-failed",
                arguments: ["code": String(coordinationError.code)]
            )
        }
        if let coordinatedError {
            throw GlifiProjectPackageIO.classify(coordinatedError, operation: .persistProject)
        }
        guard let result else {
            throw GlifiFailure(
                code: "project.commit-produced-no-result",
                category: .invariantViolation,
                operation: .persistProject,
                retryDisposition: .never,
                retainedState: .validityUnknown,
                messageKey: "failure.project.commit-produced-no-result"
            )
        }

        currentSnapshot = result
        return result
    }

    @discardableResult
    func storeArtifact<Payload: GlifiAnalysisArtifactPayload>(
        _ payload: Payload,
        descriptor: GlifiAnalysisDescriptor,
        interruption: GlifiProjectCommitInterruption?
    ) throws -> GlifiProjectSnapshot {
        guard descriptor.outputSchemaIdentifier == Payload.outputSchemaIdentifier else {
            throw GlifiFailure(
                code: "project.artifact-schema-mismatch",
                category: .invalidInput,
                operation: .persistProject,
                retryDisposition: .afterCorrection,
                retainedState: .unchanged,
                messageKey: "failure.project.artifact-schema-mismatch"
            )
        }
        let data = try GlifiArtifactCanonicalJSON.encode(payload)
        guard data.count <= Self.maximumArtifactByteCount else {
            throw GlifiFailure(
                code: "project.artifact-too-large",
                category: .insufficientResources,
                operation: .persistProject,
                retryDisposition: .afterCorrection,
                retainedState: .unchanged,
                messageKey: "failure.project.artifact-too-large"
            )
        }
        let expectedSnapshot = currentSnapshot
        var coordinatedError: Error?
        var result: GlifiProjectSnapshot?
        var coordinationError: NSError?
        let coordinator = NSFileCoordinator()

        coordinator.coordinate(
            writingItemAt: packageURL,
            options: .forMerging,
            error: &coordinationError
        ) { coordinatedURL in
            do {
                result = try GlifiProjectPackageIO.commitArtifact(
                    data,
                    descriptor: descriptor,
                    at: coordinatedURL,
                    expectedSnapshot: expectedSnapshot,
                    interruption: interruption
                )
            } catch {
                coordinatedError = error
            }
        }

        if let coordinationError {
            throw GlifiFailure(
                code: "project.coordination-failed",
                category: .transientIO,
                operation: .persistProject,
                retryDisposition: .transientBackoff,
                retainedState: .lastCommittedGeneration,
                messageKey: "failure.project.coordination-failed",
                arguments: ["code": String(coordinationError.code)]
            )
        }
        if let coordinatedError {
            throw GlifiProjectPackageIO.classify(coordinatedError, operation: .persistProject)
        }
        guard let result else {
            throw GlifiFailure(
                code: "project.commit-produced-no-result",
                category: .invariantViolation,
                operation: .persistProject,
                retryDisposition: .never,
                retainedState: .validityUnknown,
                messageKey: "failure.project.commit-produced-no-result"
            )
        }
        currentSnapshot = result
        return result
    }
}

enum GlifiProjectCommitInterruption: Sendable, CaseIterable {
    case staged
    case objectPromoted
    case databasePrepared
    case manifestPrepared
    case manifestReplaced
    case databaseCommitted
}

struct GlifiStoredProjectArtifactRecord: Equatable, Sendable {
    let artifactID: ArtifactID
    let nodeID: AnalysisNodeID
    let descriptorDigest: String
    let descriptorByteCount: Int
    let descriptorObjectPath: String
    let contentDigest: String
    let byteCount: Int
    let objectPath: String
    let outputSchemaIdentifier: String
}

private enum GlifiProjectPackageIO {
    private static var fileManager: FileManager { FileManager.default }

    static func validateDestination(_ url: URL) throws {
        guard url.isFileURL,
            url.pathExtension.lowercased() == "glifi",
            !fileManager.fileExists(atPath: url.path)
        else {
            throw GlifiFailure(
                code: "project.invalid-destination",
                category: .invalidInput,
                operation: .persistProject,
                retryDisposition: .afterCorrection,
                retainedState: .unchanged,
                messageKey: "failure.project.invalid-destination"
            )
        }
        let parent = url.deletingLastPathComponent()
        let values = try parent.resourceValues(forKeys: [.isDirectoryKey, .isSymbolicLinkKey])
        guard values.isDirectory == true, values.isSymbolicLink != true else {
            throw GlifiFailure(
                code: "project.invalid-parent",
                category: .invalidInput,
                operation: .persistProject,
                retryDisposition: .afterCorrection,
                retainedState: .unchanged,
                messageKey: "failure.project.invalid-parent"
            )
        }
    }

    static func createDirectories(in packageURL: URL) throws {
        for path in [
            "store",
            "sources/objects/sha256",
            "representations/objects/sha256",
            "artifacts/objects/sha256",
            "artifacts/descriptors/sha256",
            "investigations/events/sha256",
            "history",
            "transactions",
        ] {
            try fileManager.createDirectory(
                at: packageURL.appending(path: path, directoryHint: .isDirectory),
                withIntermediateDirectories: true
            )
        }
    }

    static func databaseURL(in packageURL: URL) -> URL {
        packageURL.appending(path: "store/project.sqlite", directoryHint: .notDirectory)
    }

    static func manifestURL(in packageURL: URL) -> URL {
        packageURL.appending(path: "manifest.json", directoryHint: .notDirectory)
    }

    static func writeManifest(_ manifest: GlifiProjectManifest, in packageURL: URL) throws {
        let data = try GlifiCanonicalJSON.encode(manifest)
        guard data.count <= GlifiProjectPackage.maximumManifestByteCount else {
            throw GlifiFailure(
                code: "project.manifest-too-large",
                category: .insufficientResources,
                operation: .persistProject,
                retryDisposition: .afterCorrection,
                retainedState: .unchanged,
                messageKey: "failure.project.manifest-too-large"
            )
        }
        try durableWrite(data, to: manifestURL(in: packageURL))
    }

    static func openVerified(at packageURL: URL) throws -> GlifiProjectSnapshot {
        do {
            let packageValues = try packageURL.resourceValues(forKeys: [
                .isDirectoryKey,
                .isSymbolicLinkKey,
            ])
            guard packageValues.isDirectory == true, packageValues.isSymbolicLink != true else {
                throw corruption("project.invalid-package")
            }

            let manifestURL = manifestURL(in: packageURL)
            let manifestValues = try manifestURL.resourceValues(forKeys: [
                .fileSizeKey,
                .isRegularFileKey,
                .isSymbolicLinkKey,
            ])
            guard manifestValues.isRegularFile == true,
                manifestValues.isSymbolicLink != true,
                let manifestSize = manifestValues.fileSize,
                manifestSize <= GlifiProjectPackage.maximumManifestByteCount
            else {
                throw corruption("project.invalid-manifest-file")
            }
            let data = try Data(contentsOf: manifestURL, options: [.mappedIfSafe, .uncached])
            let manifest = try JSONDecoder().decode(GlifiProjectManifest.self, from: data)
            try validate(manifest)

            let database = try GlifiSQLiteProjectStore.open(at: databaseURL(in: packageURL))
            try database.migrateIfNeeded(
                projectID: manifest.projectID,
                emptyInvestigationRootDigest: GlifiProjectManifest.emptyInvestigationRootDigest
            )
            try database.validateIntegrity(projectID: manifest.projectID)
            let generation = try database.generation(manifest.generation)
            guard generation.state == "prepared" || generation.state == "committed",
                generation.baseGeneration == manifest.baseGeneration,
                generation.recordDigest == manifest.generationRecordDigest,
                generation.sourceRootDigest == manifest.sourceRootDigest,
                generation.sourceCount == manifest.sourceCount,
                generation.artifactRootDigest == manifest.artifactRootDigest,
                generation.artifactCount == manifest.artifactCount,
                generation.investigationRootDigest == manifest.investigationRootDigest,
                generation.investigationEventCount == manifest.investigationEventCount
            else {
                throw corruption("project.generation-mismatch")
            }

            let sources = try database.sources(generation: manifest.generation)
            guard sources.count == manifest.sourceCount,
                try sourceRootDigest(sources) == manifest.sourceRootDigest
            else {
                throw corruption("project.source-root-mismatch")
            }
            for source in sources {
                _ = try validatedObjectURL(for: source, in: packageURL)
            }
            let storedArtifacts = try database.artifacts(generation: manifest.generation)
            let artifacts = try storedArtifacts.map {
                try validatedArtifactRecord(for: $0, in: packageURL)
            }
            guard artifacts.count == manifest.artifactCount,
                try artifactRootDigest(artifacts) == manifest.artifactRootDigest
            else {
                throw corruption("project.artifact-root-mismatch")
            }
            let artifactsMatchCorpus = artifacts.allSatisfy {
                $0.node.descriptor.corpusVersionDigest == manifest.sourceRootDigest
            }
            guard artifactsMatchCorpus else {
                throw corruption("project.artifact-corpus-mismatch")
            }
            do {
                let graph = try GlifiAnalysisGraph(artifacts.map(\.node))
                let reusable = try graph.reusableNodeIDs(
                    from: artifacts.map { try $0.reference }
                )
                guard reusable.count == artifacts.count else {
                    throw corruption("project.artifact-graph-mismatch")
                }
            } catch {
                throw corruption("project.artifact-graph-mismatch")
            }
            let investigationEvents = try database.investigationEvents(
                generation: manifest.generation
            )
            guard investigationEvents.count == manifest.investigationEventCount,
                try investigationRootDigest(investigationEvents)
                    == manifest.investigationRootDigest
            else {
                throw corruption("project.investigation-root-mismatch")
            }
            var decodedEvents: [InvestigationEventID: GlifiInvestigationEvent] = [:]
            decodedEvents.reserveCapacity(investigationEvents.count)
            for record in investigationEvents {
                let event = try readValidatedInvestigationEvent(record, in: packageURL)
                guard decodedEvents.updateValue(event, forKey: record.eventID) == nil else {
                    throw corruption("project.investigation-history-mismatch")
                }
            }
            let predecessorIDs = Set(decodedEvents.values.compactMap(\.predecessorEventID))
            for event in decodedEvents.values {
                if let predecessor = event.predecessorEventID {
                    guard decodedEvents[predecessor]?.investigationID == event.investigationID
                    else {
                        throw corruption("project.investigation-history-mismatch")
                    }
                }
            }
            let headIDs = decodedEvents.keys.filter { !predecessorIDs.contains($0) }
            do {
                var reachable = Set<InvestigationEventID>()
                for headID in headIDs {
                    let investigation = try GlifiInvestigation(
                        headEventID: headID,
                        eventsByID: decodedEvents
                    )
                    reachable.formUnion(investigation.eventIDs)
                }
                guard reachable.count == decodedEvents.count else {
                    throw corruption("project.investigation-history-mismatch")
                }
            } catch {
                throw corruption("project.investigation-history-mismatch")
            }
            return GlifiProjectSnapshot(
                projectID: manifest.projectID,
                generation: manifest.generation,
                generationRecordDigest: manifest.generationRecordDigest,
                sources: sources,
                sourceRootDigest: manifest.sourceRootDigest,
                artifacts: artifacts,
                artifactRootDigest: manifest.artifactRootDigest,
                investigationEvents: investigationEvents,
                investigationRootDigest: manifest.investigationRootDigest
            )
        } catch let failure as GlifiFailure {
            throw failure
        } catch let decodingError as DecodingError {
            _ = decodingError
            throw corruption("project.manifest-invalid")
        } catch {
            throw classify(error, operation: .persistProject)
        }
    }

    static func commitImport(
        _ importedText: GlifiImportedText,
        sourceID: SourceID,
        at packageURL: URL,
        expectedSnapshot: GlifiProjectSnapshot,
        interruption: GlifiProjectCommitInterruption?
    ) throws -> GlifiProjectSnapshot {
        let writerLease = try GlifiProjectWriterLease.acquire(in: packageURL)
        defer { writerLease.release() }
        let observedSnapshot = try openVerified(at: packageURL)
        guard observedSnapshot.projectID == expectedSnapshot.projectID,
            observedSnapshot.generation == expectedSnapshot.generation,
            observedSnapshot.sourceRootDigest == expectedSnapshot.sourceRootDigest,
            observedSnapshot.artifactRootDigest == expectedSnapshot.artifactRootDigest,
            observedSnapshot.investigationRootDigest == expectedSnapshot.investigationRootDigest
        else {
            throw GlifiFailure(
                code: "project.stale-generation",
                category: .staleArtifact,
                operation: .persistProject,
                retryDisposition: .newRequest,
                retainedState: .lastCommittedGeneration,
                messageKey: "failure.project.stale-generation"
            )
        }

        let transactionID = UUID().uuidString.lowercased()
        let transactionURL = packageURL.appending(
            path: "transactions/\(transactionID)",
            directoryHint: .isDirectory
        )
        try fileManager.createDirectory(at: transactionURL, withIntermediateDirectories: false)
        let transactionState = TransactionState(
            transactionID: transactionID,
            baseGeneration: observedSnapshot.generation,
            targetGeneration: observedSnapshot.generation + 1,
            state: "staging"
        )
        try durableWrite(
            try GlifiCanonicalJSON.encode(transactionState),
            to: transactionURL.appending(path: "transaction.json")
        )
        try interruptIfRequested(.staged, interruption)

        let objectPath = try objectPath(for: importedText.contentDigest)
        let source = GlifiProjectSourceRecord(
            sourceID: sourceID,
            sourceRevisionID: importedText.sourceRevisionID,
            format: importedText.format,
            contentDigest: importedText.contentDigest,
            byteCount: importedText.bytes.count,
            objectPath: objectPath
        )
        let stagedObjectURL = transactionURL.appending(path: "source-object")
        try durableWrite(importedText.bytes, to: stagedObjectURL)
        try promoteObject(stagedObjectURL, source: source, in: packageURL)
        try interruptIfRequested(.objectPromoted, interruption)

        var sources = observedSnapshot.sources
        sources.append(source)
        sources.sort { $0.sourceRevisionID.canonicalValue < $1.sourceRevisionID.canonicalValue }
        let sourceRootDigest = try sourceRootDigest(sources)
        // A changed corpus invalidates every currently selected analytical artifact.
        // Historical generations remain intact; selective invalidation is performed by
        // artifact replacement when the corpus itself has not changed.
        let artifacts: [GlifiProjectArtifactRecord] = []
        let artifactRootDigest = try artifactRootDigest(artifacts)
        let investigationRootDigest = observedSnapshot.investigationRootDigest
        let targetGeneration = observedSnapshot.generation + 1
        let recordDigest = try generationRecordDigest(
            projectID: observedSnapshot.projectID,
            generation: targetGeneration,
            baseGeneration: observedSnapshot.generation,
            sourceRootDigest: sourceRootDigest,
            sourceCount: sources.count,
            artifactRootDigest: artifactRootDigest,
            artifactCount: artifacts.count,
            investigationRootDigest: investigationRootDigest,
            investigationEventCount: observedSnapshot.investigationEvents.count
        )
        let database = try GlifiSQLiteProjectStore.open(at: databaseURL(in: packageURL))
        try database.discardGenerations(after: observedSnapshot.generation)
        try database.prepareSourceGeneration(
            generation: targetGeneration,
            baseGeneration: observedSnapshot.generation,
            recordDigest: recordDigest,
            sourceRootDigest: sourceRootDigest,
            artifactRootDigest: artifactRootDigest,
            investigationRootDigest: investigationRootDigest,
            source: source
        )
        try interruptIfRequested(.databasePrepared, interruption)

        let manifest = GlifiProjectManifest(
            projectID: observedSnapshot.projectID,
            generation: targetGeneration,
            baseGeneration: observedSnapshot.generation,
            generationRecordDigest: recordDigest,
            sourceRootDigest: sourceRootDigest,
            sourceCount: sources.count,
            artifactRootDigest: artifactRootDigest,
            artifactCount: artifacts.count,
            investigationRootDigest: investigationRootDigest,
            investigationEventCount: observedSnapshot.investigationEvents.count
        )
        let candidateURL = transactionURL.appending(path: "manifest.json")
        try durableWrite(try GlifiCanonicalJSON.encode(manifest), to: candidateURL)
        let decodedCandidate = try JSONDecoder().decode(
            GlifiProjectManifest.self,
            from: Data(contentsOf: candidateURL)
        )
        try validate(decodedCandidate)
        try interruptIfRequested(.manifestPrepared, interruption)

        let rootManifestURL = manifestURL(in: packageURL)
        _ = try fileManager.replaceItemAt(rootManifestURL, withItemAt: candidateURL)
        try interruptIfRequested(.manifestReplaced, interruption)

        try database.markCommitted(generation: targetGeneration)
        try interruptIfRequested(.databaseCommitted, interruption)

        try? fileManager.removeItem(at: transactionURL)
        return try openVerified(at: packageURL)
    }

    static func commitArtifact(
        _ data: Data,
        descriptor: GlifiAnalysisDescriptor,
        at packageURL: URL,
        expectedSnapshot: GlifiProjectSnapshot,
        interruption: GlifiProjectCommitInterruption?
    ) throws -> GlifiProjectSnapshot {
        let writerLease = try GlifiProjectWriterLease.acquire(in: packageURL)
        defer { writerLease.release() }
        let observedSnapshot = try openVerified(at: packageURL)
        guard observedSnapshot.projectID == expectedSnapshot.projectID,
            observedSnapshot.generation == expectedSnapshot.generation,
            observedSnapshot.sourceRootDigest == expectedSnapshot.sourceRootDigest,
            observedSnapshot.artifactRootDigest == expectedSnapshot.artifactRootDigest,
            observedSnapshot.investigationRootDigest == expectedSnapshot.investigationRootDigest
        else {
            throw GlifiFailure(
                code: "project.stale-generation",
                category: .staleArtifact,
                operation: .persistProject,
                retryDisposition: .newRequest,
                retainedState: .lastCommittedGeneration,
                messageKey: "failure.project.stale-generation"
            )
        }
        guard descriptor.corpusVersionDigest == observedSnapshot.sourceRootDigest else {
            throw GlifiFailure(
                code: "project.artifact-corpus-mismatch",
                category: .staleArtifact,
                operation: .persistProject,
                retryDisposition: .newRequest,
                retainedState: .lastCommittedGeneration,
                messageKey: "failure.project.artifact-corpus-mismatch"
            )
        }

        let node = try GlifiAnalysisNode(descriptor: descriptor)
        let descriptorData = try GlifiCanonicalJSON.encode(descriptor)
        guard descriptorData.count <= GlifiProjectPackage.maximumDescriptorByteCount else {
            throw GlifiFailure(
                code: "project.descriptor-too-large",
                category: .insufficientResources,
                operation: .persistProject,
                retryDisposition: .afterCorrection,
                retainedState: .unchanged,
                messageKey: "failure.project.descriptor-too-large"
            )
        }
        let descriptorDigest = digest(descriptorData)
        guard descriptorDigest == (try descriptor.canonicalDigest()) else {
            throw GlifiFailure(
                code: "project.descriptor-canonicalization-mismatch",
                category: .invariantViolation,
                operation: .persistProject,
                retryDisposition: .never,
                retainedState: .validityUnknown,
                messageKey: "failure.project.descriptor-canonicalization-mismatch"
            )
        }
        let contentDigest = digest(data)
        let artifact = GlifiProjectArtifactRecord(
            artifactID: try ArtifactID(digest: contentDigest),
            node: node,
            descriptorDigest: descriptorDigest,
            descriptorByteCount: descriptorData.count,
            descriptorObjectPath: try descriptorObjectPath(for: descriptorDigest),
            contentDigest: contentDigest,
            byteCount: data.count,
            objectPath: try artifactObjectPath(for: contentDigest)
        )
        if observedSnapshot.artifacts.contains(artifact) {
            return observedSnapshot
        }

        var artifacts = observedSnapshot.artifacts
        if artifacts.contains(where: { $0.node.id == node.id }) {
            let graph = try GlifiAnalysisGraph(artifacts.map(\.node))
            let invalidated = Set(try graph.invalidatedNodeIDs(changing: [node.id]))
            artifacts.removeAll { invalidated.contains($0.node.id) }
        }
        artifacts.append(artifact)
        artifacts.sort { $0.node.id.canonicalValue < $1.node.id.canonicalValue }
        guard artifacts.count <= GlifiAnalysisGraphLimits.standard.maximumNodeCount else {
            throw GlifiFailure(
                code: "project.artifact-limit-exceeded",
                category: .insufficientResources,
                operation: .persistProject,
                retryDisposition: .afterCorrection,
                retainedState: .unchanged,
                messageKey: "failure.project.artifact-limit-exceeded"
            )
        }
        let candidateGraph = try GlifiAnalysisGraph(artifacts.map(\.node))
        let reusable = try candidateGraph.reusableNodeIDs(
            from: artifacts.map { try $0.reference }
        )
        guard reusable.count == artifacts.count else {
            throw GlifiFailure(
                code: "project.artifact-dependency-mismatch",
                category: .staleArtifact,
                operation: .persistProject,
                retryDisposition: .newRequest,
                retainedState: .lastCommittedGeneration,
                messageKey: "failure.project.artifact-dependency-mismatch"
            )
        }

        let transactionID = UUID().uuidString.lowercased()
        let transactionURL = packageURL.appending(
            path: "transactions/\(transactionID)",
            directoryHint: .isDirectory
        )
        try fileManager.createDirectory(at: transactionURL, withIntermediateDirectories: false)
        let targetGeneration = observedSnapshot.generation + 1
        let transactionState = TransactionState(
            transactionID: transactionID,
            baseGeneration: observedSnapshot.generation,
            targetGeneration: targetGeneration,
            state: "staging"
        )
        try durableWrite(
            try GlifiCanonicalJSON.encode(transactionState),
            to: transactionURL.appending(path: "transaction.json")
        )
        try interruptIfRequested(.staged, interruption)

        let stagedDescriptorURL = transactionURL.appending(path: "descriptor-object")
        try durableWrite(descriptorData, to: stagedDescriptorURL)
        try promoteArtifactObject(
            stagedDescriptorURL,
            relativePath: artifact.descriptorObjectPath,
            expectedDigest: artifact.descriptorDigest,
            expectedByteCount: artifact.descriptorByteCount,
            maximumByteCount: GlifiProjectPackage.maximumDescriptorByteCount,
            in: packageURL
        )
        let stagedArtifactURL = transactionURL.appending(path: "artifact-object")
        try durableWrite(data, to: stagedArtifactURL)
        try promoteArtifactObject(
            stagedArtifactURL,
            relativePath: artifact.objectPath,
            expectedDigest: artifact.contentDigest,
            expectedByteCount: artifact.byteCount,
            maximumByteCount: GlifiProjectPackage.maximumArtifactByteCount,
            in: packageURL
        )
        try interruptIfRequested(.objectPromoted, interruption)

        let artifactRootDigest = try artifactRootDigest(artifacts)
        let investigationRootDigest = observedSnapshot.investigationRootDigest
        let recordDigest = try generationRecordDigest(
            projectID: observedSnapshot.projectID,
            generation: targetGeneration,
            baseGeneration: observedSnapshot.generation,
            sourceRootDigest: observedSnapshot.sourceRootDigest,
            sourceCount: observedSnapshot.sources.count,
            artifactRootDigest: artifactRootDigest,
            artifactCount: artifacts.count,
            investigationRootDigest: investigationRootDigest,
            investigationEventCount: observedSnapshot.investigationEvents.count
        )
        let database = try GlifiSQLiteProjectStore.open(at: databaseURL(in: packageURL))
        try database.discardGenerations(after: observedSnapshot.generation)
        try database.prepareArtifactGeneration(
            generation: targetGeneration,
            baseGeneration: observedSnapshot.generation,
            recordDigest: recordDigest,
            sourceRootDigest: observedSnapshot.sourceRootDigest,
            artifactRootDigest: artifactRootDigest,
            artifacts: artifacts.map(storedRecord),
            investigationRootDigest: investigationRootDigest
        )
        try interruptIfRequested(.databasePrepared, interruption)

        let manifest = GlifiProjectManifest(
            projectID: observedSnapshot.projectID,
            generation: targetGeneration,
            baseGeneration: observedSnapshot.generation,
            generationRecordDigest: recordDigest,
            sourceRootDigest: observedSnapshot.sourceRootDigest,
            sourceCount: observedSnapshot.sources.count,
            artifactRootDigest: artifactRootDigest,
            artifactCount: artifacts.count,
            investigationRootDigest: investigationRootDigest,
            investigationEventCount: observedSnapshot.investigationEvents.count
        )
        let candidateURL = transactionURL.appending(path: "manifest.json")
        try durableWrite(try GlifiCanonicalJSON.encode(manifest), to: candidateURL)
        let decodedCandidate = try JSONDecoder().decode(
            GlifiProjectManifest.self,
            from: Data(contentsOf: candidateURL)
        )
        try validate(decodedCandidate)
        try interruptIfRequested(.manifestPrepared, interruption)

        _ = try fileManager.replaceItemAt(manifestURL(in: packageURL), withItemAt: candidateURL)
        try interruptIfRequested(.manifestReplaced, interruption)
        try database.markCommitted(generation: targetGeneration)
        try interruptIfRequested(.databaseCommitted, interruption)

        try? fileManager.removeItem(at: transactionURL)
        return try openVerified(at: packageURL)
    }

    static func commitInvestigationEvent(
        _ event: GlifiInvestigationEvent,
        at packageURL: URL,
        expectedSnapshot: GlifiProjectSnapshot
    ) throws -> GlifiProjectSnapshot {
        let writerLease = try GlifiProjectWriterLease.acquire(in: packageURL)
        defer { writerLease.release() }
        let observedSnapshot = try openVerified(at: packageURL)
        guard observedSnapshot.projectID == expectedSnapshot.projectID,
            observedSnapshot.generation == expectedSnapshot.generation,
            observedSnapshot.sourceRootDigest == expectedSnapshot.sourceRootDigest,
            observedSnapshot.artifactRootDigest == expectedSnapshot.artifactRootDigest,
            observedSnapshot.investigationRootDigest == expectedSnapshot.investigationRootDigest
        else {
            throw GlifiFailure(
                code: "project.stale-generation",
                category: .staleArtifact,
                operation: .investigate,
                retryDisposition: .newRequest,
                retainedState: .lastCommittedGeneration,
                messageKey: "failure.project.stale-generation"
            )
        }

        let data = try GlifiCanonicalJSON.encode(event)
        guard !data.isEmpty, data.count <= GlifiProjectPackage.maximumInvestigationEventByteCount
        else {
            throw GlifiFailure(
                code: "project.investigation-event-too-large",
                category: .insufficientResources,
                operation: .investigate,
                retryDisposition: .afterCorrection,
                retainedState: .unchanged,
                messageKey: "failure.project.investigation-event-too-large"
            )
        }
        let contentDigest = digest(data)
        let eventID = try event.eventID()
        guard eventID.digest == contentDigest else {
            throw corruption("project.investigation-event-canonicalization-mismatch")
        }
        let record = GlifiProjectInvestigationEventRecord(
            eventID: eventID,
            investigationID: event.investigationID,
            predecessorEventID: event.predecessorEventID,
            contentDigest: contentDigest,
            byteCount: data.count,
            objectPath: try investigationEventObjectPath(for: contentDigest)
        )
        if observedSnapshot.investigationEvents.contains(record) { return observedSnapshot }

        let sameInvestigation = observedSnapshot.investigationEvents.filter {
            $0.investigationID == event.investigationID
        }
        if let predecessor = event.predecessorEventID {
            guard sameInvestigation.contains(where: { $0.eventID == predecessor }) else {
                throw GlifiFailure(
                    code: "investigation.predecessor-not-found",
                    category: .invalidInput,
                    operation: .investigate,
                    retryDisposition: .newRequest,
                    retainedState: .lastCommittedGeneration,
                    messageKey: "failure.investigation.predecessor-not-found"
                )
            }
        } else if !sameInvestigation.isEmpty {
            throw GlifiFailure(
                code: "investigation.duplicate-root",
                category: .invalidInput,
                operation: .investigate,
                retryDisposition: .afterCorrection,
                retainedState: .lastCommittedGeneration,
                messageKey: "failure.investigation.duplicate-root"
            )
        }

        var events = observedSnapshot.investigationEvents
        events.append(record)
        events.sort { $0.eventID.canonicalValue < $1.eventID.canonicalValue }
        guard events.count <= 100_000 else {
            throw GlifiFailure(
                code: "project.investigation-event-limit-exceeded",
                category: .insufficientResources,
                operation: .investigate,
                retryDisposition: .afterCorrection,
                retainedState: .lastCommittedGeneration,
                messageKey: "failure.project.investigation-event-limit-exceeded"
            )
        }

        let transactionID = UUID().uuidString.lowercased()
        let transactionURL = packageURL.appending(
            path: "transactions/\(transactionID)",
            directoryHint: .isDirectory
        )
        try fileManager.createDirectory(at: transactionURL, withIntermediateDirectories: false)
        let targetGeneration = observedSnapshot.generation + 1
        try durableWrite(
            try GlifiCanonicalJSON.encode(
                TransactionState(
                    transactionID: transactionID,
                    baseGeneration: observedSnapshot.generation,
                    targetGeneration: targetGeneration,
                    state: "staging"
                )
            ),
            to: transactionURL.appending(path: "transaction.json")
        )
        let stagedEventURL = transactionURL.appending(path: "investigation-event")
        try durableWrite(data, to: stagedEventURL)
        try promoteArtifactObject(
            stagedEventURL,
            relativePath: record.objectPath,
            expectedDigest: record.contentDigest,
            expectedByteCount: record.byteCount,
            maximumByteCount: GlifiProjectPackage.maximumInvestigationEventByteCount,
            in: packageURL
        )

        let investigationRootDigest = try investigationRootDigest(events)
        let recordDigest = try generationRecordDigest(
            projectID: observedSnapshot.projectID,
            generation: targetGeneration,
            baseGeneration: observedSnapshot.generation,
            sourceRootDigest: observedSnapshot.sourceRootDigest,
            sourceCount: observedSnapshot.sources.count,
            artifactRootDigest: observedSnapshot.artifactRootDigest,
            artifactCount: observedSnapshot.artifacts.count,
            investigationRootDigest: investigationRootDigest,
            investigationEventCount: events.count
        )
        let database = try GlifiSQLiteProjectStore.open(at: databaseURL(in: packageURL))
        try database.discardGenerations(after: observedSnapshot.generation)
        try database.prepareInvestigationGeneration(
            generation: targetGeneration,
            baseGeneration: observedSnapshot.generation,
            recordDigest: recordDigest,
            sourceRootDigest: observedSnapshot.sourceRootDigest,
            artifactRootDigest: observedSnapshot.artifactRootDigest,
            investigationRootDigest: investigationRootDigest,
            events: events
        )

        let manifest = GlifiProjectManifest(
            projectID: observedSnapshot.projectID,
            generation: targetGeneration,
            baseGeneration: observedSnapshot.generation,
            generationRecordDigest: recordDigest,
            sourceRootDigest: observedSnapshot.sourceRootDigest,
            sourceCount: observedSnapshot.sources.count,
            artifactRootDigest: observedSnapshot.artifactRootDigest,
            artifactCount: observedSnapshot.artifacts.count,
            investigationRootDigest: investigationRootDigest,
            investigationEventCount: events.count
        )
        let candidateURL = transactionURL.appending(path: "manifest.json")
        try durableWrite(try GlifiCanonicalJSON.encode(manifest), to: candidateURL)
        try validate(
            JSONDecoder().decode(
                GlifiProjectManifest.self,
                from: Data(contentsOf: candidateURL)
            )
        )
        _ = try fileManager.replaceItemAt(manifestURL(in: packageURL), withItemAt: candidateURL)
        try database.markCommitted(generation: targetGeneration)
        try? fileManager.removeItem(at: transactionURL)
        return try openVerified(at: packageURL)
    }

    static func validatedObjectURL(
        for source: GlifiProjectSourceRecord,
        in packageURL: URL
    ) throws -> URL {
        guard source.objectPath == (try objectPath(for: source.contentDigest)),
            source.byteCount >= 0,
            source.objectPath.utf8.count <= 256,
            !source.objectPath.hasPrefix("/"),
            !source.objectPath.split(separator: "/").contains("..")
        else {
            throw corruption("project.illegal-object-reference")
        }
        let objectURL = packageURL.appending(path: source.objectPath)
        let standardizedRoot = packageURL.standardizedFileURL.path + "/"
        guard objectURL.standardizedFileURL.path.hasPrefix(standardizedRoot) else {
            throw corruption("project.object-path-escape")
        }
        let observation = try digestFile(objectURL, maximumByteCount: source.byteCount)
        guard observation.byteCount == source.byteCount,
            observation.digest == source.contentDigest
        else {
            throw corruption("project.object-digest-mismatch")
        }
        return objectURL
    }

    static func validatedArtifactRecord(
        for stored: GlifiStoredProjectArtifactRecord,
        in packageURL: URL
    ) throws -> GlifiProjectArtifactRecord {
        let expectedDescriptorPath = try descriptorObjectPath(for: stored.descriptorDigest)
        guard stored.descriptorObjectPath == expectedDescriptorPath,
            stored.descriptorByteCount >= 0,
            stored.descriptorByteCount <= GlifiProjectPackage.maximumDescriptorByteCount,
            stored.outputSchemaIdentifier.utf8.count <= 1_024
        else {
            throw corruption("project.illegal-descriptor-reference")
        }
        let descriptorURL = try containedObjectURL(
            relativePath: stored.descriptorObjectPath,
            in: packageURL
        )
        let observation = try readFile(
            descriptorURL,
            maximumByteCount: stored.descriptorByteCount,
            retainBytes: true
        )
        guard observation.digest == stored.descriptorDigest,
            observation.byteCount == stored.descriptorByteCount,
            let descriptorData = observation.data
        else {
            throw corruption("project.descriptor-digest-mismatch")
        }
        let descriptor: GlifiAnalysisDescriptor
        do {
            descriptor = try JSONDecoder().decode(
                GlifiAnalysisDescriptor.self,
                from: descriptorData
            )
        } catch {
            throw corruption("project.descriptor-invalid")
        }
        guard try descriptor.nodeID() == stored.nodeID,
            try descriptor.canonicalDigest() == stored.descriptorDigest,
            descriptor.outputSchemaIdentifier == stored.outputSchemaIdentifier,
            stored.artifactID.digest == stored.contentDigest
        else {
            throw corruption("project.artifact-metadata-mismatch")
        }
        let record = GlifiProjectArtifactRecord(
            artifactID: stored.artifactID,
            node: try GlifiAnalysisNode(descriptor: descriptor),
            descriptorDigest: stored.descriptorDigest,
            descriptorByteCount: stored.descriptorByteCount,
            descriptorObjectPath: stored.descriptorObjectPath,
            contentDigest: stored.contentDigest,
            byteCount: stored.byteCount,
            objectPath: stored.objectPath
        )
        _ = try validatedArtifactObjectURL(for: record, in: packageURL)
        return record
    }

    private static func validatedArtifactObjectURL(
        for artifact: GlifiProjectArtifactRecord,
        in packageURL: URL
    ) throws -> URL {
        guard artifact.objectPath == (try artifactObjectPath(for: artifact.contentDigest)),
            artifact.artifactID.digest == artifact.contentDigest,
            artifact.byteCount >= 0,
            artifact.byteCount <= GlifiProjectPackage.maximumArtifactByteCount
        else {
            throw corruption("project.illegal-artifact-reference")
        }
        let objectURL = try containedObjectURL(relativePath: artifact.objectPath, in: packageURL)
        let observation = try digestFile(objectURL, maximumByteCount: artifact.byteCount)
        guard observation.byteCount == artifact.byteCount,
            observation.digest == artifact.contentDigest
        else {
            throw corruption("project.artifact-digest-mismatch")
        }
        return objectURL
    }

    private static func containedObjectURL(relativePath: String, in packageURL: URL) throws -> URL {
        guard relativePath.utf8.count <= 256,
            !relativePath.hasPrefix("/"),
            !relativePath.split(separator: "/").contains("..")
        else {
            throw corruption("project.illegal-object-reference")
        }
        let objectURL = packageURL.appending(path: relativePath)
        let standardizedRoot = packageURL.standardizedFileURL.path + "/"
        guard objectURL.standardizedFileURL.path.hasPrefix(standardizedRoot) else {
            throw corruption("project.object-path-escape")
        }
        return objectURL
    }

    static func readValidatedObject(
        _ objectURL: URL,
        source: GlifiProjectSourceRecord
    ) throws -> Data {
        let observation = try readFile(
            objectURL,
            maximumByteCount: source.byteCount,
            retainBytes: true
        )
        guard observation.byteCount == source.byteCount,
            observation.digest == source.contentDigest,
            let data = observation.data
        else {
            throw corruption("project.object-digest-mismatch")
        }
        return data
    }

    static func readValidatedArtifact(
        _ artifact: GlifiProjectArtifactRecord,
        in packageURL: URL
    ) throws -> Data {
        let objectURL = try validatedArtifactObjectURL(for: artifact, in: packageURL)
        let observation = try readFile(
            objectURL,
            maximumByteCount: artifact.byteCount,
            retainBytes: true
        )
        guard observation.byteCount == artifact.byteCount,
            observation.digest == artifact.contentDigest,
            let data = observation.data
        else {
            throw corruption("project.artifact-digest-mismatch")
        }
        return data
    }

    static func readValidatedInvestigationEvent(
        _ record: GlifiProjectInvestigationEventRecord,
        in packageURL: URL
    ) throws -> GlifiInvestigationEvent {
        guard record.objectPath == (try investigationEventObjectPath(for: record.contentDigest)),
            record.byteCount > 0,
            record.byteCount <= GlifiProjectPackage.maximumInvestigationEventByteCount,
            record.eventID.digest == record.contentDigest
        else {
            throw corruption("project.illegal-investigation-event-reference")
        }
        let objectURL = try containedObjectURL(relativePath: record.objectPath, in: packageURL)
        let observation = try readFile(
            objectURL,
            maximumByteCount: record.byteCount,
            retainBytes: true
        )
        guard observation.byteCount == record.byteCount,
            observation.digest == record.contentDigest,
            let data = observation.data,
            let event = try? JSONDecoder().decode(GlifiInvestigationEvent.self, from: data),
            try event.eventID() == record.eventID,
            event.investigationID == record.investigationID,
            event.predecessorEventID == record.predecessorEventID
        else {
            throw corruption("project.investigation-event-mismatch")
        }
        return event
    }

    static func sourceRootDigest(_ sources: [GlifiProjectSourceRecord]) throws -> String {
        let ordered = sources.sorted {
            $0.sourceRevisionID.canonicalValue < $1.sourceRevisionID.canonicalValue
        }
        return digest(try GlifiCanonicalJSON.encode(ordered))
    }

    static func artifactRootDigest(_ artifacts: [GlifiProjectArtifactRecord]) throws -> String {
        let ordered = artifacts.sorted {
            $0.node.id.canonicalValue < $1.node.id.canonicalValue
        }
        return digest(try GlifiCanonicalJSON.encode(ordered))
    }

    static func investigationRootDigest(
        _ events: [GlifiProjectInvestigationEventRecord]
    ) throws -> String {
        let ordered = events.sorted {
            $0.eventID.canonicalValue < $1.eventID.canonicalValue
        }
        return digest(try GlifiCanonicalJSON.encode(ordered))
    }

    static func generationRecordDigest(
        projectID: ProjectID,
        generation: Int,
        baseGeneration: Int?,
        sourceRootDigest: String,
        sourceCount: Int,
        artifactRootDigest: String,
        artifactCount: Int,
        investigationRootDigest: String,
        investigationEventCount: Int
    ) throws -> String {
        try digest(
            GlifiCanonicalJSON.encode(
                GenerationRecordDigestInput(
                    projectID: projectID,
                    generation: generation,
                    baseGeneration: baseGeneration,
                    sourceRootDigest: sourceRootDigest,
                    sourceCount: sourceCount,
                    artifactRootDigest: artifactRootDigest,
                    artifactCount: artifactCount,
                    investigationRootDigest: investigationRootDigest,
                    investigationEventCount: investigationEventCount
                )
            )
        )
    }

    static func classify(_ error: Error, operation: GlifiOperationKind) -> GlifiFailure {
        if let failure = error as? GlifiFailure {
            return failure
        }
        let cocoaError = error as NSError
        let authorizationCodes: Set<Int> = [
            CocoaError.fileReadNoPermission.rawValue,
            CocoaError.fileWriteNoPermission.rawValue,
        ]
        if authorizationCodes.contains(cocoaError.code) {
            return GlifiFailure(
                code: "project.authorization-denied",
                category: .authorizationDenied,
                operation: operation,
                retryDisposition: .afterUserAction,
                retainedState: .lastCommittedGeneration,
                messageKey: "failure.project.authorization-denied"
            )
        }
        return GlifiFailure(
            code: "project.io-failed",
            category: .transientIO,
            operation: operation,
            retryDisposition: .transientBackoff,
            retainedState: .lastCommittedGeneration,
            messageKey: "failure.project.io-failed",
            arguments: ["code": String(cocoaError.code)]
        )
    }

    private static func validate(_ manifest: GlifiProjectManifest) throws {
        guard manifest.schema == GlifiProjectManifest.schema else {
            throw corruption("project.manifest-schema-mismatch")
        }
        guard
            (GlifiProjectManifest.previousSchemaVersion...GlifiProjectManifest.schemaVersion)
                .contains(manifest.schemaVersion),
            manifest.formatVersion == GlifiProjectManifest.formatVersion,
            manifest.minimumReaderVersion <= GlifiProjectManifest.formatVersion
        else {
            throw GlifiFailure(
                code: "project.incompatible-version",
                category: .incompatibleVersion,
                operation: .persistProject,
                retryDisposition: .never,
                retainedState: .readOnlyRecovery,
                messageKey: "failure.project.incompatible-version"
            )
        }
        guard manifest.generation >= 0,
            manifest.sourceCount >= 0,
            manifest.artifactCount >= 0,
            manifest.investigationEventCount >= 0,
            (manifest.generation == 0) == (manifest.baseGeneration == nil),
            manifest.baseGeneration.map({ $0 >= 0 && $0 < manifest.generation }) ?? true,
            isSHA256Digest(manifest.generationRecordDigest),
            isSHA256Digest(manifest.sourceRootDigest),
            isSHA256Digest(manifest.artifactRootDigest),
            isSHA256Digest(manifest.investigationRootDigest)
        else {
            throw corruption("project.manifest-invariant-violation")
        }
        guard
            manifest.schemaVersion != GlifiProjectManifest.previousSchemaVersion
                || (manifest.investigationRootDigest
                    == GlifiProjectManifest.emptyInvestigationRootDigest
                    && manifest.investigationEventCount == 0)
        else {
            throw corruption("project.manifest-invariant-violation")
        }
    }

    private static func objectPath(for contentDigest: String) throws -> String {
        guard isSHA256Digest(contentDigest) else {
            throw corruption("project.invalid-content-digest")
        }
        let hex = String(contentDigest.dropFirst("sha256:".count))
        return "sources/objects/sha256/\(hex.prefix(2))/\(hex)"
    }

    private static func artifactObjectPath(for contentDigest: String) throws -> String {
        guard isSHA256Digest(contentDigest) else {
            throw corruption("project.invalid-artifact-digest")
        }
        let hex = String(contentDigest.dropFirst("sha256:".count))
        return "artifacts/objects/sha256/\(hex.prefix(2))/\(hex)"
    }

    private static func descriptorObjectPath(for descriptorDigest: String) throws -> String {
        guard isSHA256Digest(descriptorDigest) else {
            throw corruption("project.invalid-descriptor-digest")
        }
        let hex = String(descriptorDigest.dropFirst("sha256:".count))
        return "artifacts/descriptors/sha256/\(hex.prefix(2))/\(hex).json"
    }

    private static func investigationEventObjectPath(for contentDigest: String) throws -> String {
        guard isSHA256Digest(contentDigest) else {
            throw corruption("project.invalid-investigation-event-digest")
        }
        let hex = String(contentDigest.dropFirst("sha256:".count))
        return "investigations/events/sha256/\(hex.prefix(2))/\(hex).json"
    }

    private static func promoteObject(
        _ stagedURL: URL,
        source: GlifiProjectSourceRecord,
        in packageURL: URL
    ) throws {
        let objectURL = packageURL.appending(path: source.objectPath)
        try fileManager.createDirectory(
            at: objectURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        if fileManager.fileExists(atPath: objectURL.path) {
            _ = try validatedObjectURL(for: source, in: packageURL)
            try fileManager.removeItem(at: stagedURL)
            return
        }
        try fileManager.moveItem(at: stagedURL, to: objectURL)
        _ = try validatedObjectURL(for: source, in: packageURL)
    }

    private static func promoteArtifactObject(
        _ stagedURL: URL,
        relativePath: String,
        expectedDigest: String,
        expectedByteCount: Int,
        maximumByteCount: Int,
        in packageURL: URL
    ) throws {
        let objectURL = try containedObjectURL(relativePath: relativePath, in: packageURL)
        try fileManager.createDirectory(
            at: objectURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        if fileManager.fileExists(atPath: objectURL.path) {
            let observation = try digestFile(objectURL, maximumByteCount: maximumByteCount)
            guard observation.digest == expectedDigest,
                observation.byteCount == expectedByteCount
            else {
                throw corruption("project.artifact-object-collision")
            }
            try fileManager.removeItem(at: stagedURL)
            return
        }
        try fileManager.moveItem(at: stagedURL, to: objectURL)
        let observation = try digestFile(objectURL, maximumByteCount: maximumByteCount)
        guard observation.digest == expectedDigest,
            observation.byteCount == expectedByteCount
        else {
            throw corruption("project.artifact-object-promotion-failed")
        }
    }

    private static func storedRecord(
        _ artifact: GlifiProjectArtifactRecord
    ) -> GlifiStoredProjectArtifactRecord {
        GlifiStoredProjectArtifactRecord(
            artifactID: artifact.artifactID,
            nodeID: artifact.node.id,
            descriptorDigest: artifact.descriptorDigest,
            descriptorByteCount: artifact.descriptorByteCount,
            descriptorObjectPath: artifact.descriptorObjectPath,
            contentDigest: artifact.contentDigest,
            byteCount: artifact.byteCount,
            objectPath: artifact.objectPath,
            outputSchemaIdentifier: artifact.node.descriptor.outputSchemaIdentifier
        )
    }

    private static func durableWrite(_ data: Data, to url: URL) throws {
        guard !fileManager.fileExists(atPath: url.path) else {
            throw GlifiFailure(
                code: "project.unexpected-existing-file",
                category: .corruption,
                operation: .persistProject,
                retryDisposition: .never,
                retainedState: .lastCommittedGeneration,
                messageKey: "failure.project.unexpected-existing-file"
            )
        }
        guard fileManager.createFile(atPath: url.path, contents: nil) else {
            throw GlifiFailure(
                code: "project.file-create-failed",
                category: .transientIO,
                operation: .persistProject,
                retryDisposition: .transientBackoff,
                retainedState: .lastCommittedGeneration,
                messageKey: "failure.project.file-create-failed"
            )
        }
        let handle = try FileHandle(forWritingTo: url)
        defer { try? handle.close() }
        try handle.write(contentsOf: data)
        try handle.synchronize()
        try handle.close()
    }

    private static func digestFile(
        _ url: URL,
        maximumByteCount: Int
    ) throws -> (digest: String, byteCount: Int) {
        let observation = try readFile(
            url,
            maximumByteCount: maximumByteCount,
            retainBytes: false
        )
        return (observation.digest, observation.byteCount)
    }

    private static func readFile(
        _ url: URL,
        maximumByteCount: Int,
        retainBytes: Bool
    ) throws -> (digest: String, byteCount: Int, data: Data?) {
        var status = stat()
        guard lstat(url.path, &status) == 0,
            (status.st_mode & S_IFMT) == S_IFREG,
            status.st_nlink == 1,
            status.st_size >= 0,
            status.st_size <= maximumByteCount
        else {
            throw corruption("project.invalid-object-file")
        }
        let descriptor = Darwin.open(url.path, O_RDONLY | O_CLOEXEC | O_NOFOLLOW)
        guard descriptor >= 0 else {
            throw corruption("project.object-open-failed")
        }
        let handle = FileHandle(fileDescriptor: descriptor, closeOnDealloc: true)
        defer { try? handle.close() }
        var hasher = SHA256()
        var byteCount = 0
        var retainedData = retainBytes ? Data(capacity: Int(status.st_size)) : nil
        while true {
            try Task.checkCancellation()
            guard let chunk = try handle.read(upToCount: 1_048_576), !chunk.isEmpty else {
                break
            }
            byteCount += chunk.count
            guard byteCount <= maximumByteCount else {
                throw corruption("project.object-size-mismatch")
            }
            hasher.update(data: chunk)
            retainedData?.append(chunk)
        }
        let digest = hasher.finalize().map { String(format: "%02x", $0) }.joined()
        return ("sha256:\(digest)", byteCount, retainedData)
    }

    private static func digest(_ data: Data) -> String {
        let digest = SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
        return "sha256:\(digest)"
    }

    private static func isSHA256Digest(_ value: String) -> Bool {
        let bytes = value.utf8
        guard bytes.count == 71, value.hasPrefix("sha256:") else {
            return false
        }
        return bytes.dropFirst(7).allSatisfy { byte in
            (48...57).contains(byte) || (97...102).contains(byte)
        }
    }

    private static func interruptIfRequested(
        _ step: GlifiProjectCommitInterruption,
        _ requested: GlifiProjectCommitInterruption?
    ) throws {
        guard step == requested else { return }
        throw GlifiFailure(
            code: "test.interrupted-commit",
            category: .transientIO,
            operation: .persistProject,
            retryDisposition: .newRequest,
            retainedState: step == .manifestReplaced || step == .databaseCommitted
                ? .lastCommittedGeneration : .unchanged,
            messageKey: "failure.test.interrupted-commit"
        )
    }

    private static func corruption(_ code: String) -> GlifiFailure {
        GlifiFailure(
            code: code,
            category: .corruption,
            operation: .persistProject,
            retryDisposition: .never,
            retainedState: .readOnlyRecovery,
            messageKey: "failure.project.corruption"
        )
    }
}

private enum GlifiCanonicalJSON {
    static func encode<T: Encodable>(_ value: T) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
        return try encoder.encode(value)
    }
}

private struct GenerationRecordDigestInput: Codable {
    let projectID: ProjectID
    let generation: Int
    let baseGeneration: Int?
    let sourceRootDigest: String
    let sourceCount: Int
    let artifactRootDigest: String
    let artifactCount: Int
    let investigationRootDigest: String
    let investigationEventCount: Int
}

private struct TransactionState: Codable {
    let transactionID: String
    let baseGeneration: Int
    let targetGeneration: Int
    let state: String
}

private final class GlifiProjectWriterLease {
    private let descriptor: Int32
    private var isReleased = false

    private init(descriptor: Int32) {
        self.descriptor = descriptor
    }

    static func acquire(in packageURL: URL) throws -> GlifiProjectWriterLease {
        let lockURL = packageURL.appending(path: "transactions/.writer.lock")
        let descriptor = Darwin.open(lockURL.path, O_RDWR | O_CREAT | O_CLOEXEC, 0o600)
        guard descriptor >= 0 else {
            throw failure()
        }
        guard flock(descriptor, LOCK_EX | LOCK_NB) == 0 else {
            Darwin.close(descriptor)
            throw failure()
        }
        return GlifiProjectWriterLease(descriptor: descriptor)
    }

    func release() {
        guard !isReleased else { return }
        _ = flock(descriptor, LOCK_UN)
        Darwin.close(descriptor)
        isReleased = true
    }

    deinit {
        release()
    }

    private static func failure() -> GlifiFailure {
        GlifiFailure(
            code: "project.writer-busy",
            category: .transientIO,
            operation: .persistProject,
            retryDisposition: .transientBackoff,
            retainedState: .lastCommittedGeneration,
            messageKey: "failure.project.writer-busy"
        )
    }
}
