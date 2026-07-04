<div align="center">

# OpenPorts

![OpenPorts Icon](Icon.iconset/openports-128.png)

**Lightweight port monitor for macOS developers.**

See every listening port, know which process owns it, and stop it safely — all from your menu bar.

[![CI](https://github.com/MohamedMohana/openports/actions/workflows/ci.yml/badge.svg)](https://github.com/MohamedMohana/openports/actions/workflows/ci.yml)
[![GitHub release](https://img.shields.io/github/release/MohamedMohana/openports.svg)](https://github.com/MohamedMohana/openports/releases)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/platform-macOS%2014%2B-lightgrey.svg)](https://www.apple.com/macos)
[![Swift](https://img.shields.io/badge/Swift-6.1-orange.svg)](https://swift.org)

[Features](#features) • [Installation](#installation) • [Usage](#usage) • [Architecture](docs/ARCHITECTURE.md) • [Roadmap](#roadmap) • [Contributing](#contributing)

</div>

---

Every developer has hit it: `Error: listen EADDRINUSE: address already in use :::3000`. OpenPorts answers "what's on that port?" in one click — with the process, its safety level, and a terminate button — instead of a round trip through `lsof -i :3000` and `kill -9`.

## Features

- **Live port list** — listening TCP ports (and optionally bound UDP sockets) scanned via `lsof`, deduplicated across IPv4/IPv6
- **Process details** — PID, process name, and resolved app name/path where available
- **Safety labels** — critical / important / optional / user-created classification with kill warnings, so you don't accidentally take down `mDNSResponder`
- **One-click terminate** — SIGTERM by default, force-kill available, with configurable warning levels
- **Search & filter** — match on port number, process name, app name, protocol, or path
- **Favorites** — pin the ports you care about to a dedicated section
- **Export** — CSV, JSON, or Markdown straight from the popover footer
- **Smart notifications (opt-in)** — new-port alerts, security alerts, and high-port-count thresholds; everything off by default
- **Port age & uptime** — spot the server you started 30 seconds ago vs. the one that's been up for a week
- **Grouping** — by process, category, or app
- **Auto-refresh** — manual by default, with 3–30 s intervals available
- **In-app updates** — release checks plus a one-click `brew upgrade`
- **Launch at login**, debug log window, and a native SwiftUI popover UI
- **CLI companion** — `openports-cli` lists the same ports in your terminal (table, JSON, or CSV) and can terminate by port number with the same safety warnings

## Installation

### Homebrew (recommended)

```bash
brew install --cask MohamedMohana/tap/openports
```

### Manual download

1. Download the latest release from [GitHub Releases](https://github.com/MohamedMohana/openports/releases)
2. Extract `OpenPorts.app` and move it to `/Applications`
3. Launch from Applications or Spotlight

> **Note:** Builds are currently ad-hoc signed, so Gatekeeper shows a warning on first launch. Right-click the app → **Open** to bypass it once. If you can help with notarization, see [CONTRIBUTING.md](CONTRIBUTING.md).

## Usage

1. Launch OpenPorts — the icon appears in your menu bar
2. Click it to see the current listening ports
3. Expand any row for PID, safety level, uptime, path, and terminate actions
4. Open **Preferences…** for grouping, refresh, UDP, notification, and update settings

### Keyboard shortcuts

| Shortcut | Action |
|----------|--------|
| `⌘R` | Refresh port list |
| `⌘,` | Open preferences |
| `⌘Q` | Quit OpenPorts |

### Command line

The Homebrew cask also installs `openports-cli`, a terminal companion built on the same scanning and safety analysis as the app:

```bash
openports-cli                      # listening TCP ports as a table
openports-cli --udp                # include bound UDP sockets
openports-cli --format json        # or csv — same schema as the app's export
openports-cli --kill 3000          # terminate the process on port 3000
openports-cli --kill 3000 --force  # skip the confirmation prompt
```

`--kill` prints the same safety classification and warning the app shows (so you know before you SIGTERM your database), asks for confirmation unless `--force` is passed, and `--signal kill` force-kills instead of the default graceful SIGTERM.

> **Note:** Like the app, the CLI is ad-hoc signed. If Gatekeeper blocks the first run, clear the quarantine flag: `xattr -d com.apple.quarantine "$(brew --prefix)/bin/openports-cli"`.

## Configuration

Settings are stored in `~/Library/Preferences/com.mohamedmohana.openports.plist` and managed from the Preferences window:

- Refresh interval (manual or 3–30 s)
- Show system processes / show UDP ports
- Grouping (process, category, app)
- Kill warning level and new-process badges
- Notification opt-ins and high-port-count threshold
- Port history tracking, launch at login, automatic update checks

## How It Works

OpenPorts is a Swift Package with three targets: `OpenPortsCore`, a UI-free library that handles scanning (`lsof -nP -iTCP -sTCP:LISTEN`, plus `-iUDP` when enabled), process resolution, safety analysis, favorites, notifications, and export; `OpenPorts`, the SwiftUI menu bar app on top of it; and `OpenPortsCLI`, the `openports-cli` terminal companion built on the same core. The full picture — data flow, services, and release pipeline — is in [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md).

No telemetry, no network calls except the GitHub release check you can turn off. Everything stays on your machine.

## Roadmap

Kept intentionally small — OpenPorts stays lightweight.

- [x] Search, favorites, export, smart notifications (v2.1)
- [x] Optional UDP view toggle
- [x] Small CLI companion (`openports-cli`)
- [ ] Local-only historical summaries

Have an idea that fits? [Open a feature request](https://github.com/MohamedMohana/openports/issues/new/choose).

## Troubleshooting

**App not updating** — use Preferences → Updates → *Check for Updates* / *Update via Homebrew*, or:

```bash
brew update && brew upgrade --cask MohamedMohana/tap/openports
```

**Permission denied on terminate** — some macOS-protected processes cannot be terminated (SIP/system restrictions). That's the OS working as intended.

## Contributing

Contributions are welcome — see [CONTRIBUTING.md](CONTRIBUTING.md) for setup, style, and PR guidelines.

```bash
git clone https://github.com/MohamedMohana/openports.git
cd openports
swift build
swift test
./Scripts/lint.sh
```

## License

MIT — see [LICENSE](LICENSE).
