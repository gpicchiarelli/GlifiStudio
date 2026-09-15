#!/bin/zsh
# SPDX-License-Identifier: BSD-3-Clause

set -euo pipefail

script_directory="${0:A:h}"
project_directory="${script_directory:h}"
temporary_build_directory="$(mktemp -d "${TMPDIR%/}/GlifiStudioVerify.XXXXXX")"

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
swift format lint --strict --recursive Apps Packages
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
cli_validate_output="$(swift run \
    --package-path Packages/GlifiCore \
    --scratch-path "$temporary_build_directory/SwiftPM" \
    --skip-build \
    GlifiCLI --format json project validate "$cli_project_path")"

python3 - "$cli_create_output" "$cli_import_output" "$cli_validate_output" <<'PY'
import json
import sys

created, imported, validated = (json.loads(value) for value in sys.argv[1:])
assert created["command"] == "project.create"
assert created["result"]["project"]["generation"] == 0
assert imported["command"] == "import"
assert imported["result"]["project"]["generation"] == 1
assert imported["result"]["project"]["sourceCount"] == 1
assert imported["result"]["lastProfile"]["lexicalTokenCount"] == 3
assert validated["command"] == "project.validate"
assert validated["result"]["status"] == "valid"
assert validated["result"]["project"] == imported["result"]["project"]
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
