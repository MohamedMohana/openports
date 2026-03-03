# Changelog

All notable changes to OpenPorts will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Changed
- **Repository Cleanup**: Removed build artifacts from git tracking
  - Removed Icon.icns, Icon.png, OpenPorts.icns (generated files)
  - Removed OpenPorts-*.zip release archives (8 files, ~1.5MB)
  - These files are now properly ignored by .gitignore
  - Faster repository clones and cleaner history

### Added
- Cleanup script (`Scripts/cleanup.sh`) for removing local build artifacts
- Comprehensive .gitignore rules for generated files

### Fixed
- MenuViewModel: Set isLoading before updateMenu to prevent race conditions
- Updated Homebrew cask to v1.1.9

### Removed
- Deleted old feature branch `feature/safety-ratings-v1.1.0` (already merged)

## [1.1.9] - 2026-02-06

### Added
- Real-time preference updates using onChange modifiers
- Preferences now apply instantly without app restart

### Changed
- Improved preference synchronization
- Better UI responsiveness

## [1.1.8] - 2026-02-06

### Fixed
- Preferences window now properly displays all sections and options

## [1.1.7] - 2026-02-06

### Fixed
- Preferences changes now reflect in app menu
- Fixed preference persistence issues

## [1.1.6] - 2026-02-06

### Fixed
- Fixed preferences window rendering issues
- Improved ScrollView implementation

## [1.1.5] - 2026-02-06

### Fixed
- Preferences window now displays all sections and options properly

### Added
- Redesigned Preferences window with modern UI
- Process grouping by app (enabled by default)

## [1.1.4] - 2026-02-05

### Added
- New Preferences window with organized settings
- Configurable refresh intervals
- Port grouping options

## [1.1.3] - 2026-02-05

### Added
- Preferences UI improvements
- Better process grouping

## [1.1.2] - 2026-02-04

### Added
- Initial Preferences UI
- Basic UX improvements

## [1.1.1] - 2026-02-04

### Added
- Preferences UI foundation
- UX improvements

## [1.1.0] - 2026-02-03

### Added
- Port Safety Ratings System
  - Color-coded safety indicators (🔴 Critical, 🟠 Important, 🟢 Optional, 🔵 User-Created)
  - Warning messages for risky operations
  - Port categorization by type
- Process indicators
  - New process badges (⚡ for processes < 5 minutes old)
  - Uptime tracking (5m, 1h, 2d, etc.)
- Developer intelligence
  - Project name detection (Python, Node.js, etc.)
  - Technology detection (framework identification)
  - Category grouping option
- Enhanced UI
  - Better menu organization
  - Improved preferences window

## [1.0.0] - 2026-02-01

### Added
- Initial release
- Port scanning using lsof
- Process information display (PID, name, path)
- Process termination (graceful and force kill)
- Menu bar app with real-time updates
- Manual and auto-refresh options
- Launch at login support
- Dark mode support
- Apple Silicon and Intel support

---

## Version History Summary

- **1.1.x**: Safety ratings, preferences, developer intelligence
- **1.0.x**: Initial release with core port monitoring features

## Upcoming Features (Roadmap)

See [README.md](README.md) for the complete roadmap including:
- UDP port support
- Port favorites/watchlist
- Historical usage data
- Export to CSV/JSON
- Customizable app icon themes
- Widget support (macOS 14+)
