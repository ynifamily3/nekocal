#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
: "${SIGNING_IDENTITY:?Set SIGNING_IDENTITY to your Developer ID Application identity}"
case "$SIGNING_IDENTITY" in 'Developer ID Application: '*) ;; *) echo 'Developer ID Application required' >&2; exit 1;; esac
app="$PWD/outputs/KawaiiCal.app"
# Sign executable code from the inside out, including the bundled updater helper.
while IFS= read -r -d '' binary; do
 if file "$binary" | /usr/bin/grep -q 'Mach-O'; then
  codesign --force --options runtime --timestamp --sign "$SIGNING_IDENTITY" "$binary"
 fi
done < <(find "$app/Contents/Frameworks" -type f -print0)
while IFS= read -r -d '' helper; do
 codesign --force --options runtime --timestamp --sign "$SIGNING_IDENTITY" "$helper"
done < <(find "$app/Contents/Frameworks" -type d -name '*.app' -print0)
for framework in "$app"/Contents/Frameworks/*.framework; do
 codesign --force --options runtime --timestamp --sign "$SIGNING_IDENTITY" "$framework"
done
codesign --force --options runtime --timestamp --entitlements Itsycal/Itsycal.entitlements --sign "$SIGNING_IDENTITY" "$app"
codesign --verify --deep --strict "$app"
