#!/usr/bin/env python3
# SPDX-License-Identifier: BSD-3-Clause

"""Validate controlled Markdown metadata, identifiers, and local links."""

from __future__ import annotations

import re
import sys
from pathlib import Path
from urllib.parse import unquote


PROJECT_DIRECTORY = Path(__file__).resolve().parent.parent
DOCS_DIRECTORY = PROJECT_DIRECTORY / "docs"
METHODS_DIRECTORY = DOCS_DIRECTORY / "metodi-analitici"
UX_DIRECTORY = DOCS_DIRECTORY / "esperienza-utente"
REQUIRED_FIELDS = (
    "Identificatore",
    "Versione",
    "Stato",
    "Responsabile",
    "Ultima modifica",
    "Approvazione",
)
FIELD_PATTERN = re.compile(r"^\|\s*([^|]+?)\s*\|\s*([^|]+?)\s*\|\s*$", re.MULTILINE)
LINK_PATTERN = re.compile(r"(?<!!)\[[^\]]+\]\(([^)]+)\)")
METHOD_FILE_PATTERN = re.compile(r"^(\d{2})-[a-z0-9-]+\.md$")
UX_FILE_PATTERN = re.compile(r"^(\d{2})-[a-z0-9-]+\.md$")
METHOD_REQUIRED_MARKERS = {
    "01": ("AnalysisDescriptor", "Lineage analitico"),
    "02": ("Analysis DAG", "invalidazione"),
    "03": ("D0", "D1", "P1", "N1"),
    "04": ("TTR-v1", "MSTTR-v1", "MATTR-v1", "MTLD-bidirectional-v1"),
    "05": ("frequency spectrum", "ZipfLogOLS-v1", "HeapsLogOLS-v1"),
    "06": ("matrice unità-termine", "rappresentazione logica", "lineage"),
    "07": ("TFIDF-v1", "BM25-v1", "IDF-smooth-v1"),
    "08": ("PearsonChiSquare-v1", "GTest-v1", "FisherExactTwoSided-v1"),
    "09": ("residuo standardizzato", "CramersV-v1"),
    "10": ("CA-SVD-v1", "inerzia", "contributo"),
    "11": ("PMI-v1", "NPMI-v1", "logDice-v1"),
    "12": ("GriesDP-v1", "JuillandD-equal-v1"),
    "13": ("Cosine-v1", "JSdist-v1", "Hellinger-v1", "KL-v1"),
    "14": ("HAC-v1", "Ward-v1", "KMeans-Lloyd-v1"),
    "15": ("PCA-SVD-v1", "LSA-SVD-v1", "NMF-Frobenius-v1", "LDA"),
    "16": ("PageRank-v1", "Betweenness-v1", "lineage"),
    "17": ("metadata-first", "discretizzazione", "temporale"),
    "18": ("precision", "recall", "F1", "accuracy"),
    "19": ("TextRankSentence-v1", "LexRankSentence-v1", "MMR-v1"),
    "20": ("codebook", "CohenKappaNominal-v1", "KrippendorffAlpha-v1"),
    "21": ("WelchT-v1", "OneWayANOVA-v1", "BenjaminiHochberg-v1"),
    "22": ("Visualizzazioni scientifiche", "Navigazione bidirezionale"),
}
SCIENTIFIC_INTEGRATION_MARKERS = {
    "docs/README.md": ("GS-MET-001",),
    "docs/standard-di-progetto.md": ("GS-MET-001",),
    "docs/visione-e-principi.md": ("NS-009", "NS-014"),
    "docs/requisiti.md": ("RF-026", "RF-046", "RQ-023", "RQ-029"),
    "docs/architettura.md": ("AnalysisDescriptor", "VA-06", "GlifiMath"),
    "docs/tracciabilita.md": ("TV-026", "TV-036"),
    "docs/glossario.md": ("Analysis DAG", "Effect size"),
}
UX_REQUIRED_MARKERS = {
    "01": ("AnalyticalIntent", "review.completely", "algoritmo"),
    "02": ("Project", "Corpus", "Investigation", "Question", "Report"),
    "03": ("CollectionProfile", "partiallyReady", "needsAttention"),
    "04": ("Analysis Planner", "notApplicable", "CapabilitySnapshot"),
    "05": ("Evidence", "Finding", "Caveat", "motore interpretativo"),
    "06": ("Conclusione", "EvidenceAssessment", "SupportPolicy"),
    "07": ("L'oggetto è esplorabile", "Confronto come primitive UX"),
    "08": ("sintesi editoriale", "FollowUpAction", "dati insufficienti"),
    "09": ("exact", "contributive", "derivational", "VoiceOver"),
    "10": ("InvestigationHistory", "Undo/Redo", "Report"),
    "11": ("QuestionInterpretation", "domanda naturale", "needsClarification"),
    "12": ("NavigationSplitView", "Parità semantica", "stato per-scena"),
    "13": ("VoiceOver", "ISO 9241-210", "Comprensione"),
    "14": ("messageKey", "Confidenza", "chiavi"),
}
UX_INTEGRATION_MARKERS = {
    "docs/README.md": ("GS-UX-001",),
    "docs/standard-di-progetto.md": ("GS-UX-001",),
    "docs/visione-e-principi.md": ("NS-015", "NS-023"),
    "docs/requisiti.md": ("RF-047", "RF-074", "RQ-030", "RQ-040"),
    "docs/architettura.md": ("VA-07", "GlifiInvestigation", "CR-20"),
    "docs/tracciabilita.md": ("TV-037", "TV-048"),
    "docs/glossario.md": ("AnalyticalIntent", "EvidenceAssessment"),
    "docs/roadmap.md": ("CollectionProfile", "insufficientEvidence"),
    "docs/internazionalizzazione-interfaccia.md": ("GS-UX-001-14",),
    "docs/apple/README.md": ("GS-UX",),
    "docs/app-store/README.md": ("GS-UX-001",),
    "docs/metodi-analitici/README.md": ("GS-UX-001",),
}


def metadata(text: str) -> dict[str, str]:
    """Return metadata fields found in a Markdown table."""
    return {key.strip(): value.strip() for key, value in FIELD_PATTERN.findall(text)}


def local_link_target(source: Path, raw_target: str) -> Path | None:
    """Resolve a local Markdown link, or return None for external/anchor links."""
    target = raw_target.strip()
    if target.startswith("<") and target.endswith(">"):
        target = target[1:-1]
    target = unquote(target.split("#", maxsplit=1)[0])
    if not target or target.startswith(("#", "http://", "https://", "mailto:")):
        return None
    return (source.parent / target).resolve()


def validate_scientific_specification(errors: list[str]) -> int:
    """Validate coverage and integration of the analytical method family."""
    index_path = METHODS_DIRECTORY / "README.md"
    if not index_path.is_file():
        errors.append("docs/metodi-analitici/README.md: indice scientifico mancante")
        return 0

    index_text = index_path.read_text(encoding="utf-8")
    method_paths = sorted(
        path for path in METHODS_DIRECTORY.glob("*.md") if path.name != "README.md"
    )
    indexed_paths: set[Path] = set()
    for raw_target in LINK_PATTERN.findall(index_text):
        target = local_link_target(index_path, raw_target)
        if target is not None and target.parent == METHODS_DIRECTORY:
            indexed_paths.add(target)

    expected_paths = set(method_paths)
    for path in sorted(expected_paths - indexed_paths):
        errors.append(f"{path.relative_to(PROJECT_DIRECTORY)}: non indicizzato")
    for path in sorted(indexed_paths - expected_paths):
        errors.append(
            f"docs/metodi-analitici/README.md: riferimento estraneo o mancante: "
            f"{path.name}"
        )

    for path in method_paths:
        relative_path = path.relative_to(PROJECT_DIRECTORY)
        match = METHOD_FILE_PATTERN.fullmatch(path.name)
        if match is None:
            errors.append(f"{relative_path}: nome non conforme NN-argomento.md")
            continue

        sequence = match.group(1)
        body = path.read_text(encoding="utf-8")
        fields = metadata(body)
        expected_identifier = f"GS-MET-001-{sequence}"
        if fields.get("Identificatore") != expected_identifier:
            errors.append(
                f"{relative_path}: atteso identificatore {expected_identifier}"
            )
        if "GS-MET-001" not in fields.get("Documento padre", ""):
            errors.append(f"{relative_path}: documento padre GS-MET-001 mancante")
        if not body.startswith("<!-- SPDX-License-Identifier: BSD-3-Clause -->"):
            errors.append(f"{relative_path}: intestazione SPDX mancante")
        for marker in METHOD_REQUIRED_MARKERS.get(sequence, ()):
            if marker not in body:
                errors.append(f"{relative_path}: copertura obbligatoria mancante: {marker}")

    actual_sequences = {path.name[:2] for path in method_paths}
    expected_sequences = set(METHOD_REQUIRED_MARKERS)
    for sequence in sorted(expected_sequences - actual_sequences):
        errors.append(f"GS-MET-001-{sequence}: documento obbligatorio mancante")

    for relative, markers in SCIENTIFIC_INTEGRATION_MARKERS.items():
        path = PROJECT_DIRECTORY / relative
        if not path.is_file():
            errors.append(f"{relative}: documento di integrazione mancante")
            continue
        body = path.read_text(encoding="utf-8")
        for marker in markers:
            if marker not in body:
                errors.append(f"{relative}: integrazione scientifica mancante: {marker}")

    return len(method_paths)


def validate_ux_specification(errors: list[str]) -> int:
    """Validate coverage and integration of the user experience family."""
    index_path = UX_DIRECTORY / "README.md"
    if not index_path.is_file():
        errors.append("docs/esperienza-utente/README.md: indice UX mancante")
        return 0

    index_text = index_path.read_text(encoding="utf-8")
    ux_paths = sorted(
        path for path in UX_DIRECTORY.glob("*.md") if path.name != "README.md"
    )
    indexed_paths: set[Path] = set()
    for raw_target in LINK_PATTERN.findall(index_text):
        target = local_link_target(index_path, raw_target)
        if target is not None and target.parent == UX_DIRECTORY:
            indexed_paths.add(target)

    expected_paths = set(ux_paths)
    for path in sorted(expected_paths - indexed_paths):
        errors.append(f"{path.relative_to(PROJECT_DIRECTORY)}: non indicizzato")
    for path in sorted(indexed_paths - expected_paths):
        errors.append(
            f"docs/esperienza-utente/README.md: riferimento estraneo o mancante: "
            f"{path.name}"
        )

    for path in ux_paths:
        relative_path = path.relative_to(PROJECT_DIRECTORY)
        match = UX_FILE_PATTERN.fullmatch(path.name)
        if match is None:
            errors.append(f"{relative_path}: nome non conforme NN-argomento.md")
            continue

        sequence = match.group(1)
        body = path.read_text(encoding="utf-8")
        fields = metadata(body)
        expected_identifier = f"GS-UX-001-{sequence}"
        if fields.get("Identificatore") != expected_identifier:
            errors.append(
                f"{relative_path}: atteso identificatore {expected_identifier}"
            )
        if "GS-UX-001" not in fields.get("Documento padre", ""):
            errors.append(f"{relative_path}: documento padre GS-UX-001 mancante")
        if not body.startswith("<!-- SPDX-License-Identifier: BSD-3-Clause -->"):
            errors.append(f"{relative_path}: intestazione SPDX mancante")
        for marker in UX_REQUIRED_MARKERS.get(sequence, ()):
            if marker not in body:
                errors.append(f"{relative_path}: copertura UX mancante: {marker}")

    actual_sequences = {path.name[:2] for path in ux_paths}
    expected_sequences = set(UX_REQUIRED_MARKERS)
    for sequence in sorted(expected_sequences - actual_sequences):
        errors.append(f"GS-UX-001-{sequence}: documento obbligatorio mancante")

    for relative, markers in UX_INTEGRATION_MARKERS.items():
        path = PROJECT_DIRECTORY / relative
        if not path.is_file():
            errors.append(f"{relative}: documento di integrazione UX mancante")
            continue
        body = path.read_text(encoding="utf-8")
        for marker in markers:
            if marker not in body:
                errors.append(f"{relative}: integrazione UX mancante: {marker}")

    return len(ux_paths)


def main() -> int:
    """Run all documentation checks."""
    errors: list[str] = []
    identifiers: dict[str, Path] = {}
    controlled_files = sorted(DOCS_DIRECTORY.rglob("*.md"))
    markdown_files = [PROJECT_DIRECTORY / "README.md", *controlled_files]

    for path in markdown_files:
        text = path.read_text(encoding="utf-8")
        relative_path = path.relative_to(PROJECT_DIRECTORY)

        if path in controlled_files:
            fields = metadata(text)
            for field in REQUIRED_FIELDS:
                if field not in fields:
                    errors.append(f"{relative_path}: metadato mancante: {field}")

            identifier = fields.get("Identificatore")
            if identifier:
                if identifier in identifiers:
                    previous = identifiers[identifier].relative_to(PROJECT_DIRECTORY)
                    errors.append(
                        f"{relative_path}: identificatore duplicato {identifier} "
                        f"(già in {previous})"
                    )
                identifiers[identifier] = path

        for raw_target in LINK_PATTERN.findall(text):
            target = local_link_target(path, raw_target)
            if target is not None and not target.exists():
                errors.append(f"{relative_path}: collegamento locale non valido: {raw_target}")

    method_count = validate_scientific_specification(errors)
    ux_count = validate_ux_specification(errors)

    if errors:
        print("Documentation validation failed:", file=sys.stderr)
        for error in errors:
            print(f"- {error}", file=sys.stderr)
        return 1

    print(
        f"Documentation: {len(markdown_files)} files, "
        f"{len(identifiers)} unique identifiers, valid local links, "
        f"{method_count} scientific method specifications, "
        f"{ux_count} UX specifications"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
