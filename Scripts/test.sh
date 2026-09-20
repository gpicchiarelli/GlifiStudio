#!/bin/zsh
# SPDX-License-Identifier: BSD-3-Clause

set -euo pipefail

script_directory="${0:A:h}"
project_directory="${script_directory:h}"
temporary_root="${TMPDIR:-/tmp}"
source "$script_directory/build-cache.sh"
build_cache_directory="$(glifi_build_cache_directory)"

cleanup() {
    glifi_release_build_cache "$build_cache_directory"
}

trap cleanup EXIT

cd "$project_directory"

glifi_sweep_stale_temporaries "$temporary_root"
glifi_require_free_space "$temporary_root"
glifi_prepare_build_cache "$build_cache_directory"

swift test \
    --package-path Packages/GlifiCore \
    --scratch-path "$build_cache_directory/SwiftPM"
