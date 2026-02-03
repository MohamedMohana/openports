import Foundation
import OpenPortsCore

/// Represents a section in the menu.
struct MenuSection {
    var header: String?
    var entries: [MenuEntry]
    
    init(header: String? = nil, entries: [MenuEntry] = []) {
        self.header = header
        self.entries = entries
    }
}

/// Represents an entry in the menu.
enum MenuEntry {
    case text(String, style: MenuEntryStyle)
    case divider
    case portRow(PortInfo)
    case button(String, action: () -> Void)
    case refreshButton
}

enum MenuEntryStyle {
    case header
    case primary
    case secondary
    case warning
    case system
}

/// Descriptor for menu structure.
/// Separates data structure from presentation for testability.
struct MenuDescriptor {
    var sections: [MenuSection]
    
    init(sections: [MenuSection] = []) {
        self.sections = sections
    }
    
    /// Build menu descriptor from current ports and settings.
    func build(
        ports: [PortInfo],
        searchText: String = "",
        showSystemProcesses: Bool = true
    ) -> MenuDescriptor {
        var entries = [MenuEntry]()
        
        // Add refresh button at the top
        entries.append(.refreshButton)
        
        // Add search indicator
        let searchDisplay = searchText.isEmpty ? "Search ports..." : "Filtering: \(searchText)"
        entries.append(.text(searchDisplay, style: .secondary))
        
        // Add divider
        if !ports.isEmpty {
            entries.append(.divider)
            
            // Filter ports based on search text and system process setting
            let filteredPorts = filterPorts(ports, searchText: searchText, showSystemProcesses: showSystemProcesses)
            
            if filteredPorts.isEmpty {
                entries.append(.text("No ports found", style: .secondary))
            } else {
                // Add port rows
                for port in filteredPorts {
                    entries.append(.portRow(port))
                }
            }
        }
        
        return MenuDescriptor(sections: [MenuSection(entries: entries)])
    }
    
    /// Filter ports based on search text and system process setting.
    private func filterPorts(
        _ ports: [PortInfo],
        searchText: String,
        showSystemProcesses: Bool
    ) -> [PortInfo] {
        guard !searchText.isEmpty else { return ports }
        
        let lowerSearchText = searchText.lowercased()
        
        return ports.filter { port in
            // Filter out system processes if disabled
            if !showSystemProcesses && port.isSystemProcess {
                return false
            }
            
            // Apply search filter
            let searchIn = [
                String(port.port),
                port.portProtocol.rawValue.lowercased(),
                port.processName.lowercased(),
                port.displayName.lowercased(),
                port.bundleID?.lowercased() ?? "",
                port.executablePath?.lowercased() ?? ""
            ]
            
            return searchIn.contains { $0.contains(lowerSearchText) }
        }
    }
}
