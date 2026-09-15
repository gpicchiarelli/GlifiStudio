#!/bin/zsh
# SPDX-License-Identifier: BSD-3-Clause

set -euo pipefail

script_directory="${0:A:h}"
project_directory="${script_directory:h}"
package_sources_directory="$project_directory/Packages/GlifiCore/Sources"
core_directory="$package_sources_directory/GlifiCore"
kit_directory="$package_sources_directory/GlifiKit"
cli_directory="$package_sources_directory/GlifiCLI"
apps_directory="$project_directory/Apps"

forbidden_imports='^[[:space:]]*import[[:space:]]+(SwiftUI|AppKit|UIKit)([[:space:]]|$)'
direct_core_import='^[[:space:]]*import[[:space:]]+GlifiCore([[:space:]]|$)'

if rg --line-number "$forbidden_imports" "$core_directory" "$kit_directory" "$cli_directory"; then
    print -u2 "GlifiCore, GlifiKit e GlifiCLI non possono dipendere dai framework UI."
    exit 1
fi

if rg --line-number "$direct_core_import" "$apps_directory" "$cli_directory"; then
    print -u2 "Le app e GlifiCLI devono accedere al motore soltanto tramite GlifiKit."
    exit 1
fi

echo "Architecture boundaries: valid"
