import Foundation

/// Service for analyzing and determining the safety level of open ports
public class PortSafetyAnalyzer {
    
    private let knowledgeBase = PortKnowledgeBase()
    
    /// Common development server ports
    private let devServerPorts: Set<Int> = [
        3000, 3001, 4000, 5000, 8000, 8080, 8081, 9000, 4200, 5173, 5174
    ]
    
    /// Common database ports
    private let databasePorts: Set<Int> = [
        3306, 5432, 6379, 27017, 27018, 27019, 5672, 1521, 9042, 11211, 9200
    ]
    
    /// Critical system and network ports
    private let criticalPorts: Set<Int> = [
        22, 80, 443, 53, 67, 68, 123, 161, 631, 445, 139, 88, 389, 636
    ]
    
    /// Processes that indicate user-created development servers
    private let devServerProcesses: Set<String> = [
        "npm", "node", "nodejs", "yarn", "pnpm", "npx",
        "python", "python3", "python3.9", "python3.10", "python3.11", "python3.12", "pip",
        "manage.py", "gunicorn", "uvicorn", "django-admin",
        "ruby", "gem", "bundle", "rackup", "rails",
        "go", "go run", "dlv", "air", "realize",
        "cargo", "rustc", "rustup",
        "php", "php-fpm", "composer",
        "java", "javac", "gradle", "maven"
    ]
    
    /// Process names that indicate critical system services
    private let criticalProcessNames: Set<String> = [
        "sshd", "launchd", "mDNSResponder", "kernel_task",
        "syslogd", "logd", "configd", "notifyd",
        "Spotlight", "mds", "WindowServer", "Dock",
        "Finder", "loginwindow", "coreaudiod", "distnoted"
    ]
    
    /// Bundle ID prefixes for system processes
    private let systemBundlePrefixes: Set<String> = [
        "com.apple.", "com.apple.coreservices."
    ]
    
    public init() {}
    
    /// Analyze a port and determine its safety level
    public func analyze(_ port: PortInfo) -> PortSafety {
        let isNew = port.isNew
        let uptime = port.uptime ?? 0

        if isCritical(port) {
            return .critical
        }

        if isImportant(port) {
            return .important
        }

        if isUserCreated(port, isNew: isNew, uptime: uptime) {
            return .userCreated
        }

        return .optional
    }
    
    /// Check if port is critical (system services that should not be killed)
    private func isCritical(_ port: PortInfo) -> Bool {
        if criticalPorts.contains(port.port) {
            return true
        }
        
        if criticalProcessNames.contains(port.processName.lowercased()) {
            return true
        }
        
        if let bundleID = port.bundleID {
            for prefix in systemBundlePrefixes {
                if bundleID.hasPrefix(prefix) {
                    return true
                }
            }
        }
        
        if let path = port.executablePath {
            let systemPaths = ["/System/", "/usr/sbin/", "/usr/bin/", "/sbin/"]
            for systemPath in systemPaths {
                if path.hasPrefix(systemPath) {
                    return true
                }
            }
        }
        
        return false
    }
    
    /// Check if port is important (databases, production servers)
    private func isImportant(_ port: PortInfo) -> Bool {
        if databasePorts.contains(port.port) {
            return true
        }
        
        let processName = port.processName.lowercased()
        let importantProcesses = [
            "postgres", "postgresql", "mysql", "mysqld", "mariadb",
            "redis-server", "redis", "mongodb", "mongod",
            "docker", "docker-desktop", "nginx", "apache", "httpd",
            "elasticsearch", "influxdb", "cassandra", "vault"
        ]
        
        for importantProcess in importantProcesses {
            if processName.contains(importantProcess) {
                return true
            }
        }
        
        return false
    }
    
    /// Check if port is user-created (development servers, user apps)
    private func isUserCreated(_ port: PortInfo, isNew: Bool, uptime: TimeInterval) -> Bool {
        let processName = port.processName.lowercased()
        
        for devProcess in devServerProcesses {
            if processName.contains(devProcess) {
                return true
            }
        }
        
        if devServerPorts.contains(port.port) {
            if isNew || uptime < 3600 {
                return true
            }
        }
        
        if let path = port.executablePath {
            let userPaths = ["/Users/", "/home/"]
            for userPath in userPaths {
                if path.hasPrefix(userPath) {
                    return !port.isSystemProcess
                }
            }
        }
        
        return false
    }
    
    /// Get a detailed description of why a port has its safety level
    public func getSafetyDescription(_ port: PortInfo) -> String? {
        let safety = analyze(port)
        
        switch safety {
        case .critical:
            if criticalPorts.contains(port.port) {
                return "Critical network port (port \(port.port))"
            } else if criticalProcessNames.contains(port.processName.lowercased()) {
                return "Core macOS system process"
            } else {
                return "System service required for macOS operation"
            }
            
        case .important:
            if databasePorts.contains(port.port) {
                return "Database server (may cause data loss if killed)"
            } else {
                return "Important service (killing will stop this service)"
            }
            
        case .userCreated:
            if devServerPorts.contains(port.port) {
                return "Development server (safe to close)"
            } else {
                return "User application or service"
            }
            
        case .optional:
            return "Non-essential service or application"
        }
    }
    
    /// Check if a warning should be shown before killing a process
    public func shouldShowWarning(for port: PortInfo, warningLevel: KillWarningLevel) -> Bool {
        let safety = analyze(port)
        
        switch warningLevel {
        case .none:
            return false
        case .highRiskOnly:
            return safety == .critical || safety == .important
        case .all:
            return true
        }
    }
}

/// Warning level preference for kill confirmations
public enum KillWarningLevel: String, Sendable, CaseIterable {
    case none = "None"
    case highRiskOnly = "High Risk Only"
    case all = "All Ports"
    
    public var displayName: String {
        switch self {
        case .none: return "No Warnings"
        case .highRiskOnly: return "High Risk Only"
        case .all: return "All Ports"
        }
    }
}
