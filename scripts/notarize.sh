#!/bin/bash
set -e

# Configuration
PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BUILD_DIR="$PROJECT_DIR/build"

# Find the DMG
DMG_PATH=$(find "$BUILD_DIR" -name "*.dmg" -type f | head -1)

if [ -z "$DMG_PATH" ]; then
    echo "❌ No DMG found in $BUILD_DIR"
    echo "Run ./scripts/create-dmg.sh first"
    exit 1
fi

DMG_NAME=$(basename "$DMG_PATH")

echo "🔐 Notarizing: $DMG_NAME"
echo ""

# Check for credentials
if [ -z "$APPLE_ID" ] || [ -z "$APPLE_TEAM_ID" ]; then
    echo "⚠️  Apple Developer credentials not set"
    echo ""
    echo "You need to set these environment variables:"
    echo "  APPLE_ID          - Your company's Apple ID email"
    echo "  APPLE_TEAM_ID     - Your company's Team ID (e.g., R37TNSL35R)"
    echo "  APPLE_APP_PASSWORD - App-specific password"
    echo ""
    echo "Or use an API key (recommended):"
    echo "  APPLE_API_KEY      - Path to .p8 file"
    echo "  APPLE_API_KEY_ID   - Key ID"
    echo "  APPLE_API_ISSUER   - Issuer ID"
    echo ""
    echo "Example (App-Specific Password):"
    echo "  export APPLE_ID=\"dev@company.com\""
    echo "  export APPLE_TEAM_ID=\"R37TNSL35R\""
    echo "  export APPLE_APP_PASSWORD=\"xxxx-xxxx-xxxx-xxxx\""
    echo "  ./scripts/notarize.sh"
    echo ""
    echo "See DISTRIBUTION.md for details on getting these from your company."
    exit 1
fi

# Sign the DMG
echo "Signing DMG..."
codesign --sign "Developer ID Application" --timestamp "$DMG_PATH"

echo "✅ DMG signed"

# Submit for notarization
echo ""
echo "Submitting for notarization..."
echo "(This may take a few minutes)"

if [ -n "$APPLE_API_KEY" ]; then
    # Use API key
    xcrun notarytool submit "$DMG_PATH" \
        --key "$APPLE_API_KEY" \
        --key-id "$APPLE_API_KEY_ID" \
        --issuer "$APPLE_API_ISSUER" \
        --wait
else
    # Use Apple ID + app-specific password
    xcrun notarytool submit "$DMG_PATH" \
        --apple-id "$APPLE_ID" \
        --team-id "$APPLE_TEAM_ID" \
        --password "$APPLE_APP_PASSWORD" \
        --wait
fi

if [ $? -eq 0 ]; then
    echo "✅ Notarization successful!"
    
    # Staple the notarization ticket
    echo ""
    echo "Stapling notarization ticket..."
    xcrun stapler staple "$DMG_PATH"
    
    echo "✅ DMG is now notarized and stapled!"
    echo ""
    echo "📁 Ready for distribution: $DMG_PATH"
    echo ""
    echo "Next steps:"
    echo "  1. Upload to GitHub Releases"
    echo "  2. Run ./scripts/generate-appcast.sh to update appcast.xml"
else
    echo "❌ Notarization failed"
    echo ""
    echo "Check the logs above for errors."
    echo "Common issues:"
    echo "  - Invalid credentials"
    echo "  - Code signing issues"
    echo "  - Hardened runtime not enabled"
    exit 1
fi
