import Foundation

/// Categories for port sources
public enum PortCategory: String, Sendable, CaseIterable {
    case development = "Development"
    case database = "Database"
    case webBrowser = "Web Browser"
    case system = "System"
    case communication = "Communication"
    case media = "Media"
    case network = "Network"
    case other = "Other"
    
    /// Icon emoji for this category
    public var icon: String {
        switch self {
        case .development: return "💻"
        case .database: return "🗄️"
        case .webBrowser: return "🌐"
        case .system: return "⚙️"
        case .communication: return "💬"
        case .media: return "🎵"
        case .network: return "🔌"
        case .other: return "📦"
        }
    }
    
    /// Color for this category (for future UI use)
    public var color: String {
        switch self {
        case .development: return "#4CAF50"
        case .database: return "#FF9800"
        case .webBrowser: return "#2196F3"
        case .system: return "#9E9E9E"
        case .communication: return "#E91E63"
        case .media: return "#9C27B0"
        case .network: return "#00BCD4"
        case .other: return "#607D8B"
        }
    }
}

/// Enhanced port information with category and project detection
public struct CategorizedPortInfo {
    public let portInfo: PortInfo
    public let category: PortCategory
    public let projectName: String?
    public let technology: String?
}

/// Service for categorizing ports and detecting project names
public class PortCategorizer {
    
    public init() {}
    private let developmentTools: Set<String> = [
        "python", "python3", "python3.9", "python3.10", "python3.11", "python3.12",
        "node", "nodejs", "npm", "pnpm", "yarn",
        "ruby", "irb", "gem",
        "php", "php-fpm",
        "java", "javac",
        "go", "gofmt", "gopls",
        "rustc", "cargo",
        "dart", "flutter",
        "dotnet", "mono",
        "julia", "racket", "haskell-stack"
    ]
    
    private let databases: Set<String> = [
        "postgres", "postgresql", "postgres: server",
        "mysql", "mysqld",
        "mariadb",
        "redis-server", "redis",
        "mongodb", "mongod",
        "sqlite", "sqlite3",
        "cassandra",
        "elasticsearch",
        "influxdb"
    ]
    
    private let webBrowsers: Set<String> = [
        "chrome", "google chrome", "chromium",
        "safari",
        "firefox",
        "microsoft edge", "msedge",
        "opera",
        "brave"
    ]
    
    private let communication: Set<String> = [
        "slack",
        "discord",
        "teams",
        "zoom",
        "skype",
        "telegram",
        "whatsapp"
    ]
    
    private let media: Set<String> = [
        "spotify",
        "vlc",
        "music",
        "itunes",
        "quicktime player"
    ]
    
    private let network: Set<String> = [
        "ssh", "sshd",
        "nginx", "apache", "httpd",
        "docker", "docker-desktop",
        "kubernetes", "kubectl",
        "minikube",
        "virtualbox", "vmware",
        "wireshark",
        "tailscale", "wireguard"
    ]
    
    private let systemProcesses: Set<String> = [
        "launchd", "launchctl", "launchd: helper",
        "kernel_task", "kernel",
        "distnoted", "mDNSResponder",
        "syslogd", "logd",
        "configd", "notifyd",
        " Spotlight", "mds",
        "Terminal", "Finder"
    ]
    
    /// Categorize a port based on its process information
    public func categorize(_ port: PortInfo) -> CategorizedPortInfo {
        let category = determineCategory(port)
        let projectName = detectProjectName(port)
        let technology = detectTechnology(port)
        
        return CategorizedPortInfo(
            portInfo: port,
            category: category,
            projectName: projectName,
            technology: technology
        )
    }
    
    private func determineCategory(_ port: PortInfo) -> PortCategory {
        let processName = port.processName.lowercased()
        
        // Check development tools
        if developmentTools.contains(processName) || processName.contains("python") || processName.contains("node") || processName.contains("ruby") || processName.contains("php") || processName.contains("java") || processName.contains("go") || processName.contains("cargo") {
            return .development
        }
        
        // Check databases
        if databases.contains(processName) || processName.contains("postgres") || processName.contains("mysql") || processName.contains("redis") || processName.contains("mongo") {
            return .database
        }
        
        // Check web browsers
        if webBrowsers.contains(processName) || processName.contains("chrome") || processName.contains("safari") || processName.contains("firefox") {
            return .webBrowser
        }
        
        // Check communication
        if communication.contains(processName) || processName.contains("slack") || processName.contains("discord") || processName.contains("teams") {
            return .communication
        }
        
        // Check media
        if media.contains(processName) || processName.contains("spotify") || processName.contains("vlc") {
            return .media
        }
        
        // Check network
        if network.contains(processName) || processName.contains("nginx") || processName.contains("apache") || processName.contains("docker") {
            return .network
        }
        
        // Check system processes
        if systemProcesses.contains(processName) || port.isSystemProcess {
            return .system
        }
        
        return .other
    }
    
    /// Detect project name from executable path
    private func detectProjectName(_ port: PortInfo) -> String? {
        guard let path = port.executablePath else { return nil }
        
        let url = URL(fileURLWithPath: path)
        var components = url.pathComponents
        
        // Remove the filename
        if !components.isEmpty {
            components.removeLast()
        }
        
        // Look for common project indicators
        if let lastComponent = components.last {
            // Python projects
            if port.processName.contains("python") || port.processName.contains("manage.py") {
                return lastComponent
            }
            
            // Node.js projects
            if lastComponent == "node_modules" && components.count > 1 {
                return components[components.count - 2]
            }
            
            // Generic: check if parent directory looks like a project name
            // (not too short, not a generic system path)
            if lastComponent.count > 2 && !lastComponent.hasPrefix(".") {
                let genericPaths = ["usr", "bin", "local", "opt", "Applications", "Library", "System"]
                if !genericPaths.contains(lastComponent) {
                    return lastComponent
                }
            }
        }
        
        // Try to extract from bundle ID
        if let bundleID = port.bundleID {
            let parts = bundleID.split(separator: ".")
            if parts.count > 2 {
                return String(parts[parts.count - 2])
            }
        }
        
        return nil
    }
    
    /// Detect the specific technology being used
    private func detectTechnology(_ port: PortInfo) -> String? {
        let processName = port.processName.lowercased()
        
        if processName.contains("python") || processName.contains("django") || processName.contains("flask") {
            return "Python"
        }
        if processName.contains("node") || processName.contains("npm") || processName.contains("next") {
            return "Node.js"
        }
        if processName.contains("ruby") || processName.contains("rails") {
            return "Ruby"
        }
        if processName.contains("php") || processName.contains("laravel") || processName.contains("wordpress") {
            return "PHP"
        }
        if processName.contains("java") || processName.contains("spring") || processName.contains("tomcat") {
            return "Java"
        }
        if processName.contains("go") || processName.contains("golang") {
            return "Go"
        }
        if processName.contains("cargo") || processName.contains("rustc") {
            return "Rust"
        }
        if processName.contains("dart") || processName.contains("flutter") {
            return "Dart"
        }
        if processName.contains("dotnet") || processName.contains("mono") {
            return ".NET"
        }
        if processName.contains("postgres") {
            return "PostgreSQL"
        }
        if processName.contains("mysql") || processName.contains("maria") {
            return "MySQL"
        }
        if processName.contains("redis") {
            return "Redis"
        }
        if processName.contains("mongo") {
            return "MongoDB"
        }
        if processName.contains("chrome") {
            return "Chrome"
        }
        if processName.contains("safari") {
            return "Safari"
        }
        if processName.contains("firefox") {
            return "Firefox"
        }
        if processName.contains("nginx") {
            return "Nginx"
        }
        if processName.contains("apache") {
            return "Apache"
        }
        if processName.contains("docker") {
            return "Docker"
        }
        
        return nil
    }
    
    /// Group ports by category
    public func groupByCategory(_ ports: [PortInfo]) -> [PortCategory: [PortInfo]] {
        let categorized = ports.map { categorize($0) }
        var grouped: [PortCategory: [PortInfo]] = [:]
        
        for categorizedPort in categorized {
            if grouped[categorizedPort.category] == nil {
                grouped[categorizedPort.category] = []
            }
            grouped[categorizedPort.category]?.append(categorizedPort.portInfo)
        }
        
        return grouped
    }
}
