#!/bin/bash
set -e

# Configuration
PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
PROJECT_NAME="DockerDiskMonitor"
BUILD_DIR="$PROJECT_DIR/build"
APP_PATH="$BUILD_DIR/Release/$PROJECT_NAME.app"

# Check if app exists
if [ ! -d "$APP_PATH" ]; then
    echo "❌ App not found at $APP_PATH"
    echo "Run ./scripts/build-release.sh first"
    exit 1
fi

# Get version
VERSION=$(/usr/libexec/PlistBuddy -c "Print CFBundleShortVersionString" "$APP_PATH/Contents/Info.plist")
DMG_NAME="Docker-Disk-Monitor-$VERSION.dmg"
DMG_PATH="$BUILD_DIR/$DMG_NAME"

echo "📦 Creating DMG: $DMG_NAME"

# Remove old DMG if exists
rm -f "$DMG_PATH"

# Create temporary directory for DMG contents
DMG_TEMP="$BUILD_DIR/dmg_temp"
rm -rf "$DMG_TEMP"
mkdir -p "$DMG_TEMP"

# Copy app to temp directory
cp -R "$APP_PATH" "$DMG_TEMP/"

# Create Applications symlink
ln -s /Applications "$DMG_TEMP/Applications"

echo "Creating DMG..."

# Create DMG using hdiutil
hdiutil create -volname "Docker Disk Monitor" \
    -srcfolder "$DMG_TEMP" \
    -ov -format UDZO \
    "$DMG_PATH"

# Clean up temp directory
rm -rf "$DMG_TEMP"

# Get DMG size
DMG_SIZE=$(du -h "$DMG_PATH" | cut -f1)

echo "✅ DMG created successfully!"
echo "📁 Location: $DMG_PATH"
echo "📊 Size: $DMG_SIZE"

echo ""
echo "Next step: Run ./scripts/notarize.sh to sign and notarize"
