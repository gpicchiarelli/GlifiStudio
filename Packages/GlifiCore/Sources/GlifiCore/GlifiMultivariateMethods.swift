// SPDX-License-Identifier: BSD-3-Clause

import Foundation

/// `CA-SVD-v1` result (GS-MET-001-10).
public struct GlifiCorrespondenceResult: Codable, Equatable, Sendable {
    /// Versioned method identity.
    public static let identifier = "CA-SVD-v1"

    /// Indexes of rows kept after excluding zero mass, in input order.
    public let includedRows: [Int]
    /// Indexes of columns kept after excluding zero mass, in input order.
    public let includedColumns: [Int]
    /// Row masses `r`.
    public let rowMasses: [Double]
    /// Column masses `c`.
    public let columnMasses: [Double]
    /// Singular values of the non-trivial axes.
    public let singularValues: [Double]
    /// Principal inertias `λ = σ²`.
    public let inertias: [Double]
    /// Total inertia `Σλ`, equal to `χ²/n`.
    public let totalInertia: Double
    /// Row principal coordinates `F = D_r^{-1/2} U Σ`, one row per included row.
    public let rowCoordinates: [[Double]]
    /// Column principal coordinates `G = D_c^{-1/2} V Σ`.
    public let columnCoordinates: [[Double]]
    /// Row contributions `r_i F_ik² / λ_k`.
    public let rowContributions: [[Double]]
    /// Column contributions `c_j G_jk² / λ_k`.
    public let columnContributions: [[Double]]
    /// Row `cos² = F_ik² / d_i²`.
    public let rowCosines: [[Double]]
    /// Column `cos² = G_jk² / d_j²`.
    public let columnCosines: [[Double]]
    /// Decomposition backend: `SVD-Jacobi-v1`, or `SVD-SubspaceIteration-v1` beyond its bound.
    public let backendIdentifier: String
}

/// `PCA-SVD-v1` result (GS-MET-001-15).
public struct GlifiPrincipalComponentsResult: Codable, Equatable, Sendable {
    /// Versioned method identity.
    public static let identifier = "PCA-SVD-v1"

    /// Whether columns were scaled to unit sample standard deviation.
    public let scaled: Bool
    /// Indexes of constant columns excluded from a scaled analysis.
    public let excludedConstantColumns: [Int]
    /// Column means removed by centering.
    public let means: [Double]
    /// Variance of each component `σ_k²/(m-1)`.
    public let variances: [Double]
    /// Share of each component in the total variance.
    public let varianceShares: [Double]
    /// Loadings `V`, one row per included column.
    public let loadings: [[Double]]
    /// Scores `UΣ`, one row per input row.
    public let scores: [[Double]]
    /// Decomposition backend: `SVD-Jacobi-v1`, or `SVD-SubspaceIteration-v1` beyond its bound.
    public let backendIdentifier: String
}

/// `LSA-SVD-v1` truncated decomposition.
public struct GlifiLatentSemanticResult: Codable, Equatable, Sendable {
    /// Versioned method identity.
    public static let identifier = "LSA-SVD-v1"

    /// Requested rank `k`.
    public let requestedRank: Int
    /// Effective rank, bounded by the numerical rank.
    public let effectiveRank: Int
    /// Retained singular values `Σ_k`.
    public let singularValues: [Double]
    /// All singular values, for diagnostics.
    public let allSingularValues: [Double]
    /// `U_k Σ_k`: row coordinates.
    public let rowCoordinates: [[Double]]
    /// `V_k Σ_k`: column coordinates.
    public let columnCoordinates: [[Double]]
    /// Frobenius norm of the residual `sqrt(||A||_F² - Σ_{i≤k} σ_i²)`.
    public let residualNorm: Double
    /// Decomposition backend: `SVD-Jacobi-v1`, or `SVD-SubspaceIteration-v1` beyond its bound.
    public let backendIdentifier: String
}

/// `NMF-Frobenius-v1` factorization `X ≈ WH`.
public struct GlifiNonNegativeFactorization: Codable, Equatable, Sendable {
    /// Versioned method identity.
    public static let identifier = "NMF-Frobenius-v1"
    /// Update rule identity.
    public static let updateIdentifier = "lee-seung-multiplicative-v1"

    /// Number of factors `k`.
    public let rank: Int
    /// Row factors `W` (`m × k`).
    public let w: [[Double]]
    /// Column factors `H` (`k × n`).
    public let h: [[Double]]
    /// Final objective `||X-WH||_F²`.
    public let objective: Double
    /// Objective after every iteration of the chosen restart.
    public let objectiveHistory: [Double]
    /// Iterations of the chosen restart.
    public let iterations: Int
    /// Whether the relative change fell below the tolerance.
    public let converged: Bool
    /// Seed of the first restart; restart `r` uses `seed + r`.
    public let seed: UInt64
    /// Number of restarts evaluated.
    public let restarts: Int
    /// Zero-based restart with the smallest objective.
    public let chosenRestart: Int
}

/// Linkage of `HAC-v1`.
public enum GlifiLinkage: String, Codable, Equatable, Sendable {
    /// Minimum dissimilarity.
    case single
    /// Maximum dissimilarity.
    case complete
    /// Mean dissimilarity.
    case average
    /// `Ward-v1` on Euclidean vectors.
    case ward
}

/// One merge of the agglomerative tree.
public struct GlifiMerge: Codable, Equatable, Sendable {
    /// Cluster identity of the first child: `0..<n` are singletons, `n+s` the cluster of step `s`.
    public let first: Int
    /// Cluster identity of the second child.
    public let second: Int
    /// Merge height: linkage dissimilarity, or `sqrt(2Δ)` for Ward.
    public let height: Double
    /// Ward increment `Δ = |A||B|/(|A|+|B|)·||μ_A-μ_B||²`, `nil` for other linkages.
    public let wardIncrement: Double?
    /// Size of the new cluster.
    public let size: Int
}

/// `HAC-v1` full merge tree.
public struct GlifiHierarchicalClustering: Codable, Equatable, Sendable {
    /// Versioned method identity.
    public static let identifier = "HAC-v1"

    /// Linkage used.
    public let linkage: GlifiLinkage
    /// `n-1` merges in order.
    public let merges: [GlifiMerge]
}

/// `KMeans-Lloyd-v1` result.
public struct GlifiKMeansResult: Codable, Equatable, Sendable {
    /// Versioned method identity.
    public static let identifier = "KMeans-Lloyd-v1"
    /// Initialization identity.
    public static let initializationIdentifier = "k-means++-v1"

    /// Cluster per row, `0..<k`, renumbered by first appearance.
    public let assignments: [Int]
    /// Final centroids.
    public let centers: [[Double]]
    /// `Σ||x_i-μ_{c_i}||²`.
    public let objective: Double
    /// Assignment passes of the chosen restart, including the final unchanged pass.
    public let iterations: Int
    /// Whether assignments stabilized before the iteration bound.
    public let converged: Bool
    /// Seed of the first restart; restart `r` uses `seed + r`.
    public let seed: UInt64
    /// Restarts evaluated.
    public let restarts: Int
}

/// Multivariate methods over bounded dense matrices.
public enum GlifiMultivariateMethods {
    /// Computes `CA-SVD-v1` of a non-negative frequency matrix.
    public static func correspondenceAnalysis(
        _ counts: [[Double]],
        denseCellLimit: Int = GlifiLinearAlgebra.maximumCellCount,
        truncatedAxisCount: Int = 10
    ) throws -> GlifiCorrespondenceResult {
        guard let width = counts.first?.count, counts.allSatisfy({ $0.count == width }),
            counts.allSatisfy({ $0.allSatisfy { $0.isFinite && $0 >= 0 } })
        else {
            throw multivariateFailure("ca.invalid-matrix", category: .invalidInput)
        }
        let rowTotals = counts.map { $0.reduce(0, +) }
        let columnTotals = (0..<width).map { column in counts.reduce(0) { $0 + $1[column] } }
        let includedRows = rowTotals.indices.filter { rowTotals[$0] > 0 }
        let includedColumns = columnTotals.indices.filter { columnTotals[$0] > 0 }
        guard includedRows.count >= 2, includedColumns.count >= 2 else {
            throw multivariateFailure("ca.insufficient-dimensions")
        }
        let total = rowTotals.reduce(0, +)
        let rowMasses = includedRows.map { rowTotals[$0] / total }
        let columnMasses = includedColumns.map { columnTotals[$0] / total }
        let standardized = includedRows.enumerated().map { rowPosition, row in
            includedColumns.enumerated().map { columnPosition, column in
                let expected = rowMasses[rowPosition] * columnMasses[columnPosition]
                return (counts[row][column] / total - expected) / expected.squareRoot()
            }
        }
        let dense = includedRows.count * includedColumns.count <= denseCellLimit
        let svd =
            dense
            ? try GlifiLinearAlgebra.singularValueDecomposition(standardized)
            : try GlifiLinearAlgebra.truncatedSingularValueDecomposition(
                standardized,
                rank: min(
                    truncatedAxisCount,
                    min(includedRows.count, includedColumns.count) - 1
                )
            )
        let axisCount = min(
            min(includedRows.count, includedColumns.count) - 1,
            svd.singularValues.filter { $0 > 1e-12 }.count
        )
        guard axisCount >= 1 else {
            throw multivariateFailure("ca.no-inertia")
        }
        let values = Array(svd.singularValues.prefix(axisCount))
        let inertias = values.map { $0 * $0 }
        let rowCoordinates = rowMasses.indices.map { row in
            (0..<axisCount).map { svd.u[row][$0] * values[$0] / rowMasses[row].squareRoot() }
        }
        let columnCoordinates = columnMasses.indices.map { column in
            (0..<axisCount).map {
                svd.v[column][$0] * values[$0] / columnMasses[column].squareRoot()
            }
        }
        func contributions(_ coordinates: [[Double]], _ masses: [Double]) -> [[Double]] {
            coordinates.indices.map { index in
                (0..<axisCount).map {
                    masses[index] * coordinates[index][$0] * coordinates[index][$0] / inertias[$0]
                }
            }
        }
        // d² dal centroide calcolata dalla matrice standardizzata, valida anche quando la SVD
        // troncata restituisce solo i primi assi: d_i² = Σ_j S_ij² / r_i, d_j² = Σ_i S_ij² / c_j.
        let rowDistances = standardized.indices.map { row in
            standardized[row].reduce(0) { $0 + $1 * $1 } / rowMasses[row]
        }
        let columnDistances = columnMasses.indices.map { column in
            standardized.reduce(0) { $0 + $1[column] * $1[column] } / columnMasses[column]
        }
        func cosines(_ coordinates: [[Double]], _ distances: [Double]) -> [[Double]] {
            coordinates.indices.map { index in
                coordinates[index].map { distances[index] > 0 ? $0 * $0 / distances[index] : 0 }
            }
        }
        let frobenius = standardized.reduce(0) { total, row in
            total + row.reduce(0) { $0 + $1 * $1 }
        }
        return GlifiCorrespondenceResult(
            includedRows: includedRows,
            includedColumns: includedColumns,
            rowMasses: rowMasses,
            columnMasses: columnMasses,
            singularValues: values,
            inertias: inertias,
            totalInertia: frobenius,
            rowCoordinates: rowCoordinates,
            columnCoordinates: columnCoordinates,
            rowContributions: contributions(rowCoordinates, rowMasses),
            columnContributions: contributions(columnCoordinates, columnMasses),
            rowCosines: cosines(rowCoordinates, rowDistances),
            columnCosines: cosines(columnCoordinates, columnDistances),
            backendIdentifier: dense
                ? GlifiSingularValueDecomposition.identifier
                : GlifiLinearAlgebra.truncatedIdentifier
        )
    }

    /// Computes `PCA-SVD-v1` of the rows of `matrix`.
    public static func principalComponents(
        _ matrix: [[Double]],
        scaled: Bool,
        denseCellLimit: Int = GlifiLinearAlgebra.maximumCellCount,
        truncatedComponentCount: Int = 10
    ) throws -> GlifiPrincipalComponentsResult {
        guard matrix.count >= 2, let width = matrix.first?.count, width >= 1,
            matrix.allSatisfy({ $0.count == width && $0.allSatisfy(\.isFinite) })
        else {
            throw multivariateFailure("pca.invalid-matrix", category: .invalidInput)
        }
        let rows = Double(matrix.count)
        let means = (0..<width).map { column in matrix.reduce(0) { $0 + $1[column] } / rows }
        let deviations = (0..<width).map { column in
            (matrix.reduce(0) { $0 + ($1[column] - means[column]) * ($1[column] - means[column]) }
                / (rows - 1)).squareRoot()
        }
        let excluded = scaled ? deviations.indices.filter { deviations[$0] <= 0 } : []
        let kept = (0..<width).filter { !excluded.contains($0) }
        guard !kept.isEmpty else {
            throw multivariateFailure("pca.no-variance")
        }
        let centered = matrix.map { row in
            kept.map { column in
                let value = row[column] - means[column]
                return scaled ? value / deviations[column] : value
            }
        }
        let dense = centered.count * kept.count <= denseCellLimit
        let svd =
            dense
            ? try GlifiLinearAlgebra.singularValueDecomposition(centered)
            : try GlifiLinearAlgebra.truncatedSingularValueDecomposition(
                centered,
                rank: min(truncatedComponentCount, min(centered.count, kept.count))
            )
        let variances = svd.singularValues.map { $0 * $0 / (rows - 1) }
        // Varianza totale dalla matrice centrata: corretta anche per la SVD troncata.
        let totalVariance =
            centered.reduce(0) { total, row in total + row.reduce(0) { $0 + $1 * $1 } }
            / (rows - 1)
        guard totalVariance > 0 else {
            throw multivariateFailure("pca.no-variance")
        }
        return GlifiPrincipalComponentsResult(
            scaled: scaled,
            excludedConstantColumns: excluded,
            means: means,
            variances: variances,
            varianceShares: variances.map { $0 / totalVariance },
            loadings: svd.v,
            scores: svd.u.map { row in
                row.indices.map { row[$0] * svd.singularValues[$0] }
            },
            backendIdentifier: dense
                ? GlifiSingularValueDecomposition.identifier
                : GlifiLinearAlgebra.truncatedIdentifier
        )
    }

    /// Computes `LSA-SVD-v1` with rank `k` on an already weighted matrix.
    public static func latentSemanticAnalysis(
        _ matrix: [[Double]],
        rank: Int
    ) throws -> GlifiLatentSemanticResult {
        guard rank >= 1 else {
            throw multivariateFailure("lsa.invalid-rank", category: .invalidInput)
        }
        let cells = matrix.count * (matrix.first?.count ?? 0)
        let dense = cells <= GlifiLinearAlgebra.maximumCellCount
        let svd =
            dense
            ? try GlifiLinearAlgebra.singularValueDecomposition(matrix)
            : try GlifiLinearAlgebra.truncatedSingularValueDecomposition(
                matrix,
                rank: min(rank, matrix.count, matrix.first?.count ?? 0)
            )
        let effective = min(rank, svd.rank)
        guard effective >= 1 else {
            throw multivariateFailure("lsa.zero-matrix")
        }
        let values = Array(svd.singularValues.prefix(effective))
        let frobenius = matrix.reduce(0) { total, row in total + row.reduce(0) { $0 + $1 * $1 } }
        let captured = values.reduce(0) { $0 + $1 * $1 }
        return GlifiLatentSemanticResult(
            requestedRank: rank,
            effectiveRank: effective,
            singularValues: values,
            allSingularValues: svd.singularValues,
            rowCoordinates: svd.u.map { row in (0..<effective).map { row[$0] * values[$0] } },
            columnCoordinates: svd.v.map { row in (0..<effective).map { row[$0] * values[$0] } },
            residualNorm: max(frobenius - captured, 0).squareRoot(),
            backendIdentifier: dense
                ? GlifiSingularValueDecomposition.identifier
                : GlifiLinearAlgebra.truncatedIdentifier
        )
    }

    /// Computes `NMF-Frobenius-v1` with Lee–Seung multiplicative updates.
    ///
    /// `W` and `H` start uniform in `(0,1]` from `SplitMix64-v1`; updates divide by the
    /// denominator plus `1e-12`; iteration stops when the relative objective change is below
    /// `tolerance`. The restart with the smallest final objective is returned.
    public static func nonNegativeFactorization(
        _ matrix: [[Double]],
        rank: Int,
        seed: UInt64,
        restarts: Int = 3,
        maximumIterations: Int = 2_000,
        tolerance: Double = 1e-10
    ) throws -> GlifiNonNegativeFactorization {
        guard let width = matrix.first?.count, width >= 1,
            matrix.allSatisfy({ $0.count == width && $0.allSatisfy { $0.isFinite && $0 >= 0 } })
        else {
            throw multivariateFailure("nmf.invalid-matrix", category: .invalidInput)
        }
        guard rank >= 1, rank <= min(matrix.count, width), (1...20).contains(restarts),
            (1...100_000).contains(maximumIterations)
        else {
            throw multivariateFailure("nmf.invalid-parameters", category: .invalidInput)
        }
        guard matrix.contains(where: { $0.contains { $0 > 0 } }) else {
            throw multivariateFailure("nmf.zero-matrix")
        }
        var best: GlifiNonNegativeFactorization?
        for restart in 0..<restarts {
            try Task.checkCancellation()
            var generator = GlifiSplitMix64(seed: seed &+ UInt64(restart))
            func uniform() -> Double { Double(generator.next() >> 11 + 1) / Double(1 << 53) }
            let initialW = matrix.map { _ in (0..<rank).map { _ in uniform() } }
            let initialH = (0..<rank).map { _ in (0..<width).map { _ in uniform() } }
            let run = try leeSeung(
                matrix,
                initialW: initialW,
                initialH: initialH,
                maximumIterations: maximumIterations,
                tolerance: tolerance
            )
            let (w, h, history, converged) = (run.w, run.h, run.history, run.converged)
            let previous = objective(matrix, initialW, initialH)
            let candidate = GlifiNonNegativeFactorization(
                rank: rank,
                w: w,
                h: h,
                objective: history.last ?? previous,
                objectiveHistory: history,
                iterations: history.count,
                converged: converged,
                seed: seed,
                restarts: restarts,
                chosenRestart: restart
            )
            if best == nil || candidate.objective < (best?.objective ?? .infinity) - 1e-15 {
                best = candidate
            }
        }
        guard let best else { throw multivariateFailure("nmf.no-restart") }
        return best
    }

    /// Lee–Seung multiplicative updates from explicit initial factors: `H` first, then `W`,
    /// each denominator increased by `1e-12`; stops after `maximumIterations` or when the
    /// relative objective change is below `tolerance` (a negative tolerance never stops early).
    static func leeSeung(
        _ matrix: [[Double]],
        initialW: [[Double]],
        initialH: [[Double]],
        maximumIterations: Int,
        tolerance: Double
    ) throws -> (w: [[Double]], h: [[Double]], history: [Double], converged: Bool) {
        var w = initialW
        var h = initialH
        let rank = h.count
        let width = matrix.first?.count ?? 0
        var history: [Double] = []
        var converged = false
        var previous = objective(matrix, w, h)
        for iteration in 0..<maximumIterations {
            if iteration.isMultiple(of: 256) { try Task.checkCancellation() }
            let wt = GlifiLinearAlgebra.transpose(w)
            let numeratorH = multiply(wt, matrix)
            let denominatorH = multiply(multiply(wt, w), h)
            for factor in 0..<rank {
                for column in 0..<width {
                    h[factor][column] *=
                        numeratorH[factor][column] / (denominatorH[factor][column] + 1e-12)
                }
            }
            let ht = GlifiLinearAlgebra.transpose(h)
            let numeratorW = multiply(matrix, ht)
            let denominatorW = multiply(w, multiply(h, ht))
            for row in w.indices {
                for factor in 0..<rank {
                    w[row][factor] *= numeratorW[row][factor] / (denominatorW[row][factor] + 1e-12)
                }
            }
            let current = objective(matrix, w, h)
            history.append(current)
            if abs(previous - current) <= tolerance * max(previous, 1e-300) {
                converged = true
                break
            }
            previous = current
        }
        return (w, h, history, converged)
    }

    /// Computes `HAC-v1` on Euclidean distances between rows.
    ///
    /// Single, complete and average use the Euclidean distance; Ward merges the pair with the
    /// smallest `Δ` and reports `sqrt(2Δ)` as height. Ties choose the smallest identities.
    public static func hierarchicalClustering(
        _ points: [[Double]],
        linkage: GlifiLinkage
    ) throws -> GlifiHierarchicalClustering {
        guard points.count >= 2, points.count <= 2_000, let width = points.first?.count,
            points.allSatisfy({ $0.count == width && $0.allSatisfy(\.isFinite) })
        else {
            throw multivariateFailure("hac.invalid-points", category: .invalidInput)
        }
        let count = points.count
        func distance(_ left: Int, _ right: Int) -> Double {
            zip(points[left], points[right]).reduce(0) { $0 + ($1.0 - $1.1) * ($1.0 - $1.1) }
                .squareRoot()
        }
        let pairwise = (0..<count).map { left in (0..<count).map { distance(left, $0) } }
        var clusters: [(identity: Int, members: [Int], centroid: [Double])] = (0..<count).map {
            ($0, [$0], points[$0])
        }
        var merges: [GlifiMerge] = []
        func dissimilarity(_ left: [Int], _ right: [Int]) -> Double {
            switch linkage {
            case .single:
                return left.flatMap { a in right.map { pairwise[a][$0] } }.min() ?? 0
            case .complete:
                return left.flatMap { a in right.map { pairwise[a][$0] } }.max() ?? 0
            case .average:
                return left.reduce(0) { total, a in total + right.reduce(0) { $0 + pairwise[a][$1] }
                }
                    / Double(left.count * right.count)
            case .ward:
                return 0
            }
        }
        for step in 0..<(count - 1) {
            if step.isMultiple(of: 64) { try Task.checkCancellation() }
            var bestPair = (0, 1)
            var bestValue = Double.infinity
            for left in 0..<clusters.count {
                for right in (left + 1)..<clusters.count {
                    let value: Double
                    if linkage == .ward {
                        let a = Double(clusters[left].members.count)
                        let b = Double(clusters[right].members.count)
                        let squared = zip(clusters[left].centroid, clusters[right].centroid)
                            .reduce(0) { $0 + ($1.0 - $1.1) * ($1.0 - $1.1) }
                        value = a * b / (a + b) * squared
                    } else {
                        value = dissimilarity(clusters[left].members, clusters[right].members)
                    }
                    if !bestValue.isFinite || value < bestValue - 1e-15 * max(1, bestValue) {
                        bestValue = value
                        bestPair = (left, right)
                    }
                }
            }
            let left = clusters[bestPair.0]
            let right = clusters[bestPair.1]
            let members = left.members + right.members
            let centroid = (0..<width).map { column in
                members.reduce(0) { $0 + points[$1][column] } / Double(members.count)
            }
            merges.append(
                GlifiMerge(
                    first: min(left.identity, right.identity),
                    second: max(left.identity, right.identity),
                    height: linkage == .ward ? (2 * bestValue).squareRoot() : bestValue,
                    wardIncrement: linkage == .ward ? bestValue : nil,
                    size: members.count
                )
            )
            clusters.remove(at: bestPair.1)
            clusters[bestPair.0] = (count + step, members, centroid)
        }
        return GlifiHierarchicalClustering(linkage: linkage, merges: merges)
    }

    /// Cuts a merge tree into `k` clusters, numbered by first appearance in row order.
    public static func cut(
        _ tree: GlifiHierarchicalClustering,
        pointCount: Int,
        clusterCount: Int
    ) throws -> [Int] {
        guard (1...pointCount).contains(clusterCount), tree.merges.count == pointCount - 1 else {
            throw multivariateFailure("hac.invalid-cut", category: .invalidInput)
        }
        var parent = Array(0..<(2 * pointCount - 1))
        func root(_ value: Int) -> Int {
            var current = value
            while parent[current] != current { current = parent[current] }
            return current
        }
        for (step, merge) in tree.merges.prefix(pointCount - clusterCount).enumerated() {
            parent[root(merge.first)] = pointCount + step
            parent[root(merge.second)] = pointCount + step
        }
        var renumber: [Int: Int] = [:]
        return (0..<pointCount).map { point in
            let value = root(point)
            if let existing = renumber[value] { return existing }
            renumber[value] = renumber.count
            return renumber.count - 1
        }
    }

    /// Computes `KMeans-Lloyd-v1` with `k-means++-v1` initialization and seeded restarts.
    public static func kMeans(
        _ points: [[Double]],
        clusterCount: Int,
        seed: UInt64,
        restarts: Int = 5,
        maximumIterations: Int = 300
    ) throws -> GlifiKMeansResult {
        guard let width = points.first?.count, width >= 1,
            points.allSatisfy({ $0.count == width && $0.allSatisfy(\.isFinite) })
        else {
            throw multivariateFailure("kmeans.invalid-points", category: .invalidInput)
        }
        guard (1...points.count).contains(clusterCount), (1...50).contains(restarts) else {
            throw multivariateFailure("kmeans.invalid-parameters", category: .invalidInput)
        }
        var best: GlifiKMeansResult?
        for restart in 0..<restarts {
            try Task.checkCancellation()
            var generator = GlifiSplitMix64(seed: seed &+ UInt64(restart))
            var centers = [points[generator.index(below: points.count)]]
            while centers.count < clusterCount {
                let weights = points.map { point in
                    centers.map { squaredDistance(point, $0) }.min() ?? 0
                }
                let total = weights.reduce(0, +)
                guard total > 0 else {
                    throw multivariateFailure("kmeans.insufficient-distinct-points")
                }
                // Estrazione proporzionale al peso: u uniforme in [0, total).
                let target = Double(generator.next() >> 11) / Double(1 << 53) * total
                var cumulative = 0.0
                var chosen = weights.count - 1
                for (index, weight) in weights.enumerated() {
                    cumulative += weight
                    if target < cumulative, weight > 0 {
                        chosen = index
                        break
                    }
                }
                centers.append(points[chosen])
            }
            let candidate = try lloyd(
                points, initialCenters: centers, maximumIterations: maximumIterations)
            let result = GlifiKMeansResult(
                assignments: candidate.assignments,
                centers: candidate.centers,
                objective: candidate.objective,
                iterations: candidate.iterations,
                converged: candidate.converged,
                seed: seed,
                restarts: restarts
            )
            if best == nil || result.objective < (best?.objective ?? .infinity) - 1e-12 {
                best = result
            }
        }
        guard let best else { throw multivariateFailure("kmeans.no-restart") }
        return best
    }

    /// Lloyd iterations from explicit initial centers; empty clusters are rejected.
    static func lloyd(
        _ points: [[Double]],
        initialCenters: [[Double]],
        maximumIterations: Int
    ) throws -> (
        assignments: [Int], centers: [[Double]], objective: Double, iterations: Int, converged: Bool
    ) {
        var centers = initialCenters
        var assignments = [Int](repeating: -1, count: points.count)
        var iterations = 0
        var converged = false
        while iterations < maximumIterations {
            iterations += 1
            let next = points.map { point in
                centers.indices.min {
                    let left = squaredDistance(point, centers[$0])
                    let right = squaredDistance(point, centers[$1])
                    return left == right ? $0 < $1 : left < right
                } ?? 0
            }
            // Come R (kmeans, Lloyd), il passo finale senza cambiamenti è contato.
            if next == assignments {
                converged = true
                break
            }
            assignments = next
            for cluster in centers.indices {
                let members = points.indices.filter { assignments[$0] == cluster }
                guard !members.isEmpty else {
                    throw multivariateFailure("kmeans.empty-cluster")
                }
                centers[cluster] = centers[cluster].indices.map { column in
                    members.reduce(0) { $0 + points[$1][column] } / Double(members.count)
                }
            }
        }
        let objective = points.indices.reduce(0) {
            $0 + squaredDistance(points[$1], centers[assignments[$1]])
        }
        return (assignments, centers, objective, iterations, converged)
    }

    private static func squaredDistance(_ left: [Double], _ right: [Double]) -> Double {
        zip(left, right).reduce(0) { $0 + ($1.0 - $1.1) * ($1.0 - $1.1) }
    }

    private static func multiply(_ left: [[Double]], _ right: [[Double]]) -> [[Double]] {
        let inner = right.count
        let width = right.first?.count ?? 0
        return left.map { row in
            (0..<width).map { column in
                var total = 0.0
                for index in 0..<inner { total += row[index] * right[index][column] }
                return total
            }
        }
    }

    private static func objective(_ matrix: [[Double]], _ w: [[Double]], _ h: [[Double]]) -> Double
    {
        let product = multiply(w, h)
        return matrix.indices.reduce(0) { total, row in
            total
                + matrix[row].indices.reduce(0) {
                    $0 + (matrix[row][$1] - product[row][$1]) * (matrix[row][$1] - product[row][$1])
                }
        }
    }
}

private func multivariateFailure(
    _ code: String,
    category: GlifiFailureCategory = .insufficientData
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
