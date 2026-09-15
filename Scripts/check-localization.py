#!/usr/bin/env python3
# SPDX-License-Identifier: BSD-3-Clause

"""Validate the initial Italian localization baseline."""

from __future__ import annotations

import json
import sys
from pathlib import Path


PROJECT_DIRECTORY = Path(__file__).resolve().parent.parent
CATALOG_PATH = PROJECT_DIRECTORY / "Apps/Shared/Resources/Localizable.xcstrings"
PROJECT_PATH = PROJECT_DIRECTORY / "GlifiStudio.xcodeproj/project.pbxproj"
BASE_CONFIGURATION_PATH = PROJECT_DIRECTORY / "Config/Base.xcconfig"
EXPECTED_TRANSLATIONS = {
    "app.name": {"it": "Glifi Studio", "en": "Glifi Studio"},
    "engine.status.accessibility-label": {"it": "Stato del motore", "en": "Engine status"},
    "engine.status.checking": {"it": "Verifica di GlifiCore…", "en": "Checking GlifiCore…"},
    "engine.status.ready": {"it": "GlifiCore pronto", "en": "GlifiCore ready"},
    "home.description": {
        "it": "Un ambiente nativo per l’analisi computazionale del testo.",
        "en": "A native environment for computational text analysis.",
    },
}


def main() -> int:
    """Run localization consistency checks."""
    errors: list[str] = []
    catalog = json.loads(CATALOG_PATH.read_text(encoding="utf-8"))
    project = PROJECT_PATH.read_text(encoding="utf-8")
    base_configuration = BASE_CONFIGURATION_PATH.read_text(encoding="utf-8")

    if catalog.get("sourceLanguage") != "it":
        errors.append("Il catalogo deve dichiarare sourceLanguage = it.")

    strings = catalog.get("strings", {})
    missing_strings = EXPECTED_TRANSLATIONS.keys() - strings.keys()
    if missing_strings:
        errors.append(f"Stringhe italiane mancanti: {sorted(missing_strings)}")

    for key in EXPECTED_TRANSLATIONS.keys() & strings.keys():
        localizations = strings[key].get("localizations", {})
        for language, expected_value in EXPECTED_TRANSLATIONS[key].items():
            unit = localizations.get(language, {}).get("stringUnit", {})
            if unit.get("state") != "translated" or unit.get("value") != expected_value:
                errors.append(f"Localizzazione {language} incompleta o non valida: {key}")

    if "developmentRegion = it;" not in project:
        errors.append("La development region del progetto Xcode deve essere it.")

    if "\n\t\t\t\ten,\n" not in project:
        errors.append("Il progetto Xcode deve dichiarare en tra le regioni supportate.")

    if project.count("Localizable.xcstrings in Resources") != 4:
        errors.append("Il catalogo deve essere incluso nelle due build phase Resources.")

    required_settings = (
        "DEVELOPMENT_LANGUAGE = it",
        "LOCALIZATION_PREFERS_STRING_CATALOGS = YES",
        "SWIFT_EMIT_LOC_STRINGS = YES",
        "INFOPLIST_KEY_CFBundleDevelopmentRegion = it",
    )
    for setting in required_settings:
        if setting not in base_configuration:
            errors.append(f"Impostazione mancante in Base.xcconfig: {setting}")

    if errors:
        print("Localization validation failed:", file=sys.stderr)
        for error in errors:
            print(f"- {error}", file=sys.stderr)
        return 1

    print("Localization: Italian source language, semantic keys, and it/en catalogs valid")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
