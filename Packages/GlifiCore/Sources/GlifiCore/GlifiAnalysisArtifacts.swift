// SPDX-License-Identifier: BSD-3-Clause

import CryptoKit
import Foundation

/// A versioned analytical payload whose schema must match its descriptor.
public protocol GlifiAnalysisArtifactPayload: Codable, Sendable {
    /// Stable output schema recorded by the producer descriptor.
    static var outputSchemaIdentifier: String { get }
}

/// Canonical persisted payload for `corpus-profile-it-v1`.
public struct GlifiCorpusAnalysisArtifactPayload:
    GlifiAnalysisArtifactPayload, Equatable, Sendable
{
    /// Stable artifact payload schema.
    public static let outputSchemaIdentifier = "studio.glifi.artifact.corpus-profile.v1"
    /// Current payload schema version.
    public static let schemaVersion = 1

    /// Stable schema serialized with the payload.
    public let schemaIdentifier: String
    /// Version serialized with the payload.
    public let schemaVersion: Int
    /// Semantic producer identity bound into the immutable payload.
    public let analysisNodeID: AnalysisNodeID
    /// Complete deterministic analytical result.
    public let analysis: GlifiCorpusAnalysis

    /// Creates the canonical payload for a verified corpus analysis.
    public init(analysisNodeID: AnalysisNodeID, analysis: GlifiCorpusAnalysis) {
        schemaIdentifier = Self.outputSchemaIdentifier
        schemaVersion = Self.schemaVersion
        self.analysisNodeID = analysisNodeID
        self.analysis = analysis
    }

    private enum CodingKeys: String, CodingKey {
        case schemaIdentifier, schemaVersion, analysisNodeID, analysis
    }

    /// Decodes only the supported schema and analytical family.
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let schemaIdentifier = try container.decode(String.self, forKey: .schemaIdentifier)
        let schemaVersion = try container.decode(Int.self, forKey: .schemaVersion)
        let analysisNodeID = try container.decode(AnalysisNodeID.self, forKey: .analysisNodeID)
        let analysis = try container.decode(GlifiCorpusAnalysis.self, forKey: .analysis)
        guard schemaIdentifier == Self.outputSchemaIdentifier,
            schemaVersion == Self.schemaVersion,
            analysis.analysisIdentifier == GlifiCorpusAnalyzer.analysisIdentifier
        else {
            throw DecodingError.dataCorruptedError(
                forKey: .schemaIdentifier,
                in: container,
                debugDescription: "Unsupported corpus-analysis artifact payload"
            )
        }
        self.schemaIdentifier = schemaIdentifier
        self.schemaVersion = schemaVersion
        self.analysisNodeID = analysisNodeID
        self.analysis = analysis
    }
}

/// Canonical persisted payload for `keyness-gtest-ha-bh-v1`.
public struct GlifiKeynessArtifactPayload: GlifiAnalysisArtifactPayload, Equatable, Sendable {
    /// Stable artifact payload schema.
    public static let outputSchemaIdentifier = "studio.glifi.artifact.keyness.v1"
    /// Current payload schema version.
    public static let schemaVersion = 1

    /// Stable schema serialized with the payload.
    public let schemaIdentifier: String
    /// Version serialized with the payload.
    public let schemaVersion: Int
    /// Semantic producer identity bound into the immutable payload.
    public let analysisNodeID: AnalysisNodeID
    /// Complete deterministic multiple-comparison result.
    public let comparison: GlifiKeynessComparison

    /// Creates the canonical payload for a verified keyness comparison.
    public init(analysisNodeID: AnalysisNodeID, comparison: GlifiKeynessComparison) {
        schemaIdentifier = Self.outputSchemaIdentifier
        schemaVersion = Self.schemaVersion
        self.analysisNodeID = analysisNodeID
        self.comparison = comparison
    }

    private enum CodingKeys: String, CodingKey {
        case schemaIdentifier, schemaVersion, analysisNodeID, comparison
    }

    /// Decodes only the supported schema and analytical family.
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let schemaIdentifier = try container.decode(String.self, forKey: .schemaIdentifier)
        let schemaVersion = try container.decode(Int.self, forKey: .schemaVersion)
        let analysisNodeID = try container.decode(AnalysisNodeID.self, forKey: .analysisNodeID)
        let comparison = try container.decode(GlifiKeynessComparison.self, forKey: .comparison)
        guard schemaIdentifier == Self.outputSchemaIdentifier,
            schemaVersion == Self.schemaVersion,
            comparison.comparisonIdentifier == GlifiKeynessAnalyzer.comparisonIdentifier
        else {
            throw DecodingError.dataCorruptedError(
                forKey: .schemaIdentifier,
                in: container,
                debugDescription: "Unsupported keyness artifact payload"
            )
        }
        self.schemaIdentifier = schemaIdentifier
        self.schemaVersion = schemaVersion
        self.analysisNodeID = analysisNodeID
        self.comparison = comparison
    }
}

enum GlifiArtifactCanonicalJSON {
    static func encode(_ value: some Encodable) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
        return try encoder.encode(value)
    }
}

enum GlifiAnalysisArtifactDescriptorFactory {
    static func corpusProfile(
        projectID: ProjectID,
        sourceRootDigest: String,
        sourceRevisionIDs: [SourceRevisionID],
        tokenizationContractIdentifier: String,
        options: GlifiCorpusAnalysisOptions
    ) throws -> GlifiAnalysisDescriptor {
        try GlifiAnalysisDescriptor(
            artifactTypeIdentifier: "studio.glifi.artifact.corpus-profile",
            algorithmIdentifier: GlifiCorpusAnalyzer.analysisIdentifier,
            algorithmVersion: "1",
            corpusIdentifier: projectID.canonicalValue,
            corpusVersionDigest: sourceRootDigest,
            selectionIdentifier: try selectionIdentifier(
                domain: "source-revisions.v1",
                values: sourceRevisionIDs.sorted {
                    $0.canonicalValue < $1.canonicalValue
                }.map(\.canonicalValue)
            ),
            analyticalUnitIdentifier: "source-revision.v1",
            preprocessingIdentifiers: ["source-extraction-contract-from-input-v1"],
            linguisticProfileIdentifiers: [
                tokenizationContractIdentifier,
                "nfc-lowercase-it-v1",
            ],
            representationIdentifier: "corpus-profile-table-and-sparse-matrix-v1",
            resolvedParameters: [
                "diversityWindowSize": .integer(Int64(options.diversityWindowSize)),
                "ngramSizes": .list(options.ngramSizes.map { .integer(Int64($0)) }),
            ],
            seedPolicyIdentifier: "none-v1",
            backendIdentifier: "swift-reference-v1",
            numericPolicyIdentifier: "IEEE-754-binary64-ordered-reduction-v1",
            determinismClass: .d1,
            outputSchemaIdentifier: GlifiCorpusAnalysisArtifactPayload.outputSchemaIdentifier,
            softwareIdentifier: "GlifiCore-0.1.0",
            dependencies: []
        )
    }

    static func keyness(
        projectID: ProjectID,
        sourceRootDigest: String,
        targetSourceRevisionIDs: [SourceRevisionID],
        referenceSourceRevisionIDs: [SourceRevisionID],
        linguisticProfileIdentifiers: [String],
        options: GlifiKeynessOptions,
        dependencies: [GlifiAnalysisDependency]
    ) throws -> GlifiAnalysisDescriptor {
        let targetSelection = targetSourceRevisionIDs.sorted {
            $0.canonicalValue < $1.canonicalValue
        }.map { "target:\($0.canonicalValue)" }
        let referenceSelection = referenceSourceRevisionIDs.sorted {
            $0.canonicalValue < $1.canonicalValue
        }.map { "reference:\($0.canonicalValue)" }
        let roleAwareSelection = targetSelection + referenceSelection
        return try GlifiAnalysisDescriptor(
            artifactTypeIdentifier: "studio.glifi.artifact.keyness",
            algorithmIdentifier: GlifiKeynessAnalyzer.comparisonIdentifier,
            algorithmVersion: "1",
            corpusIdentifier: projectID.canonicalValue,
            corpusVersionDigest: sourceRootDigest,
            selectionIdentifier: try selectionIdentifier(
                domain: "keyness-groups.v1",
                values: roleAwareSelection
            ),
            analyticalUnitIdentifier: "normalized-term.v1",
            preprocessingIdentifiers: ["corpus-profile-it-v1"],
            linguisticProfileIdentifiers: linguisticProfileIdentifiers,
            representationIdentifier: "keyness-multiple-comparison-table-v1",
            resolvedParameters: [
                "lowExpectedCountThreshold": .decimal(options.lowExpectedCountThreshold)
            ],
            seedPolicyIdentifier: "none-v1",
            backendIdentifier: "swift-reference-v1",
            numericPolicyIdentifier: "IEEE-754-binary64-ordered-reduction-v1",
            determinismClass: .d1,
            outputSchemaIdentifier: GlifiKeynessArtifactPayload.outputSchemaIdentifier,
            softwareIdentifier: "GlifiCore-0.1.0",
            dependencies: dependencies
        )
    }

    private static func selectionIdentifier(domain: String, values: [String]) throws -> String {
        struct Selection: Encodable {
            let domain: String
            let values: [String]
        }
        let data = try GlifiArtifactCanonicalJSON.encode(
            Selection(domain: domain, values: values)
        )
        let digest = SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
        return "\(domain):sha256:\(digest)"
    }
}
