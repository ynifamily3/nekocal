#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p outputs
[ -f Local.xcconfig ] || cp Local.xcconfig.example Local.xcconfig
xcodebuild -project Itsycal.xcodeproj -scheme Itsycal -configuration Release -destination 'generic/platform=macOS' -derivedDataPath "$PWD/work/KawaiiCal-build" ARCHS=arm64 ONLY_ACTIVE_ARCH=YES build > outputs/build.log 2>&1
staging=$(mktemp -d "$PWD/outputs/.build-XXXXXX")
trap 'rm -rf "$staging"' EXIT
ditto work/KawaiiCal-build/Build/Products/Release/KawaiiCal.app "$staging/KawaiiCal.app"
codesign --verify --deep --strict "$staging/KawaiiCal.app"
if [ -d outputs/KawaiiCal.app ]; then
 mv outputs/KawaiiCal.app "$staging/previous.app"
fi
mv "$staging/KawaiiCal.app" outputs/KawaiiCal.app
codesign --verify --deep --strict outputs/KawaiiCal.app
printf 'Built: %s/outputs/KawaiiCal.app\n' "$PWD"
