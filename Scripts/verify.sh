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

python3 - "$cli_create_output" "$cli_import_output" "$cli_markdown_import_output" \
    "$cli_validate_output" "$cli_query_output" "$cli_markdown_query_output" \
    "$cli_analysis_output" "$cli_keyness_output" <<'PY'
import json
import sys

created, imported, markdown_imported, validated, queried, markdown_queried, analyzed, keyness = (
    json.loads(value) for value in sys.argv[1:]
)
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
