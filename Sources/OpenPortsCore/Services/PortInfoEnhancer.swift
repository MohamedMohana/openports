import Foundation
import Logging

/// Service for enhancing port information with safety, uptime, and other metadata
public actor PortInfoEnhancer {
    private let logger = Logger(label: "com.openports.portinfoenhancer")
    private let safetyAnalyzer: PortSafetyAnalyzer
    private let userDefaults: UserDefaults

    public init(safetyAnalyzer: PortSafetyAnalyzer = PortSafetyAnalyzer(), userDefaults: UserDefaults = .standard) {
        self.safetyAnalyzer = safetyAnalyzer
        self.userDefaults = userDefaults
    }

    /// Enhance port info with safety level, uptime, and other metadata
    public func enhance(_ ports: [PortInfo]) async -> [PortInfo] {
        var enhancedPorts: [PortInfo] = []

        for port in ports {
            let startTime = await getProcessStartTime(pid: port.pid)
            let uptime = startTime.map { Date().timeIntervalSince($0) }
            let isNew = uptime.map { $0 < 300 } ?? false

            let enhancedPort = PortInfo(
                port: port.port,
                portProtocol: port.portProtocol,
                pid: port.pid,
                processName: port.processName,
                appName: port.appName,
                bundleID: port.bundleID,
                executablePath: port.executablePath,
                isSystemProcess: port.isSystemProcess,
                safety: port.safety ?? safetyAnalyzer.analyze(port),
                uptime: uptime ?? port.uptime,
                isNew: isNew || port.isNew,
            )

            enhancedPorts.append(enhancedPort)
        }

        logger.info("Enhanced \(enhancedPorts.count) ports with metadata")
        return enhancedPorts
    }

    /// Get the start time of a process using the `ps` command.
    private func getProcessStartTime(pid: Int) async -> Date? {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/ps")
        process.arguments = ["-p", String(pid), "-o", "lstart="]

        let outputPipe = Pipe()
        let errorPipe = Pipe()
        process.standardOutput = outputPipe
        process.standardError = errorPipe

        do {
            try process.run()
            process.waitUntilExit()

            let data = outputPipe.fileHandleForReading.readDataToEndOfFile()
            guard let output = String(data: data, encoding: .utf8),
                  !output.isEmpty
            else {
                return nil
            }

            return Self.parseProcessStartTime(output)
        } catch {
            logger.debug("Failed to get start time for PID \(pid): \(error.localizedDescription)")
            return nil
        }
    }

    /// Parse the output of `ps -o lstart=`, e.g. "Sat Jul  4 04:09:00 2026".
    /// `ps` pads single-digit days with an extra space, so runs of spaces are
    /// collapsed before parsing with a single-digit-tolerant day format.
    static func parseProcessStartTime(_ output: String) -> Date? {
        let trimmed = output.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        let normalized = trimmed
            .split(separator: " ", omittingEmptySubsequences: true)
            .joined(separator: " ")

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "EEE MMM d HH:mm:ss yyyy"

        return formatter.date(from: normalized)
    }
}
