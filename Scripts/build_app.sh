#!/bin/bash
set -e

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_DIR="$PROJECT_DIR/build"
APP_NAME="QuiFi"
APP_BUNDLE="$BUILD_DIR/$APP_NAME.app"
CONTENTS_DIR="$APP_BUNDLE/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"

echo "🚀 Building $APP_NAME for macOS (Release mode)..."

# Ensure developer SDK and plugins are discovered
DEV_DIR="$(xcode-select -p 2>/dev/null || echo '/Applications/Xcode.app/Contents/Developer')"
if [ ! -d "$DEV_DIR/Platforms/MacOSX.platform" ] && [ -d "/Applications/Xcode.app/Contents/Developer" ]; then
    DEV_DIR="/Applications/Xcode.app/Contents/Developer"
fi
SDK_PATH="$DEV_DIR/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk"
PLUGIN_PATH="$DEV_DIR/Platforms/MacOSX.platform/Developer/usr/lib/swift/host/plugins"

EXTRA_ARGS=()
if [ -d "$SDK_PATH" ]; then
    export SDKROOT="$SDK_PATH"
fi
if [ -d "$PLUGIN_PATH" ]; then
    EXTRA_ARGS+=("-Xswiftc" "-plugin-path" "-Xswiftc" "$PLUGIN_PATH")
fi

cd "$PROJECT_DIR"
swift build -c release "${EXTRA_ARGS[@]}"

BINARY_PATH="$(swift build -c release "${EXTRA_ARGS[@]}" --show-bin-path)/$APP_NAME"

echo "📦 Creating application bundle at $APP_BUNDLE..."
rm -rf "$APP_BUNDLE"
mkdir -p "$MACOS_DIR"
mkdir -p "$RESOURCES_DIR"

# Copy compiled binary
cp "$BINARY_PATH" "$MACOS_DIR/$APP_NAME"
chmod +x "$MACOS_DIR/$APP_NAME"

# Copy Info.plist
cp "$PROJECT_DIR/Sources/QuiFi/Resources/Info.plist" "$CONTENTS_DIR/Info.plist"

# Copy AppIcon.icns if present
if [ -f "$PROJECT_DIR/Sources/QuiFi/Resources/AppIcon.icns" ]; then
    cp "$PROJECT_DIR/Sources/QuiFi/Resources/AppIcon.icns" "$RESOURCES_DIR/AppIcon.icns"
fi

# Create PkgInfo
echo -n "APPL????" > "$CONTENTS_DIR/PkgInfo"

# Ad-hoc code sign with persistent designated requirement so TCC permissions stay valid across builds
codesign --force --deep --sign - --requirements '=designated => identifier "org.quifi.app"' "$APP_BUNDLE"

echo "✅ Successfully built $APP_BUNDLE!"

# Optional zip creation
if [ "$1" == "--zip" ]; then
    echo "🗜️ Creating ZIP archive for distribution..."
    cd "$BUILD_DIR"
    zip -r -y -q "$APP_NAME-macOS.zip" "$APP_NAME.app"
    echo "🎉 Distribution archive ready: $BUILD_DIR/$APP_NAME-macOS.zip"
fi
