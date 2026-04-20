#!/bin/bash
set -e

APP_NAME="GGGoogleTranslate"
BUILD_DIR="./build"
APP_DIR="$BUILD_DIR/$APP_NAME.app"
DMG_DIR="$BUILD_DIR/dmg_staging"
DMG_FILE="$BUILD_DIR/${APP_NAME}_v1.0.1.dmg"

echo "Creating DMG..."

# 1. Clean up old files
rm -rf "$DMG_DIR"
rm -f "$DMG_FILE"
mkdir -p "$DMG_DIR"

# 2. Add the app and Applications shortcut
cp -R "$APP_DIR" "$DMG_DIR/"
ln -s /Applications "$DMG_DIR/Applications"

# 3. Create the DMG volume
hdiutil create -volname "$APP_NAME Setup" -srcfolder "$DMG_DIR" -ov -format UDZO "$DMG_FILE"

# 4. Clean up staging folder
rm -rf "$DMG_DIR"

echo ""
echo "✅ DMG File successfully created at:"
echo "   $DMG_FILE"
