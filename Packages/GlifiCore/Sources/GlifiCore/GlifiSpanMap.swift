// SPDX-License-Identifier: BSD-3-Clause

import Foundation

/// Stable coordinate spaces used by the first text extraction pipeline.
public enum GlifiTextCoordinateSpace: String, Codable, Sendable {
    case sourceBytes
    case extractedUTF8
}

/// Strength of the relationship represented by one span-map segment.
public enum GlifiSpanMappingKind: String, Codable, Sendable {
    /// Output bytes are an unchanged contiguous copy of the input bytes.
    case exact
    /// Output is deterministically derived from the declared input ranges.
    case derivational
    /// Output has no source bytes, for example an inserted structural separator.
    case synthetic
}

/// One ordered mapping from an extracted UTF-8 interval to source-byte intervals.
public struct GlifiSpanMapSegment: Codable, Equatable, Sendable {
    /// Non-empty interval in the output coordinate space.
    public let outputRange: GlifiUTF8Range
    /// Ordered contributing intervals in the input coordinate space.
    public let inputRanges: [GlifiUTF8Range]
    /// Declared relationship between output and input.
    public let kind: GlifiSpanMappingKind

    /// Creates one segment.
    ///
    /// Full structural validation is performed by `GlifiSpanMap`.
    public init(
        outputRange: GlifiUTF8Range,
        inputRanges: [GlifiUTF8Range],
        kind: GlifiSpanMappingKind
    ) {
        self.outputRange = outputRange
        self.inputRanges = inputRanges
        self.kind = kind
    }
}

/// Versioned total map from extracted UTF-8 bytes back to immutable source bytes.
public struct GlifiSpanMap: Codable, Equatable, Sendable {
    /// Stable mapping contract implemented by this representation.
    public let contractIdentifier: String
    /// Source revision owning every input range.
    public let sourceRevisionID: SourceRevisionID
    /// Input coordinate space.
    public let inputSpace: GlifiTextCoordinateSpace
    /// Output coordinate space.
    public let outputSpace: GlifiTextCoordinateSpace
    /// Exact source length, including an optional UTF-8 BOM.
    public let inputByteCount: Int
    /// Exact extracted representation length.
    public let outputByteCount: Int
    /// Ordered segments covering every output byte exactly once.
    public let segments: [GlifiSpanMapSegment]

    /// Creates and validates a total, bounded span map.
    public init(
        contractIdentifier: String,
        sourceRevisionID: SourceRevisionID,
        inputByteCount: Int,
        outputByteCount: Int,
        segments: [GlifiSpanMapSegment]
    ) throws {
        guard !contractIdentifier.isEmpty,
            inputByteCount >= 0,
            outputByteCount >= 0,
            segments.count <= max(outputByteCount, 1)
        else {
            throw spanMapFailure("text.invalid-span-map")
        }

        var nextOutputOffset = 0
        for segment in segments {
            guard segment.outputRange.start == nextOutputOffset,
                segment.outputRange.end <= outputByteCount,
                segment.inputRanges.allSatisfy({
                    $0.start >= 0 && $0.end <= inputByteCount
                })
            else {
                throw spanMapFailure("text.invalid-span-map")
            }
            switch segment.kind {
            case .exact:
                guard segment.inputRanges.count == 1,
                    segment.inputRanges[0].count == segment.outputRange.count
                else {
                    throw spanMapFailure("text.invalid-span-map")
                }
            case .derivational:
                guard !segment.inputRanges.isEmpty else {
                    throw spanMapFailure("text.invalid-span-map")
                }
            case .synthetic:
                guard segment.inputRanges.isEmpty else {
                    throw spanMapFailure("text.invalid-span-map")
                }
            }
            nextOutputOffset = segment.outputRange.end
        }
        guard nextOutputOffset == outputByteCount else {
            throw spanMapFailure("text.invalid-span-map")
        }

        self.contractIdentifier = contractIdentifier
        self.sourceRevisionID = sourceRevisionID
        inputSpace = .sourceBytes
        outputSpace = .extractedUTF8
        self.inputByteCount = inputByteCount
        self.outputByteCount = outputByteCount
        self.segments = segments
    }

    /// Resolves every source interval contributing to one extracted interval.
    public func sourceRanges(for outputRange: GlifiUTF8Range) throws -> [GlifiUTF8Range] {
        guard outputRange.end <= outputByteCount else {
            throw spanMapFailure("text.span-out-of-bounds")
        }
        var result: [GlifiUTF8Range] = []
        for segment in segments {
            let lower = max(outputRange.start, segment.outputRange.start)
            let upper = min(outputRange.end, segment.outputRange.end)
            guard lower < upper else { continue }

            switch segment.kind {
            case .exact:
                let source = segment.inputRanges[0]
                let relativeStart = lower - segment.outputRange.start
                let relativeEnd = upper - segment.outputRange.start
                try append(
                    GlifiUTF8Range(
                        start: source.start + relativeStart,
                        end: source.start + relativeEnd
                    ),
                    to: &result
                )
            case .derivational:
                for inputRange in segment.inputRanges {
                    try append(inputRange, to: &result)
                }
            case .synthetic:
                continue
            }
        }
        return result
    }

    private func append(_ range: GlifiUTF8Range, to result: inout [GlifiUTF8Range]) throws {
        guard let last = result.last, last.end == range.start else {
            result.append(range)
            return
        }
        result[result.count - 1] = try GlifiUTF8Range(start: last.start, end: range.end)
    }
}

private func spanMapFailure(_ code: String) -> GlifiFailure {
    GlifiFailure(
        code: code,
        category: .invalidInput,
        operation: .importText,
        retryDisposition: .afterCorrection,
        retainedState: .unchanged,
        messageKey: "failure.\(code)"
    )
}
