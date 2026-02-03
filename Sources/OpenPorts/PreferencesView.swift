import SwiftUI
import OpenPortsCore

struct PreferencesView: View {
    @AppStorage("refreshInterval") private var refreshInterval: Double = 5.0
    @AppStorage("groupPorts") private var groupPorts: Bool = false
    @AppStorage("showSystemProcesses") private var showSystemProcesses: Bool = true
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Preferences")
                .font(.system(.largeTitle).bold())
                .padding(.bottom)
            
            Divider()
            
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Refresh Interval")
                        .frame(width: 120, alignment: .trailing)
                    Spacer()
                    
                    Picker("", selection: $refreshInterval) {
                        Text("3 seconds").tag(3)
                        Text("5 seconds").tag(5)
                        Text("10 seconds").tag(10)
                        Text("30 seconds").tag(30)
                        Text("Manual").tag(0)
                    }
                    .pickerStyle(.menu)
                }
                .padding(.bottom, 8)
                
                Toggle("Group ports by app", isOn: $groupPorts)
                    .toggleStyle(.switch)
                
                Toggle("Show system processes", isOn: $showSystemProcesses)
                    .toggleStyle(.switch)
            }
            .padding()
        }
        .frame(width: 400)
        .padding(.vertical, 20)
    }
}
