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
                aboutTab
                    .tabItem { Label("About", systemImage: "info.circle") }
            }
            .padding(.top, 6)

            Divider()
            footer
        }
        .frame(width: 560, height: 500)
        .onAppear {
            launchAtLoginEnabled = LaunchAtLoginManager.isEnabled
        }
    }

    // MARK: General

    private var generalTab: some View {
        Form {
            Section {
                Toggle(isOn: $launchAtLoginEnabled) {
                    Label {
                        settingText(
                            "Launch at login",
                            detail: "Start OpenPorts automatically when you log in to your Mac.",
                        )
                    } icon: {
                        SettingsIcon(systemName: "power", color: .green)
                    }
                }
                .onChange(of: launchAtLoginEnabled) { _, isEnabled in
                    LaunchAtLoginManager.setEnabled(isEnabled)
                }

                LabeledContent {
                    Picker("", selection: $refreshInterval) {
                        Text("Manual").tag(0.0)
                        Text("3 seconds").tag(3.0)
                        Text("5 seconds").tag(5.0)
                        Text("10 seconds").tag(10.0)
                        Text("30 seconds").tag(30.0)
                    }
                    .labelsHidden()
                    .frame(width: 140)
                    .onChange(of: refreshInterval) { _, _ in
                        postPreferenceChange(key: AppSettingsKey.refreshInterval)
                    }
                } label: {
                    Label {
                        settingText("Auto-refresh", detail: "Manual keeps background activity lowest.")
                    } icon: {
                        SettingsIcon(systemName: "arrow.clockwise", color: .blue)
                    }
                }
            }

            Section("Scanning") {
                Toggle(isOn: $showSystemProcesses) {
                    Label {
                        settingText("Show system processes", detail: "Include macOS services like mDNSResponder.")
                    } icon: {
                        SettingsIcon(systemName: "gearshape.2", color: .gray)
                    }
                }
                .onChange(of: showSystemProcesses) { _, _ in
                    postPreferenceChange(key: AppSettingsKey.showSystemProcesses)
                }

                Toggle(isOn: $showUDPPorts) {
                    Label {
                        settingText("Show UDP ports", detail: "UDP has no listening state, so every bound socket appears.")
                    } icon: {
                        SettingsIcon(systemName: "antenna.radiowaves.left.and.right", color: .purple)
                    }
                }
                .onChange(of: showUDPPorts) { _, _ in
                    postPreferenceChange(key: AppSettingsKey.showUDPPorts)
                }
            }

            Section {
                LabeledContent {
                    Picker("", selection: $killWarningLevel) {
                        Text("None").tag(KillWarningLevel.none)
                        Text("High Risk Only").tag(KillWarningLevel.highRiskOnly)
                        Text("All Ports").tag(KillWarningLevel.all)
                    }
                    .labelsHidden()
                    .frame(width: 150)
                    .onChange(of: killWarningLevel) { _, _ in
                        postPreferenceChange(key: AppSettingsKey.killWarningLevel)
                    }
                } label: {
                    Label {
                        settingText(
                            "Confirm before terminating",
                            detail: "Ask for confirmation before Stop or Force Kill.",
                        )
                    } icon: {
                        SettingsIcon(systemName: "shield.lefthalf.filled", color: .red)
                    }
                }
            } header: {
                Text("Safety")
            } footer: {
                Text("High Risk Only warns for critical and important services; All Ports warns every time.")
            }
        }
        .formStyle(.grouped)
    }

    // MARK: Display

    private var displayTab: some View {
        Form {
            Section("Grouping") {
                Toggle(isOn: $groupByProcess) {
                    Label {
                        settingText("Group by process", detail: "One section per executable name.")
                    } icon: {
                        SettingsIcon(systemName: "terminal", color: .indigo)
                    }
                }
                .onChange(of: groupByProcess) { _, _ in
                    postPreferenceChange(key: AppSettingsKey.groupByProcess)
                }

                Toggle(isOn: $groupByCategory) {
                    Label {
                        settingText("Group by category", detail: "Development, database, system, and more.")
                    } icon: {
                        SettingsIcon(systemName: "square.grid.2x2", color: .orange)
                    }
                }
                .onChange(of: groupByCategory) { _, _ in
                    postPreferenceChange(key: AppSettingsKey.groupByCategory)
                }

                Toggle(isOn: $groupPorts) {
                    Label {
                        settingText("Group by app", detail: "One section per resolved application.")
                    } icon: {
                        SettingsIcon(systemName: "macwindow", color: .cyan)
                    }
                }
                .onChange(of: groupPorts) { _, _ in
                    postPreferenceChange(key: AppSettingsKey.groupPorts)
                }
            }

            Section {
                Toggle(isOn: $showNewProcessBadges) {
                    Label {
                        settingText("Show new process badges", detail: "Tag ports that started in the last 5 minutes.")
                    } icon: {
                        SettingsIcon(systemName: "sparkles", color: .green)
                    }
                }
                .onChange(of: showNewProcessBadges) { _, _ in
                    postPreferenceChange(key: AppSettingsKey.showNewProcessBadges)
                }

                Toggle(isOn: $portHistoryEnabled) {
                    Label {
                        settingText("Track port history", detail: "Kept locally. Never leaves this Mac.")
                    } icon: {
                        SettingsIcon(systemName: "clock.arrow.circlepath", color: .teal)
                    }
                }
                .onChange(of: portHistoryEnabled) { _, _ in
                    postPreferenceChange(key: AppSettingsKey.portHistoryEnabled)
                }
            }
        }
        .formStyle(.grouped)
    }

    // MARK: Notifications

    private var notificationsTab: some View {
        Form {
            Section {
                Toggle(isOn: $notificationsEnabled) {
                    Label {
                        settingText(
                            "Enable notifications",
                            detail: "Everything is off by default. Enable only what you need.",
                        )
                    } icon: {
                        SettingsIcon(systemName: "bell.badge", color: .red)
                    }
                }
                .onChange(of: notificationsEnabled) { _, newValue in
                    postPreferenceChange(key: AppSettingsKey.notificationsEnabled)
                    if newValue {
                        NotificationManager.shared.requestAuthorization()
                    }
                }
            }

            if notificationsEnabled {
                Section("Alerts") {
                    Toggle(isOn: $newPortAlerts) {
                        Label {
                            settingText("New port alerts", detail: "When a process starts listening on a new port.")
                        } icon: {
                            SettingsIcon(systemName: "plus.circle", color: .blue)
                        }
                    }
                    .onChange(of: newPortAlerts) { _, _ in
                        postPreferenceChange(key: AppSettingsKey.newPortAlerts)
                    }

                    Toggle(isOn: $securityAlerts) {
                        Label {
                            settingText("Security alerts", detail: "When something risky appears.")
                        } icon: {
                            SettingsIcon(systemName: "exclamationmark.shield", color: .orange)
                        }
                    }
                    .onChange(of: securityAlerts) { _, _ in
                        postPreferenceChange(key: AppSettingsKey.securityAlerts)
                    }

                    Toggle(isOn: $highPortCountAlerts) {
                        Label {
                            settingText("High port count alerts", detail: "When open ports exceed your threshold.")
                        } icon: {
                            SettingsIcon(systemName: "chart.line.uptrend.xyaxis", color: .pink)
                        }
                    }
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
                HStack(spacing: 14) {
                    AppIconProvider.swiftUIImage(size: 44)
                        .resizable()
                        .frame(width: 44, height: 44)
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

                    VStack(alignment: .leading, spacing: 2) {
                        Text("OpenPorts")
                            .font(.system(size: 14, weight: .semibold))
                        Text(versionText)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(appUpdateService.lastCheckedMessage)
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }

                    Spacer()

                    if appUpdateService.isBusy {
                        ProgressView()
                            .controlSize(.small)
                    } else {
                        Button("Check for Updates") {
                            Task {
                                await appUpdateService.checkForUpdates()
                            }
                        }
                    }
                }
                .padding(.vertical, 4)
            }

            if appUpdateService.hasUpdateAvailable {
                Section {
                    HStack(spacing: 12) {
                        SettingsIcon(systemName: "arrow.down.circle", color: .green)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Version \(appUpdateService.latestVersion ?? "") is available")
                                .font(.system(size: 12, weight: .semibold))
                            Text("Installs via Homebrew. Your settings are kept.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        Button("Release Notes") {
                            appUpdateService.openReleasePage()
                        }

                        Button("Update Now") {
                            Task {
                                await appUpdateService.installUpdateViaHomebrew()
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(appUpdateService.isBusy)
                    }
                    .padding(.vertical, 2)
                }
            } else {
                Section {
                    Label {
                        Text(appUpdateService.statusMessage)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } icon: {
                        SettingsIcon(systemName: "checkmark.seal", color: .blue)
                    }
                }
            }

            Section {
                Toggle(isOn: $autoCheckForUpdates) {
                    Label {
                        settingText("Automatically check for updates", detail: "Checks GitHub Releases in the background.")
                    } icon: {
                        SettingsIcon(systemName: "arrow.triangle.2.circlepath", color: .indigo)
                    }
                }
                .onChange(of: autoCheckForUpdates) { _, _ in
                    postPreferenceChange(key: AppSettingsKey.autoCheckForUpdates)
                }
            } footer: {
                Text("Updates install with `brew upgrade --cask mohamedmohana/tap/openports`.")
            }
        }
        .formStyle(.grouped)
    }

    // MARK: About

    private var aboutTab: some View {
        VStack(spacing: 8) {
            Spacer()

            AppIconProvider.swiftUIImage(size: 88)
                .resizable()
                .frame(width: 88, height: 88)
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                .shadow(color: .black.opacity(0.2), radius: 10, y: 4)

            Text("OpenPorts")
                .font(.title3.weight(.semibold))

            Text(versionText)
                .font(.caption)
                .foregroundStyle(.secondary)

            Text("See every listening port, know which process owns it,\nand stop it safely — all from your menu bar.")
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.top, 2)

            HStack(spacing: 10) {
                aboutLink("GitHub", url: "https://github.com/MohamedMohana/openports")
                aboutLink("Report an Issue", url: "https://github.com/MohamedMohana/openports/issues/new/choose")
                aboutLink("Changelog", url: "https://github.com/MohamedMohana/openports/blob/main/CHANGELOG.md")
            }
            .padding(.top, 10)

            Spacer()

            Text("Free and open source · MIT License")
                .font(.caption2)
                .foregroundStyle(.tertiary)
                .padding(.bottom, 10)
        }
        .frame(maxWidth: .infinity)
    }

    private func aboutLink(_ title: String, url: String) -> some View {
        Button(title) {
            if let destination = URL(string: url) {
                NSWorkspace.shared.open(destination)
            }
        }
        .controlSize(.regular)
    }

    // MARK: Shared

    private func settingText(_ title: String, detail: String) -> some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(title)
            Text(detail)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

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
        return "Version \(version) (\(build))"
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

/// System Settings-style colored icon square used in settings rows.
private struct SettingsIcon: View {
    let systemName: String
    let color: Color

    var body: some View {
        Image(systemName: systemName)
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(.white)
            .frame(width: 24, height: 24)
            .background(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(color.gradient),
            )
    }
}
