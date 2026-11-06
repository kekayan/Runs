#!/bin/bash
# Builds a Developer ID–signed, notarized Runs.app and zips it for distribution.
#
# One-time setup:
#   1. Xcode → Settings → Accounts → Manage Certificates → + → "Developer ID Application"
#   2. Store notary credentials (uses an app-specific password from account.apple.com):
#        xcrun notarytool store-credentials runs-notary --apple-id <you> --team-id 2SJYM5X9VQ
#
# Usage: ./release.sh            (build, sign, notarize)
#        SKIP_NOTARIZE=1 ./release.sh
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
BUILD_DIR="$PROJECT_DIR/build/release"
ARCHIVE="$BUILD_DIR/Runs.xcarchive"
EXPORT_DIR="$BUILD_DIR/export"
TEAM_ID="2SJYM5X9VQ"
NOTARY_PROFILE="${NOTARY_PROFILE:-runs-notary}"

rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

echo "==> Archiving"
xcodebuild -project "$PROJECT_DIR/Runs.xcodeproj" -scheme Runs -configuration Release \
    -archivePath "$ARCHIVE" -allowProvisioningUpdates \
    DEVELOPMENT_TEAM="$TEAM_ID" archive | tail -3

cat > "$BUILD_DIR/ExportOptions.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key><string>developer-id</string>
    <key>teamID</key><string>$TEAM_ID</string>
    <key>signingStyle</key><string>automatic</string>
</dict>
</plist>
PLIST

echo "==> Exporting with Developer ID"
xcodebuild -exportArchive -archivePath "$ARCHIVE" -exportPath "$EXPORT_DIR" \
    -exportOptionsPlist "$BUILD_DIR/ExportOptions.plist" -allowProvisioningUpdates | tail -3

APP="$EXPORT_DIR/Runs.app"
VERSION=$(defaults read "$APP/Contents/Info.plist" CFBundleShortVersionString)
ZIP="$BUILD_DIR/Runs-$VERSION.zip"

codesign --verify --deep --strict "$APP"
codesign -dvv "$APP" 2>&1 | grep -E "Authority=Developer ID|TeamIdentifier"

if [ "${SKIP_NOTARIZE:-0}" != "1" ]; then
    echo "==> Notarizing"
    ditto -c -k --keepParent "$APP" "$BUILD_DIR/notarize.zip"
    xcrun notarytool submit "$BUILD_DIR/notarize.zip" --keychain-profile "$NOTARY_PROFILE" --wait
    xcrun stapler staple "$APP"
    spctl --assess --type execute -vv "$APP"
fi

ditto -c -k --keepParent "$APP" "$ZIP"
echo "==> Done: $ZIP"
