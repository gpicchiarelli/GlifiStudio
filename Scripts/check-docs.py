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

    if errors:
        print("Documentation validation failed:", file=sys.stderr)
        for error in errors:
            print(f"- {error}", file=sys.stderr)
        return 1

    print(
        f"Documentation: {len(markdown_files)} files, "
        f"{len(identifiers)} unique identifiers, valid local links"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
