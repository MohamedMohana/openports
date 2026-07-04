# Architecture

OpenPorts is a Swift Package (SwiftPM, Swift 6.1, macOS 14+) with a strict split between a UI-free core library and the two thin front ends built on it: a SwiftUI menu bar app and a terminal CLI.

```
┌────────────────────────────────┬────────────────────────┐
│ OpenPorts (executable target — │ OpenPortsCLI           │
│ AppKit/SwiftUI)                │ (executable target —   │
│                                │ swift-argument-parser) │
│  StatusItemController          │                        │
│      ── StatusPopoverView      │  OpenPortsCLICommand   │
│           │                    │  PortTableFormatter    │
│      MenuViewModel             │  ProcessTerminator     │
│  PreferencesView/DebugLogsView │                        │
├───────────┴────────────────────┴────────────────────────┤
│ OpenPortsCore (library target — no UI imports)          │
│                                                         │
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
| `OpenPortsCLI` | The `openports-cli` terminal companion: same scan → resolve → enhance pipeline, rendered as a table (or JSON/CSV via `PortExporter`), plus `--kill` with the app's safety warnings. Depends on `OpenPortsCore` and [swift-argument-parser](https://github.com/apple/swift-argument-parser). |
| `OpenPortsCoreTests` | XCTest suite covering the core library. |
| `OpenPortsCLITests` | XCTest suite covering CLI parsing, table rendering, termination, and version sync with `version.env`. |

## Data flow of a refresh

1. **`MenuViewModel.refreshPorts()`** (main actor) kicks off a scan task. UDP inclusion follows the `showUDPPorts` preference.
2. **`PortScanner`** (actor) runs `lsof -nP -iTCP -sTCP:LISTEN` — and `lsof -nP -iUDP` when UDP is enabled — then parses each row into a `PortInfo`. Connected sockets (`->`) and wildcard `*:*` bindings are skipped; rows are deduplicated by (port, protocol, PID). A UDP scan failure degrades gracefully to TCP-only results.
3. **`ProcessResolver`** enriches each `PortInfo` with app name, bundle ID, and executable path via `NSRunningApplication` and friends.
4. **`PortInfoEnhancer`** (actor) adds safety classification (`PortSafetyAnalyzer`), uptime, and age.
5. **`MenuViewModel`** publishes the result; **`MenuDescriptor`** builds the display model (grouping, search filtering, favorites section); **`StatusItemController`** re-renders the popover and status icon.
6. **`NotificationManager`** compares against the previous snapshot for opt-in alerts (new ports, security, high port count).

## The CLI companion

`openports-cli` reuses the exact refresh pipeline above (steps 2–4) without the UI layers: scan → resolve → enhance, then either render a plain-text table (`PortTableFormatter`) or delegate to `PortExporter` for `--format json`/`csv`, so machine-readable output matches the app's export schema. `--kill <port>` finds the owning PID(s), prints the same `PortSafetyAnalyzer` classification and warning message the app shows, asks for confirmation (skippable with `--force`), and signals via `kill(2)` — SIGTERM by default, SIGKILL with `--signal kill`. Core services log through swift-log; the CLI bootstraps the handler to stderr (warnings only unless `--verbose`) so stdout stays pipeable. The CLI version constant is kept in lockstep with `version.env` by a test.

## Settings

All preferences live in `UserDefaults` (`com.mohamedmohana.openports`). `AppSettingsKey` centralizes key names, `AppSettings.registerDefaults` sets defaults, and `MenuViewModel` observes changes both through `NotificationCenter` (`.preferenceChanged` posts from the preferences UI) and `UserDefaults.didChangeNotification`. Preferences that change *what* is scanned (e.g. `showUDPPorts`) trigger a rescan; preferences that change *how* results display trigger a menu rebuild only.

## Update flow

`AppUpdateService` polls the GitHub Releases API (opt-out via preferences), compares versions with `SemanticVersion`, and can run `brew upgrade --cask` directly. Version metadata for packaging lives in `version.env`.

## Release pipeline

- **CI** (`.github/workflows/ci.yml`): SwiftFormat + SwiftLint (strict), build, tests, and a packaging smoke test (app bundle + `openports-cli` run) on every push/PR to `main`.
- **Release** (`.github/workflows/release.yml`), on a `v*` tag:
  1. Builds arm64 and x86_64 release binaries and packages `OpenPorts.app` via `Scripts/package_app.sh`
  2. Publishes zips (each containing `OpenPorts.app` plus the ad-hoc-signed `openports-cli` binary) + SHA-256 checksums as a GitHub release
  3. Renders and pushes an updated cask to [MohamedMohana/homebrew-tap](https://github.com/MohamedMohana/homebrew-tap) via `Scripts/render_homebrew_cask.sh`; the cask installs the app via `app` and links `openports-cli` into `$(brew --prefix)/bin` via `binary`

## Conventions

- Formatting is owned by **SwiftFormat** (`.swiftformat`), linting by **SwiftLint** (`.swiftlint.yml`); the two configs are kept mutually consistent, and CI runs both in strict mode over `Sources` and `Tests`.
- Concurrency: scanning and enrichment are actors; all UI state flows through the `@MainActor` `MenuViewModel`.
- `OpenPortsCore` must stay importable without AppKit — UI types belong in the app target.
