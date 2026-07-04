import AppKit
import OpenPortsCore
import SwiftUI

/// Developer tool: renders the popover with sample data to PNG files and exits.
/// Used to verify UI changes and regenerate README screenshots without manual clicking:
///
///     ./Scripts/package_app.sh debug arm64
///     ./OpenPorts.app/Contents/MacOS/OpenPorts --render-popover docs/assets
///
/// Run from the packaged app (not the bare binary) — parts of the app need a
/// real bundle identity.
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
        renderPreferences(to: outputDirectory)
        renderStatusIcon(to: outputDirectory)
        exit(0)
    }

    private static func renderPreferences(to directory: String) {
        for scheme in [("light", NSAppearance.Name.aqua), ("dark", NSAppearance.Name.darkAqua)] {
            snapshot(
                view: AnyView(PreferencesView().background(Color(nsColor: .windowBackgroundColor))),
                size: NSSize(width: 560, height: 520),
                appearance: scheme.1,
                to: "\(directory)/preferences-\(scheme.0).png",
            )
        }
    }

    /// Renders the menu bar icon at 4x on light and dark strips.
    private static func renderStatusIcon(to directory: String) {
        let icon = AppIconProvider.statusBarIcon()
        let strip = NSImage(size: NSSize(width: 160, height: 80), flipped: false) { _ in
            NSColor(calibratedWhite: 0.92, alpha: 1).setFill()
            NSBezierPath(rect: NSRect(x: 0, y: 40, width: 160, height: 40)).fill()
            NSColor(calibratedWhite: 0.12, alpha: 1).setFill()
            NSBezierPath(rect: NSRect(x: 0, y: 0, width: 160, height: 40)).fill()

            // Light menu bar: black glyph. Dark menu bar: white glyph.
            for (yOffset, color) in [(CGFloat(45), NSColor.black), (CGFloat(5), NSColor.white)] {
                let glyph = NSImage(size: icon.size, flipped: false) { glyphRect in
                    icon.draw(in: glyphRect)
                    color.set()
                    glyphRect.fill(using: .sourceAtop)
                    return true
                }
                glyph.draw(in: NSRect(x: 62, y: yOffset, width: 36, height: 30).insetBy(dx: 3, dy: 0))
            }
            return true
        }

        guard let tiff = strip.tiffRepresentation,
              let rep = NSBitmapImageRep(data: tiff),
              let data = rep.representation(using: .png, properties: [:]) else { return }
        try? data.write(to: URL(fileURLWithPath: "\(directory)/statusbar-icon.png"))
        print("RenderHarness: wrote \(directory)/statusbar-icon.png")
    }

    private static func snapshot(view: AnyView, size: NSSize, appearance: NSAppearance.Name, to path: String) {
        let hosting = NSHostingView(rootView: view)
        hosting.frame = NSRect(origin: .zero, size: size)

        let window = NSWindow(
            contentRect: hosting.frame,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false,
        )
        window.appearance = NSAppearance(named: appearance)
        window.contentView = hosting
        window.orderFrontRegardless()

        RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.7))

        hosting.layoutSubtreeIfNeeded()
        guard let rep = hosting.bitmapImageRepForCachingDisplay(in: hosting.bounds) else {
            print("RenderHarness: failed to render \(path)")
            return
        }
        hosting.cacheDisplay(in: hosting.bounds, to: rep)

        guard let data = rep.representation(using: .png, properties: [:]) else { return }
        try? data.write(to: URL(fileURLWithPath: path))
        print("RenderHarness: wrote \(path)")
        window.orderOut(nil)
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
