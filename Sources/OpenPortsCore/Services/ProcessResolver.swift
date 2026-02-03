import Foundation
import AppKit
import Logging

/// Service for resolving process information from PID to application details.
public actor ProcessResolver {
    private let logger = Logger(label: "com.openports.processresolver")
    
    /// Resolve detailed information for a list of PortInfo entries.
    public func resolveProcessInfo(for ports: [PortInfo]) async -> [PortInfo] {
        var resolvedPorts: [PortInfo] = []
        
        for port in ports {
            let resolvedPort = await resolveProcessInfo(for: port)
            resolvedPorts.append(resolvedPort)
        }
        
        return resolvedPorts
    }
    
    /// Resolve process information for a single PortInfo entry.
    private func resolveProcessInfo(for port: PortInfo) async -> PortInfo {
        // Try to find NSRunningApplication by PID
        if let runningApp = await findRunningApplication(for: port.pid) {
            return PortInfo(
                port: port.port,
                portProtocol: port.portProtocol,
                pid: port.pid,
                processName: port.processName,
                appName: runningApp.localizedName ?? port.processName,
                bundleID: runningApp.bundleIdentifier,
                executablePath: runningApp.bundleURL?.path,
                isSystemProcess: isSystemProcess(runningApp)
            )
        }
        
        // Fallback to process info via ps command
        if let execPath = await getExecutablePath(for: port.pid) {
            return PortInfo(
                port: port.port,
                portProtocol: port.portProtocol,
                pid: port.pid,
                processName: port.processName,
                appName: nil,
                bundleID: nil,
                executablePath: execPath,
                isSystemProcess: isSystemProcessPath(execPath)
            )
        }
        
        // Return original if resolution fails
        return port
    }
    
    /// Find NSRunningApplication by PID.
    private func findRunningApplication(for pid: Int) -> NSRunningApplication? {
        NSWorkspace.shared.runningApplications.first { app in
            return app.processIdentifier == pid
        }
    }
    
    /// Get executable path for a PID using the `ps` command.
    private func getExecutablePath(for pid: Int) async -> String? {
        do {
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/bin/ps")
            process.arguments = ["-p", String(pid), "-o", "comm"]
            
            let pipe = Pipe()
            process.standardOutput = pipe
            process.standardError = Pipe()
            
            try process.run()
            process.waitUntilExit()
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            guard let output = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespaces) else {
                return nil
            }
            
            return output.isEmpty ? nil : output
        } catch {
            logger.error("Failed to get executable path for PID \(pid): \(error.localizedDescription)")
            return nil
        }
    }
    
    /// Check if an NSRunningApplication is a system process.
    private func isSystemProcess(_ app: NSRunningApplication) -> Bool {
        guard let bundleID = app.bundleIdentifier else {
            return false
        }
        
        let systemBundlePrefixes = [
            "com.apple.",
            "com.apple.coreservices",
            "com.apple.securityd"
        ]
        
        return systemBundlePrefixes.contains { bundleID.hasPrefix($0) }
    }
    
    /// Check if a path is a system process path.
    private func isSystemProcessPath(_ path: String) -> Bool {
        let systemPaths = [
            "/System/",
            "/usr/sbin/",
            "/usr/bin/"
        ]
        
        return systemPaths.contains { path.hasPrefix($0) }
    }
}
