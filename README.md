# OpenPorts

<div align="center">

![OpenPorts Icon](Icon.iconset/openports-128.png)

### Lightweight macOS Menu Bar App for Monitoring Local Ports and Processes

[![CI](https://github.com/MohamedMohana/openports/workflows/CI/badge.svg)](https://github.com/MohamedMohana/openports/actions/workflows/CI.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Swift Version](https://img.shields.io/badge/Swift-6.0-orange.svg)](https://swift.org)

</div>

OpenPorts is a lightweight macOS menu bar application that displays which local ports are open, which process/app is using each port, and allows you to terminate the owning process directly from the UI.

## ⚠️ Security Warning

**When you first launch OpenPorts, you may see a Gatekeeper warning:**

> "Apple could not verify 'OpenPorts' is free of malware that may harm your Mac or compromise your privacy."

**This is expected and safe.** OpenPorts is not malicious - it's an open-source project. The warning appears because:

1. **No Apple Developer Account**: This project is open-source and doesn't have paid Apple Developer credentials ($99/year)
2. **No Notarization**: Without an Apple Developer account, apps cannot be submitted to Apple's notarization service
3. **Ad-hoc Signing**: The app is signed locally, which triggers macOS's Gatekeeper warning

**To launch OpenPorts:**
1. Open **System Settings** > **Privacy & Security**
2. Find "OpenPorts was blocked from opening"
3. Click **Open Anyway**

**This is normal for open-source projects** without paid Apple Developer accounts. You only need to approve it once.

> **Want to help?** If you have an Apple Developer account, see [CONTRIBUTING.md](CONTRIBUTING.md) to help with proper code signing and notarization.

## Features

- 🎯 **Port Safety Ratings** - Color-coded safety indicators (🔴 Critical, 🟠 Important, 🟢 Optional, 🔵 User-Created) to help you make informed decisions
- ⚡ **New Process Detection** - Lightning bolt badge on processes started within the last 5 minutes
- 🏃 **Uptime Tracking** - See how long each process has been running (5m, 1h, 2d, etc.)
- 🎨 **Port Categorization** - Automatically categorizes ports by type (Development, Database, System, etc.) with colorful icons
- 📂 **Project Name Detection** - Detects and displays project names for development tools (Python, Node.js, etc.)
- 🔧 **Technology Detection** - Shows specific technology being used (Python, Node.js, PostgreSQL, Docker, etc.)
- 📊 **Category Grouping** - Option to group ports by category for organized view
- 🔍 **Process Information** - Shows PID, process name, app name, bundle identifier, and executable path
- ⚙️ **Flexible Refresh** - Manual refresh (default) or configurable auto-refresh
- 🚫 **Process Termination** - Graceful terminate (SIGTERM) or force kill (SIGKILL)
- 🛡️ **Safety Features** - Admin elevation check for non-owned processes, system process warnings
- 🔎 **Search & Filter** - Quickly find ports by number, process, or app name
- 🚀 **Launch at Login** - Automatically start when you log in
- 🌙 **Dark Mode** - Fully supports macOS dark mode
- 💻 **Multi-Architecture** - Supports Apple Silicon (M1/M2/M3) and Intel Macs

### Safety Rating System

OpenPorts helps you understand whether a process should be terminated with a color-coded safety rating system:

| Safety Level | Icon | Description | Example |
|--------------|-------|-------------|----------|
| 🔴 Critical | Red | System services that should NOT be killed (SSH, HTTP, HTTPS, core macOS processes) | Port 22 (SSH), Port 443 (HTTPS) |
| 🟠 Important | Orange | Important services that may need restart after killing (databases, production servers) | Port 5432 (PostgreSQL), Port 3306 (MySQL) |
| 🟢 Optional | Green | Non-essential services and user applications | Custom web apps on port 8080 |
| 🔵 User-Created | Blue | Clearly user-initiated development servers (npm start, python manage.py) | Port 3000 (Node.js), Port 5000 (Python Flask) |

**Process Indicators:**
- ⚡ **New process** - Started within the last 5 minutes (likely a temporary dev server)
- 🏃 **Uptime** - How long the process has been running (5m, 1h, 2d)

## Installation

### Homebrew (Recommended)

```bash
brew install --cask MohamedMohana/tap/openports
open -a OpenPorts
```

#### Updating

When a new version is released, update with:

```bash
brew update && brew upgrade --cask MohamedMohana/tap/openports
```

> **Important:** Always run `brew update` first to ensure Homebrew has the latest tap information before upgrading.

> **Note:** Auto-updates have been temporarily removed. Updates will be available through Homebrew (`brew upgrade --cask MohamedMohana/tap/openports`) until we establish proper Apple Developer credentials for notarization.

### Manual Installation

1. Download latest release from [GitHub Releases](https://github.com/MohamedMohana/openports/releases)
2. Extract `OpenPorts.app` from downloaded ZIP file
3. Drag `OpenPorts.app` to your `/Applications` folder
4. Launch app from Applications or Spotlight

> **Note:** You'll see a Gatekeeper security warning on first launch - see [Security Warning](#-security-warning) above for details. This is normal for open-source projects without paid Apple Developer accounts.

### Development Build

```bash
git clone https://github.com/MohamedMohana/openports.git
cd openports
swift build
open OpenPorts.app
```

## Usage

1. **View Ports** - Click the OpenPorts icon in the menu bar to see all open listening ports
2. **Safety Ratings** - Each port shows a color-coded safety badge (🔴 Critical, 🟠 Important, 🟢 Optional, 🔵 User-Created) to help you decide whether to kill it
3. **New Process Indicator** - Lightning bolt (⚡) appears on processes started within the last 5 minutes
4. **Uptime Display** - See how long each process has been running in the port submenu
5. **Categorized View** - Ports are automatically categorized with colorful icons (💻 Development, 🗄️ Database, etc.)
6. **View Details** - Click any port to see:
    - Safety level (e.g., 🔵 User-Created)
    - Uptime (e.g., ⏱️ 5m)
    - Category (e.g., 💻 Development)
    - Technology (e.g., Python, Node.js)
    - Project name (if detected, e.g., "survey-kku")
    - Process name and ID
7. **Refresh** - Press "Refresh" (or `R`) to update the port list
8. **Group by Category** - Enable in Preferences to organize ports by type
9. **Terminate Process** - From the port submenu, select "Terminate" or "Force Kill"
10. **Preferences** - Access preferences to configure display options

## Configuration

OpenPorts stores preferences in `~/Library/Containers/com.mohamedmohana.openports/Data/Library/Preferences/`.

### Preferences

- **Refresh Interval** - Manual (default) or 3s, 5s, 10s, 30s
- **Group by Category** - Group ports by category (Development, Database, System, etc.) for organized view
- **Group by App** - Group ports by application instead of listing all processes
- **Show System Processes** - Show/hide system processes (marked with warning indicator)
- **Kill Warning Level** - Configure when to show warnings before terminating processes (None, High Risk Only, All Ports)
- **Show New Process Badges** - Display lightning bolt (⚡) on processes started within the last 5 minutes
- **Enable Port History Tracking** - Track port usage history to identify long-running vs temporary services (disabled by default)
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

## Testing

### Unit Tests

Run the comprehensive test suite:

```bash
swift test
```

**Test Coverage:**
- PortScanner integration tests (actual `lsof` scanning)
- ProcessResolver integration tests
- PortInfo model tests (creation, equality, system detection)
- PortScanResult tests (success/failure scenarios)
- Core initialization tests
- PortSafetyAnalyzer tests (safety level detection for critical, important, user-created ports)
- Safety icon and color tests

**Test Results:**
- 32 tests total
- All passing (0 failures)
- Real integration testing of actual functionality

Tests verify critical paths before users encounter issues, preventing "Open Anyway" problems.

### Security Warning on First Launch

If you see a security warning when first launching OpenPorts:

1. Open **System Settings** > **Privacy & Security**
2. Find "OpenPorts" was blocked from opening
3. Click **Open Anyway**

> This is expected - see [Security Warning](#-security-warning) above for details.

### Permission Denied When Terminating Process

If you see an error when trying to terminate a process you don't own:

1. OpenPorts will prompt for authentication
2. Enter your macOS administrator password
3. The process will be terminated

If authentication fails, the process may be protected by macOS System Integrity Protection (SIP). You may need to disable SIP or use `sudo` in Terminal.

### App Not Updating

If you installed via Homebrew, OpenPorts will check for updates via Homebrew. Update with:

```bash
brew upgrade --cask MohamedMohana/tap/openports
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

> **Have an Apple Developer account?** Help us improve distribution by contributing proper code signing and notarization. See [CONTRIBUTING.md](CONTRIBUTING.md) for details.

## Roadmap

- [ ] UDP port support (currently TCP only)
- [ ] Port favorites/watchlist with notifications
- [ ] Historical port usage data
- [ ] Export port list to CSV/JSON
- [ ] Customizable app icon themes
- [ ] Widget support (macOS 14+)
