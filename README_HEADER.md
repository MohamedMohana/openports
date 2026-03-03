<div align="center">

# OpenPorts

![OpenPorts Icon](Icon.iconset/openports-128.png)

**Smart Port Monitoring for Mac Developers**

[![GitHub release](https://img.shields.io/github/release/MohamedMohana/openports.svg)](https://github.com/MohamedMohana/openports/releases)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/platform-macOS%20Sonoma-lightgrey.svg)](https://www.apple.com/macos)
[![Swift](https://img.shields.io/badge/Swift-6.0-orange.svg)](https://swift.org)
[![Stars](https://img.shields.io/github/stars/MohamedMohana/openports?style=social)](https://github.com/MohamedMohana/openports)

[Features](#features) • [Installation](#installation) • [Usage](#usage) • [Contributing](#contributing)

</div>

---

**OpenPorts** is a lightweight macOS menu bar application that helps developers monitor and manage open network ports. Unlike other tools, OpenPorts tells you **which ports are safe to close** and lets you **kill processes directly**.

## ✨ Why OpenPorts?

- 🎯 **Smart Safety Ratings** - Know which ports are safe to close (no other tool does this!)
- ⚡ **Instant Insights** - See port age, process uptime, and technology stack at a glance
- 🔧 **Developer Intelligence** - Auto-detects Node.js, Python, Docker, and more
- 💪 **One-Click Action** - Kill processes directly from the menu bar
- 🪶 **Lightweight** - Uses <10MB RAM and <1% CPU
- 🆓 **Free & Open Source** - No tracking, no subscriptions, no catch

## 🎬 Demo

> 🎥 **Screenshots coming soon** - Check back after v2.0 release!

## 🚀 Features

### Core Features

| Feature | Description |
|---------|-------------|
| 🎯 **Safety Ratings** | Color-coded system: 🔴 Critical, 🟠 Important, 🟢 Optional, 🔵 User-Created |
| ⚡ **Port Age Tracking** | See if ports are brand new (⚡), recent (🌟), or long-running (🏛️) |
| 🏃 **Uptime Monitoring** | Track how long each process has been running (5m, 1h, 2d) |
| 🎨 **Smart Categories** | Auto-group by type: Development, Database, System, etc. |
| 📂 **Project Detection** | See project names for dev servers (React apps, Django, etc.) |
| 🔧 **Tech Stack Detection** | Identify Python, Node.js, PostgreSQL, Docker, and more |
| 🔍 **Quick Search** | Filter ports by number, process, or app name |
| 🚀 **Launch at Login** | Start automatically when you log in |
| 🌙 **Dark Mode** | Beautiful in both light and dark modes |

### Pro Features (v2.0 Coming Soon)

- 📊 Export to CSV, JSON, Markdown
- 🔔 Smart notifications for new/closed ports
- ⭐ Favorite ports for quick access
- 🔗 Copy connection strings (postgres://, mongodb://, etc.)
- ⌨️ Global keyboard shortcuts
- 🔗 URL scheme automation (openports://kill?port=3000)
- 📱 macOS Widgets

### Safety Rating System

OpenPorts uses a unique color-coded system to help you make informed decisions:

| Icon | Level | When to Kill? | Examples |
|------|-------|--------------|----------|
| 🔴 | Critical | **Never** - System services | SSH (22), HTTPS (443) |
| 🟠 | Important | **Careful** - May need restart | PostgreSQL (5432), MySQL (3306) |
| 🟢 | Optional | **Safe** - Non-essential | Custom apps on 8080 |
| 🔵 | User-Created | **Go ahead!** - Dev servers | npm start (3000), Flask (5000) |

## 📥 Installation

### Homebrew (Recommended)

```bash
brew install --cask MohamedMohana/tap/openports
```

### Manual Download

1. Download latest release from [GitHub Releases](https://github.com/MohamedMohana/openports/releases)
2. Extract `OpenPorts.app`
3. Drag to `/Applications`
4. Launch from Applications or Spotlight

> ⚠️ **First Launch Security Note**: You'll see a Gatekeeper warning. This is normal for open-source apps without paid Apple Developer accounts. Go to System Settings → Privacy & Security → Click "Open Anyway".

### Build from Source

```bash
git clone https://github.com/MohamedMohana/openports.git
cd openports
swift build -c release
./Scripts/package_app.sh release arm64  # For Apple Silicon
# or
./Scripts/package_app.sh release intel   # For Intel Macs
```

## 📖 Usage

### Quick Start

1. **Launch** - OpenPorts appears in your menu bar
2. **Click** - View all open ports and their safety ratings
3. **Monitor** - See port age, uptime, and technology stack
4. **Act** - Kill unwanted processes with one click

### Keyboard Shortcuts

| Shortcut | Action |
|----------|--------|
| `⌘R` | Refresh port list |
| `⌘F` | Search ports |
| `⌘,` | Open preferences |
| `⌘Q` | Quit OpenPorts |

### Menu Organization

```
┌─────────────────────────────────────┐
│ 🟢 12 ports active • Updated 2s ago │
├─────────────────────────────────────┤
│ 🆕 NEW (3)                        ▶│
│   ⚡ :3000 node - React App       ▶│
│   ⚡ :5000 python - Flask API     ▶│
├─────────────────────────────────────┤
│ 📌 ESTABLISHED (7)                ▶│
│   🕐 :5432 postgres - Production  ▶│
│   📌 :27017 mongo - Database      ▶│
├─────────────────────────────────────┤
│ 🏛️ LONG-RUNNING (2)               ▶│
│   🏛️ :22 ssh - System (2d)        ▶│
└─────────────────────────────────────┘
```

## ⚙️ Configuration

OpenPorts stores preferences in `~/Library/Preferences/com.mohamedmohana.openports.plist`

### Available Settings

- **Refresh Interval**: Manual (default) or 3s, 5s, 10s, 30s
- **Group by Category**: Organize ports by type
- **Group by App**: Group by application
- **Show System Processes**: Toggle system process visibility
- **Kill Warning Level**: None, High Risk Only, or All Ports
- **Show New Process Badges**: Display ⚡ for recent processes
- **Enable Port History**: Track usage patterns
- **Launch at Login**: Auto-start on login

## 🤝 Comparison with Other Tools

| Feature | OpenPorts | Little Snitch | LuLu |
|---------|-----------|---------------|------|
| **Price** | Free & Open Source | $59 | Free |
| **Port Monitoring** | ✅ | ❌ | ❌ |
| **Process Termination** | ✅ | ❌ | ❌ |
| **Safety Ratings** | ✅ Unique! | ❌ | ❌ |
| **Developer Features** | ✅ | ❌ | ❌ |
| **Port Age Tracking** | ✅ | ❌ | ❌ |
| **Technology Detection** | ✅ | ❌ | ❌ |
| **Outbound Firewall** | ❌ | ✅ | ✅ |

> OpenPorts focuses on **local port monitoring** while Little Snitch/LuLu focus on **outbound firewall**. They complement each other!

## 🛠️ Requirements

- **macOS**: 14.0 (Sonoma) or later
- **Architecture**: Apple Silicon (M1/M2/M3) or Intel
- **RAM**: < 10MB at idle
- **CPU**: < 1% at idle

## 📊 Roadmap

### v2.0 (Coming Soon)
- [ ] Export to CSV/JSON/Markdown/PDF
- [ ] Smart notifications for port changes
- [ ] Port favorites/watchlist
- [ ] Connection string copying
- [ ] URL scheme automation
- [ ] Shortcuts.app integration
- [ ] Keyboard shortcuts customization

### v2.1 (Future)
- [ ] UDP port support (currently TCP only)
- [ ] Historical usage analytics
- [ ] Bandwidth monitoring per port
- [ ] CLI companion tool
- [ ] macOS Widgets
- [ ] Custom icon themes

## 🤝 Contributing

Contributions are welcome! Please:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Make your changes
4. Run tests and linting (`./Scripts/lint.sh`)
5. Submit a pull request

### Development Setup

```bash
# Install development tools
brew install swiftlint swiftformat

# Run linting
./Scripts/lint.sh

# Run tests
swift test

# Build for development
swift build

# Package app
./Scripts/package_app.sh debug arm64
```

See [CONTRIBUTING.md](CONTRIBUTING.md) for detailed guidelines.

## 🐛 Troubleshooting

### "Apple could not verify..." Warning

This is normal! OpenPorts is open-source and doesn't have paid Apple Developer credentials.

**Solution**:
1. System Settings → Privacy & Security
2. Find "OpenPorts was blocked"
3. Click "Open Anyway"

### Permission Denied When Killing Process

Some processes are protected by macOS System Integrity Protection (SIP).

**Solution**: OpenPorts will prompt for admin authentication when needed.

### App Not Updating

If installed via Homebrew:
```bash
brew update && brew upgrade --cask MohamedMohana/tap/openports
```

## 📄 License

OpenPorts is released under the MIT License. See [LICENSE](LICENSE) for details.

## 🙏 Credits & Inspiration

- Inspired by [CodexBar](https://github.com/steipete/CodexBar)
- Port scanning powered by `lsof`
- Icons from SF Symbols

## 💬 Community

- **Issues**: [GitHub Issues](https://github.com/MohamedMohana/openports/issues)
- **Discussions**: [GitHub Discussions](https://github.com/MohamedMohana/openports/discussions)
- **Security**: See [SECURITY.md](SECURITY.md) for reporting vulnerabilities

## ⭐ Support This Project

If OpenPorts helps you, please consider:

- ⭐ **Starring** this repository
- 🐛 **Reporting** bugs and issues
- 💡 **Suggesting** new features
- 📢 **Sharing** with other developers
- 🤝 **Contributing** code or documentation

---

<div align="center">

**Built with ❤️ for Mac developers**

[⬆ Back to Top](#openports)

</div>
