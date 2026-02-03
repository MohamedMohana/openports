import SwiftUI
import OpenPortsCore

struct PortListRow: View {
    let port: PortInfo
    let onTerminate: (Bool) -> Void
    
    @State private var showingKillConfirm: Bool = false
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Text(":\(port.port)")
                        .font(.system(.body).monospacedDigit())
                        .foregroundColor(.primary)
                    Text(port.portProtocol.rawValue)
                        .font(.system(.caption))
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 2)
                }
                
                VStack(alignment: .leading, spacing: 1) {
                    HStack(spacing: 4) {
                        Text(port.displayName)
                            .font(.system(.body))
                            .foregroundColor(.primary)
                        Spacer()
                        if port.isSystemProcess {
                            Image(systemName: "lock.shield.fill")
                                .font(.caption2)
                                .foregroundColor(.orange)
                        }
                    }
                    
                    HStack(spacing: 4) {
                        Text("PID: \(port.pid)")
                            .font(.system(.caption))
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                }
                
                if let path = port.executablePath {
                    Text(path)
                        .font(.system(.caption))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
            }
            .padding(.vertical, 6)
            .contextMenu {
                Button("Terminate") {
                    showingKillConfirm = true
                }
                Button("Force Kill") {
                    onTerminate(true)
                }
            }
        }
        .alert("Confirm Kill", isPresented: $showingKillConfirm) {
            Button("Cancel", role: .cancel) {}
            
            Button("Kill Process", role: .destructive) {
                onTerminate(false)
            }
        } message: {
            Text("Are you sure you want to kill \(port.displayName) on port \(port.port)?")
            Text("The process will be terminated immediately.")
        }
    }
}
