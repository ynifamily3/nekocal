import AppKit

// Canonical 21×16pt template artwork. SVG-style top-left coordinates.
final class CatIconView: NSView {
    override var isFlipped: Bool { true }
    override func draw(_ dirtyRect: NSRect) {
        NSColor.black.setStroke()
        NSColor.black.setFill()
        let outline = NSBezierPath()
        outline.move(to: NSPoint(x: 3.7, y: 6.0))
        outline.line(to: NSPoint(x: 3.8, y: 1.8))
        outline.curve(to: NSPoint(x: 4.6, y: 1.4), controlPoint1: NSPoint(x: 3.8, y: 1.2), controlPoint2: NSPoint(x: 4.1, y: 1.1))
        outline.line(to: NSPoint(x: 7.3, y: 3.5))
        outline.curve(to: NSPoint(x: 13.7, y: 3.5), controlPoint1: NSPoint(x: 9.1, y: 2.8), controlPoint2: NSPoint(x: 11.9, y: 2.8))
        outline.line(to: NSPoint(x: 16.4, y: 1.4))
        outline.curve(to: NSPoint(x: 17.2, y: 1.8), controlPoint1: NSPoint(x: 16.9, y: 1.1), controlPoint2: NSPoint(x: 17.2, y: 1.2))
        outline.line(to: NSPoint(x: 17.3, y: 6.0))
        outline.curve(to: NSPoint(x: 16.3, y: 13.1), controlPoint1: NSPoint(x: 19.3, y: 8.6), controlPoint2: NSPoint(x: 18.4, y: 11.9))
        outline.curve(to: NSPoint(x: 4.7, y: 13.1), controlPoint1: NSPoint(x: 13.8, y: 14.6), controlPoint2: NSPoint(x: 7.2, y: 14.6))
        outline.curve(to: NSPoint(x: 3.7, y: 6.0), controlPoint1: NSPoint(x: 2.6, y: 11.9), controlPoint2: NSPoint(x: 1.7, y: 8.6))
        outline.close()
        outline.lineWidth = 1.35
        outline.lineJoinStyle = .round
        outline.lineCapStyle = .round
        outline.stroke()
        for x in [7.0, 12.5] {
            NSBezierPath(ovalIn: NSRect(x: x, y: 7.0, width: 1.5, height: 1.8)).fill()
        }
        let mouth = NSBezierPath()
        mouth.move(to: NSPoint(x: 10.5, y: 9.0))
        mouth.line(to: NSPoint(x: 10.5, y: 9.8))
        mouth.curve(to: NSPoint(x: 8.8, y: 10.4), controlPoint1: NSPoint(x: 10.0, y: 11.0), controlPoint2: NSPoint(x: 9.0, y: 11.0))
        mouth.move(to: NSPoint(x: 10.5, y: 9.8))
        mouth.curve(to: NSPoint(x: 12.2, y: 10.4), controlPoint1: NSPoint(x: 11.0, y: 11.0), controlPoint2: NSPoint(x: 12.0, y: 11.0))
        mouth.lineWidth = 1.15
        mouth.lineCapStyle = .round
        mouth.stroke()
        let whiskers = NSBezierPath()
        for (x1,y1,x2,y2) in [(0.9,8.2,4.0,8.8), (1.0,10.8,4.0,10.3), (17.0,8.8,20.1,8.2), (17.0,10.3,20.0,10.8)] {
            whiskers.move(to: NSPoint(x:x1,y:y1)); whiskers.line(to:NSPoint(x:x2,y:y2))
        }
        whiskers.lineWidth = 1.1
        whiskers.lineCapStyle = .round
        whiskers.stroke()
    }
}
let view = CatIconView(frame:NSRect(x:0,y:0,width:21,height:16))
let output = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "Itsycal/Images.xcassets/menubaricon3.imageset/KawaiiCal-MenuBarCat.pdf"
try view.dataWithPDF(inside:view.bounds).write(to:URL(fileURLWithPath:output))
