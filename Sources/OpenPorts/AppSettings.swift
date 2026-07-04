import Foundation
import OpenPortsCore

enum AppSettingsKey {
    static let refreshInterval = "refreshInterval"
    static let groupPorts = "groupPorts"
    static let showSystemProcesses = "showSystemProcesses"
    static let showUDPPorts = "showUDPPorts"
    static let groupByCategory = "groupByCategory"
    static let groupByProcess = "groupByProcess"
    static let killWarningLevel = "killWarningLevel"
    static let showNewProcessBadges = "showNewProcessBadges"
    static let portHistoryEnabled = "portHistoryEnabled"
    static let autoCheckForUpdates = "autoCheckForUpdates"
    static let lastUpdateCheckTimestamp = "lastUpdateCheckTimestamp"
    static let lastNotifiedUpdateVersion = "lastNotifiedUpdateVersion"
    static let notificationsEnabled = "notificationsEnabled"
    static let newPortAlerts = "newPortAlerts"
    static let highPortCountAlerts = "highPortCountAlerts"
    static let securityAlerts = "securityAlerts"
    static let portSpikeThreshold = "portSpikeThreshold"

    static let trackedPreferenceKeys: Set<String> = [
        refreshInterval,
        groupPorts,
        showSystemProcesses,
        showUDPPorts,
        groupByCategory,
        groupByProcess,
        killWarningLevel,
        showNewProcessBadges,
        portHistoryEnabled,
        autoCheckForUpdates,
        notificationsEnabled,
        newPortAlerts,
        highPortCountAlerts,
        securityAlerts,
        portSpikeThreshold,
    ]
}

enum AppSettings {
    static let defaultRefreshInterval: Double = 0
    static let defaultGroupPorts = false
    static let defaultShowSystemProcesses = true
    static let defaultShowUDPPorts = false
    static let defaultGroupByCategory = false
    static let defaultGroupByProcess = true
    static let defaultKillWarningLevel = KillWarningLevel.highRiskOnly
    static let defaultShowNewProcessBadges = true
    static let defaultPortHistoryEnabled = false
    static let defaultAutoCheckForUpdates = true
    static let defaultLastUpdateCheckTimestamp: Double = 0
    static let defaultLastNotifiedUpdateVersion = ""
    static let defaultNotificationsEnabled = false
    static let defaultNewPortAlerts = false
    static let defaultHighPortCountAlerts = false
    static let defaultSecurityAlerts = false
    static let defaultPortSpikeThreshold = 50

    static func registerDefaults(userDefaults: UserDefaults = .standard) {
        userDefaults.register(defaults: [
            AppSettingsKey.refreshInterval: defaultRefreshInterval,
            AppSettingsKey.groupPorts: defaultGroupPorts,
            AppSettingsKey.showSystemProcesses: defaultShowSystemProcesses,
            AppSettingsKey.showUDPPorts: defaultShowUDPPorts,
            AppSettingsKey.groupByCategory: defaultGroupByCategory,
            AppSettingsKey.groupByProcess: defaultGroupByProcess,
            AppSettingsKey.killWarningLevel: defaultKillWarningLevel.rawValue,
            AppSettingsKey.showNewProcessBadges: defaultShowNewProcessBadges,
            AppSettingsKey.portHistoryEnabled: defaultPortHistoryEnabled,
            AppSettingsKey.autoCheckForUpdates: defaultAutoCheckForUpdates,
            AppSettingsKey.lastUpdateCheckTimestamp: defaultLastUpdateCheckTimestamp,
            AppSettingsKey.lastNotifiedUpdateVersion: defaultLastNotifiedUpdateVersion,
            AppSettingsKey.notificationsEnabled: defaultNotificationsEnabled,
            AppSettingsKey.newPortAlerts: defaultNewPortAlerts,
            AppSettingsKey.highPortCountAlerts: defaultHighPortCountAlerts,
            AppSettingsKey.securityAlerts: defaultSecurityAlerts,
            AppSettingsKey.portSpikeThreshold: defaultPortSpikeThreshold,
        ])
    }
}
