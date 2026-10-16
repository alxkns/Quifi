#!/bin/bash
set -e

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

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

for test_plugin_dir in \
    "$DEV_DIR/Toolchains/XcodeDefault.xctoolchain/usr/lib/swift/host/plugins/testing" \
    "/Library/Developer/CommandLineTools/usr/lib/swift/host/plugins/testing"; do
    if [ -d "$test_plugin_dir" ]; then
        EXTRA_ARGS+=("-Xswiftc" "-plugin-path" "-Xswiftc" "$test_plugin_dir")
        break
    fi
done

cd "$PROJECT_DIR"
swift test "${EXTRA_ARGS[@]}"
