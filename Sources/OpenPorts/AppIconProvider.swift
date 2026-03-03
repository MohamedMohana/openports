import AppKit
import SwiftUI

@MainActor
enum AppIconProvider {
    static func appIcon(size: CGFloat) -> NSImage {
        let fallback = NSImage(systemSymbolName: "network", accessibilityDescription: "OpenPorts")
            ?? NSImage(size: NSSize(width: size, height: size))
        let baseIcon = NSApp.applicationIconImage ?? fallback
        guard let resized = baseIcon.copy() as? NSImage else {
            return baseIcon
        }

        resized.size = NSSize(width: size, height: size)
        resized.isTemplate = false
        return resized
    }

    static func statusBarIcon(size: CGFloat = 18) -> NSImage {
        appIcon(size: size)
    }

    static func swiftUIImage(size: CGFloat) -> Image {
        Image(nsImage: appIcon(size: size))
    }
}
