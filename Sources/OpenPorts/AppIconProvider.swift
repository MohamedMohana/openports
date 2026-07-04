import AppKit
import SwiftUI

@MainActor
enum AppIconProvider {
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

    /// The brand "port jack" glyph as a menu bar template image.
    /// Proportions mirror the app icon drawn by Scripts/generate_icons.swift;
    /// keep the two in sync when changing the mark.
    static func statusBarIcon() -> NSImage {
        let side: CGFloat = 18
        let image = NSImage(size: NSSize(width: side, height: side), flipped: false) { _ in
            let stroke: CGFloat = 1.6

            // Socket outline.
            let jackRect = CGRect(x: 2, y: 3.2, width: 14, height: 10.6)
            let jack = NSBezierPath(roundedRect: jackRect, xRadius: 3, yRadius: 3)
            jack.lineWidth = stroke
            NSColor.black.setStroke()
            jack.stroke()

            // Three pins descending from the inner top edge.
            let pinWidth: CGFloat = 1.8
            let pinHeight: CGFloat = 3.4
            let pinTop = jackRect.maxY - stroke / 2
            for centerX in [6.4, 9.0, 11.6] as [CGFloat] {
                let pinRect = CGRect(
                    x: centerX - pinWidth / 2,
                    y: pinTop - pinHeight,
                    width: pinWidth,
                    height: pinHeight,
                )
                NSColor.black.setFill()
                NSBezierPath(roundedRect: pinRect, xRadius: pinWidth / 2, yRadius: pinWidth / 2).fill()
            }

            return true
        }

        image.isTemplate = true
        return image
    }

    static func swiftUIImage(size: CGFloat) -> Image {
        Image(nsImage: appIcon(size: size))
    }
}
