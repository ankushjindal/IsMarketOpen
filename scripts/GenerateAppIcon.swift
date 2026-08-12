import AppKit
import Foundation

guard CommandLine.arguments.count == 2 else {
    fputs("usage: GenerateAppIcon.swift <output-directory>\n", stderr)
    exit(2)
}

let output = URL(fileURLWithPath: CommandLine.arguments[1], isDirectory: true)
try FileManager.default.createDirectory(at: output, withIntermediateDirectories: true)

let variants: [(String, Int)] = [
    ("icon_16x16.png", 16),
    ("icon_16x16@2x.png", 32),
    ("icon_32x32.png", 32),
    ("icon_32x32@2x.png", 64),
    ("icon_128x128.png", 128),
    ("icon_128x128@2x.png", 256),
    ("icon_256x256.png", 256),
    ("icon_256x256@2x.png", 512),
    ("icon_512x512.png", 512),
    ("icon_512x512@2x.png", 1024),
]

for (filename, pixels) in variants {
    let image = NSImage(size: NSSize(width: pixels, height: pixels))
    image.lockFocus()

    let rect = NSRect(x: 0, y: 0, width: pixels, height: pixels)
    let background = NSBezierPath(roundedRect: rect.insetBy(dx: CGFloat(pixels) * 0.06, dy: CGFloat(pixels) * 0.06), xRadius: CGFloat(pixels) * 0.22, yRadius: CGFloat(pixels) * 0.22)
    NSColor(calibratedRed: 0.055, green: 0.075, blue: 0.11, alpha: 1).setFill()
    background.fill()

    NSColor(calibratedRed: 0.33, green: 0.84, blue: 0.59, alpha: 1).setFill()
    let unit = CGFloat(pixels) / 100
    let roof = NSBezierPath()
    roof.move(to: NSPoint(x: 18 * unit, y: 62 * unit))
    roof.line(to: NSPoint(x: 50 * unit, y: 82 * unit))
    roof.line(to: NSPoint(x: 82 * unit, y: 62 * unit))
    roof.close()
    roof.fill()

    NSBezierPath(roundedRect: NSRect(x: 18 * unit, y: 55 * unit, width: 64 * unit, height: 7 * unit), xRadius: 2 * unit, yRadius: 2 * unit).fill()
    for x in [25, 40, 55, 70] {
        NSBezierPath(roundedRect: NSRect(x: CGFloat(x) * unit, y: 27 * unit, width: 7 * unit, height: 28 * unit), xRadius: 2 * unit, yRadius: 2 * unit).fill()
    }
    NSBezierPath(roundedRect: NSRect(x: 15 * unit, y: 19 * unit, width: 70 * unit, height: 8 * unit), xRadius: 2 * unit, yRadius: 2 * unit).fill()

    image.unlockFocus()
    guard let tiff = image.tiffRepresentation,
          let bitmap = NSBitmapImageRep(data: tiff),
          let png = bitmap.representation(using: .png, properties: [:])
    else { throw CocoaError(.fileWriteUnknown) }
    try png.write(to: output.appendingPathComponent(filename), options: .atomic)
}
