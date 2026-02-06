import AppKit
import OpenPortsCore
import SwiftUI

/// Controller for the menu bar status item.
@MainActor
final class StatusItemController {
    private let statusItem: NSStatusItem
    private var menu: NSMenu?
    
    init() {
        self.statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        // Configure status item
        statusItem.button?.image = NSImage(systemSymbolName: "network", accessibilityDescription: "Network ports")
        statusItem.button?.imageScaling = .scaleNone
        
        // Create the menu
        self.menu = NSMenu()
        statusItem.menu = menu
    }
    
    /// Update the menu with new descriptor data.
    func updateMenu(_ descriptor: MenuDescriptor) {
        menu?.removeAllItems()
        
        for section in descriptor.sections {
            if let header = section.header {
                let headerItem = NSMenuItem(title: header, action: nil, keyEquivalent: "")
                headerItem.isEnabled = false
                menu?.addItem(headerItem)
            }
            
            for entry in section.entries {
                switch entry {
                case .text(let text, let style):
                    let menuItem = NSMenuItem(title: text, action: nil, keyEquivalent: "")
                    menuItem.isEnabled = false
                    switch style {
                    case .warning:
                        menuItem.attributedTitle = NSAttributedString(string: text, attributes: [.foregroundColor: NSColor.systemOrange])
                    case .system:
                        menuItem.attributedTitle = NSAttributedString(string: text, attributes: [.foregroundColor: NSColor.systemGray])
                    default:
                        break
                    }
                    menu?.addItem(menuItem)
                    
                case .divider:
                    let dividerItem = NSMenuItem.separator()
                    menu?.addItem(dividerItem)
                    
                case .portRow(let port, let category, let technology, let projectName):
                    var portTitle = ":\(port.port) \(port.portProtocol.rawValue)"
                    if let icon = category?.icon {
                        portTitle = "\(icon) \(portTitle)"
                    }

                    if port.isNew {
                        portTitle = "⚡\(portTitle)"
                    }

                    if let safety = port.safety {
                        portTitle = "\(portTitle) [\(safety.icon)]"
                    }

                    let menuItem = NSMenuItem(title: portTitle, action: nil, keyEquivalent: "")
                    menuItem.submenu = createPortMenu(for: port, category: category, technology: technology, projectName: projectName)
                    menu?.addItem(menuItem)
                    
                case .button(let title, _):
                    let menuItem = NSMenuItem(title: title, action: #selector(StatusItemController.handleButtonTap(_:)), keyEquivalent: "")
                    menuItem.target = self
                    menu?.addItem(menuItem)
                    
                case .refreshButton:
                    let menuItem = NSMenuItem(title: "Refresh", action: #selector(StatusItemController.refreshMenu), keyEquivalent: "r")
                    menuItem.target = self
                    menu?.addItem(menuItem)
                    
                case .viewLogsButton:
                    let menuItem = NSMenuItem(title: "View Logs", action: #selector(StatusItemController.viewLogs), keyEquivalent: "")
                    menuItem.target = self
                    menu?.addItem(menuItem)

                case .preferencesButton:
                    let menuItem = NSMenuItem(title: "Preferences...", action: #selector(StatusItemController.showPreferences), keyEquivalent: ",")
                    menuItem.target = self
                    menu?.addItem(menuItem)
                }
            }
        }
        
        // Add the quit button at the end
        menu?.addItem(NSMenuItem.separator())
        
        let quitItem = NSMenuItem(
            title: "Quit OpenPorts",
            action: #selector(StatusItemController.quit),
            keyEquivalent: "q"
        )
        quitItem.target = self
        menu?.addItem(quitItem)
    }
    
    /// Create a submenu for a port row with kill options.
    private func createPortMenu(for port: PortInfo, category: PortCategory?, technology: String?, projectName: String?) -> NSMenu {
        let submenu = NSMenu()

        // Add safety level
        if let safety = port.safety {
            let safetyItem = NSMenuItem(title: "\(safety.icon) Safety: \(safety.rawValue)", action: nil, keyEquivalent: "")
            safetyItem.isEnabled = false
            submenu.addItem(safetyItem)
        }

        // Add uptime if available
        if let uptime = port.formattedUptime {
            let uptimeItem = NSMenuItem(title: "⏱️ Uptime: \(uptime)", action: nil, keyEquivalent: "")
            uptimeItem.isEnabled = false
            submenu.addItem(uptimeItem)
        }

        // Add category info
        if let category = category {
            let categoryItem = NSMenuItem(title: "\(category.icon) Category: \(category.rawValue)", action: nil, keyEquivalent: "")
            categoryItem.isEnabled = false
            submenu.addItem(categoryItem)
        }

        // Add technology info
        if let technology = technology {
            let techItem = NSMenuItem(title: "🔧 Technology: \(technology)", action: nil, keyEquivalent: "")
            techItem.isEnabled = false
            submenu.addItem(techItem)
        }

        // Add project name
        if let projectName = projectName {
            let projectItem = NSMenuItem(title: "📂 Project: \(projectName)", action: nil, keyEquivalent: "")
            projectItem.isEnabled = false
            submenu.addItem(projectItem)
        }

        // Add process info
        let processInfoItem = NSMenuItem(title: "📋 \(port.processName)", action: nil, keyEquivalent: "")
        processInfoItem.isEnabled = false
        submenu.addItem(processInfoItem)

        // Add PID
        let pidItem = NSMenuItem(title: "ID: \(port.pid)", action: nil, keyEquivalent: "")
        pidItem.isEnabled = false
        submenu.addItem(pidItem)

        // Add a divider
        submenu.addItem(NSMenuItem.separator())

        // Add termination options
        let terminateTitle = port.isSystemProcess ? "⚠️ Terminate (System Process)" : "Terminate"
        let terminateItem = NSMenuItem(
            title: terminateTitle,
            action: #selector(StatusItemController.terminatePort(_:)),
            keyEquivalent: ""
        )
        terminateItem.target = self
        terminateItem.representedObject = port.pid
        submenu.addItem(terminateItem)

        let forceKillTitle = port.isSystemProcess ? "⚠️ Force Kill (System Process)" : "Force Kill"
        let forceKillItem = NSMenuItem(
            title: forceKillTitle,
            action: #selector(StatusItemController.forceKill(_:)),
            keyEquivalent: ""
        )
        forceKillItem.target = self
        forceKillItem.representedObject = port.pid
        submenu.addItem(forceKillItem)

        return submenu
    }
    
    @objc private func handleButtonTap(_ sender: AnyObject) {
        // Handle button taps
    }
    
    @objc private func refreshMenu() {
        // Trigger refresh - will be implemented with NotificationCenter
        NotificationCenter.default.post(name: .refreshPorts, object: nil)
    }
    
    @objc private func terminatePort(_ sender: AnyObject?) {
        if let pid = sender?.representedObject as? Int {
            NotificationCenter.default.post(
                name: .terminatePort,
                object: pid
            )
        }
    }
    
    @objc private func forceKill(_ sender: AnyObject?) {
        if let pid = sender?.representedObject as? Int {
            NotificationCenter.default.post(
                name: .forceKill,
                object: pid
            )
        }
    }
    
    @objc private func quit() {
        NSApplication.shared.terminate(nil)
    }

    @objc private func viewLogs() {
        let logs = AppLogger.shared.getLogsText()

        // Create a simple alert to show logs
        let alert = NSAlert()
        alert.messageText = "OpenPorts Debug Logs"
        alert.informativeText = logs.isEmpty ? "No logs available" : logs
        alert.alertStyle = .informational
        alert.addButton(withTitle: "Copy to Clipboard")
        alert.addButton(withTitle: "Close")
        alert.addButton(withTitle: "Clear Logs")

        let response = alert.runModal()

        switch response {
        case .alertFirstButtonReturn:
            // Copy to clipboard
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(logs, forType: .string)
        case .alertThirdButtonReturn:
            // Clear logs
            AppLogger.shared.clear()
        default:
            break
        }
    }

    @objc private func showPreferences() {
        let prefsView = PreferencesView()
        let hostingController = NSHostingController(rootView: prefsView)
        
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 550, height: 900),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = "OpenPorts Preferences"
        window.contentViewController = hostingController
        window.center()
        window.isReleasedWhenClosed = false
        window.makeKeyAndOrderFront(nil)
        
        NSApp.activate(ignoringOtherApps: true)
    }
}

// Notification names
extension Notification.Name {
    static let refreshPorts = Notification.Name("com.mohamedmohana.openports.refreshPorts")
    static let terminatePort = Notification.Name("com.mohamedmohana.openports.terminatePort")
    static let forceKill = Notification.Name("com.mohamedmohana.openports.forceKill")
    static let showPreferences = Notification.Name("com.mohamedmohana.openports.showPreferences")
}
