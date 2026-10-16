#!/bin/bash
set -e

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
INPUT_IMAGE="${1:-$PROJECT_DIR/docs/images/AppIcon.png}"
OUTPUT_ICNS="${2:-$PROJECT_DIR/Sources/QuiFi/Resources/AppIcon.icns}"

if [ ! -f "$INPUT_IMAGE" ]; then
    echo "❌ Error: Input image '$INPUT_IMAGE' not found!"
    exit 1
fi

TMP_ICONSET="$PROJECT_DIR/build/AppIcon.iconset"
rm -rf "$TMP_ICONSET"
mkdir -p "$TMP_ICONSET"

echo "🎨 Generating iconset sizes from $INPUT_IMAGE..."

sips -z 16 16     "$INPUT_IMAGE" --out "$TMP_ICONSET/icon_16x16.png" >/dev/null
sips -z 32 32     "$INPUT_IMAGE" --out "$TMP_ICONSET/icon_16x16@2x.png" >/dev/null
sips -z 32 32     "$INPUT_IMAGE" --out "$TMP_ICONSET/icon_32x32.png" >/dev/null
sips -z 64 64     "$INPUT_IMAGE" --out "$TMP_ICONSET/icon_32x32@2x.png" >/dev/null
sips -z 128 128   "$INPUT_IMAGE" --out "$TMP_ICONSET/icon_128x128.png" >/dev/null
sips -z 256 256   "$INPUT_IMAGE" --out "$TMP_ICONSET/icon_128x128@2x.png" >/dev/null
sips -z 256 256   "$INPUT_IMAGE" --out "$TMP_ICONSET/icon_256x256.png" >/dev/null
sips -z 512 512   "$INPUT_IMAGE" --out "$TMP_ICONSET/icon_256x256@2x.png" >/dev/null
sips -z 512 512   "$INPUT_IMAGE" --out "$TMP_ICONSET/icon_512x512.png" >/dev/null
sips -z 1024 1024 "$INPUT_IMAGE" --out "$TMP_ICONSET/icon_512x512@2x.png" >/dev/null

echo "🔨 Compiling .icns with iconutil..."
mkdir -p "$(dirname "$OUTPUT_ICNS")"
iconutil -c icns "$TMP_ICONSET" -o "$OUTPUT_ICNS"

rm -rf "$TMP_ICONSET"

echo "✅ Generated $OUTPUT_ICNS successfully!"
