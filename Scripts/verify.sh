#!/bin/zsh
# SPDX-License-Identifier: BSD-3-Clause

set -euo pipefail

script_directory="${0:A:h}"
project_directory="${script_directory:h}"
temporary_root="${TMPDIR:-/tmp}"
temporary_build_directory="$(mktemp -d "${temporary_root%/}/GlifiStudioVerify.XXXXXX")"

cleanup() {
    rm -rf "$temporary_build_directory"
}

trap cleanup EXIT

cd "$project_directory"

Scripts/check-repository.py
Scripts/check-secrets.py
Scripts/check-toolchain.sh
Scripts/check-github-config.py
Scripts/check-naming.py
Scripts/check-docs.py
Scripts/check-compliance.py
Scripts/check-fixtures.py
Scripts/check-architecture.sh
Scripts/check-localization.py
Scripts/check-apple-baseline.py
Scripts/check-app-store-baseline.py
Scripts/check-swift-dialect.py
Scripts/format.sh --check
swift test \
    --package-path Packages/GlifiCore \
    --scratch-path "$temporary_build_directory/SwiftPM"

cli_output="$(swift run \
    --package-path Packages/GlifiCore \
    --scratch-path "$temporary_build_directory/SwiftPM" \
    --skip-build \
    GlifiCLI)"

if [[ "$cli_output" != "GlifiCore pronto" ]]; then
    print -u2 "Headless smoke test non superato: $cli_output"
    exit 1
fi

cli_json_output="$(swift run \
    --package-path Packages/GlifiCore \
    --scratch-path "$temporary_build_directory/SwiftPM" \
    --skip-build \
    GlifiCLI --format json status)"

expected_cli_json='{"cliProtocolVersion":1,"command":"status","outcome":"succeeded","result":{"status":"ready"}}'
if [[ "$cli_json_output" != "$expected_cli_json" ]]; then
    print -u2 "Headless JSON contract test non superato: $cli_json_output"
    exit 1
fi

cli_project_path="$temporary_build_directory/CLI-Smoke.glifi"
cli_create_output="$(swift run \
    --package-path Packages/GlifiCore \
    --scratch-path "$temporary_build_directory/SwiftPM" \
    --skip-build \
    GlifiCLI --format json project create "$cli_project_path")"
cli_import_output="$(swift run \
    --package-path Packages/GlifiCore \
    --scratch-path "$temporary_build_directory/SwiftPM" \
    --skip-build \
    GlifiCLI --format json import "$cli_project_path" \
    Fixtures/Persistence/v1/basic/source.txt)"
cli_markdown_import_output="$(swift run \
    --package-path Packages/GlifiCore \
    --scratch-path "$temporary_build_directory/SwiftPM" \
    --skip-build \
    GlifiCLI --format json import "$cli_project_path" \
    Fixtures/Markdown/v1/source.md)"
cli_validate_output="$(swift run \
    --package-path Packages/GlifiCore \
    --scratch-path "$temporary_build_directory/SwiftPM" \
    --skip-build \
    GlifiCLI --format json project validate "$cli_project_path")"
cli_query_output="$(swift run \
    --package-path Packages/GlifiCore \
    --scratch-path "$temporary_build_directory/SwiftPM" \
    --skip-build \
    GlifiCLI --format json query "$cli_project_path" --text "normalized:due")"
cli_markdown_query_output="$(swift run \
    --package-path Packages/GlifiCore \
    --scratch-path "$temporary_build_directory/SwiftPM" \
    --skip-build \
    GlifiCLI --format json query "$cli_project_path" --text "normalized:fonte")"
cli_analysis_output="$(swift run \
    --package-path Packages/GlifiCore \
    --scratch-path "$temporary_build_directory/SwiftPM" \
    --skip-build \
    GlifiCLI --format json analyze "$cli_project_path")"
target_source_revision_id="$(python3 -c \
    'import json, sys; print(json.loads(sys.argv[1])["result"]["project"]["sources"][0]["sourceRevisionID"])' \
    "$cli_import_output")"
reference_source_revision_id="$(python3 -c \
    'import json, sys; sources=json.loads(sys.argv[1])["result"]["project"]["sources"]; print(next(source["sourceRevisionID"] for source in sources if source["sourceRevisionID"] != sys.argv[2]))' \
    "$cli_markdown_import_output" "$target_source_revision_id")"
cli_keyness_output="$(swift run \
    --package-path Packages/GlifiCore \
    --scratch-path "$temporary_build_directory/SwiftPM" \
    --skip-build \
    GlifiCLI --format json keyness "$cli_project_path" \
    --target "$target_source_revision_id" \
    --reference "$reference_source_revision_id")"
cli_plan_request_path="$temporary_build_directory/plan-request.json"
print -r -- "{\"intent\":\"compare.objects\",\"targetSourceRevisionIDs\":[\"$target_source_revision_id\"],\"referenceSourceRevisionIDs\":[\"$reference_source_revision_id\"]}" \
    > "$cli_plan_request_path"
cli_plan_output="$(swift run \
    --package-path Packages/GlifiCore \
    --scratch-path "$temporary_build_directory/SwiftPM" \
    --skip-build \
    GlifiCLI --format json plan "$cli_project_path" --request "$cli_plan_request_path")"
cli_plan_reused_output="$(swift run \
    --package-path Packages/GlifiCore \
    --scratch-path "$temporary_build_directory/SwiftPM" \
    --skip-build \
    GlifiCLI --format json plan "$cli_project_path" --request "$cli_plan_request_path")"
cli_execution_output="$(swift run \
    --package-path Packages/GlifiCore \
    --scratch-path "$temporary_build_directory/SwiftPM" \
    --skip-build \
    GlifiCLI --format json --no-progress execute "$cli_project_path" \
    --request "$cli_plan_request_path")"
cli_execution_reused_output="$(swift run \
    --package-path Packages/GlifiCore \
    --scratch-path "$temporary_build_directory/SwiftPM" \
    --skip-build \
    GlifiCLI --no-progress --format json execute "$cli_project_path" \
    --request "$cli_plan_request_path")"
cli_execution_progress_path="$temporary_build_directory/execution-progress.txt"
cli_execution_text_output="$(swift run \
    --package-path Packages/GlifiCore \
    --scratch-path "$temporary_build_directory/SwiftPM" \
    --skip-build \
    GlifiCLI execute "$cli_project_path" \
    --request "$cli_plan_request_path" 2>"$cli_execution_progress_path")"
if [[ "$cli_execution_text_output" != Piano\ eseguito* ]]; then
    print -u2 "Output testuale execute inatteso: $cli_execution_text_output"
    exit 1
fi
if ! grep -Eq '^planning .* nodes$' "$cli_execution_progress_path" \
    || ! grep -Eq '^executing .* workUnits' "$cli_execution_progress_path" \
    || ! grep -Eq '^finalizing .* nodes$' "$cli_execution_progress_path"; then
    print -u2 "Stream di progresso CLI incompleto"
    exit 1
fi
interpretation_artifact_id="$(python3 -c \
    'import json,sys; print(json.loads(sys.argv[1])["result"]["interpretationArtifactID"])' \
    "$cli_execution_output")"
cli_investigation_create_request_path="$temporary_build_directory/investigation-create.json"
print -r -- "{\"schemaIdentifier\":\"studio.glifi.api.investigation-create-request\",\"schemaVersion\":1,\"question\":\"Quali differenze emergono?\",\"languageCode\":\"it\",\"interpretationArtifactID\":\"$interpretation_artifact_id\"}" \
    > "$cli_investigation_create_request_path"
cli_investigation_create_output="$(swift run \
    --package-path Packages/GlifiCore \
    --scratch-path "$temporary_build_directory/SwiftPM" \
    --skip-build \
    GlifiCLI --format json investigation create "$cli_project_path" \
    --request "$cli_investigation_create_request_path")"
investigation_id="$(python3 -c \
    'import json,sys; print(json.loads(sys.argv[1])["result"]["investigation"]["id"])' \
    "$cli_investigation_create_output")"
investigation_root_event_id="$(python3 -c \
    'import json,sys; print(json.loads(sys.argv[1])["result"]["investigation"]["headEventID"])' \
    "$cli_investigation_create_output")"
cli_investigation_select_a_request_path="$temporary_build_directory/investigation-select-a.json"
print -r -- "{\"schemaIdentifier\":\"studio.glifi.api.investigation-selection-request\",\"schemaVersion\":1,\"investigationID\":\"$investigation_id\",\"predecessorEventID\":\"$investigation_root_event_id\",\"selectedFindingIDs\":[],\"reasonIdentifier\":\"editorial.omit\"}" \
    > "$cli_investigation_select_a_request_path"
cli_investigation_select_a_output="$(swift run \
    --package-path Packages/GlifiCore \
    --scratch-path "$temporary_build_directory/SwiftPM" \
    --skip-build \
    GlifiCLI --format json investigation select "$cli_project_path" \
    --request "$cli_investigation_select_a_request_path")"
cli_investigation_select_b_request_path="$temporary_build_directory/investigation-select-b.json"
print -r -- "{\"schemaIdentifier\":\"studio.glifi.api.investigation-selection-request\",\"schemaVersion\":1,\"investigationID\":\"$investigation_id\",\"predecessorEventID\":\"$investigation_root_event_id\",\"selectedFindingIDs\":[],\"reasonIdentifier\":\"editorial.alternative\"}" \
    > "$cli_investigation_select_b_request_path"
cli_investigation_select_b_output="$(swift run \
    --package-path Packages/GlifiCore \
    --scratch-path "$temporary_build_directory/SwiftPM" \
    --skip-build \
    GlifiCLI --format json investigation select "$cli_project_path" \
    --request "$cli_investigation_select_b_request_path")"
investigation_export_head_id="$(python3 -c \
    'import json,sys; print(json.loads(sys.argv[1])["result"]["investigation"]["headEventID"])' \
    "$cli_investigation_select_b_output")"
cli_export_request_path="$temporary_build_directory/export-request.json"
print -r -- "{\"schemaIdentifier\":\"studio.glifi.api.scientific-export-request\",\"schemaVersion\":1,\"investigationHeadEventID\":\"$investigation_export_head_id\",\"formats\":[\"csv\",\"json\",\"markdown\",\"pdf\"],\"presentationLocaleIdentifier\":\"it-IT\",\"presentationTimeZoneIdentifier\":\"Europe/Rome\"}" \
    > "$cli_export_request_path"
cli_export_path="$temporary_build_directory/CLI-Export.glifiexport"
cli_export_output="$(swift run \
    --package-path Packages/GlifiCore \
    --scratch-path "$temporary_build_directory/SwiftPM" \
    --skip-build \
    GlifiCLI --format json export "$cli_project_path" \
    --request "$cli_export_request_path" --output "$cli_export_path")"
cli_investigation_list_output="$(swift run \
    --package-path Packages/GlifiCore \
    --scratch-path "$temporary_build_directory/SwiftPM" \
    --skip-build \
    GlifiCLI --format json investigation list "$cli_project_path")"
cli_oversized_plan_request_path="$temporary_build_directory/oversized-plan-request.json"
dd if=/dev/zero of="$cli_oversized_plan_request_path" bs=1048577 count=1 2>/dev/null
if cli_oversized_plan_output="$(swift run \
    --package-path Packages/GlifiCore \
    --scratch-path "$temporary_build_directory/SwiftPM" \
    --skip-build \
    GlifiCLI --format json plan "$cli_project_path" \
    --request "$cli_oversized_plan_request_path" 2>&1)"; then
    print -u2 "La richiesta planner oltre limite è stata accettata"
    exit 1
else
    cli_oversized_plan_status=$?
fi
if [[ "$cli_oversized_plan_status" -ne 7 ]]; then
    print -u2 "Exit status planner oltre limite inatteso: $cli_oversized_plan_status"
    exit 1
fi
cli_final_info_output="$(swift run \
    --package-path Packages/GlifiCore \
    --scratch-path "$temporary_build_directory/SwiftPM" \
    --skip-build \
    GlifiCLI --format json project info "$cli_project_path")"

python3 - "$cli_create_output" "$cli_import_output" "$cli_markdown_import_output" \
    "$cli_validate_output" "$cli_query_output" "$cli_markdown_query_output" \
    "$cli_analysis_output" "$cli_keyness_output" "$cli_plan_output" \
    "$cli_plan_reused_output" "$cli_execution_output" \
    "$cli_execution_reused_output" "$cli_oversized_plan_output" \
    "$cli_investigation_create_output" "$cli_investigation_select_a_output" \
    "$cli_investigation_select_b_output" "$cli_export_output" \
    "$cli_investigation_list_output" "$cli_final_info_output" \
    "$cli_export_path" <<'PY'
import hashlib
import json
import pathlib
import sys

(
    created,
    imported,
    markdown_imported,
    validated,
    queried,
    markdown_queried,
    analyzed,
    keyness,
    planned,
    reused_plan,
    executed,
    reused_execution,
    oversized_plan,
    investigation_created,
    investigation_selection_a,
    investigation_selection_b,
    exported,
    investigation_list,
    final_info,
) = (json.loads(value) for value in sys.argv[1:-1])
export_path = pathlib.Path(sys.argv[-1])
assert created["command"] == "project.create"
assert created["result"]["project"]["generation"] == 0
assert created["result"]["project"]["artifactCount"] == 0
assert imported["command"] == "import"
assert imported["result"]["project"]["generation"] == 1
assert imported["result"]["project"]["sourceCount"] == 1
assert imported["result"]["project"]["artifactCount"] == 0
assert len(imported["result"]["project"]["sources"]) == 1
assert imported["result"]["project"]["sources"][0]["format"] == "plainText"
assert imported["result"]["project"]["sources"][0]["contentDigest"].startswith("sha256:")
assert imported["result"]["lastProfile"]["lexicalTokenCount"] == 3
assert markdown_imported["command"] == "import"
assert markdown_imported["result"]["project"]["generation"] == 2
assert markdown_imported["result"]["project"]["sourceCount"] == 2
assert markdown_imported["result"]["project"]["artifactCount"] == 0
assert markdown_imported["result"]["lastProfile"]["lexicalTokenCount"] == 5
assert validated["command"] == "project.validate"
assert validated["result"]["status"] == "valid"
assert validated["result"]["project"] == markdown_imported["result"]["project"]
assert queried["command"] == "query"
assert queried["outcome"] == "succeeded"
assert queried["result"]["generation"] == 2
assert queried["result"]["matchedSourceCount"] == 1
assert queried["result"]["isTruncated"] is False
assert queried["result"]["queryDigest"].startswith("sha256:")
assert [
    (match["startUTF8"], match["endUTF8"], match["match"])
    for match in queried["result"]["matches"]
] == [(4, 7, "due"), (8, 11, "due")]
assert markdown_queried["command"] == "query"
assert markdown_queried["result"]["generation"] == 2
assert markdown_queried["result"]["matchedSourceCount"] == 1
assert len(markdown_queried["result"]["matches"]) == 1
markdown_match = markdown_queried["result"]["matches"][0]
assert markdown_match["coordinateSpace"] == "extractedUTF8"
assert (markdown_match["startUTF8"], markdown_match["endUTF8"]) == (14, 19)
assert markdown_match["sourceRanges"] == [{"start": 64, "end": 69}]
assert analyzed["command"] == "analyze"
assert analyzed["outcome"] == "succeeded"
assert analyzed["result"]["sourceGeneration"] == 2
assert analyzed["result"]["generation"] == 3
assert analyzed["result"]["artifactID"].startswith("artifact:sha256:")
assert analyzed["result"]["analysisNodeID"].startswith("analysis-node:sha256:")
assert analyzed["result"]["analysisIdentifier"] == "corpus-profile-it-v1"
assert analyzed["result"]["corpusDigest"].startswith("sha256:")
assert analyzed["result"]["tokenizationContractIdentifier"] == "it-token-v1"
assert analyzed["result"]["documentCount"] == 2
assert analyzed["result"]["lexicalTokenCount"] == 8
assert analyzed["result"]["typeCount"] == 7
assert analyzed["result"]["terms"][0]["term"] == "due"
assert analyzed["result"]["terms"][0]["frequency"] == 2
assert len(analyzed["result"]["matrix"]["cells"]) == 7
assert analyzed["result"]["matrix"]["tfidfIdentifier"] == "TFIDF-v1"
assert keyness["command"] == "keyness"
assert keyness["outcome"] == "succeeded"
assert keyness["result"]["sourceGeneration"] == 3
assert keyness["result"]["generation"] == 6
assert keyness["result"]["artifactID"].startswith("artifact:sha256:")
assert keyness["result"]["analysisNodeID"].startswith("analysis-node:sha256:")
assert keyness["result"]["comparisonIdentifier"] == "keyness-gtest-ha-bh-v1"
assert keyness["result"]["comparisonDigest"].startswith("sha256:")
assert keyness["result"]["testIdentifier"] == "GTest-v1"
assert keyness["result"]["correctionIdentifier"] == "BenjaminiHochberg-v1"
assert keyness["result"]["targetTokenCount"] == 3
assert keyness["result"]["referenceTokenCount"] == 5
assert len(keyness["result"]["terms"]) == 7
assert all(0 <= term["qValue"] <= 1 for term in keyness["result"]["terms"])
assert any(term["hasLowExpectedCount"] for term in keyness["result"]["terms"])
assert planned["command"] == "plan"
assert planned["outcome"] == "succeeded"
assert planned["result"]["sourceGeneration"] == 6
assert planned["result"]["generation"] == 7
assert planned["result"]["artifactID"].startswith("artifact:sha256:")
assert planned["result"]["analysisNodeID"].startswith("analysis-node:sha256:")
assert planned["result"]["plan"]["plannerIdentifier"] == "planner-mvp-v1"
assert planned["result"]["plan"]["capabilityCatalogIdentifier"] == "capability-catalog-mvp-v1"
assert planned["result"]["plan"]["intent"] == "compare.objects"
assert planned["result"]["plan"]["status"] == "readyWithCaveats"
assert planned["result"]["plan"]["collectionProfile"]["sourceCount"] == 2
assert [step["role"] for step in planned["result"]["plan"]["steps"]] == [
    "target",
    "reference",
    "comparison",
]
assert [decision["isIncluded"] for decision in planned["result"]["plan"]["decisions"]] == [
    True,
    True,
]
assert reused_plan["result"]["sourceGeneration"] == 7
assert reused_plan["result"]["generation"] == 7
assert reused_plan["result"]["artifactID"] == planned["result"]["artifactID"]
assert executed["command"] == "execute"
assert executed["outcome"] == "succeeded"
assert executed["result"]["sourceGeneration"] == 7
assert executed["result"]["generation"] == 8
assert executed["result"]["planArtifactID"] == planned["result"]["artifactID"]
assert executed["result"]["planAnalysisNodeID"] == planned["result"]["analysisNodeID"]
assert executed["result"]["interpretationArtifactID"].startswith("artifact:sha256:")
assert executed["result"]["interpretationAnalysisNodeID"].startswith(
    "analysis-node:sha256:"
)
assert executed["result"]["planStatus"] == "readyWithCaveats"
assert executed["result"]["terminalState"] == "completedWithCaveats"
assert executed["result"]["completedWorkUnits"] == executed["result"]["estimatedWorkUnits"]
assert [artifact["role"] for artifact in executed["result"]["artifacts"]] == [
    "target",
    "reference",
    "comparison",
]
assert all(
    artifact["artifactID"].startswith("artifact:sha256:")
    for artifact in executed["result"]["artifacts"]
)
interpretation = executed["result"]["interpretation"]
assert interpretation["ruleCatalogIdentifier"] == "interpretation-rules-mvp-v1"
assert interpretation["rankingIdentifier"] == "editorial-rank-v1"
assert interpretation["planArtifactID"] == planned["result"]["artifactID"]
assert interpretation["planAnalysisNodeID"] == planned["result"]["analysisNodeID"]
assert set(interpretation["sourceArtifactIDs"]) == {
    artifact["artifactID"] for artifact in executed["result"]["artifacts"]
}
assert interpretation["findings"] == []
assert interpretation["evidence"] == []
assert interpretation["insufficientEvidence"] is not None
assert reused_execution["result"]["sourceGeneration"] == 8
assert reused_execution["result"]["generation"] == 8
assert reused_execution["result"]["artifacts"] == executed["result"]["artifacts"]
assert (
    reused_execution["result"]["interpretationArtifactID"]
    == executed["result"]["interpretationArtifactID"]
)
assert reused_execution["result"]["interpretation"] == interpretation
assert investigation_created["command"] == "investigation.create"
assert investigation_created["result"]["generation"] == 9
created_investigation = investigation_created["result"]["investigation"]
assert created_investigation["languageCode"] == "it"
assert created_investigation["question"] == "Quali differenze emergono?"
assert created_investigation["interpretationArtifactID"] == executed["result"]["interpretationArtifactID"]
assert created_investigation["availableFindingIDs"] == []
assert created_investigation["selectedFindingIDs"] == []
assert len(created_investigation["eventIDs"]) == 1
assert investigation_selection_a["command"] == "investigation.select"
assert investigation_selection_a["result"]["generation"] == 10
assert investigation_selection_b["command"] == "investigation.select"
assert investigation_selection_b["result"]["generation"] == 11
assert investigation_selection_a["result"]["investigation"]["id"] == created_investigation["id"]
assert investigation_selection_b["result"]["investigation"]["id"] == created_investigation["id"]
assert investigation_selection_a["result"]["investigation"]["headEventID"] != investigation_selection_b["result"]["investigation"]["headEventID"]
assert exported["command"] == "export"
assert exported["outcome"] == "succeeded"
assert exported["result"]["reportRevisionID"].startswith("report-revision:sha256:")
assert exported["result"]["manifestDigest"].startswith("sha256:")
assert exported["result"]["fileCount"] == 5
manifest_bytes = (export_path / "export-manifest.json").read_bytes()
manifest = json.loads(manifest_bytes)
assert manifest["schema"] == "studio.glifi.export-manifest"
assert manifest["schemaVersion"] == 1
assert manifest["selection"]["investigationHeadEventID"] == investigation_selection_b["result"]["investigation"]["headEventID"]
assert manifest["selection"]["reportRevisionID"] == exported["result"]["reportRevisionID"]
assert [item["path"] for item in manifest["files"]] == [
    "evidence.csv",
    "findings.csv",
    "report.json",
    "report.md",
    "report.pdf",
]
assert str(export_path) not in manifest_bytes.decode("utf-8")
for item in manifest["files"]:
    data = (export_path / item["path"]).read_bytes()
    assert len(data) == item["byteCount"]
    assert "sha256:" + hashlib.sha256(data).hexdigest() == item["sha256"]
assert (export_path / "report.pdf").read_bytes().startswith(b"%PDF-")
assert (export_path / "findings.csv").read_bytes().startswith(
    b'"ordinal","finding_id","message_key"'
)
assert b"\r\n" in (export_path / "evidence.csv").read_bytes()
assert investigation_list["command"] == "investigation.list"
assert len(investigation_list["result"]) == 2
assert {item["headEventID"] for item in investigation_list["result"]} == {
    investigation_selection_a["result"]["investigation"]["headEventID"],
    investigation_selection_b["result"]["investigation"]["headEventID"],
}
assert oversized_plan["command"] == "plan"
assert oversized_plan["outcome"] == "failed"
assert oversized_plan["failure"]["code"] == "planner.request-too-large"
assert oversized_plan["failure"]["category"] == "insufficientResources"
assert final_info["result"]["project"]["generation"] == 11
assert final_info["result"]["project"]["artifactCount"] == 6
assert final_info["result"]["project"]["investigationEventCount"] == 3
PY

xcodebuild build \
    -quiet \
    -workspace GlifiStudio.xcworkspace \
    -scheme GlifiStudio-macOS \
    -configuration Debug \
    -destination "generic/platform=macOS" \
    -derivedDataPath "$temporary_build_directory/macOS" \
    CODE_SIGNING_ALLOWED=NO

xcodebuild build \
    -quiet \
    -workspace GlifiStudio.xcworkspace \
    -scheme GlifiStudio-macOS \
    -configuration Release \
    -destination "generic/platform=macOS" \
    -derivedDataPath "$temporary_build_directory/macOS" \
    CODE_SIGNING_ALLOWED=NO

xcodebuild build \
    -quiet \
    -workspace GlifiStudio.xcworkspace \
    -scheme GlifiStudio-iPadOS \
    -configuration Debug \
    -destination "generic/platform=iOS Simulator" \
    -derivedDataPath "$temporary_build_directory/iPadOS" \
    CODE_SIGNING_ALLOWED=NO

xcodebuild build \
    -quiet \
    -workspace GlifiStudio.xcworkspace \
    -scheme GlifiStudio-iPadOS \
    -configuration Release \
    -destination "generic/platform=iOS Simulator" \
    -derivedDataPath "$temporary_build_directory/iPadOS" \
    CODE_SIGNING_ALLOWED=NO
