#!/usr/bin/swift
// Generates the OpenPorts app icon set (Icon.iconset) from code so the brand
// assets stay reproducible. Run from the repo root:
//
//     swift Scripts/generate_icons.swift
//
// Design: a deep indigo squircle with a white "port jack" glyph — a rounded
// socket with three pins, the middle pin lit green to suggest a live port.
// The same glyph (monochrome) is drawn at runtime for the menu bar icon in
// AppIconProvider; keep the two in sync when changing proportions.

import AppKit

// MARK: - Canvas constants (1024-point design grid)

let canvas: CGFloat = 1024
// Apple's macOS icon grid: content squircle inset ~10% with ~22.37% corner radius.
let squircleRect = CGRect(x: 100, y: 100, width: 824, height: 824)
let squircleRadius: CGFloat = 184

struct Palette {
    static let backgroundTop = NSColor(calibratedRed: 0.42, green: 0.40, blue: 0.95, alpha: 1) // indigo 500
    static let backgroundBottom = NSColor(calibratedRed: 0.13, green: 0.12, blue: 0.42, alpha: 1) // indigo 950
    static let glyph = NSColor.white
    static let livePin = NSColor(calibratedRed: 0.20, green: 0.83, blue: 0.60, alpha: 1) // emerald 400
}

// MARK: - Drawing

func drawIcon(scaleStroke: CGFloat) {
    // Background squircle with vertical gradient.
    let squircle = NSBezierPath(roundedRect: squircleRect, xRadius: squircleRadius, yRadius: squircleRadius)
    NSGradient(starting: Palette.backgroundTop, ending: Palette.backgroundBottom)?
        .draw(in: squircle, angle: -90)

    // Soft top highlight for depth.
    NSGraphicsContext.current?.saveGraphicsState()
    squircle.addClip()
    let highlight = NSGradient(
        starting: NSColor.white.withAlphaComponent(0.18),
        ending: NSColor.white.withAlphaComponent(0.0),
    )
    highlight?.draw(
        in: NSBezierPath(rect: CGRect(x: 100, y: 564, width: 824, height: 360)),
        angle: -90,
    )
    NSGraphicsContext.current?.restoreGraphicsState()

    // Port jack glyph: rounded socket outline with three pins hanging from the
    // top edge. Coordinates are bottom-up (AppKit default).
    let stroke: CGFloat = 58 * scaleStroke
    let jackWidth: CGFloat = 520
    let jackHeight: CGFloat = 380
    let jackRect = CGRect(
        x: (canvas - jackWidth) / 2,
        y: (canvas - jackHeight) / 2 - 14,
        width: jackWidth,
        height: jackHeight,
    )

    let shadow = NSShadow()
    shadow.shadowColor = NSColor.black.withAlphaComponent(0.35)
    shadow.shadowBlurRadius = 34
    shadow.shadowOffset = NSSize(width: 0, height: -16)

    NSGraphicsContext.current?.saveGraphicsState()
    shadow.set()

    let jack = NSBezierPath(roundedRect: jackRect, xRadius: 88, yRadius: 88)
    jack.lineWidth = stroke
    Palette.glyph.setStroke()
    jack.stroke()

    NSGraphicsContext.current?.restoreGraphicsState()

    // Pins: three rounded bars descending from the inner top edge.
    let pinWidth: CGFloat = 64 * scaleStroke
    let pinHeight: CGFloat = 128
    let pinTop = jackRect.maxY - stroke / 2
    let pinSpacing: CGFloat = 150
    let centers = [canvas / 2 - pinSpacing, canvas / 2, canvas / 2 + pinSpacing]

    for (index, centerX) in centers.enumerated() {
        let pinRect = CGRect(
            x: centerX - pinWidth / 2,
            y: pinTop - pinHeight,
            width: pinWidth,
            height: pinHeight,
        )
        let pin = NSBezierPath(roundedRect: pinRect, xRadius: pinWidth / 2, yRadius: pinWidth / 2)
        (index == 1 ? Palette.livePin : Palette.glyph).setFill()
        pin.fill()
    }
}

// MARK: - Rendering

func render(pixels: Int) -> NSBitmapImageRep {
    guard let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: pixels,
        pixelsHigh: pixels,
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .calibratedRGB,
        bytesPerRow: 0,
        bitsPerPixel: 0,
    ) else {
        fatalError("Could not create bitmap for \(pixels)px")
    }

    NSGraphicsContext.saveGraphicsState()
    let context = NSGraphicsContext(bitmapImageRep: rep)!
    NSGraphicsContext.current = context
    context.cgContext.interpolationQuality = .high

    let scale = CGFloat(pixels) / canvas
    context.cgContext.scaleBy(x: scale, y: scale)

    // Thicken strokes at small sizes so the glyph stays legible at 16-64px.
    let strokeBoost: CGFloat = pixels <= 32 ? 1.9 : (pixels <= 64 ? 1.45 : 1.0)
    drawIcon(scaleStroke: strokeBoost)

    context.flushGraphics()
    NSGraphicsContext.restoreGraphicsState()
    return rep
}

func writePNG(_ rep: NSBitmapImageRep, to path: String) {
    guard let data = rep.representation(using: .png, properties: [:]) else {
        fatalError("Could not encode \(path)")
    }
    try! data.write(to: URL(fileURLWithPath: path))
    print("wrote \(path)")
}

// MARK: - Icon set output

let iconsetDir = "Icon.iconset"
try? FileManager.default.createDirectory(atPath: iconsetDir, withIntermediateDirectories: true)

let sizes: [(name: String, pixels: Int)] = [
    ("openports-16.png", 16),
    ("openports-16@2x.png", 32),
    ("openports-32.png", 32),
    ("openports-32@2x.png", 64),
    ("openports-128.png", 128),
    ("openports-128@2x.png", 256),
    ("openports-256.png", 256),
    ("openports-256@2x.png", 512),
    ("openports-512.png", 512),
    ("openports-512@2x.png", 1024),
    ("openports-1024.png", 1024),
]

for entry in sizes {
    writePNG(render(pixels: entry.pixels), to: "\(iconsetDir)/\(entry.name)")
}

let contents = """
{
  "images" : [
    { "filename" : "openports-16.png", "idiom" : "mac", "scale" : "1x", "size" : "16x16" },
    { "filename" : "openports-16@2x.png", "idiom" : "mac", "scale" : "2x", "size" : "16x16" },
    { "filename" : "openports-32.png", "idiom" : "mac", "scale" : "1x", "size" : "32x32" },
    { "filename" : "openports-32@2x.png", "idiom" : "mac", "scale" : "2x", "size" : "32x32" },
    { "filename" : "openports-128.png", "idiom" : "mac", "scale" : "1x", "size" : "128x128" },
    { "filename" : "openports-128@2x.png", "idiom" : "mac", "scale" : "2x", "size" : "128x128" },
    { "filename" : "openports-256.png", "idiom" : "mac", "scale" : "1x", "size" : "256x256" },
    { "filename" : "openports-256@2x.png", "idiom" : "mac", "scale" : "2x", "size" : "256x256" },
    { "filename" : "openports-512.png", "idiom" : "mac", "scale" : "1x", "size" : "512x512" },
    { "filename" : "openports-512@2x.png", "idiom" : "mac", "scale" : "2x", "size" : "512x512" }
  ],
  "info" : { "author" : "openports", "version" : 1 }
}
"""
try! contents.write(toFile: "\(iconsetDir)/Contents.json", atomically: true, encoding: .utf8)
print("wrote \(iconsetDir)/Contents.json")
