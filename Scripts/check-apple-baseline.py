#!/usr/bin/env python3
# SPDX-License-Identifier: BSD-3-Clause

"""Validate the Apple application baseline and least-privilege configuration."""

from __future__ import annotations

import plistlib
import sys
from pathlib import Path


PROJECT_DIRECTORY = Path(__file__).resolve().parent.parent


def read(relative_path: str) -> str:
    """Read a UTF-8 project file."""
    return (PROJECT_DIRECTORY / relative_path).read_text(encoding="utf-8")


def main() -> int:
    """Run Apple baseline checks."""
    errors: list[str] = []
    profile_document_paths = (
        "docs/apple/01-ciclo-di-vita-e-stato-swiftui.md",
        "docs/apple/02-interfaccia-adattiva.md",
        "docs/apple/03-accessibilita.md",
        "docs/apple/04-privacy-e-sicurezza.md",
        "docs/apple/05-documenti-e-accesso-ai-file.md",
        "docs/apple/06-prestazioni-ed-energia.md",
        "docs/apple/07-test-e-diagnostica.md",
        "docs/apple/08-firma-e-distribuzione.md",
        "docs/apple/09-pipeline-documentale-e-ocr.md",
        "docs/apple/10-linguistica-e-intelligenza-on-device.md",
        "docs/apple/11-calcolo-accelerato-apple-silicon.md",
        "docs/apple/12-persistenza-e-indicizzazione-di-sistema.md",
        "docs/apple/13-integrazione-di-sistema-e-lavoro-prolungato.md",
    )
    profile_documents: list[str] = []
    for relative_path in profile_document_paths:
        path = PROJECT_DIRECTORY / relative_path
        if not path.is_file():
            errors.append(f"Documento del profilo Apple mancante: {relative_path}")
            continue
        profile_documents.append(path.read_text(encoding="utf-8"))

    required_technology_fragments = (
        "Uniform Type Identifiers",
        "PDFKit",
        "Vision",
        "Natural Language",
        "Foundation Models",
        "Accelerate",
        "Core ML",
        "Metal Performance Shaders",
        "SwiftData",
        "Core Spotlight",
        "App Intents",
        "Core Transferable",
        "BackgroundTasks",
        "Logger",
        "OSSignposter",
    )
    combined_profile = "\n".join(profile_documents)
    for technology in required_technology_fragments:
        if technology not in combined_profile:
            errors.append(f"Tecnologia non assegnata nel profilo Apple: {technology}")

    project = read("GlifiStudio.xcodeproj/project.pbxproj")
    base_configuration = read("Config/Base.xcconfig")
    debug_configuration = read("Config/Debug.xcconfig")
    macos_debug_configuration = read("Config/macOS-Debug.xcconfig")
    macos_release_configuration = read("Config/macOS-Release.xcconfig")
    macos_configurations = (macos_debug_configuration, macos_release_configuration)
    ipados_configurations = (
        read("Config/iPadOS-Debug.xcconfig"),
        read("Config/iPadOS-Release.xcconfig"),
    )
    model_source = read("Apps/Shared/StudioHomeModel.swift")
    view_source = read("Apps/Shared/StudioHomeView.swift")
    macos_app_source = read("Apps/macOS/GlifiStudioMacApp.swift")

    privacy_path = PROJECT_DIRECTORY / "Apps/Shared/Resources/PrivacyInfo.xcprivacy"
    with privacy_path.open("rb") as privacy_file:
        privacy = plistlib.load(privacy_file)

    expected_privacy = {
        "NSPrivacyAccessedAPITypes": [],
        "NSPrivacyCollectedDataTypes": [],
        "NSPrivacyTracking": False,
    }
    if privacy != expected_privacy:
        errors.append("Il privacy manifest non corrisponde alla baseline locale senza raccolta dati.")

    entitlements_path = PROJECT_DIRECTORY / "Config/GlifiStudio-macOS.entitlements"
    with entitlements_path.open("rb") as entitlements_file:
        entitlements = plistlib.load(entitlements_file)

    expected_entitlements = {
        "com.apple.security.app-sandbox": True,
        "com.apple.security.files.user-selected.read-write": True,
    }
    if entitlements != expected_entitlements:
        errors.append("Gli entitlement macOS devono rispettare il minimo privilegio approvato.")

    required_base_settings = (
        "SWIFT_STRICT_CONCURRENCY = complete",
        "SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor",
        "ENABLE_STRICT_OBJC_MSGSEND = YES",
        "ENABLE_USER_SCRIPT_SANDBOXING = YES",
        "ENABLE_MODULE_VERIFIER = YES",
        "SWIFT_TREAT_WARNINGS_AS_ERRORS = YES",
    )
    for setting in required_base_settings:
        if setting not in base_configuration:
            errors.append(f"Impostazione Apple mancante in Base.xcconfig: {setting}")

    if "ENABLE_PREVIEWS = YES" not in debug_configuration:
        errors.append("Le preview SwiftUI devono essere abilitate in Debug.")

    required_macos_settings = (
        "CODE_SIGN_ENTITLEMENTS = Config/GlifiStudio-macOS.entitlements",
        "ENABLE_APP_SANDBOX = YES",
        "INFOPLIST_KEY_LSApplicationSupportsSecureRestorableState = YES",
    )
    for configuration in macos_configurations:
        for setting in required_macos_settings:
            if setting not in configuration:
                errors.append(f"Impostazione macOS mancante: {setting}")

    if "ENABLE_HARDENED_RUNTIME = NO" not in macos_debug_configuration:
        errors.append("Hardened Runtime deve essere disattivato nella configurazione Debug.")

    if "ENABLE_HARDENED_RUNTIME = YES" not in macos_release_configuration:
        errors.append("Hardened Runtime deve essere attivo nella configurazione Release.")

    required_ipados_settings = (
        "TARGETED_DEVICE_FAMILY = 2",
        "SUPPORTS_MACCATALYST = NO",
        "SUPPORTS_MAC_DESIGNED_FOR_IPHONE_IPAD = NO",
        "INFOPLIST_KEY_UIApplicationSceneManifest_Generation = YES",
        "INFOPLIST_KEY_UIApplicationSupportsIndirectInputEvents = YES",
        "INFOPLIST_KEY_UISupportedInterfaceOrientations_iPad = UIInterfaceOrientationPortrait UIInterfaceOrientationPortraitUpsideDown UIInterfaceOrientationLandscapeLeft UIInterfaceOrientationLandscapeRight",
    )
    for configuration in ipados_configurations:
        for setting in required_ipados_settings:
            if setting not in configuration:
                errors.append(f"Impostazione iPadOS mancante: {setting}")

    if project.count("PrivacyInfo.xcprivacy in Resources") != 4:
        errors.append("Il privacy manifest deve essere incluso nelle risorse di entrambe le app.")

    for capability in ("com.apple.HardenedRuntime", "com.apple.Sandbox"):
        if capability not in project:
            errors.append(f"Capability macOS non registrata nel target: {capability}")

    required_model_fragments = ("@MainActor", "@Observable", "Task.isCancelled")
    for fragment in required_model_fragments:
        if fragment not in model_source:
            errors.append(f"Il modello UI deve contenere: {fragment}")

    required_preview_fragments = (".accessibility3", ".rightToLeft", 'Locale(identifier: "en")')
    for fragment in required_preview_fragments:
        if fragment not in view_source:
            errors.append(f"Preview adattiva mancante: {fragment}")

    if ".defaultSize(" not in macos_app_source or ".frame(minWidth:" in macos_app_source:
        errors.append("La finestra macOS deve avere una default size senza minimo rigido.")

    forbidden_fragments = (
        "NSAllowsArbitraryLoads = YES",
        "com.apple.security.network.server",
        "com.apple.security.network.client",
    )
    combined_configuration = "\n".join(
        (base_configuration, *macos_configurations, *ipados_configurations)
    )
    for fragment in forbidden_fragments:
        if fragment in combined_configuration or fragment in project:
            errors.append(f"Capability non autorizzata nella baseline: {fragment}")

    if errors:
        print("Apple baseline validation failed:", file=sys.stderr)
        for error in errors:
            print(f"- {error}", file=sys.stderr)
        return 1

    print("Apple baseline: application safeguards and technology portfolio valid")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
