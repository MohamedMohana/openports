import SwiftUI
import OpenPortsCore

struct PreferencesView: View {
    @AppStorage("refreshInterval") private var refreshInterval: Double = 5
    @AppStorage("groupPorts") private var groupPorts: Bool = false
    @AppStorage("showSystemProcesses") private var showSystemProcesses: Bool = true
    @AppStorage("groupByCategory") private var groupByCategory: Bool = false
    @AppStorage("groupByProcess") private var groupByProcess: Bool = true
    @AppStorage("killWarningLevel") private var killWarningLevel: KillWarningLevel = .highRiskOnly
    @AppStorage("showNewProcessBadges") private var showNewProcessBadges: Bool = true
    @AppStorage("portHistoryEnabled") private var portHistoryEnabled: Bool = false
    @State private var launchAtLoginEnabled: Bool = false
    
    var body: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Image(systemName: "network")
                        .font(.system(size: 32))
                        .foregroundStyle(Color.blue)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Preferences")
                            .font(.system(size: 24, weight: .semibold))
                        Text("OpenPorts v\(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.1.3")")
                            .font(.system(size: 11))
                            .foregroundStyle(Color.secondary)
                    }
                    .padding(.leading, 12)
                    Spacer()
                }
                .padding(20)
            }
            
            Divider()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    SectionView(title: "Refresh Settings", icon: "arrow.clockwise") {
                        VStack(alignment: .leading, spacing: 12) {
                            PreferenceRow(label: "Auto-refresh Interval") {
                                Picker("", selection: $refreshInterval) {
                                    Text("Manual").tag(0)
                                    Text("3 seconds").tag(3)
                                    Text("5 seconds").tag(5)
                                    Text("10 seconds").tag(10)
                                    Text("30 seconds").tag(30)
                                }
                                .pickerStyle(.menu)
                                .frame(width: 140, alignment: .trailing)
                            }
                            
                            Text("When set to Manual, use the Refresh button in the menu or press ⌘R")
                                .font(.system(size: 11))
                                .foregroundStyle(.secondary)
                                .padding(.leading, 20)
                        }
                    }
                    
                    SectionView(title: "View Options", icon: "list.bullet.rectangle") {
                        VStack(alignment: .leading, spacing: 10) {
                            PreferenceRow(label: "Group by process", icon: "app") {
                                Toggle("", isOn: $groupByProcess)
                                    .toggleStyle(.switch)
                            }
                            .help("Organize ports by application name (e.g., python, docker)")
                            
                            PreferenceRow(label: "Group by category", icon: "folder") {
                                Toggle("", isOn: $groupByCategory)
                                    .toggleStyle(.switch)
                            }
                            .help("Group by type: Development, Database, System, etc.")
                            
                            PreferenceRow(label: "Group by app", icon: "square.grid.2x2") {
                                Toggle("", isOn: $groupPorts)
                                    .toggleStyle(.switch)
                            }
                            .help("Alternative grouping method")
                            
                            PreferenceRow(label: "Show system processes", icon: "gear") {
                                Toggle("", isOn: $showSystemProcesses)
                                    .toggleStyle(.switch)
                            }
                            .help("Show or hide macOS system services")
                        }
                    }
                    
                    SectionView(title: "Safety Settings", icon: "shield.lefthalf.filled") {
                        VStack(alignment: .leading, spacing: 10) {
                            PreferenceRow(label: "Kill warning level", icon: "exclamationmark.triangle") {
                                Picker("", selection: $killWarningLevel) {
                                    Text("None").tag(KillWarningLevel.none)
                                    Text("High Risk Only").tag(KillWarningLevel.highRiskOnly)
                                    Text("All Ports").tag(KillWarningLevel.all)
                                }
                                .pickerStyle(.menu)
                                .frame(width: 140, alignment: .trailing)
                            }
                            .help("When to show confirmation before terminating a process")
                            
                            PreferenceRow(label: "Show new process badges (⚡)", icon: "bolt") {
                                Toggle("", isOn: $showNewProcessBadges)
                                    .toggleStyle(.switch)
                            }
                            .help("Highlight processes started in the last 5 minutes")
                        }
                    }
                    
                    SectionView(title: "Advanced", icon: "gearshape.2") {
                        VStack(alignment: .leading, spacing: 10) {
                            PreferenceRow(label: "Port history tracking", icon: "clock.arrow.circlepath") {
                                Toggle("", isOn: $portHistoryEnabled)
                                    .toggleStyle(.switch)
                            }
                            .help("Track which ports are most frequently used")
                            
                            PreferenceRow(label: "Launch at login", icon: "power") {
                                Toggle("", isOn: $launchAtLoginEnabled)
                                    .toggleStyle(.switch)
                                    .onChange(of: launchAtLoginEnabled) { _, newValue in
                                        LaunchAtLoginManager.setEnabled(newValue)
                                    }
                            }
                            .help("Start OpenPorts automatically when you log in")
                        }
                    }
                }
                .padding(.vertical, 20)
            }
            
            Divider()
            
            HStack {
                Spacer()
                Button("Reset to Defaults") {
                    resetToDefaults()
                }
                .controlSize(.large)
                
                Button("Done") {
                    closeWindow()
                }
                .controlSize(.large)
                .keyboardShortcut(.defaultAction)
            }
            .padding(20)
        }
        .frame(width: 520)
        .onAppear {
            launchAtLoginEnabled = LaunchAtLoginManager.isEnabled
        }
    }
    
    private func resetToDefaults() {
        refreshInterval = 0
        groupPorts = false
        showSystemProcesses = true
        groupByCategory = false
        groupByProcess = true
        killWarningLevel = .highRiskOnly
        showNewProcessBadges = true
        portHistoryEnabled = false
    }
    
    private func closeWindow() {
        if let window = NSApp.keyWindow {
            window.close()
        }
    }
}

struct SectionView: View {
    let title: String
    let icon: String
    let content: any View
    
    init(title: String, icon: String, @ViewBuilder content: () -> some View) {
        self.title = title
        self.icon = icon
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.blue)
                    .frame(width: 20)
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.primary)
                Spacer()
            }
            .padding(.bottom, 4)
            
            VStack(alignment: .leading, spacing: 8) {
                AnyView(content)
            }
            .padding(.leading, 28)
        }
        .padding(.vertical, 4)
    }
}

struct PreferenceRow: View {
    let label: String
    let icon: String?
    let content: any View
    
    init(label: String, icon: String? = nil, @ViewBuilder content: () -> some View) {
        self.label = label
        self.icon = icon
        self.content = content()
    }
    
    var body: some View {
        HStack(spacing: 12) {
            if let icon = icon {
                Image(systemName: icon)
                    .font(.system(size: 13))
                    .foregroundStyle(Color.secondary)
                    .frame(width: 16)
            }
            Text(label)
                .font(.system(size: 13))
                .foregroundStyle(Color.primary)
            Spacer()
            AnyView(content)
        }
    }
}
