import AppKit

func generate(path: String, letter: String = "A") throws {
    let size: CGFloat = 1024
    let img = NSImage(size: NSSize(width: size, height: size))
    img.lockFocus()
    // Rounded background
    NSColor.systemIndigo.setFill()
    let inset: CGFloat = size * 0.06
    let radius: CGFloat = size * 0.22
    let bgRect = NSRect(x: inset, y: inset, width: size - inset * 2, height: size - inset * 2)
    let rounded = NSBezierPath(roundedRect: bgRect, xRadius: radius, yRadius: radius)
    rounded.fill()
    // Letter
    let paragraph = NSMutableParagraphStyle(); paragraph.alignment = .center
    let font = NSFont.systemFont(ofSize: size * 0.52, weight: .bold)
    let attrs: [NSAttributedString.Key: Any] = [ .font: font, .foregroundColor: NSColor.white, .paragraphStyle: paragraph ]
    let str = NSAttributedString(string: letter, attributes: attrs)
    let textSize = str.size()
    let rect = NSRect(x: 0, y: (size - textSize.height)/2, width: size, height: textSize.height)
    str.draw(in: rect)
    img.unlockFocus()
    guard let tiff = img.tiffRepresentation, let rep = NSBitmapImageRep(data: tiff), let data = rep.representation(using: .png, properties: [:]) else {
        throw NSError(domain: "gen", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to encode PNG"])
    }
    try data.write(to: URL(fileURLWithPath: path))
}

let out = CommandLine.arguments.dropFirst().first ?? "./AppIcon1024.png"
try generate(path: out)
print("Generated base icon at \(out)")
