import AppKit

enum AppIconGenerator {
    static func makeLetterIcon(letter: String = "A",
                               size: CGFloat = 512,
                               background: NSColor = NSColor.systemIndigo,
                               foreground: NSColor = NSColor.white,
                               cornerRadius: CGFloat? = nil) -> NSImage {
        let image = NSImage(size: NSSize(width: size, height: size))
        image.lockFocus()

        // Background (rounded)
        background.setFill()
        let radius = cornerRadius ?? size * 0.22
        let inset: CGFloat = size * 0.06
        let bgRect = NSRect(x: inset, y: inset, width: size - inset * 2, height: size - inset * 2)
        let rounded = NSBezierPath(roundedRect: bgRect, xRadius: radius, yRadius: radius)
        rounded.fill()

        // Letter centered
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .center
        // Font scales to image size
        let font = NSFont.systemFont(ofSize: size * 0.52, weight: .bold)
        let attrs: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: foreground,
            .paragraphStyle: paragraph
        ]
        let attributed = NSAttributedString(string: letter, attributes: attrs)
        // Center vertically by computing text size
        let textSize = attributed.size()
        let rect = NSRect(x: 0, y: (size - textSize.height) / 2, width: size, height: textSize.height)
        attributed.draw(in: rect)

        image.unlockFocus()
        return image
    }
}
