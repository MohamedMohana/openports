import Foundation
import Logging

/// Service for scanning open ports on the system using `lsof`.
public actor PortScanner {
    public init() {
    }
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
            "-sTCP:LISTEN"    // Listening TCP ports only
        ]

        let outputPipe = Pipe()
        let errorPipe = Pipe()
        process.standardOutput = outputPipe
        process.standardError = errorPipe

        logger.debug("Executing lsof command: \(lsofPath) \(process.arguments?.joined(separator: " ") ?? "")")

        try process.run()
        process.waitUntilExit()

        let data = outputPipe.fileHandleForReading.readDataToEndOfFile()
        let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()

        if let errorOutput = String(data: errorData, encoding: .utf8), !errorOutput.isEmpty {
            logger.warning("lsof stderr: \(errorOutput)")
        }

        guard let output = String(data: data, encoding: .utf8) else {
            throw PortScannerError.invalidOutput
        }

        if process.terminationStatus != 0 {
            logger.error("lsof failed with status \(process.terminationStatus)")
            throw PortScannerError.commandFailed(status: process.terminationStatus)
        }

        logger.debug("lsof output: \(output.count) characters")
        return output
    }
    
    /// Parse lsof output into PortInfo array.
    /// Expected lsof format: COMMAND PID USER FD TYPE DEVICE SIZE/OFF NODE NAME
    /// Example: ControlCe 617 mohana 9u IPv4 0x... 0t0 TCP *:7000 (LISTEN)
    private func parseLsofOutput(_ output: String) throws -> [PortInfo] {
        var ports: [PortInfo] = []
        let lines = output.components(separatedBy: .newlines).filter { !$0.isEmpty }

        logger.debug("Parsing \(lines.count) lines from lsof output")

        for (index, line) in lines.enumerated() {
            // Skip header line
            if index == 0 || line.hasPrefix("COMMAND") {
                continue
            }

            let parsedPort = parseLsofLine(line)
            if let port = parsedPort {
                ports.append(port)
            }
        }

        logger.info("Successfully parsed \(ports.count) ports from lsof output")
        return ports
    }

    /// Parse a single line of lsof output.
    /// The NAME column can contain spaces like "127.0.0.1:8080 (LISTEN)",
    /// so we need to reconstruct it from the last columns.
    private func parseLsofLine(_ line: String) -> PortInfo? {
        // Split by whitespace to get columns
        let columns = line.components(separatedBy: .whitespaces).filter { !$0.isEmpty }

        // Minimum columns needed: COMMAND, PID, USER, FD, TYPE, DEVICE, SIZE/OFF, NODE, NAME...
        // NAME can span multiple columns due to spaces like "127.0.0.1:8080 (LISTEN)"
        guard columns.count >= 8 else {
            logger.warning("Line has insufficient columns (\(columns.count)): \(line)")
            return nil
        }

        let command = columns[0]

        guard let pid = Int(columns[1]) else {
            logger.warning("Failed to parse PID from: \(columns[1])")
            return nil
        }

        let user = columns[2]

        // Reconstruct NAME column from columns 8 onwards (it may contain spaces)
        // lsof columns: COMMAND(0) PID(1) USER(2) FD(3) TYPE(4) DEVICE(5) SIZE/OFF(6) NODE(7) NAME(8+)
        let nameParts = columns[8...]
        let nameColumn = nameParts.joined(separator: " ")

        // Parse port from patterns like "*:7000" or "[::1]:42050" or "127.0.0.1:8080"
        guard let port = extractPort(from: nameColumn) else {
            logger.warning("Failed to extract port from: \(nameColumn)")
            return nil
        }

        return PortInfo(
            port: port,
            portProtocol: .tcp,
            pid: pid,
            processName: command,
            appName: nil,
            bundleID: nil,
            executablePath: nil,
            isSystemProcess: isSystemUser(user)
        )
    }

    /// Extract port number from lsof NAME column.
    /// Handles patterns: *:7000, [::1]:42050, 127.0.0.1:8080
    /// Also handles formats with (LISTEN) suffix
    private func extractPort(from nameColumn: String) -> Int? {
        // Remove "(LISTEN)" suffix if present
        let cleaned = nameColumn
            .replacingOccurrences(of: #"\s*\([^)]*\)$"#, with: "", options: .regularExpression)
            .trimmingCharacters(in: .whitespaces)

        // Find the last colon and extract port
        guard let lastColonIndex = cleaned.lastIndex(of: ":") else {
            return nil
        }

        let portString = String(cleaned[cleaned.index(after: lastColonIndex)...])
            .trimmingCharacters(in: .whitespaces)

        // Validate port is numeric and in valid range
        guard let port = Int(portString), port > 0 && port <= 65535 else {
            return nil
        }

        return port
    }

    /// Check if the user is a system user.
    private func isSystemUser(_ user: String) -> Bool {
        let systemUsers = ["root", "_windowserver", "_mbsetupuser", "_spotlight", "_coreaudiod", "_locationd"]
        return systemUsers.contains(user) || user.hasPrefix("_")
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
