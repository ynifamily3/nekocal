import AppKit

// Skeuomorphic desk-calendar app icon, drawn from scratch (no third-party
// artwork). Renders the 1024×1024 transparent foreground layer used by
// Itsycal/AppIcon.icon; Icon Composer supplies the background and mask.
//
//   swift Design/AppIconCalendar.swift Itsycal/AppIcon.icon/Assets/KawaiiCal-Calendar.png

let size: CGFloat = 1024
let output = CommandLine.arguments.dropFirst().first ?? "KawaiiCal-Calendar.png"

func rgb(_ hex: UInt32, _ alpha: CGFloat = 1) -> NSColor {
    NSColor(srgbRed: CGFloat((hex >> 16) & 0xff) / 255, green: CGFloat((hex >> 8) & 0xff) / 255, blue: CGFloat(hex & 0xff) / 255, alpha: alpha)
}

func linear(_ colors: [NSColor], _ locations: [CGFloat], in path: NSBezierPath, angle: CGFloat = -90) {
    NSGradient(colors: colors, atLocations: locations, colorSpace: .sRGB)!.draw(in: path, angle: angle)
}

final class IconView: NSView {
    override var isFlipped: Bool { false }

    override func draw(_ dirtyRect: NSRect) {
        // Calendar block. y grows upward (AppKit); top of the page is near 900.
        let page = NSRect(x: 132, y: 132, width: 760, height: 742)
        let radius: CGFloat = 78
        let headerHeight: CGFloat = 236

        // Soft contact shadow under the whole object.
        NSGraphicsContext.saveGraphicsState()
        let drop = NSShadow()
        drop.shadowColor = NSColor.black.withAlphaComponent(0.35)
        drop.shadowBlurRadius = 34
        drop.shadowOffset = NSSize(width: 0, height: -18)
        drop.set()
        rgb(0xd9d4cb).setFill()
        NSBezierPath(roundedRect: page.offsetBy(dx: 0, dy: -22), xRadius: radius, yRadius: radius).fill()
        NSGraphicsContext.restoreGraphicsState()

        // Stacked sheets peeking out below the top sheet.
        for (i, shade) in [(3, 0xcfc9bf), (2, 0xdeD9d0), (1, 0xebe7e0)] as [(Int, UInt32)] {
            let sheet = NSBezierPath(roundedRect: page.offsetBy(dx: 0, dy: -CGFloat(i) * 7), xRadius: radius, yRadius: radius)
            linear([rgb(shade), rgb(shade).blended(withFraction: 0.18, of: .black)!], [0, 1], in: sheet)
            rgb(0x000000, 0.10).setStroke()
            sheet.lineWidth = 1.5
            sheet.stroke()
        }

        // Top sheet: warm white paper.
        let sheet = NSBezierPath(roundedRect: page, xRadius: radius, yRadius: radius)
        linear([rgb(0xffffff), rgb(0xfbf9f5), rgb(0xeeeae2)], [0, 0.55, 1], in: sheet)

        // Faint paper grain, clipped to the sheet.
        NSGraphicsContext.saveGraphicsState()
        sheet.addClip()
        var seed: UInt64 = 0x5eed
        func rand() -> CGFloat { seed = seed &* 6364136223846793005 &+ 1442695040888963407; return CGFloat(seed >> 33) / CGFloat(1 << 31) }
        for _ in 0..<5000 {
            let x = page.minX + rand() * page.width, y = page.minY + rand() * page.height
            NSColor(white: rand() < 0.5 ? 0 : 1, alpha: 0.035).setFill()
            NSRect(x: x, y: y, width: 2, height: 2).fill()
        }
        NSGraphicsContext.restoreGraphicsState()

        // Red header band with a glossy finish, clipped to the sheet's top.
        let headerRect = NSRect(x: page.minX, y: page.maxY - headerHeight, width: page.width, height: headerHeight)
        NSGraphicsContext.saveGraphicsState()
        sheet.addClip()
        let header = NSBezierPath(rect: headerRect)
        linear([rgb(0xf2594d), rgb(0xd8352b), rgb(0xa8201a)], [0, 0.55, 1], in: header)
        // Gloss on the upper half.
        let gloss = NSBezierPath(rect: NSRect(x: headerRect.minX, y: headerRect.midY + 8, width: headerRect.width, height: headerRect.height / 2))
        linear([NSColor.white.withAlphaComponent(0.30), NSColor.white.withAlphaComponent(0.04)], [0, 1], in: gloss)
        // Stitching near both edges of the band.
        for y in [headerRect.maxY - 30, headerRect.minY + 30] {
            let stitch = NSBezierPath()
            stitch.move(to: NSPoint(x: headerRect.minX + 40, y: y))
            stitch.line(to: NSPoint(x: headerRect.maxX - 40, y: y))
            stitch.lineWidth = 5
            stitch.setLineDash([18, 12], count: 2, phase: 0)
            stitch.lineCapStyle = .round
            NSColor.white.withAlphaComponent(0.55).setStroke()
            stitch.stroke()
            stitch.transform(using: AffineTransform(translationByX: 0, byY: -3))
            NSColor.black.withAlphaComponent(0.18).setStroke()
            stitch.stroke()
        }
        // Shadow the band casts onto the paper.
        let lip = NSBezierPath(rect: NSRect(x: headerRect.minX, y: headerRect.minY - 26, width: headerRect.width, height: 26))
        linear([NSColor.black.withAlphaComponent(0.20), NSColor.black.withAlphaComponent(0)], [0, 1], in: lip)
        rgb(0x7d1410).setFill()
        NSRect(x: headerRect.minX, y: headerRect.minY - 2, width: headerRect.width, height: 4).fill()
        NSGraphicsContext.restoreGraphicsState()

        // Header label.
        let label = "CALENDAR" as NSString
        let labelFont = NSFont.systemFont(ofSize: 74, weight: .heavy)
        let labelShadow = NSShadow()
        labelShadow.shadowColor = NSColor.black.withAlphaComponent(0.35)
        labelShadow.shadowOffset = NSSize(width: 0, height: -4)
        labelShadow.shadowBlurRadius = 4
        let labelAttrs: [NSAttributedString.Key: Any] = [.font: labelFont, .foregroundColor: NSColor.white, .kern: 10, .shadow: labelShadow]
        let labelSize = label.size(withAttributes: labelAttrs)
        label.draw(at: NSPoint(x: page.midX - labelSize.width / 2 + 5, y: headerRect.midY - labelSize.height / 2 - 18), withAttributes: labelAttrs)

        // Big date, letterpressed into the paper.
        let day = "31" as NSString
        let dayFont = NSFont.systemFont(ofSize: 400, weight: .bold)
        let paragraph = NSMutableParagraphStyle(); paragraph.alignment = .center
        let daySize = day.size(withAttributes: [.font: dayFont, .kern: -12])
        let dayOrigin = NSPoint(x: page.midX - daySize.width / 2, y: page.minY + (page.height - headerHeight) / 2 - daySize.height / 2 + 6)
        let highlight: [NSAttributedString.Key: Any] = [.font: dayFont, .kern: -12, .foregroundColor: NSColor.white.withAlphaComponent(0.9)]
        day.draw(at: NSPoint(x: dayOrigin.x, y: dayOrigin.y - 4), withAttributes: highlight)
        let ink: [NSAttributedString.Key: Any] = [.font: dayFont, .kern: -12, .foregroundColor: rgb(0x2b2b2e)]
        day.draw(at: dayOrigin, withAttributes: ink)

        // Binder rings through punched holes at the top edge.
        for cx in [page.minX + 200, page.maxX - 200] {
            let holeRect = NSRect(x: cx - 34, y: page.maxY - 92, width: 68, height: 44)
            let hole = NSBezierPath(ovalIn: holeRect)
            linear([rgb(0x3a0c09), rgb(0x6e1712)], [0, 1], in: hole)
            // Ring: a thick rounded bar rising from the hole above the page.
            let ring = NSBezierPath(roundedRect: NSRect(x: cx - 19, y: page.maxY - 72, width: 38, height: 118), xRadius: 19, yRadius: 19)
            NSGraphicsContext.saveGraphicsState()
            let ringShadow = NSShadow()
            ringShadow.shadowColor = NSColor.black.withAlphaComponent(0.45)
            ringShadow.shadowBlurRadius = 10
            ringShadow.shadowOffset = NSSize(width: 0, height: -6)
            ringShadow.set()
            rgb(0x8f949b).setFill()
            ring.fill()
            NSGraphicsContext.restoreGraphicsState()
            linear([rgb(0x6c7178), rgb(0xf4f6f8), rgb(0xb9bec5), rgb(0x7b8087)], [0, 0.35, 0.6, 1], in: ring, angle: 0)
            rgb(0x4b4f55, 0.6).setStroke()
            ring.lineWidth = 2
            ring.stroke()
        }

        // Page curl at the lower right corner.
        let c = NSPoint(x: page.maxX, y: page.minY)
        let curlSize: CGFloat = 150
        NSGraphicsContext.saveGraphicsState()
        sheet.addClip()
        // Reveal the sheet beneath.
        let under = NSBezierPath()
        under.move(to: NSPoint(x: c.x - curlSize, y: c.y))
        under.line(to: NSPoint(x: c.x, y: c.y))
        under.line(to: NSPoint(x: c.x, y: c.y + curlSize))
        under.close()
        rgb(0xd6d0c6).setFill()
        under.fill()
        NSGraphicsContext.restoreGraphicsState()
        // The folded flap.
        let flap = NSBezierPath()
        flap.move(to: NSPoint(x: c.x - curlSize, y: c.y))
        flap.curve(to: NSPoint(x: c.x - 24, y: c.y + 30), controlPoint1: NSPoint(x: c.x - curlSize + 40, y: c.y + 40), controlPoint2: NSPoint(x: c.x - 70, y: c.y + 60))
        flap.line(to: NSPoint(x: c.x, y: c.y + curlSize))
        flap.curve(to: NSPoint(x: c.x - curlSize, y: c.y), controlPoint1: NSPoint(x: c.x - 60, y: c.y + 90), controlPoint2: NSPoint(x: c.x - 110, y: c.y + 40))
        flap.close()
        NSGraphicsContext.saveGraphicsState()
        let flapShadow = NSShadow()
        flapShadow.shadowColor = NSColor.black.withAlphaComponent(0.30)
        flapShadow.shadowBlurRadius = 16
        flapShadow.shadowOffset = NSSize(width: -6, height: 8)
        flapShadow.set()
        rgb(0xf3efe8).setFill()
        flap.fill()
        NSGraphicsContext.restoreGraphicsState()
        linear([rgb(0xffffff), rgb(0xe9e4db), rgb(0xc9c2b6)], [0, 0.6, 1], in: flap, angle: 45)

        // Thin outline to keep the edge crisp on light backgrounds.
        rgb(0x000000, 0.12).setStroke()
        sheet.lineWidth = 2
        sheet.stroke()
    }
}

let view = IconView(frame: NSRect(x: 0, y: 0, width: size, height: size))
let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: Int(size), pixelsHigh: Int(size), bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
rep.size = NSSize(width: size, height: size)
NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
view.draw(view.bounds)
NSGraphicsContext.restoreGraphicsState()
try! rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: output))
print("Wrote \(output)")
