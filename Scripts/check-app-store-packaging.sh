#!/bin/zsh
# SPDX-License-Identifier: BSD-3-Clause

set -euo pipefail

script_directory="${0:A:h}"
project_directory="${script_directory:h}"
temporary_directory="$(mktemp -d "${TMPDIR%/}/GlifiStudioAppStore.XXXXXX")"

cleanup() {
    rm -rf "$temporary_directory"
}
trap cleanup EXIT

cd "$project_directory"

xcodebuild analyze -quiet \
    -workspace GlifiStudio.xcworkspace \
    -scheme GlifiStudio-macOS \
    -configuration Release \
    -destination "generic/platform=macOS" \
    -derivedDataPath "$temporary_directory/Analyze-macOS" \
    CODE_SIGNING_ALLOWED=NO

xcodebuild analyze -quiet \
    -workspace GlifiStudio.xcworkspace \
    -scheme GlifiStudio-iPadOS \
    -configuration Release \
    -destination "generic/platform=iOS Simulator" \
    -derivedDataPath "$temporary_directory/Analyze-iPadOS" \
    CODE_SIGNING_ALLOWED=NO

xcodebuild archive -quiet \
    -workspace GlifiStudio.xcworkspace \
    -scheme GlifiStudio-macOS \
    -configuration Release \
    -destination "generic/platform=macOS" \
    -archivePath "$temporary_directory/GlifiStudio-macOS.xcarchive" \
    -derivedDataPath "$temporary_directory/Archive-macOS" \
    CODE_SIGNING_ALLOWED=NO

xcodebuild archive -quiet \
    -workspace GlifiStudio.xcworkspace \
    -scheme GlifiStudio-iPadOS \
    -configuration Release \
    -destination "generic/platform=iOS" \
    -archivePath "$temporary_directory/GlifiStudio-iPadOS.xcarchive" \
    -derivedDataPath "$temporary_directory/Archive-iPadOS" \
    CODE_SIGNING_ALLOWED=NO

typeset -a info_plists
info_plists=(
    "$temporary_directory/GlifiStudio-macOS.xcarchive/Products/Applications/GlifiStudio.app/Contents/Info.plist"
    "$temporary_directory/GlifiStudio-iPadOS.xcarchive/Products/Applications/GlifiStudio.app/Info.plist"
)

for info_plist in "${info_plists[@]}"; do
    if [[ ! -f "$info_plist" ]]; then
        print -u2 "Archivio privo di Info.plist: $info_plist"
        exit 1
    fi
    [[ "$(plutil -extract CFBundleIdentifier raw "$info_plist")" == "studio.glifi.GlifiStudio" ]]
    [[ "$(plutil -extract CFBundleShortVersionString raw "$info_plist")" == "0.1.0" ]]
    [[ "$(plutil -extract CFBundleVersion raw "$info_plist")" == "1" ]]
    [[ "$(plutil -extract ITSAppUsesNonExemptEncryption raw "$info_plist")" == "false" ]]
done

mac_resources="$temporary_directory/GlifiStudio-macOS.xcarchive/Products/Applications/GlifiStudio.app/Contents/Resources"
pad_resources="$temporary_directory/GlifiStudio-iPadOS.xcarchive/Products/Applications/GlifiStudio.app"
[[ -f "$mac_resources/PrivacyInfo.xcprivacy" ]]
[[ -f "$pad_resources/PrivacyInfo.xcprivacy" ]]
[[ -f "$mac_resources/Assets.car" ]]
[[ -f "$pad_resources/Assets.car" ]]

print "App Store packaging: static analysis and unsigned archives valid"
