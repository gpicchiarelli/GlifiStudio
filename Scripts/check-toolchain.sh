#!/bin/zsh
# SPDX-License-Identifier: BSD-3-Clause

set -euo pipefail

required_xcode_major=27
required_swift_major=6

xcode_version="$(xcodebuild -version | awk '/^Xcode / { print $2; exit }')"
xcode_major="${xcode_version%%.*}"

if [[ "$xcode_major" != "$required_xcode_major" ]]; then
    print -u2 "Toolchain non valida: richiesto Xcode ${required_xcode_major}.x, rilevato ${xcode_version:-sconosciuto}"
    exit 1
fi

swift_version_output="$(swift --version)"
swift_version="$(print -r -- "$swift_version_output" | sed -nE 's/.*Swift version ([0-9]+\.[0-9]+(\.[0-9]+)?).*/\1/p' | head -n 1)"
swift_major="${swift_version%%.*}"

if [[ "$swift_major" != "$required_swift_major" ]]; then
    print -u2 "Toolchain non valida: richiesto Swift ${required_swift_major}.x, rilevato ${swift_version:-sconosciuto}"
    exit 1
fi

print "Toolchain: Xcode $xcode_version, Swift $swift_version"
