#!/bin/bash
set -e

APP_NAME="YouTube"
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="$PROJECT_DIR/build"
APP_BUNDLE="$BUILD_DIR/$APP_NAME.app"
CONTENTS="$APP_BUNDLE/Contents"
MACOS="$CONTENTS/MacOS"
RESOURCES="$CONTENTS/Resources"

echo "[1/5] Cleaning build directory..."
rm -rf "$BUILD_DIR"
mkdir -p "$MACOS" "$RESOURCES"

echo "[2/5] Compiling Swift source code (Universal: Apple Silicon + Intel)..."
TEMP_BUILD="$BUILD_DIR/temp"
mkdir -p "$TEMP_BUILD"

swiftc -O \
    -target arm64-apple-macos13.0 \
    "$PROJECT_DIR/Sources/main.swift" \
    -o "$TEMP_BUILD/${APP_NAME}_arm64" \
    -framework Cocoa \
    -framework WebKit

swiftc -O \
    -target x86_64-apple-macos13.0 \
    "$PROJECT_DIR/Sources/main.swift" \
    -o "$TEMP_BUILD/${APP_NAME}_x86_64" \
    -framework Cocoa \
    -framework WebKit

lipo -create -output "$MACOS/$APP_NAME" "$TEMP_BUILD/${APP_NAME}_arm64" "$TEMP_BUILD/${APP_NAME}_x86_64"
rm -rf "$TEMP_BUILD"

echo "[3/5] Copying Info.plist and Resources..."
cp "$PROJECT_DIR/Info.plist" "$CONTENTS/Info.plist"

# Update executable name in Info.plist to match APP_NAME
sed -i '' "s/<string>SwitchVideoToComment<\/string>/<string>$APP_NAME<\/string>/g" "$CONTENTS/Info.plist"

# Copy resources
cp "$PROJECT_DIR/Resources/style.css" "$RESOURCES/style.css"
cp "$PROJECT_DIR/Resources/swapLayout.js" "$RESOURCES/swapLayout.js"
if [ -f "$PROJECT_DIR/Resources/AppIcon.icns" ]; then
    cp "$PROJECT_DIR/Resources/AppIcon.icns" "$RESOURCES/AppIcon.icns"
fi

echo "[4/5] Ad-hoc code signing..."
codesign --force --deep --sign - "$APP_BUNDLE"

echo "[5/5] Build Complete!"
echo "--------------------------------------------------------"
echo "Application build successfully created!"
echo "Location: $APP_BUNDLE"
echo ""
echo "To launch now:"
echo "   open \"$APP_BUNDLE\""
echo ""
echo "To copy to /Applications:"
echo "   cp -R \"$APP_BUNDLE\" /Applications/"
echo "--------------------------------------------------------"
