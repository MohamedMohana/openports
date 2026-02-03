import Foundation

/// Simple logger that captures recent log messages for debugging
@MainActor
final class AppLogger {
    static let shared = AppLogger()
    
    private(set) var logs: [String] = []
    private let maxLogs = 100
    private let dateFormatter: DateFormatter
    
    init() {
        dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm:ss.SSS"
    }
    
    func log(_ message: String, level: LogLevel = .info) {
        let timestamp = dateFormatter.string(from: Date())
        let logEntry = "[\(timestamp)] [\(level.rawValue)] \(message)"
        
        logs.append(logEntry)
        
        // Keep only recent logs
        if logs.count > maxLogs {
            logs.removeFirst(logs.count - maxLogs)
        }
        
        // Also print to console
        print(logEntry)
    }
    
    func error(_ message: String) {
        log(message, level: .error)
    }
    
    func warning(_ message: String) {
        log(message, level: .warning)
    }
    
    func debug(_ message: String) {
        log(message, level: .debug)
    }
    
    func getLogsText() -> String {
        return logs.joined(separator: "\n")
    }
    
    func clear() {
        logs.removeAll()
    }
}

enum LogLevel: String {
    case debug = "DEBUG"
    case info = "INFO"
    case warning = "WARN"
    case error = "ERROR"
}
