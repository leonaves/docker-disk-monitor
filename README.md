# Docker Disk Monitor

A macOS menu bar utility that monitors Docker disk usage and sends notifications when storage is running low.

![macOS](https://img.shields.io/badge/macOS-13.0+-blue.svg)
![Swift](https://img.shields.io/badge/Swift-5.0-orange.svg)
![License](https://img.shields.io/badge/license-MIT-green.svg)

## Features

- **Menu Bar Integration**: Lightweight menu bar app that shows Docker disk usage at a glance
- **Real-time Monitoring**: Configurable check intervals (1, 5, 10, 15, or 30 minutes)
- **Smart Notifications**: Time-sensitive alerts that break through Focus modes
  - Warning threshold (customizable 50-89%)
  - Critical threshold (fixed at 90%)
  - Intelligent throttling (max once per hour to avoid spam)
- **Docker Status Monitoring**: Clearly indicates when Docker is not running or not installed
- **Launch at Login**: Optional automatic startup when you log in
- **Native macOS Design**: Built with SwiftUI for a clean, native interface

## Requirements

- macOS 13.0 (Ventura) or later
- Docker Desktop for Mac
- ~5 MB disk space

## Installation

1. Download the latest `.dmg` from [Releases](https://github.com/leonaves/docker-disk-monitor/releases)
2. Open the DMG and drag **Docker Disk Monitor** to your Applications folder
3. Launch the app from Applications
4. Grant notification permissions when prompted
5. The app icon will appear in your menu bar

## Usage

### Menu Bar Icon

The menu bar icon indicates Docker disk usage:
- **◔** (0-25%): Low usage
- **◑** (25-50%): Moderate usage
- **◕** (50-75%): High usage
- **●** (75%+): Very high usage
- **⚙︎**: Docker not running or checking status

### Menu Options

Click the menu bar icon to see:
- Current disk usage percentage
- Used and available space
- Filesystem information
- **Refresh Now**: Manually trigger a disk check (bypasses hourly throttle)
- **Settings**: Configure monitoring preferences
- **Quit**: Exit the application

### Settings

**General Tab:**
- **Check Interval**: How often to check disk usage (1-30 minutes)
- **Launch at Login**: Start automatically when you log in
- **Docker Path**: Auto-detected Docker installation path

**Notifications Tab:**
- **Enable Disk Notifications**: Toggle all notifications on/off
- **Warning Threshold**: Set percentage for warning alerts (50-89%)
- **Critical Threshold**: Fixed at 90% for critical alerts
- **Test Notification**: Send a test notification to verify settings

**About Tab:**
- App version information
- System information

## How It Works

Docker Disk Monitor uses `docker run --rm alpine df -h` to check disk usage within Docker's VM. It accesses the Docker daemon through the Unix socket at `~/.docker/run/docker.sock`.

**Note**: This app runs **without** macOS App Sandbox to access the Docker socket. It's signed and notarized for your security.

## Building from Source

### Prerequisites

- Xcode 15.0+
- macOS 13.0+ SDK
- Swift 5.0+

### Build Steps

```bash
# Clone the repository
git clone https://github.com/leonaves/docker-disk-monitor.git
cd docker-disk-monitor

# Open in Xcode
open DockerDiskMonitor.xcodeproj

# Build and run (⌘R)
```

### Project Structure

```
DockerDiskMonitor/
├── App/                    # App entry point and delegate
│   ├── DockerDiskMonitorApp.swift
│   └── AppDelegate.swift
├── Core/                   # Business logic
│   ├── DockerManager.swift        # Docker interaction
│   ├── NotificationManager.swift  # User notifications
│   └── LaunchAtLoginManager.swift # Login item management
├── Models/                 # Data models
│   ├── DiskUsage.swift
│   └── AppSettings.swift
└── Views/                  # SwiftUI views
    └── SettingsView.swift
```

## Code Signing & Notarization

See [DISTRIBUTION.md](DISTRIBUTION.md) for detailed instructions on code signing, notarization, and distribution using a company Apple Developer account.

## Distribution

This app uses [Sparkle](https://sparkle-project.org/) for automatic updates. Updates are hosted via GitHub Releases.

## Privacy

Docker Disk Monitor:
- ✅ Only accesses Docker's Unix socket for disk usage information
- ✅ Runs entirely locally on your Mac
- ✅ Does not collect or transmit any data
- ✅ Does not require network access (except for Docker commands)
- ✅ Open source - audit the code yourself

## Troubleshooting

### "Docker Not Running" message
- Ensure Docker Desktop is installed and running
- Check that Docker Desktop is accessible from the command line: `docker ps`

### Notifications not appearing
- Check System Settings > Notifications > Docker Disk Monitor
- Ensure "Allow Notifications" is enabled
- Enable "Time Sensitive Notifications" for Focus mode breakthrough

### Permission errors
- The app needs Docker socket access, which requires disabling App Sandbox
- This is normal and required for Docker interaction

### App won't launch
- Ensure you're running macOS 13.0 (Ventura) or later
- Check that the app is properly moved to Applications folder
- If you see a security warning, go to System Settings > Privacy & Security and click "Open Anyway"

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- Built with [SwiftUI](https://developer.apple.com/xcode/swiftui/)
- Updates powered by [Sparkle](https://sparkle-project.org/)
- Inspired by the need to avoid Docker disk space disasters

## Author

**Leon Aves**
- Website: [leonaves.com](https://leonaves.com)
- GitHub: [@leonaves](https://github.com/leonaves)

---

**Note**: This is an independent project and is not affiliated with or endorsed by Docker, Inc.
