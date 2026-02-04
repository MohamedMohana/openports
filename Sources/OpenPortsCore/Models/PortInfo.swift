import Foundation

/// Safety level for ports to help users make informed decisions about killing processes
public enum PortSafety: String, Sendable, Equatable, CaseIterable {
    /// Critical system services that should not be killed (SSH, HTTP, HTTPS, core macOS processes)
    case critical = "Critical"
    
    /// Important services that may need restart after killing (databases, production servers)
    case important = "Important"
    
    /// Optional applications and services that can be safely killed (user apps, non-essential services)
    case optional = "Optional"
    
    /// Clearly user-created/development servers (npm start, python manage.py, etc.)
    case userCreated = "User-Created"
    
    /// Icon emoji for this safety level
    public var icon: String {
        switch self {
        case .critical: return "🔴"
        case .important: return "🟠"
        case .optional: return "🟢"
        case .userCreated: return "🔵"
        }
    }
    
    /// Color for this safety level (hex code)
    public var color: String {
        switch self {
        case .critical: return "#F44336"
        case .important: return "#FF9800"
        case .optional: return "#4CAF50"
        case .userCreated: return "#2196F3"
        }
    }
    
    /// Warning message when user tries to kill a process with this safety level
    public var warningMessage: String? {
        switch self {
        case .critical:
            return "This is a critical system service. Killing it may cause system instability or network issues."
        case .important:
            return "This is an important service. Killing it may require a restart of dependent applications."
        case .optional:
            return nil
        case .userCreated:
            return "This appears to be a user-created development server. Safe to close."
        }
    }
}

/// Represents information about an open port and its associated process.
public struct PortInfo: Identifiable, Sendable, Equatable {
    public let id = UUID()
    
    /// Port number
    public let port: Int
    
    /// Protocol (TCP or UDP)
    public let portProtocol: PortProtocol
    
    /// Process ID
    public let pid: Int
    
    /// Process name
    public let processName: String
    
    /// Application display name (if available from NSRunningApplication)
    public let appName: String?
    
    /// Bundle identifier (if available)
    public let bundleID: String?
    
    /// Path to executable
    public let executablePath: String?
    
    /// Whether this is a system/root process
    public let isSystemProcess: Bool
    
    /// Safety level of this port (helps users decide if they should kill it)
    public let safety: PortSafety?

    /// How long process has been running (in seconds)
    public let uptime: TimeInterval?

    /// Whether process was started recently (< 5 minutes ago)
    public let isNew: Bool

    /// Main initializer with all parameters
    public init(
        port: Int,
        portProtocol: PortProtocol,
        pid: Int,
        processName: String,
        appName: String?,
        bundleID: String?,
        executablePath: String?,
        isSystemProcess: Bool,
        safety: PortSafety?,
        uptime: TimeInterval?,
        isNew: Bool
    ) {
        self.port = port
        self.portProtocol = portProtocol
        self.pid = pid
        self.processName = processName
        self.appName = appName
        self.bundleID = bundleID
        self.executablePath = executablePath
        self.isSystemProcess = isSystemProcess
        self.safety = safety
        self.uptime = uptime
        self.isNew = isNew
    }

    /// Convenience initializer for backward compatibility
    public init(
        port: Int,
        portProtocol: PortProtocol,
        pid: Int,
        processName: String,
        appName: String?,
        bundleID: String?,
        executablePath: String?,
        isSystemProcess: Bool
    ) {
        self.port = port
        self.portProtocol = portProtocol
        self.pid = pid
        self.processName = processName
        self.appName = appName
        self.bundleID = bundleID
        self.executablePath = executablePath
        self.isSystemProcess = isSystemProcess
        self.safety = nil
        self.uptime = nil
        self.isNew = false
    }
    
    public enum PortProtocol: String, Sendable {
        case tcp = "TCP"
        case udp = "UDP"
    }
    
    /// Display name for the process (use appName if available, otherwise processName)
    public var displayName: String {
        appName ?? processName
    }
    
    /// Display location indicator (app path if available, otherwise executable path)
    public var displayPath: String? {
        executablePath
    }
    
    /// Formatted uptime string
    public var formattedUptime: String? {
        guard let uptime = uptime else { return nil }
        
        if uptime < 60 {
            return "\(Int(uptime))s"
        } else if uptime < 3600 {
            return "\(Int(uptime / 60))m"
        } else if uptime < 86400 {
            return "\(Int(uptime / 3600))h"
        } else {
            return "\(Int(uptime / 86400))d"
        }
    }
}

/// Represents the result of a port scan operation
public struct PortScanResult: Sendable, Equatable {
    /// List of discovered ports
    public let ports: [PortInfo]
    
    /// Whether scan completed successfully
    public let success: Bool
    
    /// Error message if scan failed
    public let error: String?
    
    public static let success = PortScanResult(ports: [], success: true, error: nil)
    
    public static func failure(_ error: String) -> PortScanResult {
        PortScanResult(ports: [], success: false, error: error)
    }
}
