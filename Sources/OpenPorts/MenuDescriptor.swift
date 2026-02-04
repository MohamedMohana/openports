import Foundation
import OpenPortsCore

/// Categorized port with additional metadata
public struct CategorizedPortDisplay {
    public let portInfo: PortInfo
    public let category: PortCategory?
    public let technology: String?
    public let projectName: String?
}

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
    case portRow(PortInfo, category: PortCategory?, technology: String?, projectName: String?)
    case button(String, action: () -> Void)
    case refreshButton
    case viewLogsButton
                    let menuItem = NSMenuItem(title: "View Logs", action: #selector(StatusItemController.viewLogs), keyEquivalent: "")
                    menuItem.target = self
                    menu?.addItem(menuItem)

                case .preferencesButton:
                    let menuItem = NSMenuItem(title: "Preferences...", action: #selector(StatusItemController.showPreferences), keyEquivalent: ",")
                    menuItem.target = self
                    menu?.addItem(menuItem)
            }
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
        showSystemProcesses: Bool = true,
        errorMessage: String? = nil,
        isLoading: Bool = false,
        groupByCategory: Bool = false
    ) -> MenuDescriptor {
        var entries = [MenuEntry]()
        let categorizer = PortCategorizer()

        // Add refresh button at the top
        entries.append(.refreshButton)

        // Show loading indicator or status
        if isLoading {
            entries.append(.text("Loading...", style: .secondary))
        } else if let error = errorMessage {
            entries.append(.text("Error: \(error)", style: .warning))
        } else {
            // Add search indicator
            let searchDisplay = searchText.isEmpty ? "Search ports..." : "Filtering: \(searchText)"
            entries.append(.text(searchDisplay, style: .secondary))
        }

        // Add divider
        entries.append(.divider)

        // Filter ports based on search text and system process setting
        let filteredPorts = filterPorts(ports, searchText: searchText, showSystemProcesses: showSystemProcesses)

        if !isLoading {
            if let error = errorMessage {
                entries.append(.text("⚠️ \(error)", style: .warning))
                entries.append(.text("Check System Settings > Privacy & Security", style: .secondary))
            } else if filteredPorts.isEmpty {
                entries.append(.text("No open ports found", style: .secondary))
            } else {
                // Add port count
                entries.append(.text("\(filteredPorts.count) open port(s)", style: .header))
                entries.append(.divider)

                if groupByCategory {
                    // Group ports by category
                    let groupedPorts = categorizer.groupByCategory(filteredPorts)
                    let sortedCategories = groupedPorts.keys.sorted { $0.rawValue < $1.rawValue }

                    for category in sortedCategories {
                        if let portsInCategory = groupedPorts[category] {
                            // Add category header
                            entries.append(.text("\(category.icon) \(category.rawValue) - \(portsInCategory.count)", style: .header))
                            entries.append(.divider)

                            // Add port rows in this category
                            for port in portsInCategory {
                                let categorized = categorizer.categorize(port)
                                entries.append(.portRow(port, category: categorized.category, technology: categorized.technology, projectName: categorized.projectName))
                            }
                        }
                    }
                } else {
                    // Add port rows
                    for port in filteredPorts {
                        let categorized = categorizer.categorize(port)
                        entries.append(.portRow(port, category: categorized.category, technology: categorized.technology, projectName: categorized.projectName))
                    }
                }
            }
        }

        // Add view logs button
        entries.append(.divider)
        entries.append(.viewLogsButton)

        return MenuDescriptor(sections: [MenuSection(entries: entries)])
    }
    
    /// Filter ports based on search text and system process setting.
    private func filterPorts(
        _ ports: [PortInfo],
        searchText: String,
        showSystemProcesses: Bool
    ) -> [PortInfo] {
        let lowerSearchText = searchText.lowercased()

        return ports.filter { port in
            // Filter out system processes if disabled
            if !showSystemProcesses && port.isSystemProcess {
                return false
            }

            // If no search text, include all non-system ports (if filtered)
            guard !searchText.isEmpty else { return true }

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
