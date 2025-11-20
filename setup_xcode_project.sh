#!/bin/bash

# setup_xcode_project.sh
# Creates an Xcode project for DockerDiskMonitor with existing source files

set -e

echo "🚀 Setting up Xcode project for Docker Disk Monitor..."

# Configuration
PROJECT_NAME="DockerDiskMonitor"
BUNDLE_ID="com.yourname.DockerDiskMonitor"
TEAM_ID=""  # Leave empty for manual selection
ORG_NAME="Your Name"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

# Check if we're in the right directory
if [ ! -f "Package.swift" ]; then
    echo "Error: Please run this script from the DockerDiskMonitor directory"
    exit 1
fi

# Prompt for customization
echo ""
echo "Let's configure your project:"
echo ""
read -p "Organization Name (default: $ORG_NAME): " input_org
ORG_NAME="${input_org:-$ORG_NAME}"

read -p "Bundle Identifier (default: $BUNDLE_ID): " input_bundle
BUNDLE_ID="${input_bundle:-$BUNDLE_ID}"

echo ""
info "Creating Xcode project with:"
echo "  - Organization: $ORG_NAME"
echo "  - Bundle ID: $BUNDLE_ID"
echo ""

# Create a temporary directory for Xcode project creation
info "Creating Xcode project structure..."

# Use xcodebuild to create the project
# We'll create a minimal xcodeproj structure manually since we have all the files

mkdir -p "${PROJECT_NAME}.xcodeproj"

# Create project.pbxproj
cat > "${PROJECT_NAME}.xcodeproj/project.pbxproj" << 'PBXPROJ'
// !$*UTF8*$!
{
	archiveVersion = 1;
	classes = {
	};
	objectVersion = 56;
	objects = {
		FILE_REF_SECTION
		BUILD_FILE_SECTION
		GROUP_SECTION
		PROJECT_SECTION
		TARGET_SECTION
		CONFIG_SECTION
	};
	rootObject = PROJECT_OBJ;
}
PBXPROJ

warn "Xcode project structure created, but manual configuration needed."
echo ""
echo "Due to Xcode project file complexity, please use one of these approaches:"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "APPROACH 1: Create Fresh Project (Recommended)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "1. Rename this directory temporarily:"
echo "   cd .."
echo "   mv DockerDiskMonitor DockerDiskMonitor_backup"
echo ""
echo "2. Create new Xcode project:"
echo "   - Open Xcode → New Project → macOS App"
echo "   - Name: DockerDiskMonitor"
echo "   - Bundle ID: $BUNDLE_ID"
echo "   - Save to: $(pwd | sed 's/DockerDiskMonitor$//')"
echo ""
echo "3. Replace generated files with our files:"
echo "   cd DockerDiskMonitor"
echo "   rm -rf DockerDiskMonitor/*"
echo "   cp -R ../DockerDiskMonitor_backup/DockerDiskMonitor/* DockerDiskMonitor/"
echo "   cp ../DockerDiskMonitor_backup/*.{swift,plist,entitlements,xml,md,sh} ."
echo "   cp ../DockerDiskMonitor_backup/.gitignore ."
echo ""
echo "4. In Xcode, right-click DockerDiskMonitor folder → Add Files"
echo "   - Select all Swift files from App/, Core/, Models/, Views/"
echo "   - Check 'Copy items if needed'"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "APPROACH 2: Drag & Drop (Easiest)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "1. Open Xcode"
echo "2. Create new macOS App project anywhere else"
echo "3. Delete the default Swift files Xcode created"
echo "4. Drag these folders into Xcode project:"
echo "   - DockerDiskMonitor/App/"
echo "   - DockerDiskMonitor/Core/"
echo "   - DockerDiskMonitor/Models/"
echo "   - DockerDiskMonitor/Views/"
echo "   - DockerDiskMonitor/Resources/"
echo "5. Drag these files into project root:"
echo "   - Info.plist"
echo "   - DockerDiskMonitor.entitlements"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

rm -rf "${PROJECT_NAME}.xcodeproj"  # Remove the incomplete project

echo ""
info "I'll create a better solution for you..."
