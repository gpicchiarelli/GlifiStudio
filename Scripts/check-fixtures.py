#!/usr/bin/env python3
# SPDX-License-Identifier: BSD-3-Clause

"""Validate fixture provenance, UTF-8 spans, numerical seeds, and safe descriptors."""

from __future__ import annotations

import json
import math
import sys
from collections import Counter
from pathlib import Path
from typing import Any


PROJECT_DIRECTORY = Path(__file__).resolve().parent.parent
CATALOG_PATH = PROJECT_DIRECTORY / "Fixtures/manifest.json"


def load_json(relative_path: str, errors: list[str]) -> dict[str, Any]:
    """Load a repository-relative JSON object."""
    path = Path(relative_path)
    if path.is_absolute() or ".." in path.parts:
        errors.append(f"path fixture non sicuro: {relative_path}")
        return {}
    try:
        value = json.loads((PROJECT_DIRECTORY / path).read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        errors.append(f"fixture non leggibile {relative_path}: {error}")
        return {}
    if not isinstance(value, dict):
        errors.append(f"fixture non è un oggetto JSON: {relative_path}")
        return {}
    return value


def validate_interval(
    raw: bytes, interval: dict[str, Any], context: str, errors: list[str]
) -> tuple[int, int] | None:
    """Validate a half-open UTF-8 interval and its declared surface."""
    start = interval.get("start")
    end = interval.get("end")
    surface = interval.get("surface")
    if not isinstance(start, int) or not isinstance(end, int) or not 0 <= start < end <= len(raw):
        errors.append(f"{context}: intervallo UTF-8 non valido [{start}, {end})")
        return None
    try:
        decoded = raw[start:end].decode("utf-8")
    except UnicodeDecodeError:
        errors.append(f"{context}: intervallo non allineato a UTF-8 [{start}, {end})")
        return None
    if decoded != surface:
        errors.append(f"{context}: surface attesa {surface!r}, osservata {decoded!r}")
    return start, end


def validate_linguistic(manifest: dict[str, Any], errors: list[str]) -> int:
    """Validate exact UTF-8 offsets for the Italian seed."""
    if manifest.get("schema") != "studio.glifi.linguistic-fixture-manifest":
        errors.append("manifest linguistico: schema non valido")
    if manifest.get("license") != "BSD-3-Clause" or not manifest.get("provenance"):
        errors.append("manifest linguistico: licenza/provenienza mancante")
    data = load_json(str(manifest.get("cases", "")), errors)
    if data.get("coordinateSpace") != "sourceUTF8" or data.get("intervalConvention") != "half-open":
        errors.append("fixture linguistiche: coordinate space o convenzione non valida")
    cases = data.get("cases", [])
    if not isinstance(cases, list):
        errors.append("fixture linguistiche: cases non è una lista")
        return 0
    expected_classes = {
        "apostrophe",
        "clitic",
        "abbreviation",
        "typography",
        "unicode-normalization",
        "numeric-locale",
        "unicode-grapheme",
        "email",
    }
    observed_classes: set[str] = set()
    seen_ids: set[str] = set()
    for case in cases:
        case_id = case.get("id", "<senza-id>")
        if case_id in seen_ids:
            errors.append(f"fixture linguistica duplicata: {case_id}")
        seen_ids.add(case_id)
        case_class = case.get("class")
        if isinstance(case_class, str):
            observed_classes.add(case_class)
        else:
            errors.append(f"{case_id}: class non è una stringa")
        text = case.get("text")
        if not isinstance(text, str):
            errors.append(f"{case_id}: text non è una stringa")
            continue
        raw = text.encode("utf-8")
        if case.get("utf8Length") != len(raw):
            errors.append(
                f"{case_id}: utf8Length {case.get('utf8Length')} != {len(raw)}"
            )
        previous_end = 0
        for index, token in enumerate(case.get("tokens", [])):
            result = validate_interval(raw, token, f"{case_id}/token/{index}", errors)
            if result is None:
                continue
            start, end = result
            if start < previous_end:
                errors.append(f"{case_id}: token sovrapposti o non ordinati")
            previous_end = end
            for component_index, component in enumerate(token.get("components", [])):
                component_result = validate_interval(
                    raw,
                    component,
                    f"{case_id}/token/{index}/component/{component_index}",
                    errors,
                )
                if component_result and not (
                    start <= component_result[0] < component_result[1] <= end
                ):
                    errors.append(f"{case_id}: componente fuori dal token")
        for index, sentence in enumerate(case.get("sentences", [])):
            validate_interval(raw, sentence, f"{case_id}/sentence/{index}", errors)
    if observed_classes != expected_classes:
        errors.append(
            "fixture linguistiche: classi seed inattese "
            f"(mancanti={sorted(expected_classes - observed_classes)}, "
            f"estranee={sorted(observed_classes - expected_classes)})"
        )
    return len(cases)


def close(actual: float, expected: float, tolerance: float) -> bool:
    """Compare finite reference values with the declared absolute tolerance."""
    return math.isfinite(actual) and math.isclose(
        actual, expected, rel_tol=0.0, abs_tol=tolerance
    )


def validate_scientific(manifest: dict[str, Any], errors: list[str]) -> int:
    """Recalculate the small V1 numerical seeds independently from product code."""
    if manifest.get("schema") != "studio.glifi.scientific-fixture-manifest":
        errors.append("manifest scientifico: schema non valido")
    if manifest.get("license") != "BSD-3-Clause" or not manifest.get("provenance"):
        errors.append("manifest scientifico: licenza/provenienza mancante")
    data = load_json(str(manifest.get("cases", "")), errors)
    cases = data.get("cases", [])
    if not isinstance(cases, list):
        errors.append("fixture scientifiche: cases non è una lista")
        return 0
    seen_ids: set[str] = set()
    for case in cases:
        case_id = case.get("id", "<senza-id>")
        if case_id in seen_ids:
            errors.append(f"fixture scientifica duplicata: {case_id}")
        seen_ids.add(case_id)
        tolerance = case.get("comparison", {}).get("value")
        if case.get("comparison", {}).get("kind") != "absoluteTolerance" or not isinstance(
            tolerance, (int, float)
        ):
            errors.append(f"{case_id}: confronto non supportato")
            continue
        expected = case.get("expected", {})
        inputs = case.get("input", {})
        if case_id == "pearson-chi-square-2x2-balanced":
            table = inputs["table"]
            row_totals = [sum(row) for row in table]
            column_totals = [sum(row[column] for row in table) for column in range(2)]
            total = sum(row_totals)
            statistic = sum(
                (table[row][column] - row_totals[row] * column_totals[column] / total) ** 2
                / (row_totals[row] * column_totals[column] / total)
                for row in range(2)
                for column in range(2)
            )
            cramers_v = math.sqrt(statistic / total)
            values = {"statistic": statistic, "cramersV": cramers_v}
        elif case_id == "cosine-three-dimensional":
            left, right = inputs["left"], inputs["right"]
            similarity = sum(a * b for a, b in zip(left, right, strict=True)) / (
                math.sqrt(sum(a * a for a in left)) * math.sqrt(sum(b * b for b in right))
            )
            values = {"similarity": similarity}
        elif case_id == "pmi-natural-log":
            probability = inputs["cooccurrence"] / inputs["total"]
            pmi = math.log(
                inputs["cooccurrence"]
                * inputs["total"]
                / (inputs["leftCount"] * inputs["rightCount"])
            )
            values = {"pmi": pmi, "npmi": pmi / -math.log(probability)}
        elif case_id == "tfidf-smoothed-two-documents":
            documents = inputs["documents"]
            terms = sorted({term for document in documents for term in document})
            idf = {
                term: math.log(
                    (len(documents) + 1)
                    / (sum(term in document for document in documents) + 1)
                )
                + 1
                for term in terms
            }
            vectors = [
                {term: Counter(document)[term] * idf[term] for term in terms}
                for document in documents
            ]
            values = {"idf": idf, "vectors": vectors}
        elif case_id == "corpus-profile-italian-two-documents":
            documents = inputs["documents"]
            window_size = inputs["windowSize"]
            sequence = [term for document in documents for term in document]
            terms = sorted(set(sequence))
            document_counts = [Counter(document) for document in documents]
            total_counts = Counter(sequence)
            document_frequency = {
                term: sum(term in document for document in documents) for term in terms
            }
            term_values = {}
            for term in terms:
                frequency = total_counts[term]
                opportunities = [len(document) / len(sequence) for document in documents]
                observed = [counts[term] / frequency for counts in document_counts]
                term_values[term] = {
                    "frequency": frequency,
                    "relativeFrequency": frequency / len(sequence),
                    "documentFrequency": document_frequency[term],
                    "range": sum(counts[term] > 0 for counts in document_counts),
                    "griesDP": 0.5
                    * sum(abs(actual - expected) for actual, expected in zip(observed, opportunities, strict=True)),
                }
            complete_windows = [
                sequence[start : start + window_size]
                for start in range(0, len(sequence) - window_size + 1, window_size)
            ]
            moving_windows = [
                sequence[start : start + window_size]
                for start in range(len(sequence) - window_size + 1)
            ]
            bigrams = Counter(
                " ".join(document[index : index + 2])
                for document in documents
                for index in range(len(document) - 1)
            )
            idf = {
                term: math.log(
                    (len(documents) + 1) / (document_frequency[term] + 1)
                )
                + 1
                for term in terms
            }
            count_matrix = [
                [counts[term] for term in terms] for counts in document_counts
            ]
            values = {
                "documentCount": len(documents),
                "lexicalTokenCount": len(sequence),
                "typeCount": len(terms),
                "terms": term_values,
                "diversity": {
                    "ttr": len(terms) / len(sequence),
                    "msttr": sum(len(set(window)) / window_size for window in complete_windows)
                    / len(complete_windows),
                    "mattr": sum(len(set(window)) / window_size for window in moving_windows)
                    / len(moving_windows),
                },
                "bigramCounts": dict(sorted(bigrams.items())),
                "matrix": {
                    "counts": count_matrix,
                    "tfidf": [
                        [count * idf[term] for count, term in zip(row, terms, strict=True)]
                        for row in count_matrix
                    ],
                },
            }
        elif case_id == "keyness-gtest-ha-bh-v1":
            target = inputs["target"]
            reference = inputs["reference"]
            target_counts = Counter(target)
            reference_counts = Counter(reference)
            terms = sorted(set(target) | set(reference))
            provisional = {}
            for term in terms:
                target_frequency = target_counts[term]
                reference_frequency = reference_counts[term]
                observations = [
                    target_frequency,
                    len(target) - target_frequency,
                    reference_frequency,
                    len(reference) - reference_frequency,
                ]
                column_totals = [
                    target_frequency + reference_frequency,
                    len(target) + len(reference) - target_frequency - reference_frequency,
                ]
                expected_counts = [
                    len(target) * column_totals[0] / (len(target) + len(reference)),
                    len(target) * column_totals[1] / (len(target) + len(reference)),
                    len(reference) * column_totals[0] / (len(target) + len(reference)),
                    len(reference) * column_totals[1] / (len(target) + len(reference)),
                ]
                statistic = 2 * sum(
                    observed * math.log(observed / expected_count)
                    for observed, expected_count in zip(
                        observations, expected_counts, strict=True
                    )
                    if observed
                )
                adjusted_target_rate = (target_frequency + 0.5) / (len(target) + 1)
                adjusted_reference_rate = (reference_frequency + 0.5) / (
                    len(reference) + 1
                )
                odds_ratio = (
                    (target_frequency + 0.5)
                    / (len(target) - target_frequency + 0.5)
                ) / (
                    (reference_frequency + 0.5)
                    / (len(reference) - reference_frequency + 0.5)
                )
                provisional[term] = {
                    "targetFrequency": target_frequency,
                    "referenceFrequency": reference_frequency,
                    "targetRelativeFrequency": target_frequency / len(target),
                    "referenceRelativeFrequency": reference_frequency / len(reference),
                    "gStatistic": statistic,
                    "pValue": math.erfc(math.sqrt(statistic / 2)),
                    "oddsRatioHaldaneAnscombe": odds_ratio,
                    "log2RatioHaldaneAnscombe": math.log2(
                        adjusted_target_rate / adjusted_reference_rate
                    ),
                    "minimumExpectedCount": min(expected_counts),
                }
            ordered = sorted(terms, key=lambda term: (provisional[term]["pValue"], term))
            running_minimum = 1.0
            for rank in range(len(ordered), 0, -1):
                term = ordered[rank - 1]
                candidate = len(ordered) * provisional[term]["pValue"] / rank
                running_minimum = min(running_minimum, candidate, 1.0)
                provisional[term]["qValue"] = running_minimum
            values = {
                "targetTokenCount": len(target),
                "referenceTokenCount": len(reference),
                "terms": provisional,
            }
        else:
            errors.append(f"{case_id}: caso non riconosciuto dal ricalcolo")
            continue

        def compare_tree(actual: Any, reference: Any, path: str) -> None:
            if isinstance(reference, dict):
                if not isinstance(actual, dict) or set(actual) != set(reference):
                    errors.append(f"{case_id}/{path}: struttura dizionario diversa")
                    return
                for key in reference:
                    compare_tree(actual[key], reference[key], f"{path}/{key}")
            elif isinstance(reference, list):
                if not isinstance(actual, list) or len(actual) != len(reference):
                    errors.append(f"{case_id}/{path}: struttura lista diversa")
                    return
                for index, item in enumerate(reference):
                    compare_tree(actual[index], item, f"{path}/{index}")
            elif not close(float(actual), float(reference), float(tolerance)):
                errors.append(
                    f"{case_id}/{path}: {actual} fuori tolleranza da {reference}"
                )

        compare_tree(values, expected, "expected")
    return len(cases)


def validate_adversarial(manifest: dict[str, Any], errors: list[str]) -> int:
    """Validate harmless adversarial descriptors against normative identifiers."""
    if manifest.get("schema") != "studio.glifi.adversarial-fixture-manifest":
        errors.append("manifest avversario: schema non valido")
    if manifest.get("license") != "BSD-3-Clause" or not manifest.get("provenance"):
        errors.append("manifest avversario: licenza/provenienza mancante")
    data = load_json(str(manifest.get("cases", "")), errors)
    if data.get("payloadPolicy") != "descriptors-only":
        errors.append("fixture avversarie: sono ammessi soltanto descrittori")
    cases = data.get("cases", [])
    if not isinstance(cases, list):
        errors.append("fixture avversarie: cases non è una lista")
        return 0
    security_body = (PROJECT_DIRECTORY / "docs/sicurezza/README.md").read_text(
        encoding="utf-8"
    )
    failure_body = (
        PROJECT_DIRECTORY / "docs/standard/18-errori-logging-e-osservabilita.md"
    ).read_text(encoding="utf-8")
    seen_ids: set[str] = set()
    for case in cases:
        case_id = case.get("id", "<senza-id>")
        if case_id in seen_ids:
            errors.append(f"fixture avversaria duplicata: {case_id}")
        seen_ids.add(case_id)
        if case.get("threat") not in security_body:
            errors.append(f"{case_id}: threat non registrata: {case.get('threat')}")
        if f"`{case.get('expectedCategory')}`" not in failure_body:
            errors.append(
                f"{case_id}: categoria failure non registrata: {case.get('expectedCategory')}"
            )
        limits = case.get("limit")
        if not isinstance(limits, dict) or not limits:
            errors.append(f"{case_id}: limite esplicito mancante")
        elif any(not isinstance(value, int) or value < 0 for value in limits.values()):
            errors.append(f"{case_id}: limite non intero o negativo")
    if len(cases) < 10:
        errors.append("fixture avversarie: richiesti almeno dieci descrittori seed")
    return len(cases)


def validate_query(manifest: dict[str, Any], errors: list[str]) -> int:
    """Validate the independent positional and diagnostic query seed."""
    if manifest.get("schema") != "studio.glifi.query-fixture-manifest":
        errors.append("manifest query: schema non valido")
    if manifest.get("license") != "BSD-3-Clause" or not manifest.get("provenance"):
        errors.append("manifest query: licenza/provenienza mancante")
    data = load_json(str(manifest.get("cases", "")), errors)
    if (
        data.get("schema") != "studio.glifi.query-fixture-cases"
        or data.get("coordinateSpace") != "sourceUTF8"
        or data.get("intervalConvention") != "half-open"
    ):
        errors.append("fixture query: schema o coordinate non valide")
    source = data.get("source")
    cases = data.get("cases", [])
    if not isinstance(source, str) or not isinstance(cases, list):
        errors.append("fixture query: source/cases non validi")
        return 0
    raw = source.encode("utf-8")
    seen_ids: set[str] = set()
    observed_outcomes: set[str] = set()
    for case in cases:
        case_id = case.get("id", "<senza-id>")
        if case_id in seen_ids:
            errors.append(f"fixture query duplicata: {case_id}")
        seen_ids.add(case_id)
        if not isinstance(case.get("query"), str) or not case.get("query"):
            errors.append(f"{case_id}: query mancante")
        outcome = case.get("outcome")
        if isinstance(outcome, str):
            observed_outcomes.add(outcome)
        if outcome == "succeeded":
            matches = case.get("matches")
            if not isinstance(matches, list):
                errors.append(f"{case_id}: matches non è una lista")
                continue
            previous = (-1, -1)
            for index, match in enumerate(matches):
                result = validate_interval(raw, match, f"{case_id}/match/{index}", errors)
                if result is not None and result < previous:
                    errors.append(f"{case_id}: match non ordinati")
                if result is not None:
                    previous = result
        elif outcome == "failed":
            if not str(case.get("failureCode", "")).startswith("query."):
                errors.append(f"{case_id}: failureCode query non valido")
        else:
            errors.append(f"{case_id}: outcome non valido")
    if observed_outcomes != {"succeeded", "failed"} or len(cases) < 7:
        errors.append("fixture query: richiesti almeno sette casi positivi e negativi")
    return len(cases)


def validate_markdown(manifest: dict[str, Any], errors: list[str]) -> int:
    """Validate Markdown source provenance and declared source-byte spans."""
    if manifest.get("schema") != "studio.glifi.markdown-fixture-manifest":
        errors.append("manifest Markdown: schema non valido")
    if manifest.get("license") != "BSD-3-Clause" or not manifest.get("provenance"):
        errors.append("manifest Markdown: licenza/provenienza mancante")
    source_path = Path(str(manifest.get("source", "")))
    if source_path.is_absolute() or ".." in source_path.parts:
        errors.append("fixture Markdown: path sorgente non sicuro")
        return 0
    try:
        raw = (PROJECT_DIRECTORY / source_path).read_bytes()
        raw.decode("utf-8")
    except (OSError, UnicodeDecodeError) as error:
        errors.append(f"fixture Markdown non leggibile: {error}")
        return 0
    if b"SPDX-License-Identifier: BSD-3-Clause" not in raw:
        errors.append("fixture Markdown: SPDX mancante")
    expected = load_json(str(manifest.get("expected", "")), errors)
    if (
        expected.get("schema") != "studio.glifi.markdown-fixture-expected"
        or expected.get("extractionContractIdentifier") != "md-extract-v1"
        or expected.get("coordinateSpace") != "sourceBytes"
        or expected.get("intervalConvention") != "half-open"
        or expected.get("license") != "BSD-3-Clause"
        or not isinstance(expected.get("expectedTextSuffix"), str)
    ):
        errors.append("fixture Markdown: contratto expected non valido")
    matches = expected.get("matches", [])
    if not isinstance(matches, list) or len(matches) < 2:
        errors.append("fixture Markdown: intervalli attesi insufficienti")
        return 0
    for index, match in enumerate(matches):
        validate_interval(raw, match, f"markdown/match/{index}", errors)
    return len(matches)


def main() -> int:
    """Run every fixture validation."""
    errors: list[str] = []
    catalog = load_json(str(CATALOG_PATH.relative_to(PROJECT_DIRECTORY)), errors)
    if catalog.get("schema") != "studio.glifi.fixture-catalog" or catalog.get(
        "schemaVersion"
    ) != 1:
        errors.append("catalogo fixture: schema o versione non valida")
    if catalog.get("license") != "BSD-3-Clause":
        errors.append("catalogo fixture: licenza BSD-3-Clause mancante")
    collections = catalog.get("collections", [])
    if not isinstance(collections, list):
        errors.append("catalogo fixture: collections non è una lista")
        collections = []
    manifests = {
        item.get("id"): load_json(str(item.get("path", "")), errors)
        for item in collections
        if isinstance(item, dict)
    }
    linguistic_count = validate_linguistic(manifests.get("it-token-v1-seed", {}), errors)
    scientific_count = validate_scientific(manifests.get("scientific-v1-seed", {}), errors)
    adversarial_count = validate_adversarial(
        manifests.get("adversarial-v1-descriptors", {}), errors
    )
    query_count = validate_query(manifests.get("query-v1-seed", {}), errors)
    markdown_count = validate_markdown(manifests.get("markdown-v1-seed", {}), errors)

    if errors:
        print("Fixture validation failed:", file=sys.stderr)
        for error in errors:
            print(f"- {error}", file=sys.stderr)
        return 1
    print(
        "Fixtures: "
        f"Italian={linguistic_count}, numerical={scientific_count}, "
        f"adversarial-descriptors={adversarial_count}, query={query_count}; "
        f"markdown-spans={markdown_count}; seed status preserved"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
