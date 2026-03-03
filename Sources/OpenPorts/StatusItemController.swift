import AppKit
import OpenPortsCore
import SwiftUI

/// Controller for the menu bar status item.
@MainActor
final class StatusItemController: NSObject {
    let statusItem: NSStatusItem

    private let popover = NSPopover()
    private let popoverModel = StatusPopoverModel()
    private var preferencesWindow: NSWindow?
    private var logsWindow: NSWindow?

    override init() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        super.init()

        configureStatusItemButton()
        configurePopover()
        applyUnifiedStatusIcon()
    }

    /// Update the status bar icon metadata based on current port state.
    func updateStatusIcon(ports: [PortInfo], hasWarnings: Bool) {
        applyUnifiedStatusIcon()

        let portCount = ports.count
        let warningPrefix = hasWarnings ? "Warning - " : ""
        statusItem.button?.toolTip = "\(warningPrefix)OpenPorts - \(portCount) port\(portCount == 1 ? "" : "s") active"
    }

    private func configureStatusItemButton() {
        guard let button = statusItem.button else {
            return
        }

        button.target = self
        button.action = #selector(togglePopover(_:))
        button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        button.imagePosition = .imageOnly
    }

    private func configurePopover() {
        popover.behavior = .transient
        popover.animates = false
        popover.contentSize = NSSize(width: 480, height: 620)

        let rootView = StatusPopoverView(
            model: popoverModel,
            onRefresh: { [weak self] in
                self?.refreshMenu()
            },
            onViewLogs: { [weak self] in
                self?.showLogsWindow()
            },
            onShowPreferences: { [weak self] in
                self?.showPreferences()
            },
            onQuit: { [weak self] in
                self?.quit()
            },
            onTerminate: { [weak self] pid, forceKill in
                self?.handleTerminate(pid: pid, forceKill: forceKill)
            },
        )

        let hostingController = NSHostingController(rootView: rootView)
        popover.contentViewController = hostingController
    }

    private func applyUnifiedStatusIcon() {
        statusItem.button?.image = AppIconProvider.statusBarIcon()
    }

    /// Update popover content with new descriptor data.
    func updateMenu(_ descriptor: MenuDescriptor) {
        popoverModel.descriptor = descriptor
    }

    private func handleTerminate(pid: Int, forceKill: Bool) {
        let notificationName: Notification.Name = forceKill ? .forceKill : .terminatePort
        NotificationCenter.default.post(name: notificationName, object: pid)
    }

    @objc private func togglePopover(_: AnyObject?) {
        guard let button = statusItem.button else {
            return
        }

        if popover.isShown {
            popover.performClose(nil)
            return
        }

        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
    }

    @objc private func refreshMenu() {
        NotificationCenter.default.post(name: .refreshPorts, object: nil)
    }

    @objc private func quit() {
        NSApplication.shared.terminate(nil)
    }

    private func showLogsWindow() {
        if let logsWindow {
            logsWindow.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let hostingController = NSHostingController(rootView: DebugLogsView(logger: AppLogger.shared))
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 760, height: 560),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false,
        )
        window.title = "OpenPorts Debug Logs"
        window.minSize = NSSize(width: 620, height: 420)
        window.contentViewController = hostingController
        window.center()
        window.isReleasedWhenClosed = false
        window.delegate = self
        window.makeKeyAndOrderFront(nil)

        logsWindow = window
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc private func showPreferences() {
        if let preferencesWindow {
            preferencesWindow.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let hostingController = NSHostingController(rootView: PreferencesView())
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 560, height: 620),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false,
        )
        window.title = "OpenPorts Preferences"
        window.contentViewController = hostingController
        window.center()
        window.isReleasedWhenClosed = false
        window.delegate = self
        window.makeKeyAndOrderFront(nil)

        preferencesWindow = window
        NSApp.activate(ignoringOtherApps: true)
    }
}

extension StatusItemController: NSWindowDelegate {
    func windowWillClose(_ notification: Notification) {
        guard let window = notification.object as? NSWindow else {
            return
        }

        if window == preferencesWindow {
            preferencesWindow = nil
            return
        }

        if window == logsWindow {
            logsWindow = nil
        }
    }
}

/// Notification names
extension Notification.Name {
    static let refreshPorts = Notification.Name("com.mohamedmohana.openports.refreshPorts")
    static let terminatePort = Notification.Name("com.mohamedmohana.openports.terminatePort")
    static let forceKill = Notification.Name("com.mohamedmohana.openports.forceKill")
    static let preferenceChanged = Notification.Name("com.mohamedmohana.openports.preferenceChanged")
}
