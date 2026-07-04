import AppKit
import OpenPortsCore
import SwiftUI

/// Developer tool: renders the popover with sample data to PNG files and exits.
/// Used to verify UI changes and regenerate README screenshots without manual clicking:
///
///     swift build && .build/debug/OpenPorts --render-popover docs/assets
///
@MainActor
enum RenderHarness {
    static func runIfRequested() {
        guard let flagIndex = CommandLine.arguments.firstIndex(of: "--render-popover"),
              CommandLine.arguments.count > flagIndex + 1 else {
            return
        }

        let outputDirectory = CommandLine.arguments[flagIndex + 1]
        render(to: outputDirectory)
        exit(0)
    }

    private static func render(to directory: String) {
        let ports: [PortInfo] = [
            PortInfo(port: 3000, portProtocol: .tcp, pid: 4211, processName: "node", appName: nil, bundleID: nil,
                     executablePath: "/Users/dev/projects/my-app/node_modules/.bin/next", isSystemProcess: false,
                     safety: .userCreated, uptime: 95, isNew: true),
            PortInfo(port: 5432, portProtocol: .tcp, pid: 812, processName: "postgres", appName: "PostgreSQL", bundleID: nil,
                     executablePath: "/opt/homebrew/bin/postgres", isSystemProcess: false,
                     safety: .important, uptime: 86400 * 3, isNew: false),
            PortInfo(port: 5000, portProtocol: .tcp, pid: 617, processName: "ControlCe", appName: "Control Center", bundleID: "com.apple.controlcenter",
                     executablePath: "/System/Library/CoreServices/ControlCenter.app", isSystemProcess: true,
                     safety: .critical, uptime: 86400 * 9, isNew: false),
            PortInfo(port: 5353, portProtocol: .udp, pid: 325, processName: "mDNSResponder", appName: nil, bundleID: nil,
                     executablePath: "/usr/sbin/mDNSResponder", isSystemProcess: true,
                     safety: .critical, uptime: 86400 * 9, isNew: false),
            PortInfo(port: 8080, portProtocol: .tcp, pid: 5120, processName: "python3.12", appName: nil, bundleID: nil,
                     executablePath: "/Users/dev/projects/api/venv/bin/python", isSystemProcess: false,
                     safety: .userCreated, uptime: 3600 * 2, isNew: false),
        ]

        let model = StatusPopoverModel()
        model.descriptor = MenuDescriptor().build(
            ports: ports,
            groupByProcess: false,
            favoritePorts: [3000],
        )
        model.favoritePorts = [3000]
        model.portCount = ports.count
        model.lastUpdatedAt = Date(timeIntervalSinceNow: -40)

        let view = StatusPopoverView(
            model: model,
            onRefresh: {}, onViewLogs: {}, onShowPreferences: {}, onQuit: {},
            onTerminate: { _, _ in }, onToggleFavorite: { _ in }, onExport: { _ in },
            onSearchChanged: { _ in },
        )

        for scheme in [("light", NSAppearance.Name.aqua), ("dark", NSAppearance.Name.darkAqua)] {
            let hosting = NSHostingView(rootView: view.background(Color(nsColor: .windowBackgroundColor)))
            hosting.frame = NSRect(x: 0, y: 0, width: 440, height: 600)

            let window = NSWindow(
                contentRect: hosting.frame,
                styleMask: [.borderless],
                backing: .buffered,
                defer: false,
            )
            window.appearance = NSAppearance(named: scheme.1)
            window.contentView = hosting
            window.orderFrontRegardless()

            // Let SwiftUI complete layout of lazy content.
            RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.7))

            hosting.layoutSubtreeIfNeeded()
            guard let rep = hosting.bitmapImageRepForCachingDisplay(in: hosting.bounds) else {
                print("RenderHarness: failed to render \(scheme.0)")
                continue
            }
            hosting.cacheDisplay(in: hosting.bounds, to: rep)

            guard let data = rep.representation(using: .png, properties: [:]) else { continue }
            let url = URL(fileURLWithPath: directory).appendingPathComponent("popover-\(scheme.0).png")
            try? data.write(to: url)
            print("RenderHarness: wrote \(url.path)")
            window.orderOut(nil)
        }
    }
}
