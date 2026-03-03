import AppKit
import SwiftUI

@MainActor
enum AppIconProvider {
    private static let statusBarSymbolName = "switch.2"

    private static func fallbackIcon(size: CGFloat) -> NSImage {
        NSImage(systemSymbolName: "network", accessibilityDescription: "OpenPorts")
            ?? NSImage(size: NSSize(width: size, height: size))
    }

    static func appIcon(size: CGFloat) -> NSImage {
        let fallback = fallbackIcon(size: size)
        let baseIcon = NSApp.applicationIconImage ?? fallback
        guard let resized = baseIcon.copy() as? NSImage else {
            return baseIcon
        }

        resized.size = NSSize(width: size, height: size)
        resized.isTemplate = false
        return resized
    }

    static func statusBarIcon(size: CGFloat = 14) -> NSImage {
        let symbolConfig = NSImage.SymbolConfiguration(pointSize: size, weight: .semibold)
        let symbolImage = NSImage(systemSymbolName: statusBarSymbolName, accessibilityDescription: "OpenPorts")
            ?? NSImage(systemSymbolName: "line.3.horizontal", accessibilityDescription: "OpenPorts")
            ?? fallbackIcon(size: size)

        let configuredImage = symbolImage.withSymbolConfiguration(symbolConfig) ?? symbolImage
        configuredImage.isTemplate = true
        configuredImage.size = NSSize(width: 18, height: 18)
        return configuredImage
    }

    static func swiftUIImage(size: CGFloat) -> Image {
        Image(nsImage: appIcon(size: size))
    }
}
