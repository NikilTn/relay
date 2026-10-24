#!/usr/bin/env swift
// Deterministic vector drawing for the app icon. No external image or package dependency.
import AppKit
import ImageIO
let root = URL(fileURLWithPath: CommandLine.arguments[1], isDirectory: true)
let folder = root.appendingPathComponent("App/Assets.xcassets/AppIcon.appiconset", isDirectory: true)
try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
let sizes = [16, 32, 64, 128, 256, 512, 1024]
for size in sizes {
    let cg = CGContext(data: nil, width: size, height: size, bitsPerComponent: 8,
        bytesPerRow: size * 4, space: CGColorSpaceCreateDeviceRGB(),
        bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)!
    let context = NSGraphicsContext(cgContext: cg, flipped: false)
    NSGraphicsContext.saveGraphicsState(); NSGraphicsContext.current = context
    context.cgContext.scaleBy(x: CGFloat(size) / 1024, y: CGFloat(size) / 1024)
    NSColor(srgbRed: 0.035, green: 0.09, blue: 0.15, alpha: 1).setFill()
    NSBezierPath(rect: NSRect(x: 0, y: 0, width: 1024, height: 1024)).fill()
    let points = [NSPoint(x: 225, y: 320), NSPoint(x: 512, y: 704), NSPoint(x: 799, y: 320)]
    let line = NSBezierPath(); line.move(to: points[0]); line.line(to: points[1]); line.line(to: points[2])
    line.lineWidth = 58; line.lineJoinStyle = .round; line.lineCapStyle = .round
    NSColor(srgbRed: 0.34, green: 0.90, blue: 0.76, alpha: 1).setStroke(); line.stroke()
    for (index, point) in points.enumerated() {
        let radius: CGFloat = index == 1 ? 110 : 96
        NSColor(srgbRed: 0.035, green: 0.09, blue: 0.15, alpha: 1).setFill()
        NSBezierPath(ovalIn: NSRect(x: point.x - radius - 12, y: point.y - radius - 12, width: 2 * (radius + 12), height: 2 * (radius + 12))).fill()
        (index == 1 ? NSColor(srgbRed: 0.77, green: 0.96, blue: 0.38, alpha: 1) : NSColor(srgbRed: 0.34, green: 0.90, blue: 0.76, alpha: 1)).setFill()
        NSBezierPath(ovalIn: NSRect(x: point.x - radius, y: point.y - radius, width: 2 * radius, height: 2 * radius)).fill()
        NSColor(srgbRed: 0.035, green: 0.09, blue: 0.15, alpha: 1).setFill()
        NSBezierPath(ovalIn: NSRect(x: point.x - 34, y: point.y - 34, width: 68, height: 68)).fill()
    }
    NSGraphicsContext.restoreGraphicsState()
    let url = folder.appendingPathComponent("Icon\(size).png")
    let destination = CGImageDestinationCreateWithURL(url as CFURL, "public.png" as CFString, 1, nil)!
    CGImageDestinationAddImage(destination, cg.makeImage()!, nil)
    guard CGImageDestinationFinalize(destination) else { fatalError("PNG write failed") }
}
print("Generated opaque RELAY icons at \(folder.path)")
