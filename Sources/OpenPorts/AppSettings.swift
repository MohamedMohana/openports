import Foundation
import OpenPortsCore

enum AppSettingsKey {
    static let refreshInterval = "refreshInterval"
    static let groupPorts = "groupPorts"
    static let showSystemProcesses = "showSystemProcesses"
    static let groupByCategory = "groupByCategory"
    static let groupByProcess = "groupByProcess"
    static let killWarningLevel = "killWarningLevel"
    static let showNewProcessBadges = "showNewProcessBadges"
    static let portHistoryEnabled = "portHistoryEnabled"

    static let trackedPreferenceKeys: Set<String> = [
        refreshInterval,
        groupPorts,
        showSystemProcesses,
        groupByCategory,
        groupByProcess,
        killWarningLevel,
        showNewProcessBadges,
        portHistoryEnabled,
    ]
}

enum AppSettings {
    static let defaultRefreshInterval: Double = 0
    static let defaultGroupPorts = false
    static let defaultShowSystemProcesses = true
    static let defaultGroupByCategory = false
    static let defaultGroupByProcess = true
    static let defaultKillWarningLevel = KillWarningLevel.highRiskOnly
    static let defaultShowNewProcessBadges = true
    static let defaultPortHistoryEnabled = false

    static func registerDefaults(userDefaults: UserDefaults = .standard) {
        userDefaults.register(defaults: [
            AppSettingsKey.refreshInterval: defaultRefreshInterval,
            AppSettingsKey.groupPorts: defaultGroupPorts,
            AppSettingsKey.showSystemProcesses: defaultShowSystemProcesses,
            AppSettingsKey.groupByCategory: defaultGroupByCategory,
            AppSettingsKey.groupByProcess: defaultGroupByProcess,
            AppSettingsKey.killWarningLevel: defaultKillWarningLevel.rawValue,
            AppSettingsKey.showNewProcessBadges: defaultShowNewProcessBadges,
            AppSettingsKey.portHistoryEnabled: defaultPortHistoryEnabled,
        ])
    }
}
