// SPDX-License-Identifier: BSD-3-Clause

import Foundation

/// `JaccardSet-v1` and `DiceSet-v1` over finite sets.
public enum GlifiSetSimilarity {
    /// `|A∩B| / |A∪B|`; `1` when both sets are empty.
    public static let jaccardIdentifier = "JaccardSet-v1"
    /// `2|A∩B| / (|A|+|B|)`; `1` when both sets are empty.
    public static let diceIdentifier = "DiceSet-v1"

    /// `JaccardSet-v1` similarity.
    ///
    /// Never throws: both-empty is `1`, one-empty is `0`.
    public static func jaccard<Element: Hashable>(_ a: Set<Element>, _ b: Set<Element>) -> Double {
        if a.isEmpty, b.isEmpty { return 1 }
        let unionCount = a.union(b).count
        guard unionCount > 0 else { return 1 }
        return Double(a.intersection(b).count) / Double(unionCount)
    }

    /// `DiceSet-v1` similarity.
    ///
    /// Never throws: both-empty is `1`, one-empty is `0`.
    public static func dice<Element: Hashable>(_ a: Set<Element>, _ b: Set<Element>) -> Double {
        if a.isEmpty, b.isEmpty { return 1 }
        let denominator = a.count + b.count
        guard denominator > 0 else { return 1 }
        return 2 * Double(a.intersection(b).count) / Double(denominator)
    }
}

/// `Cosine-v1`, `Euclidean-v1`, and `Manhattan-v1` over aligned real vectors.
public enum GlifiVectorSimilarity {
    /// `(x·y) / (‖x‖₂‖y‖₂)`; undefined (throws) for a zero vector.
    public static let cosineIdentifier = "Cosine-v1"
    /// `sqrt[Σ(x_i-y_i)²]`.
    public static let euclideanIdentifier = "Euclidean-v1"
    /// `Σ|x_i-y_i|`.
    public static let manhattanIdentifier = "Manhattan-v1"

    /// `Cosine-v1` similarity.
    ///
    /// Throws for misaligned dimensions or a zero-norm vector.
    public static func cosine(_ x: [Double], _ y: [Double]) throws -> Double {
        try validateAligned(x, y)
        let dotProduct = zip(x, y).reduce(0.0) { $0 + $1.0 * $1.1 }
        let normX = x.reduce(0.0) { $0 + $1 * $1 }.squareRoot()
        let normY = y.reduce(0.0) { $0 + $1 * $1 }.squareRoot()
        guard normX > 0, normY > 0 else {
            throw similarityFailure("similarity.zero-vector", category: .insufficientData)
        }
        return dotProduct / (normX * normY)
    }

    /// `Euclidean-v1` distance.
    ///
    /// Throws for misaligned dimensions.
    public static func euclidean(_ x: [Double], _ y: [Double]) throws -> Double {
        try validateAligned(x, y)
        return zip(x, y).reduce(0.0) { result, pair in
            let difference = pair.0 - pair.1
            return result + difference * difference
        }.squareRoot()
    }

    /// `Manhattan-v1` distance.
    ///
    /// Throws for misaligned dimensions.
    public static func manhattan(_ x: [Double], _ y: [Double]) throws -> Double {
        try validateAligned(x, y)
        return zip(x, y).reduce(0.0) { $0 + abs($1.0 - $1.1) }
    }

    private static func validateAligned(_ x: [Double], _ y: [Double]) throws {
        guard !x.isEmpty, x.count == y.count else {
            throw similarityFailure("similarity.dimension-mismatch", category: .invalidInput)
        }
        guard x.allSatisfy(\.isFinite), y.allSatisfy(\.isFinite) else {
            throw similarityFailure("similarity.non-finite-value", category: .invalidInput)
        }
    }
}

/// `KL-v1`, `JSdiv-v1`, `JSdist-v1`, and `Hellinger-v1` over aligned, normalized
/// probability distributions (base-2 logarithm).
public enum GlifiProbabilityDivergence {
    /// Kullback–Leibler divergence; directional, not a metric.
    public static let klIdentifier = "KL-v1"
    /// Jensen–Shannon divergence; symmetric, not itself a metric.
    public static let jsDivergenceIdentifier = "JSdiv-v1"
    /// `sqrt(JSdiv-v1)`; a metric.
    public static let jsDistanceIdentifier = "JSdist-v1"
    /// Hellinger distance; a metric in `[0, 1]`.
    public static let hellingerIdentifier = "Hellinger-v1"

    /// `KL-v1(p‖q)` divergence.
    ///
    /// Throws when `q_i=0` where `p_i>0` (undefined).
    public static func klDivergence(_ p: [Double], _ q: [Double]) throws -> Double {
        try validateDistribution(p)
        try validateDistribution(q)
        try validateAlignedDistributions(p, q)
        var result = 0.0
        for (pValue, qValue) in zip(p, q) {
            guard pValue > 0 else { continue }
            guard qValue > 0 else {
                throw similarityFailure("similarity.kl-undefined", category: .insufficientData)
            }
            result += pValue * log2(pValue / qValue)
        }
        return result
    }

    /// Computes `JSdiv-v1`, always finite for two valid distributions.
    public static func jensenShannonDivergence(_ p: [Double], _ q: [Double]) throws -> Double {
        try validateDistribution(p)
        try validateDistribution(q)
        try validateAlignedDistributions(p, q)
        let mixture = zip(p, q).map { ($0 + $1) / 2 }
        let divergence =
            0.5 * (try klDivergence(p, mixture)) + 0.5 * (try klDivergence(q, mixture))
        return max(0, divergence)
    }

    /// Computes `JSdist-v1 = sqrt(JSdiv-v1)`.
    public static func jensenShannonDistance(_ p: [Double], _ q: [Double]) throws -> Double {
        try jensenShannonDivergence(p, q).squareRoot()
    }

    /// Computes `Hellinger-v1`.
    public static func hellinger(_ p: [Double], _ q: [Double]) throws -> Double {
        try validateDistribution(p)
        try validateDistribution(q)
        try validateAlignedDistributions(p, q)
        let sumOfSquares = zip(p, q).reduce(0.0) { result, pair in
            let difference = pair.0.squareRoot() - pair.1.squareRoot()
            return result + difference * difference
        }
        return sumOfSquares.squareRoot() / 2.0.squareRoot()
    }

    private static func validateDistribution(_ distribution: [Double]) throws {
        guard !distribution.isEmpty else {
            throw similarityFailure("similarity.empty-distribution", category: .invalidInput)
        }
        guard distribution.allSatisfy({ $0.isFinite && $0 >= 0 }) else {
            throw similarityFailure(
                "similarity.negative-or-non-finite-probability",
                category: .invalidInput
            )
        }
        guard abs(distribution.reduce(0, +) - 1) < 1e-9 else {
            throw similarityFailure("similarity.not-normalized", category: .invalidInput)
        }
    }

    private static func validateAlignedDistributions(_ p: [Double], _ q: [Double]) throws {
        guard p.count == q.count else {
            throw similarityFailure("similarity.dimension-mismatch", category: .invalidInput)
        }
    }
}

func similarityFailure(
    _ code: String,
    category: GlifiFailureCategory = .invalidInput
) -> GlifiFailure {
    GlifiFailure(
        code: code,
        category: category,
        operation: .analyze,
        retryDisposition: GlifiFailureTaxonomy.defaultRetry(category),
        retainedState: GlifiFailureTaxonomy.defaultRetained(category),
        messageKey: "failure.\(code)"
    )
}
