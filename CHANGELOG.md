# Changelog

All notable changes to OpenPorts will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

No unreleased changes yet.

## [2.0.3] - 2026-03-03

### Changed
- Simplified menu row titles for faster scanning (safety, port/protocol, process, concise tags)
- Added safety-based row coloring for higher-risk entries
- Improved port submenu clarity with stronger process action labels (`SIGTERM` / `SIGKILL`)

### Fixed
- Stopped showing misleading pseudo-project labels (for example `CoreServices`, `Frameworks`, `Contents`, `libexec`) for system paths
- Project detection now favors real user workspace paths and ignores generic directory components

## [2.0.2] - 2026-03-03

### Added
- In-app Updates section in Preferences with manual checks and Homebrew upgrade action
- Automatic daily update checks (configurable) with macOS notification when a newer release is available
- `SemanticVersion` parser/comparator with unit tests for release version comparison

### Changed
- README rewritten to clearly separate shipped features from planned features
- Reset-to-defaults now includes update-check preferences

### Fixed
- Prevented repeated release notifications for the same version by tracking last notified version

## [2.0.1] - 2026-03-03

### Added
- Typed app settings layer (`AppSettings`) to centralize defaults and preference keys
- Auto-refresh timer wiring in `MenuViewModel` based on the preferences interval
- Relative "Updated …" status line in the menu descriptor

### Changed
- Preferences window redesigned with native grouped form sections and clearer control hierarchy
- Status icon now reflects scan warnings (`exclamationmark.triangle.fill`) and preferences window reuse
- CI workflow now runs non-mutating formatting checks (`swiftformat --lint`) and strict lint/test gates
- Release workflow now uses valid architecture mapping and packages app bundles from the correct path

### Fixed
- Fixed Swift compile failures in `FavoritesManager` and `NotificationManager` (`@Published var`, actor isolation)
- Removed broken partial integrations that referenced undefined symbols in `StatusItemController`
- Fixed URL scheme parsing in `AppDelegate` (`openports://kill?port=3000&force=true`)
- Updated `.swift-version` from `5.1` to `6.1`
- Synchronized project version metadata for the stabilization target (`2.0.1`)

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

## Current Development Focus

See [README.md](README.md) for the active roadmap. Current lightweight priorities:
- Export actions (CSV/JSON/Markdown)
- Favorites/watchlist
- Lightweight menu search/filter
- Continued UX cleanup and performance stability
