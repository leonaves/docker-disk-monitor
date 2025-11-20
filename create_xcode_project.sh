#!/bin/bash

# create_xcode_project.sh
# Automated Xcode project creation for DockerDiskMonitor

set -e

echo "🚀 Creating Xcode project for Docker Disk Monitor..."
echo ""

# Get user input
read -p "Enter your organization identifier (e.g., com.yourname): " org_id
if [ -z "$org_id" ]; then
    echo "Error: Organization identifier is required"
    exit 1
fi

BUNDLE_ID="${org_id}.DockerDiskMonitor"
PROJECT_DIR="$(pwd)"
PARENT_DIR="$(dirname "$PROJECT_DIR")"
BACKUP_DIR="${PARENT_DIR}/DockerDiskMonitor_source_backup"

echo ""
echo "Configuration:"
echo "  Bundle ID: $BUNDLE_ID"
echo "  Project Directory: $PROJECT_DIR"
echo ""

# Step 1: Backup current directory
echo "📦 Backing up source files..."
cp -R "$PROJECT_DIR" "$BACKUP_DIR"
echo "   Backup created at: $BACKUP_DIR"

# Step 2: Instructions for Xcode
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📋 NEXT STEPS - Please follow these carefully:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "1. This script will now open Xcode. Please:"
echo "   - Choose: macOS → App"
echo "   - Product Name: DockerDiskMonitor"
echo "   - Organization Identifier: $org_id"
echo "   - Bundle Identifier: $BUNDLE_ID"
echo "   - Interface: SwiftUI"
echo "   - Language: Swift"
echo ""
echo "2. When choosing location:"
echo "   - Navigate to: $PARENT_DIR"
echo "   - The existing DockerDiskMonitor folder will be replaced"
echo "   - Click 'Replace' or 'Move to Trash'"
echo ""
echo "3. After Xcode creates the project:"
echo "   - CLOSE XCODE"
echo "   - Return to this terminal"
echo "   - Press ENTER to continue"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
read -p "Press ENTER to open Xcode now..."

open -a Xcode

echo ""
echo "Waiting for you to create the project in Xcode..."
echo "(Create the project, then close Xcode and return here)"
echo ""
read -p "Press ENTER after you've created the project and closed Xcode..."

# Step 3: Restore our files
echo ""
echo "🔄 Restoring source files..."

cd "$PARENT_DIR"

if [ ! -d "DockerDiskMonitor/DockerDiskMonitor.xcodeproj" ]; then
    echo "Error: Xcode project not found. Please create it first."
    echo "Your source files are safe at: $BACKUP_DIR"
    exit 1
fi

# Keep the Xcode project but restore our files
cd DockerDiskMonitor

# Remove Xcode's generated files but keep the project
rm -rf DockerDiskMonitor/DockerDiskMonitorApp.swift DockerDiskMonitor/ContentView.swift DockerDiskMonitor/Assets.xcassets 2>/dev/null || true

# Copy our source files back
echo "   Copying App files..."
cp -R "$BACKUP_DIR/DockerDiskMonitor/App" DockerDiskMonitor/

echo "   Copying Core files..."
cp -R "$BACKUP_DIR/DockerDiskMonitor/Core" DockerDiskMonitor/

echo "   Copying Models files..."
cp -R "$BACKUP_DIR/DockerDiskMonitor/Models" DockerDiskMonitor/

echo "   Copying Views files..."
cp -R "$BACKUP_DIR/DockerDiskMonitor/Views" DockerDiskMonitor/

echo "   Copying Resources..."
cp -R "$BACKUP_DIR/DockerDiskMonitor/Resources" DockerDiskMonitor/

echo "   Copying Info.plist..."
cp "$BACKUP_DIR/DockerDiskMonitor/Info.plist" DockerDiskMonitor/

echo "   Copying configuration files..."
cp "$BACKUP_DIR/DockerDiskMonitor.entitlements" .
cp "$BACKUP_DIR/Package.swift" .
cp "$BACKUP_DIR/appcast.xml" .
cp "$BACKUP_DIR/.gitignore" .
cp "$BACKUP_DIR"/*.md .
cp "$BACKUP_DIR"/*.sh .
cp "$BACKUP_DIR"/*.swift . 2>/dev/null || true
cp "$BACKUP_DIR/LICENSE" . 2>/dev/null || true

# Make scripts executable
chmod +x *.sh 2>/dev/null || true

echo ""
echo "✅ Files restored!"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📝 FINAL STEPS IN XCODE:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "1. Open the project:"
echo "   open DockerDiskMonitor.xcodeproj"
echo ""
echo "2. Add source files to the project:"
echo "   - Right-click 'DockerDiskMonitor' folder in Project Navigator"
echo "   - Choose 'Add Files to DockerDiskMonitor...'"
echo "   - Select these folders (hold ⌘ to multi-select):"
echo "     • DockerDiskMonitor/App"
echo "     • DockerDiskMonitor/Core"
echo "     • DockerDiskMonitor/Models"
echo "     • DockerDiskMonitor/Views"
echo "     • DockerDiskMonitor/Resources"
echo "   - Click 'Add'"
echo ""
echo "3. Configure Info.plist:"
echo "   - Select project in navigator → Build Settings"
echo "   - Search 'Info.plist File'"
echo "   - Set to: DockerDiskMonitor/Info.plist"
echo ""
echo "4. Configure Entitlements:"
echo "   - Build Settings → Search 'Code Signing Entitlements'"
echo "   - Set to: DockerDiskMonitor.entitlements"
echo ""
echo "5. Add Sparkle framework:"
echo "   - File → Add Package Dependencies"
echo "   - URL: https://github.com/sparkle-project/Sparkle"
echo "   - Version: 2.6.0+"
echo ""
echo "6. Build and Run (⌘R)"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Your backup is at: $BACKUP_DIR"
echo "(You can delete it after everything works)"
echo ""
read -p "Press ENTER to open Xcode now..."

open DockerDiskMonitor.xcodeproj

echo ""
echo "✨ Setup complete! Follow the steps above in Xcode."
