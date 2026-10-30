#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
source_app="$PWD/outputs/KawaiiCal.app"
target_app=/Applications/KawaiiCal.app
[ -d "$source_app" ] || { echo 'Build first with scripts/build.sh' >&2; exit 1; }
[ "$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$source_app/Contents/Info.plist")" = ing.miel.KawaiiCal ]
codesign --verify --deep --strict "$source_app"
if pgrep -f -x "$target_app/Contents/MacOS/KawaiiCal" > /dev/null; then
 echo 'Quit KawaiiCal before installing; open forms may contain unsaved edits.' >&2
 exit 1
fi
staging=$(mktemp -d /Applications/.KawaiiCal-install-XXXXXX)
trap 'rm -rf "$staging"' EXIT
ditto "$source_app" "$staging/KawaiiCal.app"
codesign --verify --deep --strict "$staging/KawaiiCal.app"
if [ -e "$target_app" ]; then
 [ "$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$target_app/Contents/Info.plist")" = ing.miel.KawaiiCal ]
 mkdir -p outputs/installed-backups
 backup=$(mktemp -d "$PWD/outputs/installed-backups/install-XXXXXX")
 mv "$target_app" "$backup/KawaiiCal.app"
fi
if ! mv "$staging/KawaiiCal.app" "$target_app"; then
 if [ -n "${backup:-}" ]; then mv "$backup/KawaiiCal.app" "$target_app"; fi
 exit 1
fi
echo "Installed: $target_app"
