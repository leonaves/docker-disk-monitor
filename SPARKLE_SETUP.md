# Sparkle Auto-Update Setup Guide

This guide walks you through integrating Sparkle 2.x for automatic updates.

## Step 1: Add Sparkle via Swift Package Manager

1. Open `DockerDiskMonitor.xcodeproj` in Xcode
2. Go to **File > Add Package Dependencies...**
3. In the search bar, enter: `https://github.com/sparkle-project/Sparkle`
4. Select version: **2.7.0** (or latest 2.x)
5. Click **Add Package**
6. Check **DockerDiskMonitor** target and click **Add Package**

## Step 2: Generate EdDSA Keys

Sparkle uses EdDSA keys to sign updates for security.

```bash
# Generate keys (run from project root)
./scripts/generate-sparkle-keys.sh
```

This will create:
- `sparkle_eddsa_private.pem` - **Keep this secret!** (already in .gitignore)
- `sparkle_eddsa_public.pem` - Public key for verification

**Important:** Back up your private key securely. Without it, you can't sign future updates.

## Step 3: Update Info.plist

Add the following keys to `DockerDiskMonitor/DockerDiskMonitor/Info.plist`:

```xml
<key>SUFeedURL</key>
<string>https://github.com/leonaves/docker-disk-monitor/releases/latest/download/appcast.xml</string>
<key>SUPublicEDKey</key>
<string>YOUR_PUBLIC_KEY_FROM_sparkle_eddsa_public.pem</string>
<key>SUEnableAutomaticChecks</key>
<true/>
<key>SUScheduledCheckInterval</key>
<integer>86400</integer>
```

Replace `YOUR_PUBLIC_KEY_FROM_sparkle_eddsa_public.pem` with the content of `sparkle_eddsa_public.pem`.

## Step 4: Import Sparkle in AppDelegate

Add Sparkle import and updater controller:

```swift
import Sparkle

class AppDelegate: NSObject, NSApplicationDelegate {
    private var updaterController: SPUStandardUpdaterController!
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Initialize Sparkle
        updaterController = SPUStandardUpdaterController(
            startingUpdater: true,
            updaterDelegate: nil,
            userDriverDelegate: nil
        )
        
        // ... rest of existing code
    }
}
```

## Step 5: Add "Check for Updates" Menu Item (Optional)

In `AppDelegate.swift`, add to the menu:

```swift
extension AppDelegate: NSMenuDelegate {
    func menuWillOpen(_ menu: NSMenu) {
        // ... existing menu items
        
        menu.addItem(NSMenuItem.separator())
        
        let updateItem = NSMenuItem(
            title: "Check for Updates...",
            action: #selector(checkForUpdates),
            keyEquivalent: ""
        )
        menu.addItem(updateItem)
        
        // ... rest of menu
    }
}

extension AppDelegate {
    @objc private func checkForUpdates() {
        updaterController.updater.checkForUpdates()
    }
}
```

## Step 6: Build and Test

1. Build the app (⌘B)
2. Run it (⌘R)
3. Sparkle should initialize successfully
4. You can trigger manual update checks via the menu

## How Updates Work

1. **User runs app** → Sparkle checks `SUFeedURL` (once per day by default)
2. **Finds appcast.xml** → Compares version numbers
3. **New version available** → Shows update dialog
4. **User accepts** → Downloads DMG, verifies signature
5. **Installs update** → Replaces app and relaunches

## Creating an Update Release

See `DISTRIBUTION.md` for the complete release process, including:
- Building and signing the DMG
- Generating appcast.xml
- Uploading to GitHub Releases

## Troubleshooting

### "Could not locate feed URL"
- Check that `SUFeedURL` is correctly set in Info.plist
- Ensure the URL is publicly accessible

### "Update verification failed"
- Ensure the DMG is signed with your private key
- Check that the public key in Info.plist matches your key pair

### Updates not checking
- Verify `SUEnableAutomaticChecks` is `true`
- Check Console.app for Sparkle logs

## Security Notes

- **Never commit** `sparkle_eddsa_private.pem` to version control
- Store the private key securely (password manager, encrypted backup)
- Without the private key, you cannot sign future updates
- Users will see security warnings if signatures don't match

## Resources

- [Sparkle Documentation](https://sparkle-project.org/documentation/)
- [Sparkle GitHub](https://github.com/sparkle-project/Sparkle)
- [Appcast Format](https://sparkle-project.org/documentation/publishing/)
