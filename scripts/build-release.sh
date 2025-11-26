#!/bin/bash
set -e

# Configuration
PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
PROJECT_NAME="DockerDiskMonitor"
SCHEME="DockerDiskMonitor"
CONFIGURATION="Release"
BUILD_DIR="$PROJECT_DIR/build"

echo "🔨 Building $PROJECT_NAME Release..."

# Clean previous builds
echo "Cleaning previous builds..."
rm -rf "$BUILD_DIR"

# Build the app
echo "Building app..."
xcodebuild \
    -project "$PROJECT_DIR/$PROJECT_NAME.xcodeproj" \
    -scheme "$SCHEME" \
    -configuration "$CONFIGURATION" \
    -derivedDataPath "$BUILD_DIR/DerivedData" \
    clean build

# Find the built app
APP_PATH=$(find "$BUILD_DIR/DerivedData" -name "$PROJECT_NAME.app" -type d | head -1)

if [ ! -d "$APP_PATH" ]; then
    echo "❌ Failed to find built app"
    exit 1
fi

# Copy to build directory
mkdir -p "$BUILD_DIR/Release"
cp -R "$APP_PATH" "$BUILD_DIR/Release/"

echo "✅ Build complete!"
echo "📁 App location: $BUILD_DIR/Release/$PROJECT_NAME.app"

# Get version info
VERSION=$(/usr/libexec/PlistBuddy -c "Print CFBundleShortVersionString" "$BUILD_DIR/Release/$PROJECT_NAME.app/Contents/Info.plist")
BUILD=$(/usr/libexec/PlistBuddy -c "Print CFBundleVersion" "$BUILD_DIR/Release/$PROJECT_NAME.app/Contents/Info.plist")

echo "📦 Version: $VERSION (Build $BUILD)"

# Verify code signature
echo ""
echo "🔍 Verifying code signature..."
codesign --verify --verbose "$BUILD_DIR/Release/$PROJECT_NAME.app"

if [ $? -eq 0 ]; then
    echo "✅ Code signature valid"
else
    echo "⚠️  Code signature verification failed"
fi

echo ""
echo "Next steps:"
echo "  1. Run ./scripts/create-dmg.sh to package as DMG"
echo "  2. Run ./scripts/notarize.sh to notarize the DMG"
