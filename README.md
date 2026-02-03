# OpenPorts

<div align="center">

![OpenPorts Icon](Icon.iconset/openports-128.png)

### Lightweight macOS Menu Bar App for Monitoring Local Ports and Processes

[![CI](https://github.com/MohamedMohana/openports/workflows/CI/badge.svg)](https://github.com/MohamedMohana/openports/actions/workflows/CI.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Swift Version](https://img.shields.io/badge/Swift-6.0-orange.svg)](https://swift.org)

</div>

OpenPorts is a lightweight macOS menu bar application that displays which local ports are open, which process/app is using each port, and allows you to terminate the owning process directly from the UI.

## Features

- 📊 **Real-time Port Monitoring** - Auto-refreshes every 3-5 seconds (configurable)
- 🔍 **Process Information** - Shows PID, process name, app name, bundle identifier, and executable path
- ⚙️ **Flexible Refresh** - Auto-refresh or manual refresh on menu click
- 🔧 **Preferences** - Configure refresh interval, grouping, and display options
- 🚫 **Process Termination** - Graceful terminate (SIGTERM) or force kill (SIGKILL)
- 🛡️ **Safety Features** - Admin elevation check for non-owned processes, system process warnings
- 🔎 **Search & Filter** - Quickly find ports by number, process, or app name
- 🚀 **Launch at Login** - Automatically start when you log in
- 🌙 **Dark Mode** - Fully supports macOS dark mode
- 💻 **Multi-Architecture** - Supports Apple Silicon (M1/M2/M3) and Intel Macs

## Installation

### Homebrew (Recommended)

```bash
brew tap MohamedMohana/tap
brew install MohamedMohana/tap/openports
open -a OpenPorts
```

### Manual Installation

1. Download latest release from [GitHub Releases](https://github.com/MohamedMohana/openports/releases)
2. Extract `OpenPorts.app` from downloaded ZIP file
3. Drag `OpenPorts.app` to your `/Applications` folder
4. Launch app from Applications or Spotlight

### Development Build

```bash
git clone https://github.com/MohamedMohana/openports.git
cd openports
./Scripts/package_app.sh debug
open OpenPorts.app
```

### Manual Installation

1. Download the latest release from [GitHub Releases](https://github.com/MohamedMohana/openports/releases)
2. Extract `OpenPorts.app` from the downloaded ZIP file
3. Drag `OpenPorts.app` to your `/Applications` folder
4. Launch the app from Applications or Spotlight

### Development Build

```bash
git clone https://github.com/MohamedMohana/openports.git
cd openports
./Scripts/package_app.sh debug
open OpenPorts.app
```

### Manual Installation

1. Download the latest release from [GitHub Releases](https://github.com/MohamedMohana/openports/releases)
2. Extract `OpenPorts.app` from the downloaded ZIP file
3. Drag `OpenPorts.app` to your `/Applications` folder
4. Launch the app from Applications or Spotlight

### Development Build

```bash
# Clone the repository
git clone https://github.com/MohamedMohana/openports.git
cd openports

# Build the app
./Scripts/package_app.sh debug

# Launch
open OpenPorts.app
```

## Usage

1. **View Ports** - Click the OpenPorts icon in the menu bar to see all open listening ports
2. **Refresh** - Click "Refresh" in the menu or click the menu bar icon (if configured)
3. **Filter** - Use the search field to filter by port number, process name, or app name
4. **Terminate Process** - Right-click a port entry and select "Terminate" or "Force Kill"
5. **Preferences** - Access preferences from the menu to configure refresh interval and other settings

## Configuration

OpenPorts stores preferences in `~/Library/Containers/com.mohamedmohana.openports/Data/Library/Preferences/`.

### Preferences

- **Refresh Interval** - Manual, 3s, 5s, 10s, or 30s
- **Group by App** - Group ports by application instead of listing all processes
- **Show System Processes** - Show/hide system processes (marked with warning indicator)
- **Launch at Login** - Automatically start OpenPorts when you log in

## Requirements

- **macOS**: 14.0 (Sonoma) or later
- **Architecture**: Apple Silicon (M1/M2/M3) or Intel

## Building from Source

### Prerequisites

- Xcode 15.0 or later
- Swift 6.0 or later
- SwiftLint and SwiftFormat (install via `brew install swiftlint swiftformat`)

### Build Commands

```bash
# Lint and format code
./Scripts/lint.sh

# Build for current architecture (debug)
swift build

# Build for release
swift build -c release

# Package as .app bundle
./Scripts/package_app.sh debug  # Development build
./Scripts/package_app.sh release  # Production build

# Sign and notarize (requires Apple Developer credentials)
./Scripts/sign-and-notarize.sh
```

## Troubleshooting

### Security Warning on First Launch

If you see a security warning when first launching OpenPorts:

1. Open **System Settings** > **Privacy & Security**
2. Find "OpenPorts" was blocked from opening
3. Click **Open Anyway**

### Permission Denied When Terminating Process

If you see an error when trying to terminate a process you don't own:

1. OpenPorts will prompt for authentication
2. Enter your macOS administrator password
3. The process will be terminated

If authentication fails, the process may be protected by macOS System Integrity Protection (SIP). You may need to disable SIP or use `sudo` in Terminal.

### App Not Updating

If you installed via Homebrew, OpenPorts will check for updates via Homebrew. Update with:

```bash
brew upgrade MohamedMohana/tap/openports
```

If you installed manually, OpenPorts includes Sparkle for automatic updates. Check "About" in preferences.

## Architecture

OpenPorts follows a clean, modular architecture:

- **OpenPortsCore** - Platform-agnostic logic (port scanning, process resolution, data models)
- **OpenPorts** - macOS-specific app (menu bar integration, SwiftUI views, AppKit)

## Credits

Inspired by [CodexBar](https://github.com/steipete/CodexBar) and other macOS menu bar applications.

## License

OpenPorts is released under the MIT License. See [LICENSE](LICENSE) for details.

## Contributing

Contributions are welcome! Please:

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Run tests and linting (`./Scripts/lint.sh`)
5. Submit a pull request

## Roadmap

- [ ] UDP port support (currently TCP only)
- [ ] Port favorites/watchlist with notifications
- [ ] Historical port usage data
- [ ] Export port list to CSV/JSON
- [ ] Customizable app icon themes
- [ ] Widget support (macOS 14+)
