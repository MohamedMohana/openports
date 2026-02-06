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
    
    private func postPreferenceChange(key: String) {
        NotificationCenter.default.post(name: .preferenceChanged, object: key)
    }
    
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
                VStack(alignment: .leading, spacing: 0) {
                    Color.clear.frame(height: 8)
                    VStack(alignment: .leading, spacing: 24) {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack(spacing: 8) {
                                Image(systemName: "arrow.clockwise")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(Color.blue)
                                    .frame(width: 20)
                                Text("Refresh Settings")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundStyle(Color.primary)
                                Spacer()
                            }
                            .padding(.bottom, 4)
                            
                            VStack(alignment: .leading, spacing: 12) {
                                HStack(spacing: 12) {
                                    Text("Auto-refresh Interval")
                                        .font(.system(size: 13))
                                        .foregroundStyle(Color.primary)
                                    Spacer()
                                    Picker("", selection: $refreshInterval) {
                                        Text("Manual").tag(0)
                                        Text("3 seconds").tag(3)
                                        Text("5 seconds").tag(5)
                                        Text("10 seconds").tag(10)
                                        Text("30 seconds").tag(30)
                                    }
                                    .pickerStyle(.menu)
                                    .frame(width: 140, alignment: .trailing)
                                    .onChange(of: refreshInterval) { _, _ in
                                        postPreferenceChange(key: "refreshInterval")
                                    }
                                }
                                
                                Text("When set to Manual, use the Refresh button in the menu or press ⌘R")
                                    .font(.system(size: 11))
                                    .foregroundStyle(.secondary)
                                    .padding(.leading, 0)
                            }
                        }
                        
                        VStack(alignment: .leading, spacing: 12) {
                            HStack(spacing: 8) {
                                Image(systemName: "list.bullet.rectangle")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(Color.blue)
                                    .frame(width: 20)
                                Text("View Options")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundStyle(Color.primary)
                                Spacer()
                            }
                            .padding(.bottom, 4)
                            
                            VStack(alignment: .leading, spacing: 10) {
                                HStack(spacing: 12) {
                                    Image(systemName: "app")
                                        .font(.system(size: 13))
                                        .foregroundStyle(Color.secondary)
                                        .frame(width: 16)
                                    Text("Group by process")
                                        .font(.system(size: 13))
                                        .foregroundStyle(Color.primary)
                                    Spacer()
                                    Toggle("", isOn: $groupByProcess)
                                        .toggleStyle(.switch)
                                        .onChange(of: groupByProcess) { _, _ in
                                            postPreferenceChange(key: "groupByProcess")
                                        }
                                }
                                .help("Organize ports by application name (e.g., python, docker)")
                                
                                HStack(spacing: 12) {
                                    Image(systemName: "folder")
                                        .font(.system(size: 13))
                                        .foregroundStyle(Color.secondary)
                                        .frame(width: 16)
                                    Text("Group by category")
                                        .font(.system(size: 13))
                                        .foregroundStyle(Color.primary)
                                    Spacer()
                                    Toggle("", isOn: $groupByCategory)
                                        .toggleStyle(.switch)
                                        .onChange(of: groupByCategory) { _, _ in
                                            postPreferenceChange(key: "groupByCategory")
                                        }
                                }
                                .help("Group by type: Development, Database, System, etc.")
                                
                                HStack(spacing: 12) {
                                    Image(systemName: "square.grid.2x2")
                                        .font(.system(size: 13))
                                        .foregroundStyle(Color.secondary)
                                        .frame(width: 16)
                                    Text("Group by app")
                                        .font(.system(size: 13))
                                        .foregroundStyle(Color.primary)
                                    Spacer()
                                    Toggle("", isOn: $groupPorts)
                                        .toggleStyle(.switch)
                                        .onChange(of: groupPorts) { _, _ in
                                            postPreferenceChange(key: "groupPorts")
                                        }
                                }
                                .help("Alternative grouping method")
                                
                                HStack(spacing: 12) {
                                    Image(systemName: "gear")
                                        .font(.system(size: 13))
                                        .foregroundStyle(Color.secondary)
                                        .frame(width: 16)
                                    Text("Show system processes")
                                        .font(.system(size: 13))
                                        .foregroundStyle(Color.primary)
                                    Spacer()
                                    Toggle("", isOn: $showSystemProcesses)
                                        .toggleStyle(.switch)
                                        .onChange(of: showSystemProcesses) { _, _ in
                                            postPreferenceChange(key: "showSystemProcesses")
                                        }
                                }
                                .help("Show or hide macOS system services")
                            }
                        }
                        
                        VStack(alignment: .leading, spacing: 12) {
                            HStack(spacing: 8) {
                                Image(systemName: "shield.lefthalf.filled")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(Color.blue)
                                    .frame(width: 20)
                                Text("Safety Settings")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundStyle(Color.primary)
                                Spacer()
                            }
                            .padding(.bottom, 4)
                            
                            VStack(alignment: .leading, spacing: 10) {
                                HStack(spacing: 12) {
                                    Image(systemName: "exclamationmark.triangle")
                                        .font(.system(size: 13))
                                        .foregroundStyle(Color.secondary)
                                        .frame(width: 16)
                                    Text("Kill warning level")
                                        .font(.system(size: 13))
                                        .foregroundStyle(Color.primary)
                                    Spacer()
                                    Picker("", selection: $killWarningLevel) {
                                        Text("None").tag(KillWarningLevel.none)
                                        Text("High Risk Only").tag(KillWarningLevel.highRiskOnly)
                                        Text("All Ports").tag(KillWarningLevel.all)
                                    }
                                    .pickerStyle(.menu)
                                    .frame(width: 140, alignment: .trailing)
                                    .onChange(of: killWarningLevel) { _, _ in
                                        postPreferenceChange(key: "killWarningLevel")
                                    }
                                }
                                .help("When to show confirmation before terminating a process")
                                
                                HStack(spacing: 12) {
                                    Image(systemName: "bolt")
                                        .font(.system(size: 13))
                                        .foregroundStyle(Color.secondary)
                                        .frame(width: 16)
                                    Text("Show new process badges (⚡)")
                                        .font(.system(size: 13))
                                        .foregroundStyle(Color.primary)
                                    Spacer()
                                    Toggle("", isOn: $showNewProcessBadges)
                                        .toggleStyle(.switch)
                                        .onChange(of: showNewProcessBadges) { _, _ in
                                            postPreferenceChange(key: "showNewProcessBadges")
                                        }
                                }
                                .help("Highlight processes started in the last 5 minutes")
                            }
                        }
                        
                        VStack(alignment: .leading, spacing: 12) {
                            HStack(spacing: 8) {
                                Image(systemName: "gearshape.2")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(Color.blue)
                                    .frame(width: 20)
                                Text("Advanced")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundStyle(Color.primary)
                                Spacer()
                            }
                            .padding(.bottom, 4)
                            
                            VStack(alignment: .leading, spacing: 10) {
                                HStack(spacing: 12) {
                                    Image(systemName: "clock.arrow.circlepath")
                                        .font(.system(size: 13))
                                        .foregroundStyle(Color.secondary)
                                        .frame(width: 16)
                                    Text("Port history tracking")
                                        .font(.system(size: 13))
                                        .foregroundStyle(Color.primary)
                                    Spacer()
                                    Toggle("", isOn: $portHistoryEnabled)
                                        .toggleStyle(.switch)
                                        .onChange(of: portHistoryEnabled) { _, _ in
                                            postPreferenceChange(key: "portHistoryEnabled")
                                        }
                                }
                                .help("Track which ports are most frequently used")
                                
                                HStack(spacing: 12) {
                                    Image(systemName: "power")
                                        .font(.system(size: 13))
                                        .foregroundStyle(Color.secondary)
                                        .frame(width: 16)
                                    Text("Launch at login")
                                        .font(.system(size: 13))
                                        .foregroundStyle(Color.primary)
                                    Spacer()
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
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 20)
            }
            .frame(maxHeight: .infinity)
            
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
