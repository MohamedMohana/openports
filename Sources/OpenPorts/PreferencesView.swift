import OpenPortsCore
import SwiftUI

struct PreferencesView: View {
    @AppStorage(AppSettingsKey.refreshInterval) private var refreshInterval = AppSettings.defaultRefreshInterval
    @AppStorage(AppSettingsKey.groupPorts) private var groupPorts = AppSettings.defaultGroupPorts
    @AppStorage(AppSettingsKey.showSystemProcesses) private var showSystemProcesses = AppSettings.defaultShowSystemProcesses
    @AppStorage(AppSettingsKey.showUDPPorts) private var showUDPPorts = AppSettings.defaultShowUDPPorts
    @AppStorage(AppSettingsKey.groupByCategory) private var groupByCategory = AppSettings.defaultGroupByCategory
    @AppStorage(AppSettingsKey.groupByProcess) private var groupByProcess = AppSettings.defaultGroupByProcess
    @AppStorage(AppSettingsKey.killWarningLevel) private var killWarningLevel = AppSettings.defaultKillWarningLevel
    @AppStorage(AppSettingsKey.showNewProcessBadges) private var showNewProcessBadges = AppSettings.defaultShowNewProcessBadges
    @AppStorage(AppSettingsKey.portHistoryEnabled) private var portHistoryEnabled = AppSettings.defaultPortHistoryEnabled
    @AppStorage(AppSettingsKey.autoCheckForUpdates) private var autoCheckForUpdates = AppSettings.defaultAutoCheckForUpdates
    @AppStorage(AppSettingsKey.notificationsEnabled) private var notificationsEnabled = AppSettings.defaultNotificationsEnabled
    @AppStorage(AppSettingsKey.newPortAlerts) private var newPortAlerts = AppSettings.defaultNewPortAlerts
    @AppStorage(AppSettingsKey.highPortCountAlerts) private var highPortCountAlerts = AppSettings.defaultHighPortCountAlerts
    @AppStorage(AppSettingsKey.securityAlerts) private var securityAlerts = AppSettings.defaultSecurityAlerts
    @AppStorage(AppSettingsKey.portSpikeThreshold) private var portSpikeThreshold = AppSettings.defaultPortSpikeThreshold

    @State private var launchAtLoginEnabled = false
    @ObservedObject private var appUpdateService = AppUpdateService.shared

    var body: some View {
        VStack(spacing: 0) {
            TabView {
                generalTab
                    .tabItem { Label("General", systemImage: "gearshape") }
                displayTab
                    .tabItem { Label("Display", systemImage: "list.bullet.rectangle") }
                notificationsTab
                    .tabItem { Label("Notifications", systemImage: "bell.badge") }
                updatesTab
                    .tabItem { Label("Updates", systemImage: "arrow.triangle.2.circlepath") }
            }
            .padding(.top, 6)

            Divider()
            footer
        }
        .frame(width: 540, height: 470)
        .onAppear {
            launchAtLoginEnabled = LaunchAtLoginManager.isEnabled
        }
    }

    // MARK: General

    private var generalTab: some View {
        Form {
            Section {
                LabeledContent("Auto-refresh") {
                    Picker("", selection: $refreshInterval) {
                        Text("Manual").tag(0.0)
                        Text("3 seconds").tag(3.0)
                        Text("5 seconds").tag(5.0)
                        Text("10 seconds").tag(10.0)
                        Text("30 seconds").tag(30.0)
                    }
                    .labelsHidden()
                    .frame(width: 150)
                    .onChange(of: refreshInterval) { _, _ in
                        postPreferenceChange(key: AppSettingsKey.refreshInterval)
                    }
                }

                Toggle("Launch at login", isOn: $launchAtLoginEnabled)
                    .onChange(of: launchAtLoginEnabled) { _, isEnabled in
                        LaunchAtLoginManager.setEnabled(isEnabled)
                    }
            } footer: {
                Text("Manual refresh keeps background activity lowest.")
            }

            Section("Scanning") {
                Toggle("Show system processes", isOn: $showSystemProcesses)
                    .onChange(of: showSystemProcesses) { _, _ in
                        postPreferenceChange(key: AppSettingsKey.showSystemProcesses)
                    }

                Toggle("Show UDP ports", isOn: $showUDPPorts)
                    .onChange(of: showUDPPorts) { _, _ in
                        postPreferenceChange(key: AppSettingsKey.showUDPPorts)
                    }
            }

            Section {
                LabeledContent("Kill warning level") {
                    Picker("", selection: $killWarningLevel) {
                        Text("None").tag(KillWarningLevel.none)
                        Text("High Risk Only").tag(KillWarningLevel.highRiskOnly)
                        Text("All Ports").tag(KillWarningLevel.all)
                    }
                    .labelsHidden()
                    .frame(width: 170)
                    .onChange(of: killWarningLevel) { _, _ in
                        postPreferenceChange(key: AppSettingsKey.killWarningLevel)
                    }
                }
            } header: {
                Text("Safety")
            } footer: {
                Text("High-risk warnings are recommended before terminating critical or important services.")
            }
        }
        .formStyle(.grouped)
    }

    // MARK: Display

    private var displayTab: some View {
        Form {
            Section("Grouping") {
                Toggle("Group by process", isOn: $groupByProcess)
                    .onChange(of: groupByProcess) { _, _ in
                        postPreferenceChange(key: AppSettingsKey.groupByProcess)
                    }

                Toggle("Group by category", isOn: $groupByCategory)
                    .onChange(of: groupByCategory) { _, _ in
                        postPreferenceChange(key: AppSettingsKey.groupByCategory)
                    }

                Toggle("Group by app", isOn: $groupPorts)
                    .onChange(of: groupPorts) { _, _ in
                        postPreferenceChange(key: AppSettingsKey.groupPorts)
                    }
            }

            Section {
                Toggle("Show new process badges", isOn: $showNewProcessBadges)
                    .onChange(of: showNewProcessBadges) { _, _ in
                        postPreferenceChange(key: AppSettingsKey.showNewProcessBadges)
                    }

                Toggle("Track port history", isOn: $portHistoryEnabled)
                    .onChange(of: portHistoryEnabled) { _, _ in
                        postPreferenceChange(key: AppSettingsKey.portHistoryEnabled)
                    }
            } footer: {
                Text("History is kept locally and never leaves this Mac.")
            }
        }
        .formStyle(.grouped)
    }

    // MARK: Notifications

    private var notificationsTab: some View {
        Form {
            Section {
                Toggle("Enable notifications", isOn: $notificationsEnabled)
                    .onChange(of: notificationsEnabled) { _, newValue in
                        postPreferenceChange(key: AppSettingsKey.notificationsEnabled)
                        if newValue {
                            NotificationManager.shared.requestAuthorization()
                        }
                    }
            } footer: {
                Text("All notifications are disabled by default. Enable only the alerts you need.")
            }

            if notificationsEnabled {
                Section("Alerts") {
                    Toggle("New port alerts", isOn: $newPortAlerts)
                        .onChange(of: newPortAlerts) { _, _ in
                            postPreferenceChange(key: AppSettingsKey.newPortAlerts)
                        }

                    Toggle("Security alerts", isOn: $securityAlerts)
                        .onChange(of: securityAlerts) { _, _ in
                            postPreferenceChange(key: AppSettingsKey.securityAlerts)
                        }

                    Toggle("High port count alerts", isOn: $highPortCountAlerts)
                        .onChange(of: highPortCountAlerts) { _, _ in
                            postPreferenceChange(key: AppSettingsKey.highPortCountAlerts)
                        }

                    if highPortCountAlerts {
                        LabeledContent("Port count threshold") {
                            Stepper("\(portSpikeThreshold)", value: $portSpikeThreshold, in: 10 ... 500, step: 10)
                                .onChange(of: portSpikeThreshold) { _, _ in
                                    postPreferenceChange(key: AppSettingsKey.portSpikeThreshold)
                                }
                        }
                    }
                }
            }
        }
        .formStyle(.grouped)
    }

    // MARK: Updates

    private var updatesTab: some View {
        Form {
            Section {
                Toggle("Automatically check for updates", isOn: $autoCheckForUpdates)
                    .onChange(of: autoCheckForUpdates) { _, _ in
                        postPreferenceChange(key: AppSettingsKey.autoCheckForUpdates)
                    }

                HStack(spacing: 10) {
                    Button("Check for Updates") {
                        Task {
                            await appUpdateService.checkForUpdates()
                        }
                    }
                    .disabled(appUpdateService.isBusy)

                    Button("Update via Homebrew") {
                        Task {
                            await appUpdateService.installUpdateViaHomebrew()
                        }
                    }
                    .disabled(appUpdateService.isBusy)

                    Button("Release Notes") {
                        appUpdateService.openReleasePage()
                    }
                }

                Text(appUpdateService.statusMessage)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text(appUpdateService.lastCheckedMessage)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            } footer: {
                Text("Uses GitHub releases for checks and Homebrew (`mohamedmohana/tap/openports`) for installs.")
            }
        }
        .formStyle(.grouped)
    }

    // MARK: Footer

    private var footer: some View {
        HStack {
            Button("Reset to Defaults", role: .destructive) {
                resetToDefaults()
            }

            Spacer()

            Text(versionText)
                .font(.caption)
                .foregroundStyle(.tertiary)

            Spacer()

            Button("Done") {
                closeWindow()
            }
            .keyboardShortcut(.defaultAction)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 11)
    }

    private var versionText: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "?"
        return "OpenPorts \(version) (\(build))"
    }

    private func postPreferenceChange(key: String) {
        NotificationCenter.default.post(name: .preferenceChanged, object: key)
    }

    private func resetToDefaults() {
        refreshInterval = AppSettings.defaultRefreshInterval
        groupPorts = AppSettings.defaultGroupPorts
        showSystemProcesses = AppSettings.defaultShowSystemProcesses
        showUDPPorts = AppSettings.defaultShowUDPPorts
        groupByCategory = AppSettings.defaultGroupByCategory
        groupByProcess = AppSettings.defaultGroupByProcess
        killWarningLevel = AppSettings.defaultKillWarningLevel
        showNewProcessBadges = AppSettings.defaultShowNewProcessBadges
        portHistoryEnabled = AppSettings.defaultPortHistoryEnabled
        autoCheckForUpdates = AppSettings.defaultAutoCheckForUpdates
        notificationsEnabled = AppSettings.defaultNotificationsEnabled
        newPortAlerts = AppSettings.defaultNewPortAlerts
        highPortCountAlerts = AppSettings.defaultHighPortCountAlerts
        securityAlerts = AppSettings.defaultSecurityAlerts
        portSpikeThreshold = AppSettings.defaultPortSpikeThreshold
        launchAtLoginEnabled = false
        LaunchAtLoginManager.setEnabled(false)

        for key in AppSettingsKey.trackedPreferenceKeys {
            postPreferenceChange(key: key)
        }
    }

    private func closeWindow() {
        NSApp.keyWindow?.close()
    }
}
