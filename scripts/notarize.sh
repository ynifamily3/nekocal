#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
: "${SIGNING_IDENTITY:?Set SIGNING_IDENTITY to your Developer ID Application identity}"
: "${NOTARY_PROFILE:?Set NOTARY_PROFILE to your notarytool Keychain profile}"
case "$SIGNING_IDENTITY" in 'Developer ID Application: '*) ;; *) echo 'Developer ID Application required' >&2; exit 1;; esac
# Validate credentials before producing a new release.
xcrun notarytool history --keychain-profile "$NOTARY_PROFILE" --output-format json > /dev/null
./scripts/build.sh
./scripts/sign.sh
app="$PWD/outputs/KawaiiCal.app"
ditto -c -k --keepParent "$app" outputs/KawaiiCal-notary.zip
xcrun notarytool submit outputs/KawaiiCal-notary.zip --keychain-profile "$NOTARY_PROFILE" --wait --output-format json > outputs/notary-result.json
if ! python3 -c 'import json; r=json.load(open("outputs/notary-result.json")); print(r["status"]); raise SystemExit(r["status"] != "Accepted")'; then
 submission=$(python3 -c 'import json; print(json.load(open("outputs/notary-result.json"))["id"])')
 xcrun notarytool log "$submission" --keychain-profile "$NOTARY_PROFILE" outputs/notary-log.json
 echo 'Notarization not accepted; see outputs/notary-log.json' >&2
 exit 1
fi
xcrun stapler staple "$app"
xcrun stapler validate "$app"
spctl --assess --type execute --verbose=4 "$app"
ditto -c -k --keepParent "$app" outputs/KawaiiCal.zip
