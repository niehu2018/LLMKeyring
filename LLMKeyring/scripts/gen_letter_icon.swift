import Foundation
import AppKit

let args = CommandLine.arguments
guard args.count >= 2 else {
  fputs("Usage: gen_letter_icon.swift <output.png> [letter]\n", stderr)
  exit(1)
}

let outPath = args[1]
let letter = args.count >= 3 ? args[2] : "A"
let size: CGFloat = 1024

let img = NSImage(size: NSSize(width: size, height: size))
img.lockFocus()

// Background
NSColor(calibratedRed: 0.12, green: 0.38, blue: 0.98, alpha: 1.0).setFill()
NSBezierPath(rect: NSRect(x: 0, y: 0, width: size, height: size)).fill()

// Text attributes
let paragraph = NSMutableParagraphStyle()
paragraph.alignment = .center
let font = NSFont.systemFont(ofSize: 720, weight: .bold)
let attributes: [NSAttributedString.Key: Any] = [
  .font: font,
  .foregroundColor: NSColor.white,
  .paragraphStyle: paragraph
]

let ns = NSString(string: letter)
let textSize = ns.size(withAttributes: attributes)
let textRect = NSRect(x: (size - textSize.width) / 2.0,
                      y: (size - textSize.height) / 2.0,
                      width: textSize.width,
                      height: textSize.height)
ns.draw(in: textRect, withAttributes: attributes)

img.unlockFocus()

guard let tiff = img.tiffRepresentation,
      let rep = NSBitmapImageRep(data: tiff),
      let png = rep.representation(using: .png, properties: [:]) else {
  fputs("Failed to render PNG icon\n", stderr)
  exit(2)
}

let outUrl = URL(fileURLWithPath: outPath)
try FileManager.default.createDirectory(at: outUrl.deletingLastPathComponent(), withIntermediateDirectories: true)
do {
  try png.write(to: outUrl)
} catch {
  fputs("Write error: \(error)\n", stderr)
  exit(3)
}

