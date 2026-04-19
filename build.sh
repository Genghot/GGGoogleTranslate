#!/bin/bash
# Build GGG Translate macOS app using swiftc directly
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
APP_NAME="GGGoogleTranslate"
BUILD_DIR="$SCRIPT_DIR/build"
APP_DIR="$BUILD_DIR/${APP_NAME}.app"
SOURCES_DIR="$SCRIPT_DIR/Sources"

SDK_PATH=$(xcrun --show-sdk-path)
DEPLOYMENT_TARGET="14.0"

echo "🔨 Building GGG Translate..."
echo "   Swift: $(swiftc --version 2>&1 | head -1)"
echo "   SDK: $SDK_PATH"
echo ""

# Collect all Swift source files (excluding Resources directory)
SWIFT_FILES=$(find "$SOURCES_DIR" -name "*.swift" -not -path "*/Resources/*" | sort)

echo "   Compiling source files:"
for f in $SWIFT_FILES; do
    echo "     - $(basename $f)"
done
echo ""

# Create VFS overlay to fix SwiftBridging redefinition bug
mkdir -p "$BUILD_DIR"
echo "" > "$BUILD_DIR/empty.modulemap"
cat > "$BUILD_DIR/vfs_overlay.yaml" << EOF
{
  "version": 0,
  "roots": [
    {
      "name": "/Library/Developer/CommandLineTools/usr/include/swift",
      "type": "directory",
      "contents": [
        {
          "name": "module.modulemap",
          "type": "file",
          "external-contents": "$BUILD_DIR/empty.modulemap"
        }
      ]
    }
  ]
}
EOF

# Compile
swiftc \
    $SWIFT_FILES \
    -o "$BUILD_DIR/GGGoogleTranslate" \
    -sdk "$SDK_PATH" \
    -target arm64-apple-macosx${DEPLOYMENT_TARGET} \
    -framework Cocoa \
    -framework WebKit \
    -framework Carbon \
    -framework ServiceManagement \
    -Osize \
    -parse-as-library \
    -swift-version 5 \
    -Xcc -ivfsoverlay -Xcc "$BUILD_DIR/vfs_overlay.yaml"

echo "✅ Compilation successful"
echo ""

# Create app bundle structure
echo "📦 Creating app bundle..."
rm -rf "$APP_DIR"
mkdir -p "$APP_DIR/Contents/MacOS"
mkdir -p "$APP_DIR/Contents/Resources"

# Copy executable
cp "$BUILD_DIR/GGGoogleTranslate" "$APP_DIR/Contents/MacOS/GGGoogleTranslate"

# Copy Info.plist
cp "$SOURCES_DIR/Resources/Info.plist" "$APP_DIR/Contents/Info.plist"

# Copy app icon if exists
if [ -f "$SCRIPT_DIR/assets/AppIcon.icns" ]; then
    cp "$SCRIPT_DIR/assets/AppIcon.icns" "$APP_DIR/Contents/Resources/AppIcon.icns"
    echo "  ✅ App icon copied"
else
    echo "  ⚠️  No AppIcon.icns found in assets/"
    echo "     Create it: sips -s format icns input.png --out assets/AppIcon.icns"
fi

# Sign with ad-hoc signature
codesign --force --deep --sign - \
    --entitlements "$SOURCES_DIR/Resources/GGGTranslate.entitlements" \
    "$APP_DIR" 2>/dev/null && echo "  ✅ Code signed (ad-hoc)" || echo "  ⚠️  Code signing skipped"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ Built successfully!"
echo "   $APP_DIR"
echo ""
echo "   To run:     open \"$APP_DIR\""
echo "   To install: cp -r \"$APP_DIR\" /Applications/"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
