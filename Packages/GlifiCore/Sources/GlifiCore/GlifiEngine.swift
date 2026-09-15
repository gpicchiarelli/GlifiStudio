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

/// One bounded concordance row resolved against immutable source bytes.
public struct GlifiProjectQueryMatch: Equatable, Sendable {
    /// Source revision that owns every returned interval and excerpt.
    public let sourceRevisionID: SourceRevisionID
    /// Exact UTF-8 match interval in the extracted text representation.
    public let range: GlifiUTF8Range
    /// Ordered source-byte intervals contributing to the extracted match.
    public let sourceRanges: [GlifiUTF8Range]
    /// Bounded text preceding the match.
    public let leftContext: String
    /// Exact surface covered by `range`.
    public let match: String
    /// Bounded text following the match.
    public let rightContext: String

    /// Creates a concordance row from already verified source coordinates.
    public init(
        sourceRevisionID: SourceRevisionID,
        range: GlifiUTF8Range,
        sourceRanges: [GlifiUTF8Range],
        leftContext: String,
        match: String,
        rightContext: String
    ) {
        self.sourceRevisionID = sourceRevisionID
        self.range = range
        self.sourceRanges = sourceRanges
        self.leftContext = leftContext
        self.match = match
        self.rightContext = rightContext
    }
}

/// Deterministic bounded project query result ordered by source identity and position.
public struct GlifiProjectQueryResult: Equatable, Sendable {
    /// Project queried by this result.
    public let projectID: ProjectID
    /// Exact authoritative generation queried.
    public let generation: Int
    /// Digest of the canonical query AST.
    public let queryDigest: String
    /// Number of source scopes selected by the predicate.
    public let matchedSourceCount: Int
    /// Bounded concordance rows in canonical order.
    public let matches: [GlifiProjectQueryMatch]
    /// Whether rows or source scans were curtailed by a declared limit.
    public let isTruncated: Bool

    /// Creates one immutable project query result.
    public init(
        projectID: ProjectID,
        generation: Int,
        queryDigest: String,
        matchedSourceCount: Int,
        matches: [GlifiProjectQueryMatch],
        isTruncated: Bool
    ) {
        self.projectID = projectID
        self.generation = generation
        self.queryDigest = queryDigest
        self.matchedSourceCount = matchedSourceCount
        self.matches = matches
        self.isTruncated = isTruncated
    }
}

/// Deterministic corpus profile bound to one verified project generation.
public struct GlifiProjectCorpusAnalysisResult: Equatable, Sendable {
    /// Project analyzed by this result.
    public let projectID: ProjectID
    /// Exact source generation captured before analysis.
    public let sourceGeneration: Int
    /// Authoritative generation that reaches the persisted Artifact.
    public let generation: Int
    /// Immutable persisted result identity.
    public let artifactID: ArtifactID
    /// Semantic producer identity.
    public let analysisNodeID: AnalysisNodeID
    /// Analytical values derived from every source in the captured generation.
    public let analysis: GlifiCorpusAnalysis

    /// Creates a result with explicit project and generation lineage.
    public init(
        projectID: ProjectID,
        sourceGeneration: Int,
        generation: Int,
        artifactID: ArtifactID,
        analysisNodeID: AnalysisNodeID,
        analysis: GlifiCorpusAnalysis
    ) {
        self.projectID = projectID
        self.sourceGeneration = sourceGeneration
        self.generation = generation
        self.artifactID = artifactID
        self.analysisNodeID = analysisNodeID
        self.analysis = analysis
    }
}

/// Deterministic two-group comparison bound to one verified project generation.
public struct GlifiProjectKeynessResult: Equatable, Sendable {
    /// Project that owns both compared populations.
    public let projectID: ProjectID
    /// Exact source generation captured before comparison.
    public let sourceGeneration: Int
    /// Authoritative generation that reaches the persisted Artifact.
    public let generation: Int
    /// Immutable persisted result identity.
    public let artifactID: ArtifactID
    /// Semantic producer identity.
    public let analysisNodeID: AnalysisNodeID
    /// Statistical comparison and complete population lineage.
    public let comparison: GlifiKeynessComparison

    /// Creates a result with explicit project and generation lineage.
    public init(
        projectID: ProjectID,
        sourceGeneration: Int,
        generation: Int,
        artifactID: ArtifactID,
        analysisNodeID: AnalysisNodeID,
        comparison: GlifiKeynessComparison
    ) {
        self.projectID = projectID
        self.sourceGeneration = sourceGeneration
        self.generation = generation
        self.artifactID = artifactID
        self.analysisNodeID = analysisNodeID
        self.comparison = comparison
    }
}

/// Provides the headless entry point to GlifiCore capabilities.
public actor GlifiEngine {
    private let defaultLanguageConfiguration: GlifiLanguageConfiguration
    private let textImporter: GlifiTextImporter
    private let textTokenizer: any GlifiTokenizing
    private let textAnalyzer: GlifiTextAnalyzer
    private let corpusAnalyzer: GlifiCorpusAnalyzer
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
        textTokenizer = tokenizer
        textAnalyzer = GlifiTextAnalyzer(tokenizer: tokenizer)
        corpusAnalyzer = GlifiCorpusAnalyzer(tokenizer: tokenizer)
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

    /// Profiles every source in one verified generation using bounded deterministic methods.
    public func analyzeCorpus(
        in project: GlifiProjectPackage,
        options: GlifiCorpusAnalysisOptions = .standard
    ) async throws -> GlifiProjectCorpusAnalysisResult {
        do {
            try Task.checkCancellation()
            let snapshot = await project.snapshot()
            try validateCorpusSelection(
                documentByteCounts: snapshot.sources.map(\.byteCount),
                options: options
            )
            let descriptor = try GlifiAnalysisArtifactDescriptorFactory.corpusProfile(
                projectID: snapshot.projectID,
                sourceRootDigest: snapshot.sourceRootDigest,
                sourceRevisionIDs: snapshot.sources.map(\.sourceRevisionID),
                tokenizationContractIdentifier: textTokenizer.tokenizationContractIdentifier,
                options: options
            )
            let nodeID = try descriptor.nodeID()
            if let artifact = snapshot.artifacts.first(where: { $0.node.id == nodeID }) {
                let data = try await project.artifactData(for: artifact.artifactID)
                let payload: GlifiCorpusAnalysisArtifactPayload = try decodeArtifact(data)
                guard payload.analysisNodeID == nodeID else {
                    throw analysisArtifactFailure("analysis.payload-node-mismatch")
                }
                try validatePlannedAnalysis(
                    payload.analysis,
                    sourceRevisionIDs: snapshot.sources.map(\.sourceRevisionID)
                )
                return GlifiProjectCorpusAnalysisResult(
                    projectID: snapshot.projectID,
                    sourceGeneration: snapshot.generation,
                    generation: snapshot.generation,
                    artifactID: artifact.artifactID,
                    analysisNodeID: nodeID,
                    analysis: payload.analysis
                )
            }

            var sources: [GlifiImportedText] = []
            sources.reserveCapacity(snapshot.sources.count)
            for source in snapshot.sources {
                try Task.checkCancellation()
                let data = try await project.sourceData(for: source.sourceRevisionID)
                sources.append(
                    try textImporter.importText(
                        from: data,
                        format: source.format,
                        limits: GlifiTextImportLimits(
                            maximumByteCount: options.maximumSourceByteCount
                        ),
                        sourceRevisionID: source.sourceRevisionID
                    )
                )
            }
            let analysis = try GlifiDiagnostics.measure(.analyzeCorpus) {
                try corpusAnalyzer.analyze(sources, options: options)
            }
            try validatePlannedAnalysis(
                analysis,
                sourceRevisionIDs: snapshot.sources.map(\.sourceRevisionID)
            )
            try Task.checkCancellation()
            let committed = try await project.storeArtifact(
                GlifiCorpusAnalysisArtifactPayload(
                    analysisNodeID: nodeID,
                    analysis: analysis
                ),
                descriptor: descriptor
            )
            guard let artifact = committed.artifacts.first(where: { $0.node.id == nodeID }) else {
                throw analysisArtifactFailure("analysis.persisted-artifact-missing")
            }
            return GlifiProjectCorpusAnalysisResult(
                projectID: snapshot.projectID,
                sourceGeneration: snapshot.generation,
                generation: committed.generation,
                artifactID: artifact.artifactID,
                analysisNodeID: nodeID,
                analysis: analysis
            )
        } catch let failure as GlifiFailure {
            throw failure
        } catch is CancellationError {
            throw GlifiFailure(
                code: "operation.cancelled",
                category: .cancelled,
                operation: .analyze,
                retryDisposition: .newRequest,
                retainedState: .lastCommittedGeneration,
                messageKey: "failure.operation.cancelled"
            )
        } catch {
            throw GlifiFailure(
                code: "analysis.internal-failure",
                category: .invariantViolation,
                operation: .analyze,
                retryDisposition: .never,
                retainedState: .validityUnknown,
                messageKey: "failure.analysis.internal-failure"
            )
        }
    }

    /// Compares two disjoint source-revision groups from one verified generation.
    public func compareKeyness(
        in project: GlifiProjectPackage,
        targetSourceRevisionIDs: [SourceRevisionID],
        referenceSourceRevisionIDs: [SourceRevisionID],
        corpusOptions: GlifiCorpusAnalysisOptions = .standard,
        keynessOptions: GlifiKeynessOptions = .standard
    ) async throws -> GlifiProjectKeynessResult {
        do {
            try Task.checkCancellation()
            guard !targetSourceRevisionIDs.isEmpty, !referenceSourceRevisionIDs.isEmpty else {
                throw keynessFailure("keyness.empty-group", category: .insufficientData)
            }
            guard Set(targetSourceRevisionIDs).count == targetSourceRevisionIDs.count,
                Set(referenceSourceRevisionIDs).count == referenceSourceRevisionIDs.count
            else {
                throw keynessFailure("keyness.duplicate-source", category: .invalidInput)
            }
            guard Set(targetSourceRevisionIDs).isDisjoint(with: referenceSourceRevisionIDs) else {
                throw keynessFailure("keyness.overlapping-groups", category: .invalidInput)
            }

            let snapshot = await project.snapshot()
            let recordsByID = Dictionary(
                uniqueKeysWithValues: snapshot.sources.map {
                    ($0.sourceRevisionID, $0)
                })
            let targetRecords = try selectedRecords(
                targetSourceRevisionIDs,
                recordsByID: recordsByID
            )
            let referenceRecords = try selectedRecords(
                referenceSourceRevisionIDs,
                recordsByID: recordsByID
            )
            try validateCorpusSelection(
                documentByteCounts: targetRecords.map(\.byteCount),
                options: corpusOptions
            )
            try validateCorpusSelection(
                documentByteCounts: referenceRecords.map(\.byteCount),
                options: corpusOptions
            )

            let targetArtifact = try await corpusAnalysisArtifact(
                targetRecords,
                projectID: snapshot.projectID,
                sourceRootDigest: snapshot.sourceRootDigest,
                options: corpusOptions,
                in: project
            )
            let referenceArtifact = try await corpusAnalysisArtifact(
                referenceRecords,
                projectID: snapshot.projectID,
                sourceRootDigest: snapshot.sourceRootDigest,
                options: corpusOptions,
                in: project
            )
            let dependencies = try [targetArtifact.record, referenceArtifact.record].map {
                artifact in
                try GlifiAnalysisDependency(
                    nodeID: artifact.node.id,
                    artifactDigest: artifact.contentDigest,
                    outputSchemaIdentifier: artifact.node.descriptor.outputSchemaIdentifier
                )
            }
            let descriptor = try GlifiAnalysisArtifactDescriptorFactory.keyness(
                projectID: snapshot.projectID,
                sourceRootDigest: snapshot.sourceRootDigest,
                targetSourceRevisionIDs: targetSourceRevisionIDs,
                referenceSourceRevisionIDs: referenceSourceRevisionIDs,
                linguisticProfileIdentifiers: [
                    targetArtifact.analysis.tokenizationContractIdentifier,
                    targetArtifact.analysis.normalizationIdentifier,
                ],
                options: keynessOptions,
                dependencies: dependencies
            )
            let nodeID = try descriptor.nodeID()
            let preparedSnapshot = await project.snapshot()
            if let artifact = preparedSnapshot.artifacts.first(where: { $0.node.id == nodeID }) {
                let data = try await project.artifactData(for: artifact.artifactID)
                let payload: GlifiKeynessArtifactPayload = try decodeArtifact(data)
                guard payload.analysisNodeID == nodeID else {
                    throw analysisArtifactFailure("keyness.payload-node-mismatch")
                }
                try validatePlannedKeyness(
                    payload.comparison,
                    target: targetArtifact.analysis,
                    reference: referenceArtifact.analysis,
                    options: keynessOptions
                )
                return GlifiProjectKeynessResult(
                    projectID: snapshot.projectID,
                    sourceGeneration: snapshot.generation,
                    generation: preparedSnapshot.generation,
                    artifactID: artifact.artifactID,
                    analysisNodeID: nodeID,
                    comparison: payload.comparison
                )
            }
            let comparison = try GlifiDiagnostics.measure(.compareKeyness) {
                try GlifiKeynessAnalyzer().compare(
                    target: targetArtifact.analysis,
                    reference: referenceArtifact.analysis,
                    options: keynessOptions
                )
            }
            try validatePlannedKeyness(
                comparison,
                target: targetArtifact.analysis,
                reference: referenceArtifact.analysis,
                options: keynessOptions
            )
            try Task.checkCancellation()
            let committed = try await project.storeArtifact(
                GlifiKeynessArtifactPayload(
                    analysisNodeID: nodeID,
                    comparison: comparison
                ),
                descriptor: descriptor
            )
            guard let artifact = committed.artifacts.first(where: { $0.node.id == nodeID }) else {
                throw analysisArtifactFailure("keyness.persisted-artifact-missing")
            }
            return GlifiProjectKeynessResult(
                projectID: snapshot.projectID,
                sourceGeneration: snapshot.generation,
                generation: committed.generation,
                artifactID: artifact.artifactID,
                analysisNodeID: nodeID,
                comparison: comparison
            )
        } catch let failure as GlifiFailure {
            throw failure
        } catch is CancellationError {
            throw GlifiFailure(
                code: "operation.cancelled",
                category: .cancelled,
                operation: .analyze,
                retryDisposition: .newRequest,
                retainedState: .lastCommittedGeneration,
                messageKey: "failure.operation.cancelled"
            )
        } catch {
            throw GlifiFailure(
                code: "keyness.internal-failure",
                category: .invariantViolation,
                operation: .analyze,
                retryDisposition: .never,
                retainedState: .validityUnknown,
                messageKey: "failure.keyness.internal-failure"
            )
        }
    }

    /// Parses and executes a bounded query against one verified project generation.
    public func query(
        _ queryText: String,
        in project: GlifiProjectPackage,
        limits: GlifiQueryLimits = .standard
    ) async throws -> GlifiProjectQueryResult {
        do {
            let query = try GlifiQueryParser(tokenizer: textTokenizer).parse(
                queryText,
                limits: limits
            )
            let queryDigest = try query.canonicalDigest()
            let snapshot = await project.snapshot()
            guard !snapshot.sources.isEmpty else {
                throw GlifiFailure(
                    code: "query.empty-project",
                    category: .insufficientData,
                    operation: .query,
                    retryDisposition: .afterCorrection,
                    retainedState: .lastCommittedGeneration,
                    messageKey: "failure.query.empty-project"
                )
            }
            guard snapshot.sources.count <= limits.maximumSourceCount else {
                throw GlifiFailure(
                    code: "query.source-limit-exceeded",
                    category: .insufficientResources,
                    operation: .query,
                    retryDisposition: .afterConditionsChange,
                    retainedState: .lastCommittedGeneration,
                    messageKey: "failure.query.source-limit-exceeded",
                    arguments: ["maximumSourceCount": String(limits.maximumSourceCount)]
                )
            }

            var scannedByteCount = 0
            var matchedSourceCount = 0
            var matches: [GlifiProjectQueryMatch] = []
            var isTruncated = false
            for source in snapshot.sources {
                try Task.checkCancellation()
                guard source.byteCount <= limits.maximumScannedByteCount - scannedByteCount else {
                    throw GlifiFailure(
                        code: "query.scan-byte-limit-exceeded",
                        category: .insufficientResources,
                        operation: .query,
                        retryDisposition: .afterConditionsChange,
                        retainedState: .lastCommittedGeneration,
                        messageKey: "failure.query.scan-byte-limit-exceeded",
                        arguments: [
                            "maximumScannedByteCount": String(limits.maximumScannedByteCount)
                        ]
                    )
                }
                scannedByteCount += source.byteCount
                let data = try await project.sourceData(for: source.sourceRevisionID)
                let importedText = try textImporter.importText(
                    from: data,
                    format: source.format,
                    sourceRevisionID: source.sourceRevisionID
                )
                let tokenization = try textTokenizer.tokenize(importedText.text)
                let result = try GlifiQueryEvaluator().evaluate(
                    query,
                    in: importedText,
                    tokenization: tokenization,
                    limits: limits
                )
                if result.matchedScope { matchedSourceCount += 1 }
                for match in result.matches {
                    guard matches.count < limits.maximumResultCount else {
                        isTruncated = true
                        break
                    }
                    guard let surface = match.range.text(in: importedText.text) else {
                        throw GlifiFailure(
                            code: "query.invalid-match",
                            category: .invariantViolation,
                            operation: .query,
                            retryDisposition: .never,
                            retainedState: .validityUnknown,
                            messageKey: "failure.query.invalid-match"
                        )
                    }
                    matches.append(
                        GlifiProjectQueryMatch(
                            sourceRevisionID: match.sourceRevisionID,
                            range: match.range,
                            sourceRanges: try importedText.spanMap.sourceRanges(
                                for: match.range
                            ),
                            leftContext: match.leftContextRange?.text(in: importedText.text) ?? "",
                            match: surface,
                            rightContext: match.rightContextRange?.text(in: importedText.text) ?? ""
                        )
                    )
                }
                isTruncated = isTruncated || result.isTruncated
                if isTruncated { break }
            }
            return GlifiProjectQueryResult(
                projectID: snapshot.projectID,
                generation: snapshot.generation,
                queryDigest: queryDigest,
                matchedSourceCount: matchedSourceCount,
                matches: matches,
                isTruncated: isTruncated
            )
        } catch let failure as GlifiFailure {
            throw failure
        } catch is CancellationError {
            throw GlifiFailure(
                code: "operation.cancelled",
                category: .cancelled,
                operation: .query,
                retryDisposition: .newRequest,
                retainedState: .lastCommittedGeneration,
                messageKey: "failure.operation.cancelled"
            )
        } catch {
            throw GlifiFailure(
                code: "query.internal-failure",
                category: .invariantViolation,
                operation: .query,
                retryDisposition: .never,
                retainedState: .validityUnknown,
                messageKey: "failure.query.internal-failure"
            )
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

    private func selectedRecords(
        _ sourceRevisionIDs: [SourceRevisionID],
        recordsByID: [SourceRevisionID: GlifiProjectSourceRecord]
    ) throws -> [GlifiProjectSourceRecord] {
        try sourceRevisionIDs.sorted {
            $0.canonicalValue < $1.canonicalValue
        }.map { sourceRevisionID in
            guard let record = recordsByID[sourceRevisionID] else {
                throw keynessFailure("keyness.source-not-found", category: .invalidInput)
            }
            return record
        }
    }

    private func corpusAnalysisArtifact(
        _ records: [GlifiProjectSourceRecord],
        projectID: ProjectID,
        sourceRootDigest: String,
        options: GlifiCorpusAnalysisOptions,
        in project: GlifiProjectPackage
    ) async throws -> (analysis: GlifiCorpusAnalysis, record: GlifiProjectArtifactRecord) {
        let descriptor = try GlifiAnalysisArtifactDescriptorFactory.corpusProfile(
            projectID: projectID,
            sourceRootDigest: sourceRootDigest,
            sourceRevisionIDs: records.map(\.sourceRevisionID),
            tokenizationContractIdentifier: textTokenizer.tokenizationContractIdentifier,
            options: options
        )
        let nodeID = try descriptor.nodeID()
        let currentSnapshot = await project.snapshot()
        guard currentSnapshot.sourceRootDigest == sourceRootDigest else {
            throw GlifiFailure(
                code: "project.artifact-corpus-mismatch",
                category: .staleArtifact,
                operation: .analyze,
                retryDisposition: .newRequest,
                retainedState: .lastCommittedGeneration,
                messageKey: "failure.project.artifact-corpus-mismatch"
            )
        }
        if let artifact = currentSnapshot.artifacts.first(where: { $0.node.id == nodeID }) {
            let data = try await project.artifactData(for: artifact.artifactID)
            let payload: GlifiCorpusAnalysisArtifactPayload = try decodeArtifact(data)
            guard payload.analysisNodeID == nodeID else {
                throw analysisArtifactFailure("analysis.payload-node-mismatch")
            }
            try validatePlannedAnalysis(
                payload.analysis,
                sourceRevisionIDs: records.map(\.sourceRevisionID)
            )
            return (payload.analysis, artifact)
        }
        let sources = try await importedSources(
            records,
            from: project,
            maximumSourceByteCount: options.maximumSourceByteCount
        )
        let analysis = try GlifiDiagnostics.measure(.analyzeCorpus) {
            try corpusAnalyzer.analyze(sources, options: options)
        }
        try validatePlannedAnalysis(
            analysis,
            sourceRevisionIDs: records.map(\.sourceRevisionID)
        )
        let committed = try await project.storeArtifact(
            GlifiCorpusAnalysisArtifactPayload(
                analysisNodeID: nodeID,
                analysis: analysis
            ),
            descriptor: descriptor
        )
        guard let artifact = committed.artifacts.first(where: { $0.node.id == nodeID }) else {
            throw analysisArtifactFailure("analysis.persisted-artifact-missing")
        }
        return (analysis, artifact)
    }

    private func decodeArtifact<Payload: Decodable>(_ data: Data) throws -> Payload {
        do {
            return try JSONDecoder().decode(Payload.self, from: data)
        } catch {
            throw GlifiFailure(
                code: "analysis.artifact-payload-invalid",
                category: .corruption,
                operation: .analyze,
                retryDisposition: .never,
                retainedState: .readOnlyRecovery,
                messageKey: "failure.analysis.artifact-payload-invalid"
            )
        }
    }

    private func validatePlannedAnalysis(
        _ analysis: GlifiCorpusAnalysis,
        sourceRevisionIDs: [SourceRevisionID]
    ) throws {
        let expectedIDs = sourceRevisionIDs.sorted {
            $0.canonicalValue < $1.canonicalValue
        }
        guard analysis.sourceRevisionIDs == expectedIDs,
            analysis.tokenizationContractIdentifier
                == textTokenizer.tokenizationContractIdentifier,
            analysis.normalizationIdentifier == "nfc-lowercase-it-v1",
            analysis.numericPolicyIdentifier == "IEEE-754-binary64-ordered-reduction-v1"
        else {
            throw analysisArtifactFailure("analysis.descriptor-result-mismatch")
        }
    }

    private func validatePlannedKeyness(
        _ comparison: GlifiKeynessComparison,
        target: GlifiCorpusAnalysis,
        reference: GlifiCorpusAnalysis,
        options: GlifiKeynessOptions
    ) throws {
        guard comparison.targetSourceRevisionIDs == target.sourceRevisionIDs,
            comparison.referenceSourceRevisionIDs == reference.sourceRevisionIDs,
            comparison.targetCorpusDigest == target.corpusDigest,
            comparison.referenceCorpusDigest == reference.corpusDigest,
            comparison.lowExpectedCountThreshold == options.lowExpectedCountThreshold,
            comparison.numericPolicyIdentifier == "IEEE-754-binary64-ordered-reduction-v1"
        else {
            throw analysisArtifactFailure("keyness.descriptor-result-mismatch")
        }
    }

    private func importedSources(
        _ records: [GlifiProjectSourceRecord],
        from project: GlifiProjectPackage,
        maximumSourceByteCount: Int
    ) async throws -> [GlifiImportedText] {
        var sources: [GlifiImportedText] = []
        sources.reserveCapacity(records.count)
        for record in records {
            try Task.checkCancellation()
            let data = try await project.sourceData(for: record.sourceRevisionID)
            sources.append(
                try textImporter.importText(
                    from: data,
                    format: record.format,
                    limits: GlifiTextImportLimits(maximumByteCount: maximumSourceByteCount),
                    sourceRevisionID: record.sourceRevisionID
                )
            )
        }
        return sources
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

private func analysisArtifactFailure(_ code: String) -> GlifiFailure {
    GlifiFailure(
        code: code,
        category: .invariantViolation,
        operation: .analyze,
        retryDisposition: .never,
        retainedState: .validityUnknown,
        messageKey: "failure.\(code)"
    )
}
