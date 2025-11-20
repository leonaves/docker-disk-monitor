# Quick Start Guide

This guide will help you get Docker Disk Monitor built and running in under 10 minutes.

## Prerequisites

- macOS 13+ (Ventura or later)
- Xcode 15+ installed
- Docker Desktop for Mac
- Apple Developer account (for code signing)

## Step-by-Step Setup

### 1. Create Xcode Project (3 minutes)

Since we have existing source files, use the automated script:

```bash
cd /Users/leon.aves/dev/DockerDiskMonitor
./create_xcode_project.sh
```

The script will:
1. Back up your source files
2. Guide you through creating the Xcode project
3. Automatically restore all source files to the new project
4. Open Xcode for you

Follow the on-screen instructions!

### 2. Add Files to Xcode (2 minutes)

After the script completes, Xcode will open. Now add the source files:

1. In Project Navigator, right-click **DockerDiskMonitor** folder
2. Choose **Add Files to "DockerDiskMonitor"...**
3. Hold **⌘** and select these folders:
   - `DockerDiskMonitor/App`
   - `DockerDiskMonitor/Core`
   - `DockerDiskMonitor/Models`
   - `DockerDiskMonitor/Views`
   - `DockerDiskMonitor/Resources`
4. Ensure these options are checked:
   - ✓ Copy items if needed
   - ✓ Create groups
   - ✓ Add to targets: DockerDiskMonitor
5. Click **Add**

### 3. Configure Project Settings (2 minutes)

**In Project Settings (select project in navigator) → General:**
- Minimum Deployments: `macOS 13.0`

**In Signing & Capabilities:**
1. Select your **Team** (sign in with Apple ID if needed)
2. Click **+ Capability** → **Hardened Runtime**
3. Under Hardened Runtime, expand and check:
   - ☐ Disable Library Validation
   - ☐ Disable Executable Memory Protection

**In Build Settings (search for each):**
- **Info.plist File**: Set to `DockerDiskMonitor/Info.plist`
- **Code Signing Entitlements**: Set to `DockerDiskMonitor.entitlements`

### 4. Add Sparkle Framework (2 minutes)

1. **File → Add Package Dependencies**
2. Enter URL: `https://github.com/sparkle-project/Sparkle`
3. Select version: `2.6.0` (or "Up to Next Major Version")
4. Click **Add Package**
5. Ensure "Sparkle" is added to the `DockerDiskMonitor` target

### 5. Update Info.plist (Optional - 1 minute)

The Info.plist is already configured, but you can update the Sparkle feed URL later:

In `DockerDiskMonitor/Info.plist`, find:
```xml
<key>SUFeedURL</key>
<string>https://yourdomain.com/appcast.xml</string>
```

Replace `yourdomain.com` when you're ready to host updates. For now, leave it as is.

### 6. Build and Run (1 minute)

1. Press **⌘R** or Product → Run
2. The app will build and launch
3. Look for the gauge icon in your menu bar (top-right)
4. Click it to see Docker disk usage

**First Launch:**
- Grant notification permissions when prompted
- If Docker isn't running, you'll see "Docker Not Running"
- Start Docker Desktop to see real disk usage

### 7. Test the App (1 minute)

1. Click the menu bar icon → **Settings**
2. Enable "Launch at Login" if desired
3. Adjust "Warning Threshold" slider
4. Click "Send Test Notification" to verify notifications work
5. Click "Refresh Now" from the menu to manually check disk usage

## That's It!

You now have Docker Disk Monitor running on your Mac.

## Next Steps

### For Development

- Modify settings in `Views/SettingsView.swift`
- Customize Docker monitoring in `Core/DockerManager.swift`
- Change icon colors in `generate_icons.swift`

### For Distribution

See the main [README.md](README.md) for detailed instructions on:

1. **Code Signing**: Sign the app with your Developer ID
2. **Notarization**: Submit to Apple for notarization
3. **DMG Creation**: Package the app for distribution
4. **Auto-Updates**: Set up Sparkle with signing keys

## Common Issues

### "Sparkle not found" Error

**Solution:**
1. File → Add Package Dependencies
2. Add: `https://github.com/sparkle-project/Sparkle`
3. Clean build: Product → Clean Build Folder (⇧⌘K)

### "Cannot find 'Combine' in scope" Error

**Solution:**
Add `import Combine` to the top of `AppDelegate.swift` (already included in the template)

### Menu Bar Icon Not Showing

**Solution:**
1. Check `Info.plist` has: `<key>LSUIElement</key><true/>`
2. This makes it a menu bar app (no Dock icon)
3. Look in the top-right of your screen

### Docker Not Found

**Solution:**
The app auto-detects Docker at:
- `/usr/local/bin/docker` (Intel)
- `/opt/homebrew/bin/docker` (Apple Silicon)

If Docker is elsewhere:
1. Open Terminal
2. Run: `which docker`
3. The app will find it automatically on next launch

### Code Signing Issues

**Solution:**
1. Xcode → Settings → Accounts
2. Ensure your Apple ID is added
3. Select it and download certificates
4. In project settings, select your Team

## Testing Without Building

If you just want to test the functionality:

```bash
# Run the icon generator
swift generate_icons.swift

# Check that Docker manager works
swift DockerDiskMonitor/Core/DockerManager.swift
```

## Need Help?

- Check the main [README.md](README.md) for detailed documentation
- File an issue on GitHub
- Check Xcode's build logs for specific errors

---

**Enjoy monitoring your Docker disk usage!** 🚀
