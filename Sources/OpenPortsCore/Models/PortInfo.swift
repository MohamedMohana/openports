import Foundation

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
