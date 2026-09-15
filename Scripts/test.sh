#!/bin/zsh
# SPDX-License-Identifier: BSD-3-Clause

set -euo pipefail

script_directory="${0:A:h}"
project_directory="${script_directory:h}"
temporary_build_directory="$(mktemp -d "${TMPDIR%/}/GlifiStudioTests.XXXXXX")"

cleanup() {
    rm -rf "$temporary_build_directory"
}

trap cleanup EXIT

cd "$project_directory"

swift test \
    --package-path Packages/GlifiCore \
    --scratch-path "$temporary_build_directory/SwiftPM"
