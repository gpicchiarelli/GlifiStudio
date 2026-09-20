// SPDX-License-Identifier: BSD-3-Clause

import Foundation
import Testing

@testable import GlifiCore

@Test("Jaccard e Dice rispettano i casi limite degli insiemi e i valori esatti attesi")
func setSimilarityMatchesSpecifiedCases() throws {
    let empty = Set<String>()
    #expect(GlifiSetSimilarity.jaccard(empty, empty) == 1)
    #expect(GlifiSetSimilarity.dice(empty, empty) == 1)

    let nonEmpty: Set<String> = ["a", "b"]
    #expect(GlifiSetSimilarity.jaccard(nonEmpty, empty) == 0)
    #expect(GlifiSetSimilarity.dice(nonEmpty, empty) == 0)
    #expect(GlifiSetSimilarity.jaccard(empty, nonEmpty) == 0)

    #expect(GlifiSetSimilarity.jaccard(nonEmpty, nonEmpty) == 1)
    #expect(GlifiSetSimilarity.dice(nonEmpty, nonEmpty) == 1)

    let a: Set<String> = ["a", "b", "c"]
    let b: Set<String> = ["b", "c", "d"]
    #expect(abs(GlifiSetSimilarity.jaccard(a, b) - 0.5) < 1e-12)
    #expect(abs(GlifiSetSimilarity.dice(a, b) - (2.0 / 3.0)) < 1e-9)
}

@Test("Coseno, euclidea e Manhattan coincidono con i valori attesi su vettori noti")
func vectorSimilarityMatchesKnownValues() throws {
    #expect(try abs(GlifiVectorSimilarity.cosine([1, 0], [0, 1])) < 1e-12)
    #expect(try abs(GlifiVectorSimilarity.cosine([1, 2, 3], [1, 2, 3]) - 1) < 1e-12)
    // Vettore parallelo (scalato): coseno = 1 indipendentemente dalla norma.
    #expect(try abs(GlifiVectorSimilarity.cosine([1, 2, 3], [2, 4, 6]) - 1) < 1e-9)

    // Triangolo 3-4-5.
    #expect(try abs(GlifiVectorSimilarity.euclidean([0, 0], [3, 4]) - 5) < 1e-12)
    #expect(try abs(GlifiVectorSimilarity.manhattan([0, 0], [3, 4]) - 7) < 1e-12)

    do {
        _ = try GlifiVectorSimilarity.cosine([0, 0], [1, 1])
        Issue.record("Il vettore nullo non è stato rifiutato")
    } catch let failure as GlifiFailure {
        #expect(failure.code == "similarity.zero-vector")
    }
    do {
        _ = try GlifiVectorSimilarity.euclidean([1, 2], [1, 2, 3])
        Issue.record("La dimensione disallineata non è stata rifiutata")
    } catch let failure as GlifiFailure {
        #expect(failure.code == "similarity.dimension-mismatch")
    }

    // Simmetria e disuguaglianza triangolare su un caso concreto.
    let x: [Double] = [0, 0]
    let y: [Double] = [3, 0]
    let z: [Double] = [3, 4]
    let xy = try GlifiVectorSimilarity.euclidean(x, y)
    let yx = try GlifiVectorSimilarity.euclidean(y, x)
    let yz = try GlifiVectorSimilarity.euclidean(y, z)
    let xz = try GlifiVectorSimilarity.euclidean(x, z)
    #expect(abs(xy - yx) < 1e-12)
    #expect(xz <= xy + yz + 1e-9)
}

@Test("KL, Jensen-Shannon ed Hellinger coincidono con i casi noti in forma chiusa")
func probabilityDivergenceMatchesClosedFormCases() throws {
    let uniform: [Double] = [0.5, 0.5]
    #expect(try abs(GlifiProbabilityDivergence.klDivergence(uniform, uniform)) < 1e-12)
    #expect(
        try abs(GlifiProbabilityDivergence.jensenShannonDivergence(uniform, uniform)) < 1e-12
    )
    #expect(try abs(GlifiProbabilityDivergence.hellinger(uniform, uniform)) < 1e-12)

    // Masse puntuali disgiunte su due esiti: caso estremo con forma chiusa nota.
    let pointA: [Double] = [1, 0]
    let pointB: [Double] = [0, 1]
    // KL(pointA‖pointB) è indefinita: q_2=0 dove p_2... in realtà p_1=1>0 e q_1=0.
    do {
        _ = try GlifiProbabilityDivergence.klDivergence(pointA, pointB)
        Issue.record("La KL indefinita non è stata rifiutata")
    } catch let failure as GlifiFailure {
        #expect(failure.code == "similarity.kl-undefined")
    }
    // JS(pointA,pointB) = 1 bit esatto: m=[0.5,0.5], KL(p‖m)=KL(q‖m)=log2(2)=1.
    let jsDivergence = try GlifiProbabilityDivergence.jensenShannonDivergence(pointA, pointB)
    #expect(abs(jsDivergence - 1) < 1e-9)
    let jsDistance = try GlifiProbabilityDivergence.jensenShannonDistance(pointA, pointB)
    #expect(abs(jsDistance - 1) < 1e-9)
    // Hellinger fra masse puntuali disgiunte è il massimo teorico, esattamente 1.
    let hellingerDistance = try GlifiProbabilityDivergence.hellinger(pointA, pointB)
    #expect(abs(hellingerDistance - 1) < 1e-9)

    // Simmetria di JS ed Hellinger.
    #expect(
        try abs(
            GlifiProbabilityDivergence.jensenShannonDivergence(pointA, pointB)
                - GlifiProbabilityDivergence.jensenShannonDivergence(pointB, pointA)
        ) < 1e-12
    )
    #expect(
        try abs(
            GlifiProbabilityDivergence.hellinger(pointA, pointB)
                - GlifiProbabilityDivergence.hellinger(pointB, pointA)
        ) < 1e-12
    )

    do {
        _ = try GlifiProbabilityDivergence.klDivergence([0.5, 0.6], uniform)
        Issue.record("La distribuzione non normalizzata non è stata rifiutata")
    } catch let failure as GlifiFailure {
        #expect(failure.code == "similarity.not-normalized")
    }
    do {
        _ = try GlifiProbabilityDivergence.hellinger([1, 0, 0], uniform)
        Issue.record("La dimensione disallineata non è stata rifiutata")
    } catch let failure as GlifiFailure {
        #expect(failure.code == "similarity.dimension-mismatch")
    }
}
