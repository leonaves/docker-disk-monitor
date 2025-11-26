#!/bin/bash
set -e

# Configuration
PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BUILD_DIR="$PROJECT_DIR/build"
APPCAST_PATH="$PROJECT_DIR/appcast.xml"

# Check if Sparkle is available
if ! command -v generate_appcast &> /dev/null; then
    echo "❌ Sparkle's generate_appcast tool not found"
    echo ""
    echo "Install Sparkle via Homebrew:"
    echo "  brew install sparkle"
    echo ""
    echo "Or add Sparkle to your Xcode project and use:"
    echo "  $(find ~/Library/Developer/Xcode/DerivedData -name generate_appcast | head -1)"
    exit 1
fi

# Check if private key exists
if [ ! -f "$PROJECT_DIR/sparkle_eddsa_private.pem" ]; then
    echo "❌ Private key not found: sparkle_eddsa_private.pem"
    echo "Run ./scripts/generate-sparkle-keys.sh first"
    exit 1
fi

# Find all DMGs in build directory
DMGS=$(find "$BUILD_DIR" -name "*.dmg" -type f)

if [ -z "$DMGS" ]; then
    echo "❌ No DMG files found in $BUILD_DIR"
    echo "Run ./scripts/create-dmg.sh first"
    exit 1
fi

echo "📝 Generating appcast.xml..."
echo ""
echo "DMGs found:"
for dmg in $DMGS; do
    echo "  - $(basename "$dmg")"
done
echo ""

# Generate appcast
generate_appcast "$BUILD_DIR" \
    --ed-key-file "$PROJECT_DIR/sparkle_eddsa_private.pem" \
    --download-url-prefix "https://github.com/leonaves/docker-disk-monitor/releases/latest/download/"

# Move appcast to project root
if [ -f "$BUILD_DIR/appcast.xml" ]; then
    mv "$BUILD_DIR/appcast.xml" "$APPCAST_PATH"
    echo "✅ Appcast generated: $APPCAST_PATH"
    echo ""
    echo "Next steps:"
    echo "  1. Upload DMG(s) to GitHub Releases"
    echo "  2. Upload appcast.xml to GitHub Releases"
    echo "  3. Create a new release tag (e.g., v1.0.0)"
    echo ""
    echo "GitHub Release command:"
    for dmg in $DMGS; do
        DMG_NAME=$(basename "$dmg")
        VERSION=$(echo "$DMG_NAME" | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)
        echo "  gh release create v$VERSION \"$dmg\" \"$APPCAST_PATH\" --title \"Version $VERSION\" --notes \"Release notes here\""
    done
else
    echo "❌ Failed to generate appcast"
    exit 1
fi
