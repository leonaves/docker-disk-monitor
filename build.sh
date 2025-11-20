#!/bin/bash

# build.sh
# Automated build script for Docker Disk Monitor
#
# Usage:
#   ./build.sh              # Build the app
#   ./build.sh clean        # Clean build
#   ./build.sh sign         # Build and sign
#   ./build.sh dmg          # Build, sign, and create DMG
#   ./build.sh notarize     # Build, sign, create DMG, and notarize

set -e  # Exit on error

# Configuration
APP_NAME="DockerDiskMonitor"
SCHEME="DockerDiskMonitor"
CONFIGURATION="Release"
BUILD_DIR="build"
IDENTITY="Developer ID Application"  # Will use first matching cert
VERSION="1.0.0"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Helper functions
info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
    exit 1
}

# Check if xcodeproj exists
check_project() {
    if [ ! -d "${APP_NAME}.xcodeproj" ]; then
        error "Xcode project not found. Please create it first (see QUICKSTART.md)"
    fi
}

# Clean build
clean() {
    info "Cleaning build directory..."
    rm -rf "${BUILD_DIR}"
    xcodebuild clean -scheme "${SCHEME}" -configuration "${CONFIGURATION}"
    info "Clean complete"
}

# Build the app
build() {
    info "Building ${APP_NAME}..."

    xcodebuild \
        -scheme "${SCHEME}" \
        -configuration "${CONFIGURATION}" \
        -derivedDataPath "${BUILD_DIR}" \
        build

    # Copy to build directory root for easier access
    mkdir -p "${BUILD_DIR}/Release"
    cp -R "${BUILD_DIR}/Build/Products/${CONFIGURATION}/${APP_NAME}.app" "${BUILD_DIR}/Release/"

    info "Build complete: ${BUILD_DIR}/Release/${APP_NAME}.app"
}

# Sign the application
sign_app() {
    info "Signing application..."

    local app_path="${BUILD_DIR}/Release/${APP_NAME}.app"

    if [ ! -d "$app_path" ]; then
        error "App not found at $app_path. Build first."
    fi

    # Find signing identity
    local cert=$(security find-identity -v -p codesigning | grep "${IDENTITY}" | head -1 | awk -F '"' '{print $2}')

    if [ -z "$cert" ]; then
        error "No Developer ID certificate found. Install one from developer.apple.com"
    fi

    info "Using certificate: $cert"

    # Sign the app
    codesign --deep --force --verify --verbose \
        --sign "$cert" \
        --options runtime \
        --entitlements "${APP_NAME}.entitlements" \
        "$app_path"

    # Verify
    info "Verifying signature..."
    codesign --verify --deep --strict --verbose=2 "$app_path"
    spctl -a -t exec -vv "$app_path" || warn "Gatekeeper verification failed (expected before notarization)"

    info "Signing complete"
}

# Create DMG
create_dmg() {
    info "Creating DMG..."

    local app_path="${BUILD_DIR}/Release/${APP_NAME}.app"
    local dmg_name="${APP_NAME}-${VERSION}.dmg"

    if [ ! -d "$app_path" ]; then
        error "App not found at $app_path. Build and sign first."
    fi

    # Remove old DMG if exists
    rm -f "$dmg_name"

    # Check if create-dmg is installed
    if command -v create-dmg &> /dev/null; then
        info "Using create-dmg tool..."
        create-dmg \
            --volname "Docker Disk Monitor" \
            --window-pos 200 120 \
            --window-size 600 400 \
            --icon-size 100 \
            --icon "${APP_NAME}.app" 175 120 \
            --hide-extension "${APP_NAME}.app" \
            --app-drop-link 425 120 \
            --no-internet-enable \
            "$dmg_name" \
            "$app_path" || true  # create-dmg sometimes returns non-zero even on success
    else
        info "create-dmg not found, using hdiutil..."
        hdiutil create -volname "Docker Disk Monitor" \
            -srcfolder "$app_path" \
            -ov -format UDZO \
            "$dmg_name"
    fi

    if [ ! -f "$dmg_name" ]; then
        error "DMG creation failed"
    fi

    # Sign the DMG
    info "Signing DMG..."
    local cert=$(security find-identity -v -p codesigning | grep "${IDENTITY}" | head -1 | awk -F '"' '{print $2}')
    codesign --sign "$cert" "$dmg_name"

    info "DMG created: $dmg_name"
}

# Notarize the DMG
notarize() {
    info "Notarizing DMG..."

    local dmg_name="${APP_NAME}-${VERSION}.dmg"

    if [ ! -f "$dmg_name" ]; then
        error "DMG not found: $dmg_name. Create DMG first."
    fi

    # Check for required environment variables
    if [ -z "$APPLE_ID" ] || [ -z "$APPLE_TEAM_ID" ] || [ -z "$APPLE_APP_PASSWORD" ]; then
        error "Notarization requires environment variables:
        APPLE_ID=your@email.com
        APPLE_TEAM_ID=YOUR_TEAM_ID
        APPLE_APP_PASSWORD=xxxx-xxxx-xxxx-xxxx

        Get app-specific password from: https://appleid.apple.com/account/manage"
    fi

    info "Submitting to Apple for notarization..."
    xcrun notarytool submit "$dmg_name" \
        --apple-id "$APPLE_ID" \
        --team-id "$APPLE_TEAM_ID" \
        --password "$APPLE_APP_PASSWORD" \
        --wait

    info "Stapling notarization ticket..."
    xcrun stapler staple "$dmg_name"

    info "Verifying notarization..."
    xcrun stapler validate "$dmg_name"
    spctl -a -t open --context context:primary-signature -v "$dmg_name"

    info "Notarization complete! DMG is ready for distribution: $dmg_name"
}

# Show usage
usage() {
    cat << EOF
Docker Disk Monitor Build Script

Usage: $0 [command]

Commands:
    (none)      Build the app
    clean       Clean build directory
    sign        Build and sign the app
    dmg         Build, sign, and create DMG
    notarize    Build, sign, create DMG, and notarize
    help        Show this help message

Examples:
    $0              # Just build
    $0 sign         # Build and sign
    $0 dmg          # Build, sign, and create DMG
    $0 notarize     # Complete build and notarize

For notarization, set these environment variables:
    export APPLE_ID="your@email.com"
    export APPLE_TEAM_ID="YOUR_TEAM_ID"
    export APPLE_APP_PASSWORD="xxxx-xxxx-xxxx-xxxx"

Get app-specific password from: https://appleid.apple.com/account/manage

EOF
}

# Main script
main() {
    local command="${1:-build}"

    case "$command" in
        clean)
            check_project
            clean
            ;;
        build)
            check_project
            build
            ;;
        sign)
            check_project
            build
            sign_app
            ;;
        dmg)
            check_project
            build
            sign_app
            create_dmg
            ;;
        notarize)
            check_project
            build
            sign_app
            create_dmg
            notarize
            ;;
        help|--help|-h)
            usage
            ;;
        *)
            error "Unknown command: $command. Use '$0 help' for usage."
            ;;
    esac
}

# Run main function
main "$@"
