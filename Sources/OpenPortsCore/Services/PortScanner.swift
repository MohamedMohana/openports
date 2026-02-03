import Foundation
import Logging

/// Service for scanning open ports on the system using `lsof`.
public actor PortScanner {
    private let logger = Logger(label: "com.openports.portscanner")
    private let lsofPath = "/usr/sbin/lsof"
    
    /// Scan for open listening TCP ports.
    public func scanOpenPorts() async -> PortScanResult {
        guard FileManager.default.fileExists(atPath: lsofPath) else {
            logger.error("lsof not found at \(lsofPath)")
            return .failure("lsof command not found. Please ensure macOS developer tools are installed.")
        }
        
        do {
            let output = try await runLsofCommand()
            let ports = try parseLsofOutput(output)
            logger.info("Found \(ports.count) open ports")
            return PortScanResult(ports: ports, success: true, error: nil)
        } catch {
            logger.error("Failed to scan ports: \(error.localizedDescription)")
            return .failure(error.localizedDescription)
        }
    }
    
    /// Execute lsof command and return output.
    private func runLsofCommand() async throws -> String {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: lsofPath)
        process.arguments = [
            "-nP",             // Don't resolve hostnames, show numeric ports
            "-iTCP",          // TCP ports only
            "-sTCP:LISTEN",   // Listening TCP ports only
            "-P",             // No port name resolution
            "-c",             // Custom format
            "\"p\\nT\\nL\\nc\\nU\"" // port, protocol, command, user
        ]
        
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe
        
        try process.run()
        process.waitUntilExit()
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        guard let output = String(data: data, encoding: .utf8) else {
            throw PortScannerError.invalidOutput
        }
        
        if process.terminationStatus != 0 {
            throw PortScannerError.commandFailed(status: process.terminationStatus)
        }
        
        return output
    }
    
    /// Parse lsof output into PortInfo array.
    private func parseLsofOutput(_ output: String) throws -> [PortInfo] {
        var ports: [PortInfo] = []
        let lines = output.components(separatedBy: .newlines).filter { !$0.isEmpty }
        
        for (index, line) in lines.enumerated() {
            if index == 0 {
                continue // Skip header line
            }
            
            // Expected format: COMMAND   PID   USER   FD   TYPE             DEVICE SIZE/OFF NODE NAME
            // Sample: ControlCe   617 mohana    9u  IPv4 0xb933088e65555510      0t0  TCP *:7000 (LISTEN)
            
            // Split by whitespace to get columns
            let columns = line.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
            
            guard columns.count >= 2 else {
                logger.warning("Skipping malformed line: \(line)")
                continue
            }
            
            let command = columns[0]
            guard let pid = Int(columns[1]) else {
                logger.warning("Failed to parse PID from line: \(line)")
                continue
            }
            
            let user = columns[2]
            
            // Find the NODE column which contains the port info (last column before NAME)
            // Look for pattern like "*:7000 (LISTEN)" or "[::1]:42050 (LISTEN)"
            var port: Int = 0
            for column in columns {
                if column.contains(")") && column.contains(":") {
                    // Extract port number from pattern like "*:7000 (LISTEN)" or "[::1]:42050 (LISTEN)"
                    // Remove the LISTEN parenthetical part first
                    let portAndAddr = column.replacingOccurrences(of: #" \([^)]*\)"#, with: "", options: .regularExpression)
                    
                    // Extract port from pattern like "*:7000" or "[::1]:42050"
                    if let colonRange = portAndAddr.range(of: ":") {
                        let afterColon = portAndAddr[colonRange.upperBound...]
                        // Get everything up to the next space or end
                        let portStr = afterColon.prefix(while: { $0 != " " })
                        port = Int(portStr) ?? 0
                    }
                    break
                }
            }
            
            guard port > 0 else {
                logger.warning("Failed to parse port from line: \(line)")
                continue
            }
            
            let portInfo = PortInfo(
                port: port,
                portProtocol: .tcp,
                pid: pid,
                processName: command,
                appName: nil,
                bundleID: nil,
                executablePath: nil,
                isSystemProcess: isSystemUser(user)
            )
            
            ports.append(portInfo)
        }
        
        return ports
    }
    
    /// Check if the user is a system user.
    private func isSystemUser(_ user: String) -> Bool {
        let systemUsers = ["root", "_windowserver", "_mbsetupuser", "_spotlight"]
        return systemUsers.contains(user)
    }
}

enum PortScannerError: LocalizedError {
    case invalidOutput
    case commandFailed(status: Int32)
    
    var errorDescription: String? {
        switch self {
        case .invalidOutput:
            return "Invalid output from lsof command"
        case .commandFailed(let status):
            return "lsof command failed with status: \(status)"
        }
    }
}
