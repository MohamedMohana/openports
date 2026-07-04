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
    case preferencesButton
}

enum MenuEntryStyle {
    case header
    case primary
    case secondary
    case warning
    case system
}

/// Descriptor for menu structure.
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
        groupByCategory: Bool = false,
        groupByProcess: Bool = false,
        lastUpdatedAt _: Date? = nil,
        favoritePorts: Set<Int> = [],
    ) -> MenuDescriptor {
        var entries = [MenuEntry]()

        // Loading, scan freshness, and empty states are rendered by the popover
        // itself from its summary state; the descriptor only carries content rows.
        if isLoading {
            return MenuDescriptor(sections: [MenuSection(entries: entries)])
        }

        if let error = errorMessage {
            entries.append(.text(error, style: .warning))
            entries.append(.text("If scans keep failing, check System Settings › Privacy & Security.", style: .secondary))
            return MenuDescriptor(sections: [MenuSection(entries: entries)])
        }

        let categorizer = PortCategorizer()
        let filteredPorts = filterPorts(ports, searchText: searchText, showSystemProcesses: showSystemProcesses)

        let favoritePortsList = filteredPorts.filter { favoritePorts.contains($0.port) }
        let nonFavoritePorts = filteredPorts.filter { !favoritePorts.contains($0.port) }

        if !favoritePortsList.isEmpty {
            entries.append(.text("Favorites", style: .header))

            for port in favoritePortsList.sorted(by: { $0.port < $1.port }) {
                entries.append(portRowEntry(for: port, categorizer: categorizer))
            }
        }

        if !nonFavoritePorts.isEmpty {
            if groupByProcess {
                let groupedPorts = categorizer.groupByProcess(nonFavoritePorts)

                for processName in groupedPorts.keys.sorted(by: <) {
                    guard let portsInProcess = groupedPorts[processName] else { continue }
                    entries.append(.text(processName, style: .header))

                    for port in portsInProcess.sorted(by: { $0.port < $1.port }) {
                        entries.append(portRowEntry(for: port, categorizer: categorizer))
                    }
                }
            } else if groupByCategory {
                let groupedPorts = categorizer.groupByCategory(nonFavoritePorts)

                for category in groupedPorts.keys.sorted(by: { $0.rawValue < $1.rawValue }) {
                    guard let portsInCategory = groupedPorts[category] else { continue }
                    entries.append(.text(category.rawValue, style: .header))

                    for port in portsInCategory {
                        entries.append(portRowEntry(for: port, categorizer: categorizer))
                    }
                }
            } else {
                entries.append(.text(favoritePortsList.isEmpty ? "Ports" : "Other Ports", style: .header))

                for port in nonFavoritePorts {
                    entries.append(portRowEntry(for: port, categorizer: categorizer))
                }
            }
        }

        return MenuDescriptor(sections: [MenuSection(entries: entries)])
    }

    private func portRowEntry(for port: PortInfo, categorizer: PortCategorizer) -> MenuEntry {
        let categorized = categorizer.categorize(port)
        return .portRow(
            port,
            category: categorized.category,
            technology: categorized.technology,
            projectName: categorized.projectName,
        )
    }

    /// Filter ports based on search text and system process setting.
    private func filterPorts(
        _ ports: [PortInfo],
        searchText: String,
        showSystemProcesses: Bool,
    ) -> [PortInfo] {
        let lowerSearchText = searchText.lowercased()

        return ports.filter { port in
            // Filter out system processes if disabled
            if !showSystemProcesses, port.isSystemProcess {
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
                port.executablePath?.lowercased() ?? "",
            ]

            return searchIn.contains { $0.contains(lowerSearchText) }
        }
    }
}
