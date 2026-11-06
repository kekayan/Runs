#!/bin/bash
# Packages a signed Runs.app into a signed, notarized, stapled DMG with an Applications shortcut.
# Usage: ./make_dmg.sh <path/to/Runs.app> <out.dmg>
set -euo pipefail

APP="$1"
DMG="$2"
NOTARY_PROFILE="${NOTARY_PROFILE:-runs-notary}"

STAGING="$(mktemp -d)"
trap 'rm -rf "$STAGING"' EXIT
ditto "$APP" "$STAGING/Runs.app"
ln -s /Applications "$STAGING/Applications"

echo "==> Creating DMG"
rm -f "$DMG"
hdiutil create -volname "Runs" -srcfolder "$STAGING" -fs HFS+ -format UDZO -ov "$DMG" >/dev/null 2>&1
# Signing the DMG is optional (the app inside is already signed). Sign it only if a local
# Developer ID certificate exists; Xcode's cloud-managed signing doesn't install one.
IDENTITY=$(security find-identity -v -p codesigning | awk -F'"' '/Developer ID Application/ {print $2; exit}')
if [ -n "$IDENTITY" ]; then
    codesign --sign "$IDENTITY" --timestamp "$DMG"
fi

if [ "${SKIP_NOTARIZE:-0}" != "1" ]; then
    echo "==> Notarizing DMG"
    xcrun notarytool submit "$DMG" --keychain-profile "$NOTARY_PROFILE" --wait
    xcrun stapler staple "$DMG"
    xcrun stapler validate "$DMG"
fi
echo "==> Done: $DMG"
