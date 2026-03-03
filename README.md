<div align="center">

# OpenPorts

![OpenPorts Icon](Icon.iconset/openports-128.png)

**Lightweight Port Monitor for macOS Developers**

[![GitHub release](https://img.shields.io/github/release/MohamedMohana/openports.svg)](https://github.com/MohamedMohana/openports/releases)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/platform-macOS%20Sonoma-lightgrey.svg)](https://www.apple.com/macos)
[![Swift](https://img.shields.io/badge/Swift-6.1-orange.svg)](https://swift.org)

[Features](#what-ships-today) • [Installation](#installation) • [Roadmap](#roadmap) • [Contributing](#contributing)

</div>

---

OpenPorts is a macOS menu bar app that shows listening local TCP ports, the owning process, and quick controls to terminate processes when needed.

## What Ships Today

These are implemented and available in the app now:

- Menu bar view of listening TCP ports (`lsof`-based scan)
- Process details: PID, process name, app name/path when resolvable
- Safety labels (critical, important, optional, user-created) with kill warnings
- Port age and uptime indicators
- Custom SwiftUI popover control center (replaces the old plain menu layout)
- Grouping options in Preferences (by process / by category / by app)
- Manual refresh and optional auto-refresh interval
- Launch at login
- Port row deduplication for cleaner menu output
- Dedicated debug logs window with live updates and auto-scroll toggle
- In-app updates panel in Preferences:
  - automatic update checks toggle
  - manual `Check for Updates`
  - `Update via Homebrew`
  - release notes shortcut
- macOS notification when a newer OpenPorts release is detected

## Not Shipped Yet (Planned)

These are tracked but not released in the UI yet:

- Export actions (CSV/JSON/Markdown) in stable menu flow ([#4](https://github.com/MohamedMohana/openports/issues/4))
- Favorites/watchlist with lightweight defaults ([#5](https://github.com/MohamedMohana/openports/issues/5))
- Lightweight menu search/filter ([#6](https://github.com/MohamedMohana/openports/issues/6))
- Expanded smart notifications for port events ([#7](https://github.com/MohamedMohana/openports/issues/7))

## Installation

### Homebrew (Recommended)

```bash
brew install --cask MohamedMohana/tap/openports
```

### Manual Download

1. Download the latest release from [GitHub Releases](https://github.com/MohamedMohana/openports/releases)
2. Extract `OpenPorts.app`
3. Move it to `/Applications`
4. Launch from Applications or Spotlight

## Usage

1. Launch OpenPorts (menu bar icon appears)
2. Click icon to inspect current listening ports
3. Expand any port row to see PID, safety, uptime, path, and terminate actions
4. Open `Preferences...` for grouping, refresh, and update settings

### Keyboard Shortcuts

- `⌘R` refresh port list
- `⌘,` open preferences
- `⌘Q` quit OpenPorts

## Configuration

Preferences file:

- `~/Library/Preferences/com.mohamedmohana.openports.plist`

Current settings include:

- Refresh interval
- Show system processes
- Group by process / category / app
- Kill warning level
- Show new process badges
- Port history tracking toggle
- Launch at login
- Auto-check for updates

## Roadmap

### v2.0.x (Current)

- [x] Stabilize CI/build/release workflow
- [x] Native Preferences polish
- [x] Deduplicate duplicate menu rows
- [x] Add in-app update checks + Homebrew update action
- [ ] Export actions (Issue [#4](https://github.com/MohamedMohana/openports/issues/4))
- [ ] Favorites/watchlist (Issue [#5](https://github.com/MohamedMohana/openports/issues/5))
- [ ] Lightweight search/filter (Issue [#6](https://github.com/MohamedMohana/openports/issues/6))
- [ ] Expanded smart notifications (Issue [#7](https://github.com/MohamedMohana/openports/issues/7))

### Next (Only If Lightweight)

- [ ] Optional UDP view toggle
- [ ] Small CLI companion
- [ ] Local-only historical summaries

## Troubleshooting

### App Not Updating

Try in-app first:

- Preferences -> Updates -> `Check for Updates`
- Preferences -> Updates -> `Update via Homebrew`

Or terminal:

```bash
brew update && brew upgrade --cask MohamedMohana/tap/openports
```

### Permission Denied on Terminate

Some macOS-protected processes cannot be terminated (SIP/system restrictions).

## Contributing

```bash
git clone https://github.com/MohamedMohana/openports.git
cd openports
./Scripts/lint.sh
swift test
swift build
```

## License

MIT. See [LICENSE](LICENSE).
