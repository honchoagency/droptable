import AppKit

// Renders a 1024×1024 app icon PNG: a database cylinder being dropped, for
// an app whose entire job is finding and deleting old database dumps.
// Usage: swift make-icon.swift <output.png>

let size = 1024.0
let rep = NSBitmapImageRep(
    bitmapDataPlanes: nil, pixelsWide: Int(size), pixelsHigh: Int(size),
    bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
    colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!

NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
let ctx = NSGraphicsContext.current!.cgContext

func rgb(_ r: Double, _ g: Double, _ b: Double, _ a: Double = 1) -> CGColor {
    CGColor(red: r / 255, green: g / 255, blue: b / 255, alpha: a)
}

let bgTop = rgb(51, 121, 176)      // lifted steel blue
let bgBottom = rgb(13, 32, 54)     // deep navy
let cylTop = rgb(255, 255, 255)    // lid highlight
let cylMain = rgb(223, 236, 250)   // body
let cylBottom = rgb(168, 197, 227) // underside shadow
let badgeColor = rgb(214, 58, 58)  // delete-red
let badgeRing = rgb(13, 32, 54)    // matches bg so the badge reads as "cut into" the scene

// Rounded-rect "squircle" background with a steel-blue → navy gradient.
let margin = 90.0
let rect = CGRect(x: margin, y: margin, width: size - margin * 2, height: size - margin * 2)
let bg = CGPath(roundedRect: rect, cornerWidth: 200, cornerHeight: 200, transform: nil)
ctx.saveGState()
ctx.addPath(bg)
ctx.clip()
let bgGrad = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                        colors: [bgTop, bgBottom] as CFArray, locations: [0, 1])!
ctx.drawLinearGradient(bgGrad, start: CGPoint(x: 0, y: size), end: CGPoint(x: 0, y: 0), options: [])
ctx.restoreGState()

let cx = size / 2
let cy = size / 2 + 30
let cylW = 460.0
let capH = 140.0
let bodyTop = cy + 190
let bodyBottom = cy - 170

// Classic 3-piece database cylinder: bottom cap, then body (covers its
// upper half), then top cap (covers the body's top edge).
func ellipse(_ midY: Double) -> CGRect {
    CGRect(x: cx - cylW / 2, y: midY - capH / 2, width: cylW, height: capH)
}

ctx.setFillColor(cylBottom)
ctx.addPath(CGPath(ellipseIn: ellipse(bodyBottom), transform: nil))
ctx.fillPath()

ctx.setFillColor(cylMain)
ctx.fill(CGRect(x: cx - cylW / 2, y: bodyBottom, width: cylW, height: bodyTop - bodyBottom))

ctx.setFillColor(cylTop)
ctx.addPath(CGPath(ellipseIn: ellipse(bodyTop), transform: nil))
ctx.fillPath()

// A thin band a third of the way down, echoing a stacked-rows database glyph.
ctx.setStrokeColor(cylBottom)
ctx.setLineWidth(10)
let bandY = bodyBottom + (bodyTop - bodyBottom) * 0.62
ctx.addPath(CGPath(ellipseIn: ellipse(bandY), transform: nil))
ctx.strokePath()

// "Drop" badge: a red circle with a white minus, cut into the bottom-right
// of the cylinder like a delete/remove overlay.
let badgeR = 150.0
let badgeCx = cx + cylW / 2 - 40
let badgeCy = bodyBottom - 10

ctx.setFillColor(badgeRing)
ctx.addArc(center: CGPoint(x: badgeCx, y: badgeCy), radius: badgeR + 14, startAngle: 0, endAngle: .pi * 2, clockwise: false)
ctx.fillPath()

ctx.setFillColor(badgeColor)
ctx.addArc(center: CGPoint(x: badgeCx, y: badgeCy), radius: badgeR, startAngle: 0, endAngle: .pi * 2, clockwise: false)
ctx.fillPath()

ctx.setFillColor(cylTop)
let bar = CGPath(roundedRect: CGRect(x: badgeCx - 70, y: badgeCy - 22, width: 140, height: 44),
                 cornerWidth: 22, cornerHeight: 22, transform: nil)
ctx.addPath(bar)
ctx.fillPath()

NSGraphicsContext.restoreGraphicsState()

let outPath = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "icon.png"
let png = rep.representation(using: .png, properties: [:])!
try! png.write(to: URL(fileURLWithPath: outPath))
print("wrote \(outPath)")
