import Foundation

/// Service for tracking port history to distinguish between temporary and long-running services
public class PortHistoryTracker {
    
    private let userDefaults: UserDefaults
    private let historyKey = "portHistory"
    private let lastScanKey = "lastPortScan"
    
    /// Enable/disable history tracking (user preference)
    var isEnabled: Bool {
        get {
            userDefaults.bool(forKey: "portHistoryEnabled")
        }
        set {
            userDefaults.set(newValue, forKey: "portHistoryEnabled")
        }
    }
    
    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }
    
    /// Record port history for the current scan
    func recordPorts(_ ports: [PortInfo]) {
        guard isEnabled else { return }
        
        let timestamp = Date()
        let scanData = ports.map { port in
            PortHistoryEntry(
                port: port.port,
                processName: port.processName,
                pid: port.pid,
                timestamp: timestamp
            )
        }
        
        var history = loadHistory()
        history.append(scanData)
        
        history = cleanOldHistory(history, maxAge: 30 * 24 * 60 * 60)
        
        if let data = try? JSONEncoder().encode(history) {
            userDefaults.set(data, forKey: historyKey)
        }
        
        userDefaults.set(timestamp, forKey: lastScanKey)
    }
    
    /// Check if a port is commonly seen (suggests a permanent service)
    func isCommonPort(_ port: Int, threshold: Int = 5) -> Bool {
        guard isEnabled else { return false }
        
        let history = loadHistory()
        let portOccurrences = history.flatMap { $0 }.filter { $0.port == port }.count
        return portOccurrences >= threshold
    }
    
    /// Check if a port has been seen recently (within last 24 hours)
    func hasSeenRecently(_ port: Int, within: TimeInterval = 24 * 60 * 60) -> Bool {
        guard isEnabled else { return false }
        
        let history = loadHistory()
        let cutoffDate = Date().addingTimeInterval(-within)
        
        return history.contains { scan in
            scan.contains { entry in
                entry.port == port && entry.timestamp >= cutoffDate
            }
        }
    }
    
    /// Get the average uptime for a port (estimates how long it typically runs)
    func getAverageUptime(for port: Int) -> TimeInterval? {
        guard isEnabled else { return nil }
        
        let history = loadHistory()
        let portEntries = history.flatMap { $0 }.filter { $0.port == port }
        
        guard portEntries.count >= 2 else { return nil }
        
        let intervals = zip(portEntries.dropLast(), portEntries.dropFirst()).map { entry1, entry2 in
            entry2.timestamp.timeIntervalSince(entry1.timestamp)
        }
        
        return intervals.reduce(0, +) / Double(intervals.count)
    }
    
    /// Clear all history data
    func clearHistory() {
        userDefaults.removeObject(forKey: historyKey)
        userDefaults.removeObject(forKey: lastScanKey)
    }
    
    /// Load history from UserDefaults
    private func loadHistory() -> [[PortHistoryEntry]] {
        guard let data = userDefaults.data(forKey: historyKey),
              let history = try? JSONDecoder().decode([[PortHistoryEntry]].self, from: data) else {
            return []
        }
        return history
    }
    
    /// Remove history entries older than specified max age
    private func cleanOldHistory(_ history: [[PortHistoryEntry]], maxAge: TimeInterval) -> [[PortHistoryEntry]] {
        let cutoffDate = Date().addingTimeInterval(-maxAge)
        return history.compactMap { scan -> [PortHistoryEntry]? in
            let filtered = scan.filter { $0.timestamp >= cutoffDate }
            return filtered.isEmpty ? nil : filtered
        }
    }
}

/// Port history entry for tracking
private struct PortHistoryEntry: Codable, Sendable {
    let port: Int
    let processName: String
    let pid: Int
    let timestamp: Date
}
