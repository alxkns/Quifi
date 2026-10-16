#!/bin/bash
set -e

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_DIR="$PROJECT_DIR/build"
APP_NAME="QuiFi"
DMG_NAME="QuiFi.dmg"
APP_BUNDLE="$BUILD_DIR/$APP_NAME.app"

# Ensure the app bundle exists
if [ ! -d "$APP_BUNDLE" ]; then
    echo "🔨 App bundle not found. Building it first..."
    "$PROJECT_DIR/Scripts/build_app.sh"
fi

echo "💿 Creating macOS DMG for $APP_NAME..."

DMG_TEMP="$BUILD_DIR/dmg_temp"
rm -rf "$DMG_TEMP"
mkdir -p "$DMG_TEMP"

# Copy the .app bundle
cp -R "$APP_BUNDLE" "$DMG_TEMP/"

# Create symlink to /Applications for easy drag-and-drop install
ln -s /Applications "$DMG_TEMP/Applications"

# Output DMG path
DMG_PATH="$BUILD_DIR/$DMG_NAME"
rm -f "$DMG_PATH"

# Build DMG using hdiutil
hdiutil create \
    -volname "$APP_NAME" \
    -srcfolder "$DMG_TEMP" \
    -ov \
    -format UDZO \
    "$DMG_PATH"

rm -rf "$DMG_TEMP"

echo "✅ DMG successfully created at: $DMG_PATH"
