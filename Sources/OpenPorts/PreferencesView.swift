import OpenPortsCore
import SwiftUI

struct PreferencesView: View {
    @AppStorage(AppSettingsKey.refreshInterval) private var refreshInterval = AppSettings.defaultRefreshInterval
    @AppStorage(AppSettingsKey.groupPorts) private var groupPorts = AppSettings.defaultGroupPorts
    @AppStorage(AppSettingsKey.showSystemProcesses) private var showSystemProcesses = AppSettings.defaultShowSystemProcesses
    @AppStorage(AppSettingsKey.groupByCategory) private var groupByCategory = AppSettings.defaultGroupByCategory
    @AppStorage(AppSettingsKey.groupByProcess) private var groupByProcess = AppSettings.defaultGroupByProcess
    @AppStorage(AppSettingsKey.killWarningLevel) private var killWarningLevel = AppSettings.defaultKillWarningLevel
    @AppStorage(AppSettingsKey.showNewProcessBadges) private var showNewProcessBadges = AppSettings.defaultShowNewProcessBadges
    @AppStorage(AppSettingsKey.portHistoryEnabled) private var portHistoryEnabled = AppSettings.defaultPortHistoryEnabled
    @AppStorage(AppSettingsKey.autoCheckForUpdates) private var autoCheckForUpdates = AppSettings.defaultAutoCheckForUpdates

    @State private var launchAtLoginEnabled = false
    @ObservedObject private var appUpdateService = AppUpdateService.shared

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            form
            Divider()
            footer
        }
        .frame(minWidth: 520, idealWidth: 560, minHeight: 520, idealHeight: 620)
        .onAppear {
            launchAtLoginEnabled = LaunchAtLoginManager.isEnabled
        }
    }

    private var header: some View {
        HStack(alignment: .center, spacing: 12) {
            AppIconProvider.swiftUIImage(size: 36)
                .resizable()
                .frame(width: 36, height: 36)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

            VStack(alignment: .leading, spacing: 2) {
                Text("OpenPorts Preferences")
                    .font(.title3.weight(.semibold))
                Text(versionText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
    }

    private var form: some View {
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

                Toggle("Show system processes", isOn: $showSystemProcesses)
                    .onChange(of: showSystemProcesses) { _, _ in
                        postPreferenceChange(key: AppSettingsKey.showSystemProcesses)
                    }

                Toggle("Launch at login", isOn: $launchAtLoginEnabled)
                    .onChange(of: launchAtLoginEnabled) { _, isEnabled in
                        LaunchAtLoginManager.setEnabled(isEnabled)
                    }
            } header: {
                Text("General")
            } footer: {
                Text("Use Manual refresh for the lowest background activity.")
            }

            Section {
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
            } header: {
                Text("Organization")
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

                Toggle("Show new process badges", isOn: $showNewProcessBadges)
                    .onChange(of: showNewProcessBadges) { _, _ in
                        postPreferenceChange(key: AppSettingsKey.showNewProcessBadges)
                    }
            } header: {
                Text("Safety")
            } footer: {
                Text("High-risk warnings are recommended before terminating critical or important services.")
            }

            Section {
                Toggle("Enable port history tracking", isOn: $portHistoryEnabled)
                    .onChange(of: portHistoryEnabled) { _, _ in
                        postPreferenceChange(key: AppSettingsKey.portHistoryEnabled)
                    }
            } header: {
                Text("Advanced")
            }

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
            } header: {
                Text("Updates")
            } footer: {
                Text("Uses GitHub releases for checks and Homebrew (`mohamedmohana/tap/openports`) for installs.")
            }
        }
        .formStyle(.grouped)
        .padding(16)
    }

    private var footer: some View {
        HStack {
            Button("Reset to Defaults", role: .destructive) {
                resetToDefaults()
            }

            Spacer()

            Button("Done") {
                closeWindow()
            }
            .keyboardShortcut(.defaultAction)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
    }

    private var versionText: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "?"
        return "Version \(version) (\(build))"
    }

    private func postPreferenceChange(key: String) {
        NotificationCenter.default.post(name: .preferenceChanged, object: key)
    }

    private func resetToDefaults() {
        refreshInterval = AppSettings.defaultRefreshInterval
        groupPorts = AppSettings.defaultGroupPorts
        showSystemProcesses = AppSettings.defaultShowSystemProcesses
        groupByCategory = AppSettings.defaultGroupByCategory
        groupByProcess = AppSettings.defaultGroupByProcess
        killWarningLevel = AppSettings.defaultKillWarningLevel
        showNewProcessBadges = AppSettings.defaultShowNewProcessBadges
        portHistoryEnabled = AppSettings.defaultPortHistoryEnabled
        autoCheckForUpdates = AppSettings.defaultAutoCheckForUpdates
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
