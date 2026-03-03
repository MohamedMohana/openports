import Foundation

/// Export format options
public enum ExportFormat: String, CaseIterable, Sendable {
    case csv = "CSV"
    case json = "JSON"
    case markdown = "Markdown"
    
    public var fileExtension: String {
        switch self {
        case .csv: return "csv"
        case .json: return "json"
        case .markdown: return "md"
        }
    }
    
    public var mimeType: String {
        switch self {
        case .csv: return "text/csv"
        case .json: return "application/json"
        case .markdown: return "text/markdown"
        }
    }
    
    public var displayName: String {
        switch self {
        case .csv: return "CSV (Excel-compatible)"
        case .json: return "JSON (Developer-friendly)"
        case .markdown: return "Markdown (Documentation)"
        }
    }
}

/// Service for exporting port data to various formats
public actor PortExporter {
    public init() {}
    
    /// Export ports to the specified format
    public func export(ports: [PortInfo], format: ExportFormat) -> String {
        switch format {
        case .csv:
            return exportCSV(ports)
        case .json:
            return exportJSON(ports)
        case .markdown:
            return exportMarkdown(ports)
        }
    }
    
    /// Export to CSV format (Excel-compatible)
    private func exportCSV(_ ports: [PortInfo]) -> String {
        var csv = "Port,Protocol,Process Name,PID,App Name,Safety Level,Age,Uptime,Category,Technology,Project,System Process\n"
        
        let categorizer = PortCategorizer()
        
        for port in ports {
            let categorized = categorizer.categorize(port)
            let category = categorized.category.rawValue
            let technology = categorized.technology ?? ""
            let project = categorized.projectName ?? ""
            
            let row = [
                "\(port.port)",
                port.portProtocol.rawValue,
                escapeCSV(port.processName),
                "\(port.pid)",
                escapeCSV(port.appName ?? ""),
                port.safety?.rawValue ?? "Unknown",
                port.age.rawValue,
                port.formattedUptime ?? "",
                escapeCSV(category),
                escapeCSV(technology),
                escapeCSV(project),
                port.isSystemProcess ? "Yes" : "No"
            ].joined(separator: ",")
            
            csv += row + "\n"
        }
        
        return csv
    }
    
    /// Export to JSON format (pretty-printed)
    private func exportJSON(_ ports: [PortInfo]) -> String {
        let categorizer = PortCategorizer()
        
        let exportData = ports.map { port -> [String: Any] in
            let categorized = categorizer.categorize(port)
            
            return [
                "port": port.port,
                "protocol": port.portProtocol.rawValue,
                "process": [
                    "name": port.processName,
                    "pid": port.pid,
                    "appName": port.appName ?? "",
                    "bundleId": port.bundleID ?? "",
                    "path": port.executablePath ?? ""
                ],
                "safety": [
                    "level": port.safety?.rawValue ?? "Unknown",
                    "icon": port.safety?.icon ?? ""
                ],
                "age": [
                    "category": port.age.rawValue,
                    "icon": port.age.icon,
                    "uptime": port.formattedUptime ?? "Unknown"
                ],
                "category": categorized.category.rawValue,
                "technology": categorized.technology ?? "",
                "project": categorized.projectName ?? "",
                "isSystemProcess": port.isSystemProcess
            ]
        }
        
        let root: [String: Any] = [
            "exportedAt": ISO8601DateFormatter().string(from: Date()),
            "totalCount": ports.count,
            "ports": exportData
        ]
        
        guard let jsonData = try? JSONSerialization.data(withJSONObject: root, options: .prettyPrinted),
              let jsonString = String(data: jsonData, encoding: .utf8) else {
            return "{}"
        }
        
        return jsonString
    }
    
    /// Export to Markdown format (documentation-friendly)
    private func exportMarkdown(_ ports: [PortInfo]) -> String {
        var md = "# OpenPorts Export\n\n"
        md += "**Exported**: \(Date().formatted(date: .long, time: .shortened))\n"
        md += "**Total Ports**: \(ports.count)\n\n"
        md += "---\n\n"
        
        let categorizer = PortCategorizer()
        
        // Group by age
        let groupedByAge = Dictionary(grouping: ports, by: { $0.age })
            .sorted { $0.key.sortOrder < $1.key.sortOrder }
        
        for (age, portsInAge) in groupedByAge {
            md += "## \(age.icon) \(age.rawValue) (\(portsInAge.count))\n\n"
            
            for port in portsInAge {
                let categorized = categorizer.categorize(port)
                
                md += "### :\(port.port) - \(port.displayName)\n\n"
                md += "| Property | Value |\n"
                md += "|----------|-------|\n"
                md += "| **Protocol** | \(port.portProtocol.rawValue) |\n"
                md += "| **PID** | \(port.pid) |\n"
                md += "| **Safety** | \(port.safety?.icon ?? "") \(port.safety?.rawValue ?? "Unknown") |\n"
                md += "| **Age** | \(port.age.icon) \(port.age.description) |\n"
                md += "| **Uptime** | \(port.formattedUptime ?? "Unknown") |\n"
                md += "| **Category** | \(categorized.category.icon) \(categorized.category.rawValue) |\n"
                
                if let tech = categorized.technology {
                    md += "| **Technology** | \(tech) |\n"
                }
                
                if let project = categorized.projectName {
                    md += "| **Project** | \(project) |\n"
                }
                
                md += "| **System Process** | \(port.isSystemProcess ? "Yes" : "No") |\n"
                md += "\n"
            }
            
            md += "---\n\n"
        }
        
        md += "\n*Generated by [OpenPorts](https://github.com/MohamedMohana/openports) - Smart Port Monitoring for Mac Developers*\n"
        
        return md
    }
    
    /// Escape CSV special characters
    private func escapeCSV(_ field: String) -> String {
        if field.contains(",") || field.contains("\"") || field.contains("\n") {
            return "\"" + field.replacingOccurrences(of: "\"", with: "\"\"") + "\""
        }
        return field
    }
    
    /// Save export to file
    public func saveToFile(_ content: String, filename: String, format: ExportFormat) -> URL? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        let timestamp = dateFormatter.string(from: Date())
        
        let fileName = "openports-export-\(timestamp).\(format.fileExtension)"
        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent(fileName)
        
        do {
            try content.write(to: fileURL, atomically: true, encoding: .utf8)
            return fileURL
        } catch {
            print("Failed to save export: \(error)")
            return nil
        }
    }
}
