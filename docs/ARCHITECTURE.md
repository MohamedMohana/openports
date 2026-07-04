# Architecture

OpenPorts is a Swift Package (SwiftPM, Swift 6.1, macOS 14+) with a strict split between a UI-free core library and a thin SwiftUI menu bar app.

```
┌─────────────────────────────────────────────────────────┐
│ OpenPorts (executable target — AppKit/SwiftUI)          │
│                                                         │
│  StatusItemController ── StatusPopoverView              │
│           │                     │                       │
│      MenuViewModel ──── PreferencesView / DebugLogsView │
│           │                                             │
├───────────┼─────────────────────────────────────────────┤
│ OpenPortsCore (library target — no UI imports)          │
│           │                                             │
│  PortScanner → ProcessResolver → PortInfoEnhancer       │
│      (lsof)      (NSRunningApp,     (safety, uptime,    │
│                   sysctl)            categorization)    │
│                                                         │
│  PortSafetyAnalyzer · PortCategorizer · PortKnowledgeBase│
│  FavoritesManager · NotificationManager · PortExporter  │
│  PortHistoryTracker · SemanticVersion                   │
└─────────────────────────────────────────────────────────┘
```

## Targets

| Target | Role |
|--------|------|
| `OpenPortsCore` | All domain logic: scanning, parsing, enrichment, safety analysis, favorites, notifications, export. Depends only on Foundation and [swift-log](https://github.com/apple/swift-log). |
| `OpenPorts` | The menu bar app: status item, popover UI, preferences, update service. Depends on `OpenPortsCore`. |
| `OpenPortsCoreTests` | XCTest suite covering the core library. |

## Data flow of a refresh

1. **`MenuViewModel.refreshPorts()`** (main actor) kicks off a scan task. UDP inclusion follows the `showUDPPorts` preference.
2. **`PortScanner`** (actor) runs `lsof -nP -iTCP -sTCP:LISTEN` — and `lsof -nP -iUDP` when UDP is enabled — then parses each row into a `PortInfo`. Connected sockets (`->`) and wildcard `*:*` bindings are skipped; rows are deduplicated by (port, protocol, PID). A UDP scan failure degrades gracefully to TCP-only results.
3. **`ProcessResolver`** enriches each `PortInfo` with app name, bundle ID, and executable path via `NSRunningApplication` and friends.
4. **`PortInfoEnhancer`** (actor) adds safety classification (`PortSafetyAnalyzer`), uptime, and age.
5. **`MenuViewModel`** publishes the result; **`MenuDescriptor`** builds the display model (grouping, search filtering, favorites section); **`StatusItemController`** re-renders the popover and status icon.
6. **`NotificationManager`** compares against the previous snapshot for opt-in alerts (new ports, security, high port count).

## Settings

All preferences live in `UserDefaults` (`com.mohamedmohana.openports`). `AppSettingsKey` centralizes key names, `AppSettings.registerDefaults` sets defaults, and `MenuViewModel` observes changes both through `NotificationCenter` (`.preferenceChanged` posts from the preferences UI) and `UserDefaults.didChangeNotification`. Preferences that change *what* is scanned (e.g. `showUDPPorts`) trigger a rescan; preferences that change *how* results display trigger a menu rebuild only.

## Update flow

`AppUpdateService` polls the GitHub Releases API (opt-out via preferences), compares versions with `SemanticVersion`, and can run `brew upgrade --cask` directly. Version metadata for packaging lives in `version.env`.

## Release pipeline

- **CI** (`.github/workflows/ci.yml`): SwiftFormat + SwiftLint (strict), build, tests, and an app-bundle packaging smoke test on every push/PR to `main`.
- **Release** (`.github/workflows/release.yml`), on a `v*` tag:
  1. Builds arm64 and x86_64 release binaries and packages `OpenPorts.app` via `Scripts/package_app.sh`
  2. Publishes zips + SHA-256 checksums as a GitHub release
  3. Renders and pushes an updated cask to [MohamedMohana/homebrew-tap](https://github.com/MohamedMohana/homebrew-tap) via `Scripts/render_homebrew_cask.sh`

## Conventions

- Formatting is owned by **SwiftFormat** (`.swiftformat`), linting by **SwiftLint** (`.swiftlint.yml`); the two configs are kept mutually consistent, and CI runs both in strict mode over `Sources` and `Tests`.
- Concurrency: scanning and enrichment are actors; all UI state flows through the `@MainActor` `MenuViewModel`.
- `OpenPortsCore` must stay importable without AppKit — UI types belong in the app target.
