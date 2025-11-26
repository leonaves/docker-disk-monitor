# Distribution Guide: Code Signing & Notarization

This guide explains how to build, sign, notarize, and distribute Docker Disk Monitor using your company's Apple Developer account.

## Prerequisites

- Xcode 15.0+
- Access to your company's Apple Developer account
- GitHub CLI (`gh`) for releases

## Part 1: Getting Company Developer Credentials

### What You Need From Your Company

Your company's Apple Developer account admin needs to provide:

1. **Developer ID Application Certificate**
   - A .p12 file (certificate + private key)
   - The password for the .p12 file
   
2. **Team ID**
   - 10-character code (e.g., `R37TNSL35R`)
   - Found at: https://developer.apple.com/account → Membership

3. **Notarization Credentials** (choose one):
   
   **Option A: App-Specific Password** (simpler)
   - Company Apple ID email
   - App-specific password generated at appleid.apple.com
   
   **Option B: API Key** (better for automation)
   - .p8 file (API key)
   - Issuer ID
   - Key ID

### Installing the Certificate

1. Get the .p12 file from your company admin
2. Double-click the .p12 file
3. Enter the password when prompted
4. The certificate will be added to your macOS Keychain
5. Verify in **Keychain Access** → Search for "Developer ID Application"

### Setting Up Notarization Credentials

#### Option A: Using App-Specific Password

Create a shell script to set environment variables (don't commit this!):

```bash
# ~/.docker-disk-monitor-env.sh
export APPLE_ID="company-dev@company.com"
export APPLE_TEAM_ID="R37TNSL35R"
export APPLE_APP_PASSWORD="xxxx-xxxx-xxxx-xxxx"
```

Then before building:
```bash
source ~/.docker-disk-monitor-env.sh
```

#### Option B: Using API Key

Save the .p8 file securely and set:

```bash
# ~/.docker-disk-monitor-env.sh
export APPLE_API_KEY="$HOME/.apple-keys/AuthKey_KEYID.p8"
export APPLE_API_KEY_ID="ABC123XYZ"
export APPLE_API_ISSUER="12345678-1234-1234-1234-123456789012"
export APPLE_TEAM_ID="R37TNSL35R"
```

## Part 2: Building a Release

### Step 1: Update Version Number

Edit `DockerDiskMonitor/DockerDiskMonitor/Info.plist`:

```xml
<key>CFBundleShortVersionString</key>
<string>1.0.1</string>  <!-- Increment this -->
<key>CFBundleVersion</key>
<string>2</string>  <!-- Increment this -->
```

### Step 2: Build Release

```bash
./scripts/build-release.sh
```

This will:
- Clean previous builds
- Build in Release configuration
- Sign with your company's Developer ID certificate
- Output to `build/Release/DockerDiskMonitor.app`

### Step 3: Create DMG

```bash
./scripts/create-dmg.sh
```

This creates: `build/Docker-Disk-Monitor-X.X.X.dmg`

### Step 4: Notarize

```bash
# Load credentials first
source ~/.docker-disk-monitor-env.sh

# Notarize
./scripts/notarize.sh
```

This will:
1. Sign the DMG
2. Submit to Apple for notarization (takes 2-10 minutes)
3. Wait for approval
4. Staple the notarization ticket to the DMG

**Common Issues:**

- **"Invalid credentials"**: Check your APPLE_ID and APPLE_APP_PASSWORD
- **"Code signature invalid"**: Ensure the Developer ID certificate is installed
- **"Hardened runtime error"**: This is already configured correctly in the project

## Part 3: Setting Up Sparkle Updates

### Step 1: Add Sparkle to Project

See `SPARKLE_SETUP.md` for detailed instructions.

Quick version:
1. Open project in Xcode
2. File → Add Package Dependencies
3. Enter: `https://github.com/sparkle-project/Sparkle`
4. Select version 2.7.0+

### Step 2: Generate Sparkle Keys

```bash
./scripts/generate-sparkle-keys.sh
```

This creates:
- `sparkle_eddsa_private.pem` - **Back this up!** Needed to sign all future updates
- `sparkle_eddsa_public.pem` - Add this to Info.plist

### Step 3: Update Info.plist

Add the public key from `sparkle_eddsa_public.pem` to your Info.plist:

```xml
<key>SUPublicEDKey</key>
<string>PASTE_CONTENT_HERE</string>
<key>SUFeedURL</key>
<string>https://github.com/leonaves/docker-disk-monitor/releases/latest/download/appcast.xml</string>
```

## Part 4: Creating a Release

### Step 1: Build and Notarize

```bash
# Set credentials
source ~/.docker-disk-monitor-env.sh

# Build everything
./scripts/build-release.sh
./scripts/create-dmg.sh
./scripts/notarize.sh
```

### Step 2: Generate Appcast

```bash
./scripts/generate-appcast.sh
```

This creates `appcast.xml` with signatures for Sparkle.

### Step 3: Create GitHub Release

```bash
# Get the version
VERSION="1.0.1"  # Use your version number

# Create release and upload files
gh release create "v$VERSION" \
  build/Docker-Disk-Monitor-$VERSION.dmg \
  appcast.xml \
  --title "Version $VERSION" \
  --notes "
## What's New
- Feature 1
- Feature 2
- Bug fixes

## Installation
Download the DMG, open it, and drag Docker Disk Monitor to Applications.
"
```

### Step 4: Verify Release

1. Go to https://github.com/leonaves/docker-disk-monitor/releases
2. Verify the DMG and appcast.xml are uploaded
3. Test downloading and installing the DMG

### Step 5: Test Auto-Update

1. Install the previous version
2. Launch the app
3. Sparkle should detect the new version
4. Accept the update and verify it installs correctly

## Part 5: Release Checklist

Before each release:

- [ ] Update version in Info.plist
- [ ] Update CHANGELOG.md (if you create one)
- [ ] Build and test locally
- [ ] Run all scripts successfully:
  - [ ] `./scripts/build-release.sh`
  - [ ] `./scripts/create-dmg.sh`
  - [ ] `./scripts/notarize.sh`
  - [ ] `./scripts/generate-appcast.sh`
- [ ] Create GitHub release with DMG + appcast.xml
- [ ] Test downloading and installing from GitHub
- [ ] Test auto-update from previous version

## Troubleshooting

### Code Signing Issues

**Problem**: "No signing certificate found"

**Solution**:
1. Open Keychain Access
2. Search for "Developer ID Application"
3. Ensure certificate is valid and not expired
4. Check certificate chain is complete (intermediate certificates)

**Problem**: "Code object is not signed at all"

**Solution**:
- Clean build folder: `rm -rf build/`
- Rebuild: `./scripts/build-release.sh`

### Notarization Issues

**Problem**: "Invalid credentials"

**Solution**:
- Verify APPLE_ID is correct
- Regenerate app-specific password at appleid.apple.com
- Ensure APPLE_TEAM_ID matches your company's Team ID

**Problem**: "Notarization failed - hardened runtime"

**Solution**:
- This should already be enabled in project settings
- Verify in Xcode: Build Settings → Hardened Runtime = YES

**Problem**: "The binary is not signed with a valid Developer ID certificate"

**Solution**:
- Install company's Developer ID certificate
- Ensure it's for "Developer ID Application" (not "Mac App Distribution")

### Sparkle Issues

**Problem**: "Could not download update"

**Solution**:
- Verify appcast.xml is uploaded to GitHub Releases
- Check SUFeedURL in Info.plist points to correct location
- Ensure GitHub release is public

**Problem**: "Update signature verification failed"

**Solution**:
- Ensure DMG was signed with same private key
- Verify public key in Info.plist matches your key pair
- Regenerate appcast.xml: `./scripts/generate-appcast.sh`

## Security Best Practices

1. **Never commit secrets**:
   - `sparkle_eddsa_private.pem` (in .gitignore)
   - `.p12` certificate files (in .gitignore)
   - `.p8` API key files (in .gitignore)
   - Environment variable scripts with credentials

2. **Back up important files**:
   - Sparkle private key (`sparkle_eddsa_private.pem`)
   - Company Developer ID certificate (.p12)
   - Store in encrypted password manager or secure backup

3. **Use API keys for automation**:
   - More secure than app-specific passwords
   - Can be revoked independently
   - Better for CI/CD pipelines

## Company Admin: How to Help Your Developer

Your developer needs these items to distribute the app:

### 1. Export Developer ID Certificate

1. Go to https://developer.apple.com/account/resources/certificates
2. Find "Developer ID Application" certificate
3. Download and open to install in Keychain
4. Open **Keychain Access** → Find certificate → Right-click → Export
5. Save as .p12 with a password
6. Send the .p12 file + password securely to developer

### 2. Provide Team ID

1. Go to https://developer.apple.com/account
2. Click "Membership" in sidebar
3. Find "Team ID" (10 characters, e.g., `R37TNSL35R`)
4. Share this with developer

### 3. Notarization Access (choose one)

**Option A: App-Specific Password**
1. Go to appleid.apple.com → Sign in
2. Security section → App-Specific Passwords
3. Generate new password for "Docker Disk Monitor"
4. Share: Apple ID email + app-specific password

**Option B: API Key** (recommended)
1. Go to https://appstoreconnect.apple.com/access/api
2. Click "+" to generate new key
3. Name: "Docker Disk Monitor Notarization"
4. Access: Developer
5. Download .p8 file (only downloadable once!)
6. Share: .p8 file + Issuer ID + Key ID

## Resources

- [Apple Code Signing Guide](https://developer.apple.com/support/code-signing/)
- [Notarization Documentation](https://developer.apple.com/documentation/security/notarizing_macos_software_before_distribution)
- [Sparkle Documentation](https://sparkle-project.org/documentation/)
- [xcrun notarytool Guide](https://developer.apple.com/documentation/security/notarizing_macos_software_before_distribution/customizing_the_notarization_workflow)

## Need Help?

- Check the GitHub Issues: https://github.com/leonaves/docker-disk-monitor/issues
- Contact your company's Apple Developer admin
- Review Apple's notarization logs: `xcrun notarytool log <submission-id>`
