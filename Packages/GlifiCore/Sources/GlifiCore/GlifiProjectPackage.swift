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

/// Verified authoritative view of one committed project generation.
public struct GlifiProjectSnapshot: Equatable, Sendable {
    /// Stable identity of the project aggregate.
    public let projectID: ProjectID
    /// Monotonic authoritative generation selected by the root manifest.
    public let generation: Int
    /// Ordered source revisions reachable from this generation.
    public let sources: [GlifiProjectSourceRecord]
    /// Digest of the canonical ordered source root.
    public let sourceRootDigest: String

    /// Creates an immutable verified snapshot.
    public init(
        projectID: ProjectID,
        generation: Int,
        sources: [GlifiProjectSourceRecord],
        sourceRootDigest: String
    ) {
        self.projectID = projectID
        self.generation = generation
        self.sources = sources
        self.sourceRootDigest = sourceRootDigest
    }
}

/// Bounded root manifest whose replacement is the project commit point.
public struct GlifiProjectManifest: Codable, Equatable, Sendable {
    /// Stable schema identifier.
    public static let schema = "studio.glifi.project-manifest"
    /// Current manifest schema version.
    public static let schemaVersion = 1
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

    init(
        projectID: ProjectID,
        generation: Int,
        baseGeneration: Int?,
        generationRecordDigest: String,
        sourceRootDigest: String,
        sourceCount: Int
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
    }
}

/// Owns transactional reads and writes for one local `.glifi` package.
public actor GlifiProjectPackage {
    /// Maximum accepted root-manifest size before decoding.
    public static let maximumManifestByteCount = 1_048_576

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
            let recordDigest = try GlifiProjectPackageIO.generationRecordDigest(
                projectID: projectID,
                generation: 0,
                baseGeneration: nil,
                sourceRootDigest: sourceRootDigest,
                sourceCount: 0
            )
            try database.insertInitialGeneration(
                recordDigest: recordDigest,
                sourceRootDigest: sourceRootDigest
            )
            let manifest = GlifiProjectManifest(
                projectID: projectID,
                generation: 0,
                baseGeneration: nil,
                generationRecordDigest: recordDigest,
                sourceRootDigest: sourceRootDigest,
                sourceCount: 0
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
}

enum GlifiProjectCommitInterruption: Sendable, CaseIterable {
    case staged
    case objectPromoted
    case databasePrepared
    case manifestPrepared
    case manifestReplaced
    case databaseCommitted
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
            try database.validateIntegrity(projectID: manifest.projectID)
            let generation = try database.generation(manifest.generation)
            guard generation.state == "prepared" || generation.state == "committed",
                generation.baseGeneration == manifest.baseGeneration,
                generation.recordDigest == manifest.generationRecordDigest,
                generation.sourceRootDigest == manifest.sourceRootDigest,
                generation.sourceCount == manifest.sourceCount
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
            return GlifiProjectSnapshot(
                projectID: manifest.projectID,
                generation: manifest.generation,
                sources: sources,
                sourceRootDigest: manifest.sourceRootDigest
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
            observedSnapshot.sourceRootDigest == expectedSnapshot.sourceRootDigest
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
        let targetGeneration = observedSnapshot.generation + 1
        let recordDigest = try generationRecordDigest(
            projectID: observedSnapshot.projectID,
            generation: targetGeneration,
            baseGeneration: observedSnapshot.generation,
            sourceRootDigest: sourceRootDigest,
            sourceCount: sources.count
        )
        let database = try GlifiSQLiteProjectStore.open(at: databaseURL(in: packageURL))
        try database.discardGenerations(after: observedSnapshot.generation)
        try database.prepareGeneration(
            generation: targetGeneration,
            baseGeneration: observedSnapshot.generation,
            recordDigest: recordDigest,
            sourceRootDigest: sourceRootDigest,
            source: source
        )
        try interruptIfRequested(.databasePrepared, interruption)

        let manifest = GlifiProjectManifest(
            projectID: observedSnapshot.projectID,
            generation: targetGeneration,
            baseGeneration: observedSnapshot.generation,
            generationRecordDigest: recordDigest,
            sourceRootDigest: sourceRootDigest,
            sourceCount: sources.count
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

    static func sourceRootDigest(_ sources: [GlifiProjectSourceRecord]) throws -> String {
        let ordered = sources.sorted {
            $0.sourceRevisionID.canonicalValue < $1.sourceRevisionID.canonicalValue
        }
        return digest(try GlifiCanonicalJSON.encode(ordered))
    }

    static func generationRecordDigest(
        projectID: ProjectID,
        generation: Int,
        baseGeneration: Int?,
        sourceRootDigest: String,
        sourceCount: Int
    ) throws -> String {
        try digest(
            GlifiCanonicalJSON.encode(
                GenerationRecordDigestInput(
                    projectID: projectID,
                    generation: generation,
                    baseGeneration: baseGeneration,
                    sourceRootDigest: sourceRootDigest,
                    sourceCount: sourceCount
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
        guard manifest.schemaVersion == GlifiProjectManifest.schemaVersion,
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
            (manifest.generation == 0) == (manifest.baseGeneration == nil),
            manifest.baseGeneration.map({ $0 >= 0 && $0 < manifest.generation }) ?? true,
            isSHA256Digest(manifest.generationRecordDigest),
            isSHA256Digest(manifest.sourceRootDigest)
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
