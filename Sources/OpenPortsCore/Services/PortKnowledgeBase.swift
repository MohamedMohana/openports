import Foundation

/// Knowledge base containing information about common ports
public class PortKnowledgeBase {
    
    public init() {}
    
    /// Get information about a port
    public func getInfo(for port: Int) -> PortInfo? {
        return portDatabase[port]
    }
    
    /// Check if port is commonly used for development
    public func isDevelopmentPort(_ port: Int) -> Bool {
        guard let info = portDatabase[port] else { return false }
        return info.category == .development
    }
    
    /// Get a description for a port
    public func getDescription(for port: Int) -> String? {
        return portDatabase[port]?.description
    }
    
    /// Get the technology commonly associated with a port
    public func getTechnology(for port: Int) -> String? {
        return portDatabase[port]?.technology
    }
    
    /// Port information structure
    public struct PortInfo {
        let port: Int
        let description: String
        let category: PortCategory
        let technology: String?
        let isCommon: Bool
    }
    
    /// Database of common ports
    private let portDatabase: [Int: PortInfo] = [
        22: PortInfo(port: 22, description: "SSH - Secure Shell", category: .network, technology: "SSH", isCommon: true),
        23: PortInfo(port: 23, description: "Telnet - Insecure remote access", category: .network, technology: "Telnet", isCommon: true),
        25: PortInfo(port: 25, description: "SMTP - Email transmission", category: .network, technology: "SMTP", isCommon: true),
        53: PortInfo(port: 53, description: "DNS - Domain Name System", category: .network, technology: "DNS", isCommon: true),
        80: PortInfo(port: 80, description: "HTTP - Web server", category: .network, technology: "HTTP", isCommon: true),
        110: PortInfo(port: 110, description: "POP3 - Email retrieval", category: .network, technology: "POP3", isCommon: true),
        143: PortInfo(port: 143, description: "IMAP - Email retrieval", category: .network, technology: "IMAP", isCommon: true),
        443: PortInfo(port: 443, description: "HTTPS - Secure web server", category: .network, technology: "HTTPS", isCommon: true),
        445: PortInfo(port: 445, description: "SMB - File sharing", category: .system, technology: "SMB", isCommon: true),
        587: PortInfo(port: 587, description: "SMTP - Email submission", category: .network, technology: "SMTP", isCommon: true),
        631: PortInfo(port: 631, description: "IPP - Printer service", category: .system, technology: "CUPS", isCommon: true),
        993: PortInfo(port: 993, description: "IMAPS - Secure email", category: .network, technology: "IMAPS", isCommon: true),
        995: PortInfo(port: 995, description: "POP3S - Secure email", category: .network, technology: "POP3S", isCommon: true),
        
        3000: PortInfo(port: 3000, description: "Node.js/React dev server", category: .development, technology: "Node.js", isCommon: true),
        3001: PortInfo(port: 3001, description: "Development server alternate", category: .development, technology: "Node.js", isCommon: true),
        4000: PortInfo(port: 4000, description: "Development server", category: .development, technology: "Various", isCommon: true),
        4200: PortInfo(port: 4200, description: "Angular dev server", category: .development, technology: "Angular", isCommon: true),
        5000: PortInfo(port: 5000, description: "Python Flask dev server", category: .development, technology: "Python/Flask", isCommon: true),
        5173: PortInfo(port: 5173, description: "Vite dev server", category: .development, technology: "Vite", isCommon: true),
        5174: PortInfo(port: 5174, description: "Vite dev server (HMR)", category: .development, technology: "Vite", isCommon: true),
        8000: PortInfo(port: 8000, description: "Python Django dev server", category: .development, technology: "Python/Django", isCommon: true),
        8080: PortInfo(port: 8080, description: "Alternate HTTP/Dev server", category: .development, technology: "Various", isCommon: true),
        8081: PortInfo(port: 8081, description: "Alternate dev server", category: .development, technology: "Various", isCommon: true),
        9000: PortInfo(port: 9000, description: "Development server", category: .development, technology: "Various", isCommon: true),
        
        3306: PortInfo(port: 3306, description: "MySQL database", category: .database, technology: "MySQL", isCommon: true),
        5432: PortInfo(port: 5432, description: "PostgreSQL database", category: .database, technology: "PostgreSQL", isCommon: true),
        6379: PortInfo(port: 6379, description: "Redis cache server", category: .database, technology: "Redis", isCommon: true),
        11211: PortInfo(port: 11211, description: "Memcached cache", category: .database, technology: "Memcached", isCommon: true),
        1521: PortInfo(port: 1521, description: "Oracle database", category: .database, technology: "Oracle", isCommon: true),
        27017: PortInfo(port: 27017, description: "MongoDB database", category: .database, technology: "MongoDB", isCommon: true),
        27018: PortInfo(port: 27018, description: "MongoDB shard server", category: .database, technology: "MongoDB", isCommon: true),
        27019: PortInfo(port: 27019, description: "MongoDB config server", category: .database, technology: "MongoDB", isCommon: true),
        9042: PortInfo(port: 9042, description: "Cassandra database", category: .database, technology: "Cassandra", isCommon: true),
        5672: PortInfo(port: 5672, description: "RabbitMQ message broker", category: .database, technology: "RabbitMQ", isCommon: true),
        9200: PortInfo(port: 9200, description: "Elasticsearch HTTP", category: .database, technology: "Elasticsearch", isCommon: true),
        9300: PortInfo(port: 9300, description: "Elasticsearch node", category: .database, technology: "Elasticsearch", isCommon: true),
        
        1434: PortInfo(port: 1434, description: "SQL Server monitor", category: .database, technology: "SQL Server", isCommon: true),
        50000: PortInfo(port: 50000, description: "SQL Server default", category: .database, technology: "SQL Server", isCommon: true),
        54321: PortInfo(port: 54321, description: "PostgreSQL alternate", category: .database, technology: "PostgreSQL", isCommon: true),
        
        1080: PortInfo(port: 1080, description: "SOCKS proxy", category: .network, technology: "SOCKS", isCommon: true),
        3128: PortInfo(port: 3128, description: "Squid proxy", category: .network, technology: "Squid", isCommon: true),
        8088: PortInfo(port: 8088, description: "HTTP proxy", category: .network, technology: "HTTP Proxy", isCommon: true),
        8443: PortInfo(port: 8443, description: "HTTPS alternate", category: .network, technology: "HTTPS", isCommon: true),
        
        2375: PortInfo(port: 2375, description: "Docker daemon", category: .network, technology: "Docker", isCommon: true),
        2376: PortInfo(port: 2376, description: "Docker daemon (TLS)", category: .network, technology: "Docker", isCommon: true),
        6443: PortInfo(port: 6443, description: "Kubernetes API", category: .network, technology: "Kubernetes", isCommon: true),
        10250: PortInfo(port: 10250, description: "Kubelet API", category: .network, technology: "Kubernetes", isCommon: true),
        10255: PortInfo(port: 10255, description: "Kubelet read-only", category: .network, technology: "Kubernetes", isCommon: true),
    ]
}
